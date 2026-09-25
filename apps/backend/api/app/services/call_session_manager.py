import asyncio
import base64
from datetime import UTC, date, datetime, timedelta
import json
import logging
import re
import time
from typing import Any
import uuid

from fastapi import WebSocket
from sqlalchemy import desc, select
from sqlalchemy.orm import selectinload

from ai.services.dass_extraction_service import DASSExtractionService
from app.core.call_config import call_config
from app.core.prompt_templates import LUNA_SYSTEM_PROMPT
from app.core.security import decode_access_token
from app.core.tz import get_wib_now, get_wib_today
from app.db.session import AsyncSessionLocal
from app.models.conversation import Conversation, ConversationSummary, Message
from app.models.dass import DASSAssessment
from app.models.diary import DiaryEntry
from app.models.enums import MessageType
from app.models.user import User
from app.services.dass_service import DASSService
from app.services.diary_generator import DiaryGeneratorService
from app.services.emotion_analyzer import EmotionAnalyzerService
from app.services.ml_emotion_detector import MLEmotionDetectorService
from app.services.turn_aggregator import TurnAggregator
from packages.ai.factories.llm_factory import LLMFactory
from packages.ai.factories.tts_factory import TTSFactory
from packages.ai.interfaces.llm import LLMMessage
from packages.ai.orchestration.orchestrator import AIOrchestrator, OrchestratedTurnResult
from packages.ai.providers.tts.elevenlabs_ttd_provider import ElevenLabsTTDProvider, ElevenLabsTTDSession
from packages.ai.utils.emotion_style_mapper import (
    map_emotion_to_delivery_style,
    resolve_dynamic_voice_style,
    strip_audio_tags,
)
from packages.ai.utils.sentence_chunker import LatencyAwareSentenceChunker, SpeechChunk
from packages.ai.utils.tts_text_normalizer import sanitize_text_for_tts
from packages.ai.utils.voice_character_modes import (
    DEFAULT_VOICE_MODE,
    get_voice_character_mode,
)

logger = logging.getLogger(__name__)


class CallSession:
    def __init__(
        self,
        session_id: str,
        websocket: WebSocket,
        auth_token: str | None = None,
        voice_mode: str | None = None,
    ) -> None:
        self.session_id = session_id
        self.websocket = websocket
        self.auth_token = auth_token
        self.voice_mode: str = voice_mode or DEFAULT_VOICE_MODE
        self.state: str = "idle"  # idle | listening | user_speaking | ai_thinking | ai_speaking | interrupted
        self.db_conversation_id: Any | None = None
        self.user_id: Any | None = None
        self.user_name: str | None = None
        self.is_history_loaded: bool = False
        self.conversation_history: list[LLMMessage] = [
            LLMMessage(role="system", content=LUNA_SYSTEM_PROMPT)
        ]
        self.current_task_id: int = 0
        self.assistant_turn_id: int = 0
        self.cancelled_assistant_turn_ids: set[int] = set()
        self._current_ai_task: asyncio.Task[Any] | None = None
        self._active_ttd_session: ElevenLabsTTDSession | None = None
        self._endpoint_timer_task: asyncio.Task[Any] | None = None
        self.aggregator = TurnAggregator(call_id=session_id, initial_turn_id=1)
        self.thesis_metrics_log: list[dict[str, Any]] = []
        self.latest_orchestration_turn: OrchestratedTurnResult | None = None
        self.dass_scores: dict[str, int] | None = None

    def cancel_active_ai_task(self) -> None:
        if self._current_ai_task and not self._current_ai_task.done():
            current = asyncio.current_task()
            if current != self._current_ai_task:
                logger.info(f"⚡ [BARGE-IN CANCEL] Session {self.session_id}: Cancelling active AI task {self.current_task_id}")
                self._current_ai_task.cancel()
            self._current_ai_task = None
        if self._active_ttd_session:
            asyncio.create_task(self._active_ttd_session.close())
            self._active_ttd_session = None
        self.cancel_endpoint_timer()
        if self.assistant_turn_id > 0:
            self.cancelled_assistant_turn_ids.add(self.assistant_turn_id)

    def cancel_endpoint_timer(self) -> None:
        if self._endpoint_timer_task and not self._endpoint_timer_task.done():
            current = asyncio.current_task()
            if current != self._endpoint_timer_task:
                self._endpoint_timer_task.cancel()
            self._endpoint_timer_task = None


class CallSessionManager:
    """Session Manager for real-time WebSocket AI phone calls with conversation history & dynamic AI emotion analysis."""

    def __init__(self) -> None:
        self._active_sessions: dict[str, CallSession] = {}
        self.orchestrator = AIOrchestrator()

    def register_session(
        self,
        session_id: str,
        websocket: WebSocket,
        auth_token: str | None = None,
        voice_mode: str | None = None,
    ) -> CallSession:
        session = CallSession(
            session_id=session_id,
            websocket=websocket,
            auth_token=auth_token,
            voice_mode=voice_mode,
        )
        self._active_sessions[session_id] = session
        logger.info(f"Registered call session {session_id} (Voice Mode: {session.voice_mode})")
        return session

    def unregister_session(self, session_id: str) -> None:
        if session_id in self._active_sessions:
            session = self._active_sessions[session_id]
            session.cancel_active_ai_task()
            session.cancel_endpoint_timer()

            # Launch background sync for Today's Diary & DASS-21 ONCE upon session disconnect
            if session.conversation_history and len(session.conversation_history) > 1:
                logger.info(f"🔌 [DISCONNECT DIARY SYNC START] Session {session_id}: Generating today's diary entry via DeepSeek LLM...")
                asyncio.create_task(self._sync_today_diary(session))
                logger.info(f"📊 [DISCONNECT DASS SYNC START] Session {session_id}: Extracting today's DASS-21 assessment...")
                asyncio.create_task(self._sync_today_dass(session))

            del self._active_sessions[session_id]
            logger.info(f"Unregistered call session {session_id}")

    def get_session(self, session_id: str) -> CallSession | None:
        return self._active_sessions.get(session_id)

    async def load_conversation_history(self, session: CallSession) -> None:
        if session.is_history_loaded:
            return

        try:
            async with AsyncSessionLocal() as db:
                user = None
                if session.auth_token:
                    decoded = decode_access_token(session.auth_token)
                    if decoded and "sub" in decoded:
                        try:
                            u_uuid = uuid.UUID(decoded["sub"])
                            res_user = await db.execute(select(User).where(User.id == u_uuid))
                            user = res_user.scalar_one_or_none()
                        except Exception:
                            pass

                if user:
                    session.user_id = user.id
                    session.user_name = user.display_name or user.username or None
                    logger.info(f"👤 [USER CONTEXT LOADED] Session {session.session_id}: User ID {user.id}, Name: '{session.user_name}'")

                    # Retrieve previous conversation history memory context
                    conv_query = (
                        select(Conversation)
                        .options(selectinload(Conversation.messages))
                        .where(Conversation.user_id == user.id)
                        .order_by(Conversation.started_at.desc())
                    )
                    res_conv = await db.execute(conv_query)
                    past_convs = res_conv.scalars().all()

                    if past_convs:
                        all_past_msgs = []
                        for pc in past_convs[:5]:
                            sorted_m = sorted(pc.messages, key=lambda m: m.sequence_number)
                            all_past_msgs.extend([f"{m.role}: {m.content}" for m in sorted_m if m.content])

                        if all_past_msgs:
                            memory_summary = " ".join(all_past_msgs[-10:])[:1000]
                            session.conversation_history[0].content += (
                                f"\n\n[Memori Percakapan Terdahulu Pengguna]:\n{memory_summary}"
                            )

                    # Retrieve latest DASS-21 psychometric assessment context
                    dass_stmt = (
                        select(DASSAssessment)
                        .where(DASSAssessment.user_id == user.id)
                        .order_by(desc(DASSAssessment.assessed_date))
                        .limit(1)
                    )
                    res_dass = await db.execute(dass_stmt)
                    latest_dass = res_dass.scalars().first()
                    if latest_dass and (latest_dass.depression_score > 0 or latest_dass.anxiety_score > 0 or latest_dass.stress_score > 0):
                        session.dass_scores = {
                            "depression": latest_dass.depression_score,
                            "anxiety": latest_dass.anxiety_score,
                            "stress": latest_dass.stress_score,
                        }
                        session.conversation_history[0].content += (
                            f"\n\n[Profil Asesmen Psikologis DASS-21 Terkini Pengguna]:\n"
                            f"- Tingkat Depresi: {latest_dass.depression_severity} (Skor: {latest_dass.depression_score})\n"
                            f"- Tingkat Kecemasan: {latest_dass.anxiety_severity} (Skor: {latest_dass.anxiety_score})\n"
                            f"- Tingkat Stres: {latest_dass.stress_severity} (Skor: {latest_dass.stress_score})\n"
                            f"Gunakan profil ini sebagai acuan empati dan gaya berbicara (jangan sebut angka skor secara kaku, "
                            f"melainkan sesuaikan kehangatan dan kepekaanmu terhadap kondisi emosionalnya)."
                        )
                        logger.info(
                            f"📊 [DASS CONTEXT LOADED] Session {session.session_id}: "
                            f"Depression={latest_dass.depression_severity}, Anxiety={latest_dass.anxiety_severity}, Stress={latest_dass.stress_severity}"
                        )

                    # Always create a NEW distinct Conversation record for this new voice session
                    now_str = get_wib_now().strftime("%d %b %Y %H:%M")
                    new_conv = Conversation(
                        user_id=user.id,
                        title=f"Panggilan Suara LUNA {now_str}"
                    )
                    db.add(new_conv)
                    await db.commit()
                    await db.refresh(new_conv)

                    session.db_conversation_id = new_conv.id
                    logger.info(
                        f"📜 [NEW VOICE CONVERSATION CREATED] Session {session.session_id}: "
                        f"Created Conversation ID {new_conv.id} ('{new_conv.title}') in DB"
                    )

            session.is_history_loaded = True
        except Exception as e:
            logger.error(f"⚠️ [LOAD HISTORY EXCEPTION] Session {session.session_id}: {e}")
            session.is_history_loaded = True

    async def _save_message_to_db(self, session: CallSession, role: str, content: str) -> None:
        if not session.db_conversation_id or not content.strip():
            return
        try:
            async with AsyncSessionLocal() as db:
                query = (
                    select(Conversation)
                    .options(selectinload(Conversation.messages))
                    .where(Conversation.id == session.db_conversation_id)
                )
                res = await db.execute(query)
                conv = res.scalar_one_or_none()
                if conv:
                    next_seq = len(conv.messages) + 1
                    msg = Message(
                        conversation_id=conv.id,
                        role=role,
                        content=content,
                        message_type=MessageType.VOICE,
                        sequence_number=next_seq,
                    )
                    conv.last_message_at = datetime.now(UTC)
                    db.add(msg)
                    await db.commit()
                    await db.refresh(msg)
                    logger.info(f"💾 [SAVED TO DB] Session {session.session_id}: Saved {role} voice message to DB")

                    if role == "user" and content and content.strip():
                        try:
                            analysis_result = await MLEmotionDetectorService.predict_message_emotion(content)
                            await MLEmotionDetectorService.save_emotion_to_db(msg.id, analysis_result, db)
                            logger.info(f"🧠 [VOICE EMOTION PERSISTED]: Saved emotion for voice turn message {msg.id}")
                        except Exception as emo_err:
                            logger.warning(f"⚠️ [VOICE EMOTION EXCEPTION]: Failed to save emotion analysis: {emo_err}")
        except Exception as e:
            logger.error(f"⚠️ [SAVE MSG EXCEPTION] Session {session.session_id}: {e}")

    async def update_session_end(self, session_id: str, duration_seconds: int | None = None) -> None:
        session = self.get_session(session_id)
        if not session or not session.db_conversation_id:
            return
        try:
            async with AsyncSessionLocal() as db:
                query = select(Conversation).where(Conversation.id == session.db_conversation_id)
                res = await db.execute(query)
                conv = res.scalar_one_or_none()
                if conv:
                    now = datetime.now(UTC)
                    if duration_seconds and duration_seconds > 0:
                        conv.last_message_at = conv.started_at + timedelta(seconds=duration_seconds)
                    else:
                        conv.last_message_at = now
                    await db.commit()
                    logger.info(f"⏱️ [SESSION END DURATION PERSISTED] Session {session_id}: Updated last_message_at to {conv.last_message_at}")
        except Exception as e:
            logger.error(f"⚠️ [UPDATE SESSION END EXCEPTION] Session {session_id}: {e}")

    async def _sync_today_diary(self, session: CallSession) -> None:
        """Create or Update today's single DiaryEntry ONCE upon disconnecting a voice call session using DeepSeek AI."""
        if not session.user_id:
            return

        try:
            user_texts = [m.content for m in session.conversation_history if m.role == "user" and m.content]
            if not user_texts:
                return

            analysis = await EmotionAnalyzerService.analyze_transcript(session.conversation_history)

            session_title = analysis.get("session_title")
            session_summary = analysis.get("diary_summary") or analysis.get("ai_insight")
            if session.db_conversation_id:
                async with AsyncSessionLocal() as db_conv:
                    conv_res = await db_conv.execute(select(Conversation).where(Conversation.id == session.db_conversation_id))
                    conv_obj = conv_res.scalar_one_or_none()
                    if conv_obj:
                        if session_title:
                            conv_obj.title = session_title
                        if session_summary:
                            new_summary = ConversationSummary(
                                conversation_id=conv_obj.id,
                                summary=session_summary,
                            )
                            db_conv.add(new_summary)
                        await db_conv.commit()
                        logger.info(f"🏷️ [AI CONVERSATION TITLE & SUMMARY PERSISTED]: Conversation {conv_obj.id} -> '{session_title}'")

            async with AsyncSessionLocal() as db:
                diary_entry = await DiaryGeneratorService.generate_today_diary(session.user_id, db)
                logger.info(f"📖 [DISCONNECT DIARY SYNC SUCCESS] Session {session.session_id}: Synced cumulative DiaryEntry '{diary_entry.title}' for {diary_entry.entry_date}")
        except Exception as e:
            logger.error(f"⚠️ [SYNC DIARY EXCEPTION] Session {session.session_id}: {e}")

    async def _sync_today_dass(self, session: CallSession) -> None:
        """Extract and update today's DASS-21 assessment upon disconnecting a voice call session."""
        if not session.user_id:
            return

        try:
            user_texts = [m.content for m in session.conversation_history if m.role == "user" and m.content]
            if not user_texts:
                return

            formatted_msgs = []
            for m in session.conversation_history:
                if m.role in ("user", "assistant") and m.content and m.content.strip():
                    formatted_msgs.append(f"{m.role.upper()}: {m.content}")

            transcript = "\n".join(formatted_msgs)
            extractor = DASSExtractionService()
            extracted_items = await extractor.extract_from_transcript(transcript)

            async with AsyncSessionLocal() as db:
                today_wib = get_wib_today()
                saved_record = await DASSService.save_or_update_extracted(
                    user_id=session.user_id,
                    assessed_date=today_wib,
                    extracted_items=extracted_items,
                    conversation_id=session.db_conversation_id,
                    db=db,
                )
                logger.info(
                    f"📊 [DISCONNECT DASS SYNC SUCCESS] Session {session.session_id}: "
                    f"Synced DASS-21 for {today_wib} (D: {saved_record.depression_score}, "
                    f"A: {saved_record.anxiety_score}, S: {saved_record.stress_score})"
                )
        except Exception as e:
            logger.error(f"⚠️ [SYNC DASS EXCEPTION] Session {session.session_id}: {e}")

    # --------------------------------------------------------------------------
    # Hybrid Half-Duplex WebSocket Event Handlers
    # --------------------------------------------------------------------------

    async def handle_event(self, session: CallSession, payload: dict[str, Any]) -> None:
        """Central event dispatcher for Hybrid Half-Duplex WebSocket protocol."""
        event_type = payload.get("type")

        if event_type == "stt.partial":
            await self._handle_stt_partial(session, payload)
        elif event_type == "stt.final_segment":
            await self._handle_stt_final_segment(session, payload)
        elif event_type == "stt.status":
            await self._handle_stt_status(session, payload)
        elif event_type == "assistant.interrupt":
            await self._handle_assistant_interrupt(session, payload)
        elif event_type == "playback.finished":
            await self._handle_playback_finished(session, payload)
        elif event_type == "user.force_commit":
            await self._handle_force_commit(session, payload)
        elif event_type == "call.sync":
            await self._handle_call_sync(session, payload)
        # Backward compatibility events
        elif event_type == "start_call":
            if "voice_mode" in payload and payload["voice_mode"]:
                session.voice_mode = str(payload["voice_mode"]).strip()
            logger.info(f"🚀 [CALL STARTED] Session {session.session_id} (Voice Mode: {session.voice_mode})")
            session.state = "listening"
            await session.websocket.send_json({
                "type": "call_started",
                "session_id": session.session_id,
                "voice_mode": session.voice_mode,
            })
        elif event_type == "user_transcript":
            user_text = payload.get("text", "")
            logger.info(f"💬 [LEGACY USER TRANSCRIPT] Session {session.session_id}: '{user_text}'")
            await self.handle_user_transcript(session, user_text)
        elif event_type == "user_interrupted":
            logger.info(f"⚡ [LEGACY USER INTERRUPTED] Session {session.session_id}")
            await self._handle_assistant_interrupt(session, {"assistant_turn_id": session.assistant_turn_id})
        elif event_type == "ping":
            await session.websocket.send_json({"type": "pong"})

    async def _handle_stt_partial(self, session: CallSession, payload: dict[str, Any]) -> None:
        text = payload.get("text", "").strip()
        user_turn_id = payload.get("user_turn_id", session.aggregator.user_turn_id)
        stt_session_id = payload.get("stt_session_id", 1)

        if session.aggregator.is_committed:
            return

        if user_turn_id != session.aggregator.user_turn_id:
            logger.info(
                f"🔄 [TURN AUTO-ALIGN PARTIAL] Session {session.session_id}: Aligning turn {session.aggregator.user_turn_id} -> {user_turn_id}"
            )
            session.aggregator.current_turn.user_turn_id = user_turn_id

        session.state = "user_speaking"
        session.cancel_endpoint_timer()
        session.aggregator.add_partial(text, stt_session_id)
        await self._evaluate_and_act(session)

    async def _handle_stt_final_segment(self, session: CallSession, payload: dict[str, Any]) -> None:
        text = payload.get("text", "").strip()
        user_turn_id = payload.get("user_turn_id", session.aggregator.user_turn_id)
        stt_session_id = payload.get("stt_session_id", 1)

        if session.aggregator.is_committed:
            logger.warning(f"⚠️ [STT FINAL DISCARDED] Turn already committed: {session.aggregator.user_turn_id}")
            return

        if user_turn_id != session.aggregator.user_turn_id:
            logger.info(
                f"🔄 [TURN AUTO-ALIGN FINAL] Session {session.session_id}: Aligning turn {session.aggregator.user_turn_id} -> {user_turn_id}"
            )
            session.aggregator.current_turn.user_turn_id = user_turn_id

        session.cancel_endpoint_timer()
        session.aggregator.add_final_segment(text, stt_session_id)
        logger.info(
            f"🎙️ [STT FINAL SEGMENT] Session {session.session_id} | Turn {user_turn_id} | "
            f"Session {stt_session_id}: '{text}'"
        )
        await self._evaluate_and_act(session)

    async def _handle_stt_status(self, session: CallSession, payload: dict[str, Any]) -> None:
        status = payload.get("status", "")
        user_turn_id = payload.get("user_turn_id", session.aggregator.user_turn_id)
        stt_session_id = payload.get("stt_session_id", 1)

        if session.aggregator.is_committed:
            return

        if user_turn_id != session.aggregator.user_turn_id:
            session.aggregator.current_turn.user_turn_id = user_turn_id

        session.aggregator.update_stt_status(status, stt_session_id)
        logger.info(f"🎙️ [STT STATUS] Session {session.session_id} | Turn {user_turn_id}: status={status}")
        await self._evaluate_and_act(session)

    async def _handle_assistant_interrupt(self, session: CallSession, payload: dict[str, Any]) -> None:
        turn_id = payload.get("assistant_turn_id", session.assistant_turn_id)
        logger.info(f"⚡ [ASSISTANT INTERRUPT] Session {session.session_id} | Assistant Turn {turn_id}")

        session.cancel_active_ai_task()
        session.cancel_endpoint_timer()
        session.cancelled_assistant_turn_ids.add(turn_id)
        session.state = "interrupted"

        # Prepare new user turn for immediate speaking
        session.aggregator.reset_for_new_turn()

        # Send structured interrupt ack and legacy ack
        await session.websocket.send_json({
            "type": "assistant.interrupted_ack",
            "call_id": session.session_id,
            "assistant_turn_id": turn_id,
        })
        await session.websocket.send_json({"type": "interrupted_ack"})

    async def _handle_playback_finished(self, session: CallSession, payload: dict[str, Any]) -> None:
        turn_id = payload.get("assistant_turn_id", session.assistant_turn_id)
        if turn_id in session.cancelled_assistant_turn_ids:
            logger.info(f"⚡ [PLAYBACK FINISHED IGNORED] Session {session.session_id}: Turn {turn_id} was cancelled")
            return

        logger.info(f"🔊 [PLAYBACK FINISHED CONFIRMED] Session {session.session_id}: Turn {turn_id}")
        session.state = "listening"

        if session.aggregator.is_committed:
            session.aggregator.reset_for_new_turn()

        await session.websocket.send_json({
            "type": "call.sync_state",
            "call_id": session.session_id,
            "state": "listening",
            "active_user_turn_id": session.aggregator.user_turn_id,
            "active_assistant_turn_id": session.assistant_turn_id,
        })

    async def _handle_force_commit(self, session: CallSession, payload: dict[str, Any]) -> None:
        user_turn_id = payload.get("user_turn_id", session.aggregator.user_turn_id)
        if session.aggregator.is_committed:
            return

        if user_turn_id != session.aggregator.user_turn_id:
            logger.info(
                f"🔄 [FORCE COMMIT AUTO-ALIGN] Session {session.session_id}: Aligning turn {session.aggregator.user_turn_id} -> {user_turn_id}"
            )
            session.aggregator.current_turn.user_turn_id = user_turn_id

        logger.info(f"👆 [USER FORCE COMMIT] Session {session.session_id} | Turn {user_turn_id}")
        transcript = session.aggregator.force_commit()
        if transcript.strip():
            await self._commit_turn_and_start_ai(session, transcript, reason="manual_commit")
        else:
            logger.info(
                f"ℹ️ [EMPTY FORCE COMMIT] Session {session.session_id}: Turn {user_turn_id} transcript is empty, resetting aggregator and keeping turn open"
            )
            session.aggregator.reset_for_new_turn(user_turn_id)
            await session.websocket.send_json({
                "type": "turn.keep_open",
                "call_id": session.session_id,
                "user_turn_id": user_turn_id,
                "restart_stt": True,
                "reason": "empty_force_commit",
            })

    async def _handle_call_sync(self, session: CallSession, payload: dict[str, Any]) -> None:
        await session.websocket.send_json({
            "type": "call.sync_state",
            "call_id": session.session_id,
            "state": session.state,
            "active_user_turn_id": session.aggregator.user_turn_id,
            "active_assistant_turn_id": session.assistant_turn_id,
        })

    # --------------------------------------------------------------------------
    # Evaluation & Scheduling
    # --------------------------------------------------------------------------

    async def _evaluate_and_act(self, session: CallSession) -> None:
        if session.aggregator.is_committed:
            return

        result = session.aggregator.evaluate_turn()
        user_turn_id = session.aggregator.user_turn_id

        if result.decision == "COMMIT":
            final_transcript = session.aggregator.commit(reason=result.reason)
            if final_transcript.strip():
                await self._commit_turn_and_start_ai(session, final_transcript, result.reason)
            else:
                session.aggregator.reset_for_new_turn(user_turn_id)
                await session.websocket.send_json({
                    "type": "turn.keep_open",
                    "call_id": session.session_id,
                    "user_turn_id": user_turn_id,
                    "restart_stt": True,
                    "reason": "empty_transcript",
                })

        elif result.decision == "KEEP_OPEN":
            await session.websocket.send_json({
                "type": "turn.keep_open",
                "call_id": session.session_id,
                "user_turn_id": user_turn_id,
                "restart_stt": True,
                "wait_ms": result.wait_ms,
                "reason": result.reason,
            })
            self._schedule_endpoint_timer(session, user_turn_id, result.wait_ms)

        elif result.decision == "WAIT":
            self._schedule_endpoint_timer(session, user_turn_id, result.wait_ms)

    def _schedule_endpoint_timer(self, session: CallSession, user_turn_id: int, wait_ms: int) -> None:
        session.cancel_endpoint_timer()

        async def _timer_worker() -> None:
            try:
                await asyncio.sleep(wait_ms / 1000.0)
                if session.aggregator.user_turn_id == user_turn_id and not session.aggregator.is_committed:
                    logger.info(f"⏳ [ENDPOINT TIMER FIRED] Session {session.session_id}: Turn {user_turn_id} after {wait_ms}ms")
                    eval_res = session.aggregator.evaluate_turn()
                    if eval_res.decision == "COMMIT":
                        transcript = session.aggregator.commit(reason=eval_res.reason)
                        if transcript.strip():
                            await self._commit_turn_and_start_ai(session, transcript, eval_res.reason)
                    elif eval_res.decision == "KEEP_OPEN":
                        await session.websocket.send_json({
                            "type": "turn.keep_open",
                            "call_id": session.session_id,
                            "user_turn_id": user_turn_id,
                            "restart_stt": True,
                            "wait_ms": eval_res.wait_ms,
                            "reason": eval_res.reason,
                        })
                        self._schedule_endpoint_timer(session, user_turn_id, eval_res.wait_ms)
                    elif eval_res.decision == "WAIT":
                        if eval_res.wait_ms <= 80:
                            transcript = session.aggregator.commit(reason=eval_res.reason)
                            if transcript.strip():
                                await self._commit_turn_and_start_ai(session, transcript, eval_res.reason)
                        else:
                            self._schedule_endpoint_timer(session, user_turn_id, eval_res.wait_ms)
            except asyncio.CancelledError:
                pass
            except Exception as ex:
                logger.error(f"⚠️ [ENDPOINT TIMER ERROR] Session {session.session_id}: {ex}")

        session._endpoint_timer_task = asyncio.create_task(_timer_worker())

    async def _commit_turn_and_start_ai(self, session: CallSession, final_transcript: str, reason: str) -> None:
        session.cancel_endpoint_timer()
        session.cancel_active_ai_task()

        user_turn_id = session.aggregator.user_turn_id
        session.assistant_turn_id += 1
        assistant_turn_id = session.assistant_turn_id
        session.state = "ai_thinking"

        logger.info(
            f"🎯 [COMMIT & START AI] Session {session.session_id} | User Turn {user_turn_id} -> "
            f"Assistant Turn {assistant_turn_id} | Reason: '{reason}': '{final_transcript}'"
        )


        # Notify client turn committed
        await session.websocket.send_json({
            "type": "turn.committed",
            "call_id": session.session_id,
            "user_turn_id": user_turn_id,
            "final_transcript": final_transcript,
            "endpoint_reason": reason,
        })

        # Notify client AI is thinking with structured IDs
        await session.websocket.send_json({
            "type": "ai.thinking",
            "call_id": session.session_id,
            "assistant_turn_id": assistant_turn_id,
        })

        # Record thesis evaluation metrics
        if call_config.enable_thesis_logging:
            metrics = session.aggregator.get_turn_metrics()
            session.thesis_metrics_log.append(metrics)
            logger.info(f"📊 [THESIS METRICS] Session {session.session_id}: {metrics}")

        # Update conversation history
        if session.conversation_history and session.conversation_history[-1].role == "user":
            session.conversation_history[-1] = LLMMessage(role="user", content=final_transcript)
        else:
            session.conversation_history.append(LLMMessage(role="user", content=final_transcript))

        session.current_task_id = assistant_turn_id
        session._current_ai_task = asyncio.create_task(
            self._process_ai_response_pipeline(session, assistant_turn_id)
        )

        # Save user message and emotion to DB concurrently in background without blocking audio pipeline
        asyncio.create_task(self._save_message_to_db(session, "user", final_transcript))

    # Legacy method wrapper
    async def handle_user_transcript(self, session: CallSession, user_text: str) -> None:
        if not user_text.strip():
            return
        session.aggregator.add_final_segment(user_text, stt_session_id=1)
        transcript = session.aggregator.commit(reason="legacy_user_transcript")
        await self._commit_turn_and_start_ai(session, transcript, reason="legacy_user_transcript")

    async def _send_session_summary_event(self, session: CallSession) -> None:
        """Send quick per-speech turn transcript payload over WebSocket without calling external LLM."""
        try:
            transcript_list = [
                {"role": m.role, "content": m.content}
                for m in session.conversation_history
                if m.role in ("user", "assistant") and m.content and m.content.strip()
            ]

            turn = session.latest_orchestration_turn
            if turn:
                dominant = turn.emotion.primary_emotion.capitalize()
                scores = turn.emotion.scores or {}
                stress_level = "Tinggi" if turn.safety_decision.risk_level in ["high", "critical"] else ("Sedang" if turn.safety_decision.risk_level == "medium" else "Rendah")
                breakdown = [
                    {"label": "Ketenangan & Kedamaian", "emoji": "😌", "percent": round(scores.get("neutral", 0.70), 2), "color": "#4ECDC4"},
                    {"label": "Bahagia & Puas", "emoji": "😃", "percent": round(scores.get("happy", 0.20), 2), "color": "#FFE6A7"},
                    {"label": "Tingkat Stres / Cemas", "emoji": "😟", "percent": round(scores.get("fearful", 0.10), 2), "color": "#FF8B94"},
                ]
            else:
                dominant = "Tenang 🌿"
                stress_level = "Rendah"
                breakdown = [
                    {"label": "Ketenangan & Kedamaian", "emoji": "😌", "percent": 0.85, "color": "#4ECDC4"},
                    {"label": "Bahagia & Puas", "emoji": "😃", "percent": 0.60, "color": "#FFE6A7"},
                    {"label": "Tingkat Stres", "emoji": "😟", "percent": 0.15, "color": "#FF8B94"},
                ]

            summary_payload = {
                "type": "voice_session_summary",
                "session_id": session.session_id,
                "emotion_analysis": {
                    "dominant_emotion": dominant,
                    "calm_score": f"{int((turn.emotion.scores.get('neutral', 0.85) if turn else 0.85) * 100)}%",
                    "stress_level": stress_level,
                    "empathy_level": "Sangat Tinggi",
                    "ai_insight": "Pengguna sedang berdialog dengan LUNA AI.",
                    "emotions_breakdown": breakdown,
                },
                "transcript": transcript_list,
            }

            await session.websocket.send_json(summary_payload)
            logger.info(f"📊 [SENT TURN SPEECH SUMMARY] Session {session.session_id}: Sent {len(transcript_list)} transcript messages via WebSocket.")
        except Exception as e:
            logger.error(f"⚠️ [SUMMARY EVENT EXCEPTION] Session {session.session_id}: {e}")

    async def _process_ai_response_pipeline(self, session: CallSession, task_id: int) -> None:
        t_start = time.perf_counter()
        t_llm_first_token: float | None = None
        t_tts_first_audio: float | None = None

        try:
            tts_provider = TTSFactory.get_provider()

            logger.info(
                f"🤖 [AI ORCHESTRATION PIPELINE START] Session {session.session_id} (Assistant Turn {task_id}): "
                f"Using Multi-Stage AIOrchestrator & TTS '{tts_provider.__class__.__name__}'"
            )

            session.state = "ai_speaking"

            # Ambil pesan teks user terakhir untuk dievaluasi oleh multi-agent orchestrator
            user_content = ""
            for msg in reversed(session.conversation_history):
                if msg.role == "user" and msg.content:
                    user_content = msg.content
                    break

            # Eksekusi Orkestrasi: Emotion + Symptoms + Risk + SafetyGate + Qdrant RAG + DASS Profiling + Personalization
            turn = await self.orchestrator.prepare_turn(
                user_text=user_content or "Halo Luna",
                conversation_history=session.conversation_history,
                dass_scores=session.dass_scores,
                user_name=session.user_name,
            )
            session.latest_orchestration_turn = turn

            # Notifikasi darurat ke WebSocket jika Safety Gate mendeteksi skenario krisis
            if turn.is_crisis:
                logger.warning(f"🚨 [CALL CRISIS ALERT] Session {session.session_id}: Safety Gate escalated to crisis protocol!")
                try:
                    await session.websocket.send_json({
                        "type": "ai.crisis_escalation",
                        "call_id": session.session_id,
                        "assistant_turn_id": task_id,
                        "risk_level": turn.safety_decision.risk_level,
                        "protocol_action": str(turn.safety_decision.response_policy),
                        "hotline": "Hotline Dinkes (WhatsApp 0813-8007-3120) / Kemenkes 119 ext 8",
                        "hotline_url": "https://api.whatsapp.com/send/?phone=6281380073120&text=halo%20kak%2C%20saya%20ingin%20bercerita%20mengenai...&type=phone_number&app_absent=0",
                    })
                except Exception as ws_err:
                    logger.warning(f"Failed to send crisis event over websocket: {ws_err}")

            # Dynamic Voice Resolution: Voice Character Mode + Empathetic Adaptive Emotion Modulation
            detected_emo = turn.emotion.primary_emotion if turn.emotion else "neutral"
            confidence = turn.emotion.confidence if turn.emotion else 0.5
            risk = turn.safety_decision.risk_level if turn.safety_decision else "low"

            dyn_res = resolve_dynamic_voice_style(
                mode_id=session.voice_mode,
                detected_emotion=detected_emo,
                confidence=confidence,
                risk_level=risk,
            )
            delivery_style = dyn_res.delivery_style
            audio_tag = dyn_res.audio_tag
            effective_voice_id = dyn_res.voice_id

            logger.info(
                f"🎭 [DYNAMIC VOICE MAPPING] Session {session.session_id} | "
                f"Mode: '{dyn_res.mode.id}' ({dyn_res.mode.name}) | "
                f"User: '{detected_emo}' ({int(confidence*100)}%) -> "
                f"Voice: '{effective_voice_id}' | Style: '{delivery_style}' | Settings: {dyn_res.voice_settings} "
                f"(Override: {dyn_res.is_emotion_override})"
            )

            # LatencyAwareSentenceChunker buffers pure conversational text without text-tag pollution.
            # Emotion is controlled via the official ElevenLabs voice_settings contract.
            chunker = LatencyAwareSentenceChunker(delivery_style=delivery_style, audio_tag="")
            full_display_parts: list[str] = []
            total_audio_bytes = 0
            is_ttd = isinstance(tts_provider, ElevenLabsTTDProvider)

            # Instrument LLM token stream to record TTFT
            async def _instrumented_token_stream():
                nonlocal t_llm_first_token
                async for tok in turn.token_stream:
                    if session.current_task_id != task_id or task_id in session.cancelled_assistant_turn_ids:
                        break
                    if t_llm_first_token is None:
                        t_llm_first_token = time.perf_counter()
                        ttft_ms = (t_llm_first_token - t_start) * 1000.0
                        logger.info(f"⚡ [LLM TTFT] Session {session.session_id} (Turn {task_id}): First token in {ttft_ms:.1f}ms")
                    yield tok

            if is_ttd:
                # Concurrent true streaming via ElevenLabs TTD WebSocket with dynamically resolved voice and voice_settings
                ttd_session = tts_provider.create_session(
                    voice_id=effective_voice_id,
                    voice_settings=dyn_res.voice_settings,
                )
                session._active_ttd_session = ttd_session
                try:
                    await ttd_session.connect()

                    async for ref_chunk, sentence_audio in ttd_session.stream_sentence_audio(
                        chunker.chunk_stream(_instrumented_token_stream())
                    ):
                        if session.current_task_id != task_id or task_id in session.cancelled_assistant_turn_ids:
                            logger.info(f"⚡ [TTD STREAM INTERRUPTED] Session {session.session_id}")
                            break

                        if t_tts_first_audio is None:
                            t_tts_first_audio = time.perf_counter()
                            ttfa_ms = (t_tts_first_audio - t_start) * 1000.0
                            logger.info(f"⚡ [TTD TTFA] Session {session.session_id} (Turn {task_id}): First audio chunk in {ttfa_ms:.1f}ms")

                        text_to_show = ref_chunk.display_text if ref_chunk else ""
                        seq = ref_chunk.sequence if ref_chunk else (len(full_display_parts) + 1)
                        if text_to_show:
                            full_display_parts.append(text_to_show)

                        # Emit clean transcript chunk to Flutter
                        await session.websocket.send_json({
                            "type": "ai.transcript_chunk",
                            "call_id": session.session_id,
                            "assistant_turn_id": task_id,
                            "sequence": seq,
                            "text": text_to_show,
                        })

                        # Emit audio chunk
                        total_audio_bytes += len(sentence_audio)
                        b64_audio = base64.b64encode(sentence_audio).decode("ascii")
                        await session.websocket.send_json({
                            "type": "ai.audio_chunk",
                            "call_id": session.session_id,
                            "assistant_turn_id": task_id,
                            "sequence": seq,
                            "text": text_to_show,
                            "audio_base64": b64_audio,
                            "envelope": [],
                        })
                        logger.info(
                            f"🔊 [OUTGOING TTD AUDIO CHUNK {seq}] Session {session.session_id}: "
                            f"Sent {len(sentence_audio)} bytes for '{text_to_show[:35]}...'"
                        )

                except Exception as ttd_err:
                    logger.error(f"⚠️ [TTD STREAMING ERROR] Session {session.session_id}: {ttd_err}")
                    # If failure happened before any audio reached Flutter, gracefully fallback to REST
                    if total_audio_bytes == 0:
                        logger.warning(f"🔄 [FALLBACK TO REST TTS] Session {session.session_id}: Attempting fallback synthesis...")
                        remaining_text = "".join(full_display_parts).strip() or "Aku di sini mendengarkanmu. Ceritakan apa yang sedang kamu rasakan."
                        audio_fb = None
                        try:
                            logger.info(f"🔄 [FALLBACK TO ELEVENLABS REST] Session {session.session_id}: Synthesizing with voice {effective_voice_id}")
                            fallback_provider = TTSFactory.get_provider("elevenlabs_rest", force_new=True)
                            audio_fb = await fallback_provider.synthesize(
                                remaining_text,
                                voice_id=effective_voice_id,
                                voice_settings=dyn_res.voice_settings,
                            )
                        except Exception as fb_err:
                            logger.error(f"⚠️ [ELEVENLABS REST FALLBACK ERROR] {fb_err}. Falling back to EdgeTTS...")
                            fallback_provider = TTSFactory.get_provider("edge_tts", force_new=True)
                            audio_fb = await fallback_provider.synthesize(remaining_text)
                        if audio_fb:
                            total_audio_bytes += len(audio_fb)
                            b64_fb = base64.b64encode(audio_fb).decode("ascii")
                            await session.websocket.send_json({
                                "type": "ai.transcript_chunk",
                                "call_id": session.session_id,
                                "assistant_turn_id": task_id,
                                "sequence": 1,
                                "text": remaining_text,
                            })
                            await session.websocket.send_json({
                                "type": "ai.audio_chunk",
                                "call_id": session.session_id,
                                "assistant_turn_id": task_id,
                                "sequence": 1,
                                "text": remaining_text,
                                "audio_base64": b64_fb,
                                "envelope": [],
                            })
                finally:
                    await ttd_session.close()
                    session._active_ttd_session = None

            else:
                # Fallback path for EdgeTTS, MockTTS, or OpenAI
                seq = 0
                async for chunk in chunker.chunk_stream(_instrumented_token_stream()):
                    if session.current_task_id != task_id or task_id in session.cancelled_assistant_turn_ids:
                        break

                    seq += 1
                    full_display_parts.append(chunk.display_text)

                    # Send transcript chunk
                    await session.websocket.send_json({
                        "type": "ai.transcript_chunk",
                        "call_id": session.session_id,
                        "assistant_turn_id": task_id,
                        "sequence": seq,
                        "text": chunk.display_text,
                    })

                    # Synthesize
                    chunk_audio = None
                    envelope = []
                    try:
                        tts_target_text = chunk.tts_text if chunk.is_first else chunk.display_text
                        if hasattr(tts_provider, "synthesize_with_envelope"):
                            chunk_audio, envelope = await tts_provider.synthesize_with_envelope(
                                tts_target_text, voice_id=effective_voice_id
                            )
                        else:
                            chunk_audio = await tts_provider.synthesize(
                                tts_target_text, voice_id=effective_voice_id
                            )

                        if chunk_audio:
                            total_audio_bytes += len(chunk_audio)
                            b64_audio = base64.b64encode(chunk_audio).decode("ascii")
                            await session.websocket.send_json({
                                "type": "ai.audio_chunk",
                                "call_id": session.session_id,
                                "assistant_turn_id": task_id,
                                "sequence": seq,
                                "text": chunk.display_text,
                                "audio_base64": b64_audio,
                                "envelope": envelope,
                            })
                    except Exception as synth_ex:
                        logger.error(f"⚠️ [SYNTHESIS EXCEPTION SENTENCE {seq}] {synth_ex}")

            # Check if interrupted during generation
            if session.current_task_id != task_id or task_id in session.cancelled_assistant_turn_ids:
                logger.info(f"⚡ [ASSISTANT TURN CANCELLED DISCARD] Session {session.session_id} (Turn {task_id})")
                return

            full_spoken_text = " ".join(full_display_parts).strip()
            if not full_spoken_text:
                full_spoken_text = "Aku di sini mendengarkanmu. Ceritakan apa yang sedang kamu rasakan."

            # Save clean assistant response to conversation history and DB (NEVER SAVE AUDIO TAGS!)
            clean_history_text = strip_audio_tags(full_spoken_text)
            session.conversation_history.append(
                LLMMessage(role="assistant", content=clean_history_text)
            )
            await self._save_message_to_db(session, "assistant", clean_history_text)

            t_end = time.perf_counter()
            total_duration_ms = (t_end - t_start) * 1000.0
            logger.info(
                f"✅ [AI SPEECH COMPLETE] Session {session.session_id} (Assistant Turn {task_id}): "
                f"Total {len(full_display_parts)} sentences, {total_audio_bytes} audio bytes in {total_duration_ms:.1f}ms."
            )

            # Signal speech completion
            await session.websocket.send_json({
                "type": "ai.speech_finished",
                "call_id": session.session_id,
                "assistant_turn_id": task_id,
            })
            await self._send_session_summary_event(session)

        except asyncio.CancelledError:
            logger.info(f"⚡ [AI PIPELINE CANCELLED] Session {session.session_id} (Assistant Turn {task_id})")
            if session.current_task_id == task_id:
                session.state = "interrupted"
        except Exception as e:
            logger.error(f"❌ [AI PIPELINE ERROR] Session {session.session_id} (Assistant Turn {task_id}): {e}")
            if session.current_task_id == task_id:
                session.state = "listening"
                await session.websocket.send_json({"type": "error", "message": str(e)})
                await session.websocket.send_json({
                    "type": "call.sync_state",
                    "call_id": session.session_id,
                    "state": "listening",
                    "active_user_turn_id": session.aggregator.user_turn_id,
                    "active_assistant_turn_id": session.assistant_turn_id,
                })


call_session_manager = CallSessionManager()

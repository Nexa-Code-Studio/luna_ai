import asyncio
import base64
from datetime import UTC, date, datetime, timedelta
import json
import logging
import time
from typing import Any

from fastapi import WebSocket
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.core.call_config import call_config
from app.core.prompt_templates import LUNA_SYSTEM_PROMPT
from app.core.tz import get_wib_now
from app.db.session import AsyncSessionLocal
from app.models.conversation import Conversation, Message
from app.models.diary import DiaryEntry
from app.models.enums import MessageType
from app.models.user import User
from app.services.diary_generator import DiaryGeneratorService
from app.services.emotion_analyzer import EmotionAnalyzerService
from app.services.ml_emotion_detector import MLEmotionDetectorService
from app.services.turn_aggregator import TurnAggregator
from packages.ai.factories.llm_factory import LLMFactory
from packages.ai.factories.tts_factory import TTSFactory
from packages.ai.interfaces.llm import LLMMessage
from packages.ai.orchestration.orchestrator import AIOrchestrator, OrchestratedTurnResult

logger = logging.getLogger(__name__)


class CallSession:
    def __init__(self, session_id: str, websocket: WebSocket) -> None:
        self.session_id = session_id
        self.websocket = websocket
        self.state: str = "idle"  # idle | listening | user_speaking | ai_thinking | ai_speaking | interrupted
        self.db_conversation_id: Any | None = None
        self.user_id: Any | None = None
        self.is_history_loaded: bool = False
        self.conversation_history: list[LLMMessage] = [
            LLMMessage(role="system", content=LUNA_SYSTEM_PROMPT)
        ]
        self.current_task_id: int = 0
        self.assistant_turn_id: int = 0
        self.cancelled_assistant_turn_ids: set[int] = set()
        self._current_ai_task: asyncio.Task[Any] | None = None
        self._endpoint_timer_task: asyncio.Task[Any] | None = None
        self.aggregator = TurnAggregator(call_id=session_id, initial_turn_id=1)
        self.thesis_metrics_log: list[dict[str, Any]] = []
        self.latest_orchestration_turn: OrchestratedTurnResult | None = None

    def cancel_active_ai_task(self) -> None:
        if self._current_ai_task and not self._current_ai_task.done():
            current = asyncio.current_task()
            if current != self._current_ai_task:
                logger.info(f"⚡ [BARGE-IN CANCEL] Session {self.session_id}: Cancelling active AI task {self.current_task_id}")
                self._current_ai_task.cancel()
            self._current_ai_task = None
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

    def register_session(self, session_id: str, websocket: WebSocket) -> CallSession:
        session = CallSession(session_id=session_id, websocket=websocket)
        self._active_sessions[session_id] = session
        logger.info(f"Registered call session {session_id}")
        return session

    def unregister_session(self, session_id: str) -> None:
        if session_id in self._active_sessions:
            session = self._active_sessions[session_id]
            session.cancel_active_ai_task()
            session.cancel_endpoint_timer()

            # Launch background sync for Today's Diary ONCE upon session disconnect
            if session.conversation_history and len(session.conversation_history) > 1:
                logger.info(f"🔌 [DISCONNECT DIARY SYNC START] Session {session_id}: Generating today's diary entry via DeepSeek LLM...")
                asyncio.create_task(self._sync_today_diary(session))

            del self._active_sessions[session_id]
            logger.info(f"Unregistered call session {session_id}")

    def get_session(self, session_id: str) -> CallSession | None:
        return self._active_sessions.get(session_id)

    async def load_conversation_history(self, session: CallSession) -> None:
        if session.is_history_loaded:
            return

        try:
            async with AsyncSessionLocal() as db:
                user_query = select(User).where(User.email == "user.luna@gmail.com")
                res_user = await db.execute(user_query)
                user = res_user.scalar_one_or_none()
                if not user:
                    res_any = await db.execute(select(User))
                    user = res_any.scalars().first()

                if user:
                    session.user_id = user.id

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
            if session_title and session.db_conversation_id:
                async with AsyncSessionLocal() as db_conv:
                    conv_res = await db_conv.execute(select(Conversation).where(Conversation.id == session.db_conversation_id))
                    conv_obj = conv_res.scalar_one_or_none()
                    if conv_obj:
                        conv_obj.title = session_title
                        await db_conv.commit()
                        logger.info(f"🏷️ [AI CONVERSATION TITLE PERSISTED]: Conversation {conv_obj.id} -> '{session_title}'")

            async with AsyncSessionLocal() as db:
                diary_entry = await DiaryGeneratorService.generate_today_diary(session.user_id, db)
                logger.info(f"📖 [DISCONNECT DIARY SYNC SUCCESS] Session {session.session_id}: Synced cumulative DiaryEntry '{diary_entry.title}' for {diary_entry.entry_date}")
        except Exception as e:
            logger.error(f"⚠️ [SYNC DIARY EXCEPTION] Session {session.session_id}: {e}")

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
            logger.info(f"🚀 [CALL STARTED] Session {session.session_id}")
            session.state = "listening"
            await session.websocket.send_json({"type": "call_started", "session_id": session.session_id})
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

        if user_turn_id != session.aggregator.user_turn_id or session.aggregator.is_committed:
            return

        session.state = "user_speaking"
        session.cancel_endpoint_timer()
        session.aggregator.add_partial(text, stt_session_id)
        await self._evaluate_and_act(session)

    async def _handle_stt_final_segment(self, session: CallSession, payload: dict[str, Any]) -> None:
        text = payload.get("text", "").strip()
        user_turn_id = payload.get("user_turn_id", session.aggregator.user_turn_id)
        stt_session_id = payload.get("stt_session_id", 1)

        if user_turn_id != session.aggregator.user_turn_id or session.aggregator.is_committed:
            logger.warning(f"⚠️ [STT FINAL DISCARDED] Turn {user_turn_id} != active {session.aggregator.user_turn_id}")
            return

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

        if user_turn_id != session.aggregator.user_turn_id or session.aggregator.is_committed:
            return

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
        if user_turn_id != session.aggregator.user_turn_id:
            return

        logger.info(f"👆 [USER FORCE COMMIT] Session {session.session_id} | Turn {user_turn_id}")
        transcript = session.aggregator.force_commit()
        if transcript.strip():
            await self._commit_turn_and_start_ai(session, transcript, reason="manual_commit")

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

            # Eksekusi Orkestrasi: Emotion + Symptoms + Risk + SafetyGate + Qdrant RAG
            turn = await self.orchestrator.prepare_turn(
                user_text=user_content or "Halo Luna",
                conversation_history=session.conversation_history,
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
                        "hotline": "Kemenkes 119 ext 8 / LISA 0811-3855-472",
                    })
                except Exception as ws_err:
                    logger.warning(f"Failed to send crisis event over websocket: {ws_err}")

            full_text_list = []
            sentence_buffer = ""
            total_audio_bytes = 0
            chunk_sequence = 0

            async def _synthesize_and_send_chunk(text_chunk: str) -> None:
                nonlocal total_audio_bytes, chunk_sequence
                clean_chunk = text_chunk.strip()
                if not clean_chunk or session.current_task_id != task_id or task_id in session.cancelled_assistant_turn_ids:
                    return
                try:
                    logger.info(f"🎙️ [TTS CHUNK SYNTHESIZING] Session {session.session_id}: '{clean_chunk}'")
                    audio_bytes = await tts_provider.synthesize(clean_chunk)
                    if session.current_task_id == task_id and task_id not in session.cancelled_assistant_turn_ids and audio_bytes:
                        total_audio_bytes += len(audio_bytes)
                        chunk_sequence += 1
                        b64_audio = base64.b64encode(audio_bytes).decode("ascii")

                        # Send structured JSON audio chunk
                        await session.websocket.send_json({
                            "type": "ai.audio_chunk",
                            "call_id": session.session_id,
                            "assistant_turn_id": task_id,
                            "sequence": chunk_sequence,
                            "audio_base64": b64_audio,
                        })

                        logger.info(f"🔊 [OUTGOING TTS AUDIO CHUNK] Session {session.session_id}: Sent seq {chunk_sequence} ({len(audio_bytes)} bytes)")
                except Exception as ex:
                    logger.error(f"⚠️ [TTS CHUNK SYNTHESIS ERROR] Session {session.session_id}: {ex}")

            try:
                transcript_seq = 0
                async for token in turn.token_stream:
                    if session.current_task_id != task_id or task_id in session.cancelled_assistant_turn_ids:
                        logger.info(f"⚡ [LLM STREAM SUPERSEDED] Session {session.session_id} (Assistant Turn {task_id})")
                        break
                    full_text_list.append(token)
                    sentence_buffer += token
                    transcript_seq += 1

                    # Send structured transcript chunk
                    await session.websocket.send_json({
                        "type": "ai.transcript_chunk",
                        "call_id": session.session_id,
                        "assistant_turn_id": task_id,
                        "sequence": transcript_seq,
                        "text": token,
                    })

                    # Check for sentence delimiters for immediate TTS streaming
                    if any(p in sentence_buffer for p in [".", "!", "?", "\n"]) or ("," in sentence_buffer and len(sentence_buffer) >= 35):
                        chunk_to_speak = sentence_buffer
                        sentence_buffer = ""
                        await _synthesize_and_send_chunk(chunk_to_speak)

                # Trailing text in sentence buffer
                if sentence_buffer.strip() and session.current_task_id == task_id and task_id not in session.cancelled_assistant_turn_ids:
                    await _synthesize_and_send_chunk(sentence_buffer)
                    sentence_buffer = ""

            except asyncio.CancelledError:
                logger.info(f"⚡ [LLM STREAM CANCELLED] Session {session.session_id} (Assistant Turn {task_id})")
                raise
            except Exception as e:
                logger.error(f"❌ [LLM STREAM ERROR] Session {session.session_id} (Assistant Turn {task_id}): {e}")
                fallback_msg = "Aku di sini mendengarkanmu. Bisakah kamu bercerita sedikit lagi tentang apa yang kamu rasakan?"
                full_text_list = [fallback_msg]
                await _synthesize_and_send_chunk(fallback_msg)

            if session.current_task_id != task_id or task_id in session.cancelled_assistant_turn_ids:
                return

            full_response = "".join(full_text_list).strip()
            logger.info(f"🧠 [AI GENERATED TEXT COMPLETE] Session {session.session_id} (Assistant Turn {task_id}): '{full_response}'")

            if full_response and session.current_task_id == task_id:
                session.conversation_history.append(
                    LLMMessage(role="assistant", content=full_response)
                )
                await self._save_message_to_db(session, "assistant", full_response)

            # Signal speech completion if this task is still active
            if session.current_task_id == task_id and task_id not in session.cancelled_assistant_turn_ids:
                logger.info(f"✅ [AI SPEECH COMPLETE] Session {session.session_id} (Assistant Turn {task_id}): Sent total {total_audio_bytes} audio bytes.")
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
                await session.websocket.send_json({"type": "error", "message": str(e)})
                session.state = "listening"


call_session_manager = CallSessionManager()

import asyncio
from datetime import UTC, date, datetime, timedelta
import logging
from typing import Any

from fastapi import WebSocket
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.core.prompt_templates import LUNA_SYSTEM_PROMPT
from app.db.session import AsyncSessionLocal
from app.models.conversation import Conversation, Message
from app.models.diary import DiaryEntry
from app.models.enums import MessageType
from app.models.user import User
from app.services.diary_generator import DiaryGeneratorService
from app.services.emotion_analyzer import EmotionAnalyzerService
from packages.ai.factories.llm_factory import LLMFactory
from packages.ai.factories.tts_factory import TTSFactory
from packages.ai.interfaces.llm import LLMMessage

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
        self._current_ai_task: asyncio.Task[Any] | None = None

    def cancel_active_ai_task(self) -> None:
        if self._current_ai_task and not self._current_ai_task.done():
            logger.info(f"⚡ [BARGE-IN CANCEL] Session {self.session_id}: Cancelling active AI task {self.current_task_id}")
            self._current_ai_task.cancel()
            self._current_ai_task = None


class CallSessionManager:
    """Session Manager for real-time WebSocket AI phone calls with conversation history & dynamic AI emotion analysis."""

    def __init__(self) -> None:
        self._active_sessions: dict[str, CallSession] = {}

    def register_session(self, session_id: str, websocket: WebSocket) -> CallSession:
        session = CallSession(session_id=session_id, websocket=websocket)
        self._active_sessions[session_id] = session
        logger.info(f"Registered call session {session_id}")
        return session

    def unregister_session(self, session_id: str) -> None:
        if session_id in self._active_sessions:
            session = self._active_sessions[session_id]
            session.cancel_active_ai_task()

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
                    now_str = datetime.now().strftime("%d %b %Y %H:%M")
                    new_conv = Conversation(
                        user_id=user.id,
                        title=f"Panggilan Suara LUNA $skeleton"
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
                    logger.info(f"💾 [SAVED TO DB] Session {session.session_id}: Saved {role} voice message to DB")
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

            # 1. Invoke DeepSeek LLM for dynamic conversation title generation
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

            # 2. Invoke DiaryGeneratorService to aggregate today's conversations and generate cumulative AI Diary
            async with AsyncSessionLocal() as db:
                diary_entry = await DiaryGeneratorService.generate_today_diary(session.user_id, db)
                logger.info(f"📖 [DISCONNECT DIARY SYNC SUCCESS] Session {session.session_id}: Synced cumulative DiaryEntry '{diary_entry.title}' for {diary_entry.entry_date}")
        except Exception as e:
            logger.error(f"⚠️ [SYNC DIARY EXCEPTION] Session {session.session_id}: {e}")

    async def handle_user_transcript(self, session: CallSession, user_text: str) -> None:
        if not user_text.strip():
            return

        # Interrupt any ongoing AI generation and assign new task ID
        session.cancel_active_ai_task()
        session.current_task_id += 1
        task_id = session.current_task_id
        session.state = "ai_thinking"

        logger.info(f"💬 [USER SPEECH TRANSCRIPT] Session {session.session_id} (Task {task_id}): '{user_text}'")

        # Notify client AI is thinking
        await session.websocket.send_json({"type": "ai_thinking"})

        # Record user message (clean up duplicate consecutive user messages if previous was empty/failed)
        if session.conversation_history and session.conversation_history[-1].role == "user":
            session.conversation_history[-1] = LLMMessage(role="user", content=user_text)
        else:
            session.conversation_history.append(LLMMessage(role="user", content=user_text))

        # Save user message to database
        await self._save_message_to_db(session, "user", user_text)

        # Launch background async task for LLM + TTS streaming
        session._current_ai_task = asyncio.create_task(
            self._process_ai_response_pipeline(session, task_id)
        )

    async def _send_session_summary_event(self, session: CallSession) -> None:
        """Send quick per-speech turn transcript payload over WebSocket without calling external LLM."""
        try:
            transcript_list = [
                {"role": m.role, "content": m.content}
                for m in session.conversation_history
                if m.role in ("user", "assistant") and m.content and m.content.strip()
            ]

            summary_payload = {
                "type": "voice_session_summary",
                "session_id": session.session_id,
                "emotion_analysis": {
                    "dominant_emotion": "Tenang 🌿",
                    "calm_score": "85%",
                    "stress_level": "Rendah",
                    "empathy_level": "Sangat Tinggi",
                    "ai_insight": "Pengguna sedang berdialog dengan LUNA AI.",
                    "emotions_breakdown": [
                        {"label": "Ketenangan & Kedamaian", "emoji": "😌", "percent": 0.85, "color": "#4ECDC4"},
                        {"label": "Bahagia & Puas", "emoji": "😃", "percent": 0.60, "color": "#FFE6A7"},
                        {"label": "Tingkat Stres", "emoji": "😟", "percent": 0.15, "color": "#FF8B94"},
                    ],
                },
                "transcript": transcript_list,
            }

            await session.websocket.send_json(summary_payload)
            logger.info(f"📊 [SENT TURN SPEECH SUMMARY] Session {session.session_id}: Sent {len(transcript_list)} transcript messages via WebSocket.")
        except Exception as e:
            logger.error(f"⚠️ [SUMMARY EVENT EXCEPTION] Session {session.session_id}: {e}")

    async def _process_ai_response_pipeline(self, session: CallSession, task_id: int) -> None:
        try:
            llm_provider = LLMFactory.get_provider()
            tts_provider = TTSFactory.get_provider()

            logger.info(
                f"🤖 [AI PIPELINE START] Session {session.session_id} (Task {task_id}): "
                f"Using LLM '{llm_provider.__class__.__name__}' & TTS '{tts_provider.__class__.__name__}'"
            )

            session.state = "ai_speaking"

            # 1. Stream LLM tokens and synthesize TTS in sentence chunks for ultra-low latency (< 1.2s response time)
            full_text_list = []
            sentence_buffer = ""
            total_audio_bytes = 0

            async def _synthesize_and_send_chunk(text_chunk: str) -> None:
                nonlocal total_audio_bytes
                clean_chunk = text_chunk.strip()
                if not clean_chunk or session.current_task_id != task_id:
                    return
                try:
                    logger.info(f"🎙️ [TTS CHUNK SYNTHESIZING] Session {session.session_id}: '{clean_chunk}'")
                    audio_bytes = await tts_provider.synthesize(clean_chunk)
                    if session.current_task_id == task_id and audio_bytes:
                        total_audio_bytes += len(audio_bytes)
                        logger.info(f"🔊 [OUTGOING TTS AUDIO CHUNK] Session {session.session_id}: Sent {len(audio_bytes)} audio bytes")
                        await session.websocket.send_bytes(audio_bytes)
                except Exception as ex:
                    logger.error(f"⚠️ [TTS CHUNK SYNTHESIS ERROR] Session {session.session_id}: {ex}")

            try:
                async for token in llm_provider.stream_response(session.conversation_history):
                    if session.current_task_id != task_id:
                        logger.info(f"⚡ [LLM STREAM SUPERSEDED] Session {session.session_id} (Task {task_id})")
                        break
                    full_text_list.append(token)
                    sentence_buffer += token

                    # Stream text chunk to client
                    await session.websocket.send_json({
                        "type": "ai_transcript_chunk",
                        "text": token,
                    })

                    # Check for sentence end punctuation for immediate audio synthesis
                    if any(p in sentence_buffer for p in [".", "!", "?", "\n"]) or ("," in sentence_buffer and len(sentence_buffer) >= 35):
                        chunk_to_speak = sentence_buffer
                        sentence_buffer = ""
                        await _synthesize_and_send_chunk(chunk_to_speak)

                # Process any trailing text remaining in buffer
                if sentence_buffer.strip() and session.current_task_id == task_id:
                    await _synthesize_and_send_chunk(sentence_buffer)
                    sentence_buffer = ""

            except asyncio.CancelledError:
                logger.info(f"⚡ [LLM STREAM CANCELLED] Session {session.session_id} (Task {task_id})")
                raise
            except Exception as e:
                logger.error(f"❌ [LLM STREAM ERROR] Session {session.session_id} (Task {task_id}): {e}")
                fallback_msg = "Aku di sini mendengarkanmu. Bisakah kamu bercerita sedikit lagi tentang apa yang kamu rasakan?"
                full_text_list = [fallback_msg]
                await _synthesize_and_send_chunk(fallback_msg)

            if session.current_task_id != task_id:
                return

            full_response = "".join(full_text_list).strip()
            logger.info(f"🧠 [AI GENERATED TEXT COMPLETE] Session {session.session_id} (Task {task_id}): '{full_response}'")

            if full_response and session.current_task_id == task_id:
                session.conversation_history.append(
                    LLMMessage(role="assistant", content=full_response)
                )
                await self._save_message_to_db(session, "assistant", full_response)

            # Signal speech completion if this task is still active
            if session.current_task_id == task_id:
                session.state = "listening"
                logger.info(f"✅ [AI SPEECH COMPLETE] Session {session.session_id} (Task {task_id}): Sent total {total_audio_bytes} audio bytes.")
                await session.websocket.send_json({"type": "ai_speech_finished"})
                await self._send_session_summary_event(session)

        except asyncio.CancelledError:
            logger.info(f"⚡ [AI PIPELINE CANCELLED] Session {session.session_id} (Task {task_id})")
            if session.current_task_id == task_id:
                session.state = "interrupted"
        except Exception as e:
            logger.error(f"❌ [AI PIPELINE ERROR] Session {session.session_id} (Task {task_id}): {e}")
            if session.current_task_id == task_id:
                await session.websocket.send_json({"type": "error", "message": str(e)})
                session.state = "listening"


call_session_manager = CallSessionManager()

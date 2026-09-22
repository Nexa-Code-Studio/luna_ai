#!/usr/bin/env python3
"""
⚡ VPS Stress & Concurrency Test Runner for Luna AI
Tests concurrent multi-user load, auth throughput, real-time WebSocket AI phone sessions,
and combined long-form audio streaming (30s–1min) or individual cycles on https://luna.nexacode.dev.
"""

import argparse
import asyncio
import json
import logging
import os
import sys
import time
import wave
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import aiohttp
import websockets

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("load_test")

AUDIO_TRANSCRIPTS = {
    "1.wav": "Kan aku udah bilang berkali-kali, tapi kamu masih melakukan hal yang sama. Aku rasanya stres dan dikecewakan.",
    "2.wav": "Aku sebenarnya takut banget kalau sesuatu yang buruk tuh bakal terjadi... Aku merasa cemas dan panik secara fisik.",
    "3.wav": "Hari ini aku pergi ke kampus dan mengikuti kegiatan seperti biasa.",
    "4.wav": "Aku akhir-akhir ini rasanya capek dan sedih terus. Merasa tidak ada semangat dan kehilangan harapan.",
    "5.wav": "Wah, akhirnya selesai juga! Aku senang banget hari ini!",
    "combined_speech_33s.wav": (
        "Kan aku udah bilang berkali-kali, tapi kamu masih melakukan hal yang sama. Aku rasanya stres dan dikecewakan. "
        "Aku sebenarnya takut banget kalau sesuatu yang buruk tuh bakal terjadi... Aku merasa cemas dan panik secara fisik. "
        "Hari ini aku pergi ke kampus dan mengikuti kegiatan seperti biasa. "
        "Aku akhir-akhir ini rasanya capek dan sedih terus. Merasa tidak ada semangat dan kehilangan harapan. "
        "Wah, akhirnya selesai juga! Aku senang banget hari ini!"
    ),
}


@dataclass
class TurnMetric:
    audio_file: str
    audio_bytes_sent: int
    user_speech_duration_s: float = 0.0  # Durasi rekaman audio ucapan mock user berbicara
    speech_send_duration_s: float = 0.0  # Berapa detik audio itu dikirimkan ke server
    ttfa_ms: float = 0.0  # Jeda waktu user menunggu selesai bicara s/d AI mulai bersuara (TTFA)
    turn_latency_ms: float = 0.0  # Durasi respon AI sampai selesai berbicara (speech_finished)
    audio_chunks_received: int = 0
    transcript_tokens_received: int = 0
    success: bool = False
    error: str = ""


@dataclass
class UserSessionReport:
    user_index: int
    email: str
    auth_latency_ms: float = 0.0
    auth_success: bool = False
    ws_connect_latency_ms: float = 0.0
    ws_success: bool = False
    turns: list[TurnMetric] = field(default_factory=list)
    total_duration_s: float = 0.0
    session_error: str = ""


def ensure_combined_audio(audio_dir: Path) -> Path:
    """Concatenate 1.wav to 5.wav into combined_speech_33s.wav if not present."""
    combined_path = audio_dir / "combined_speech_33s.wav"
    if combined_path.exists() and combined_path.stat().st_size > 0:
        return combined_path

    parts = [audio_dir / f"{i}.wav" for i in range(1, 6)]
    for p in parts:
        if not p.exists():
            raise FileNotFoundError(f"Missing audio file component: {p}")

    logger.info(f"🔨 Generating {combined_path.name} from 1.wav..5.wav...")
    with wave.open(str(parts[0]), "rb") as first_w:
        params = first_w.getparams()

    with wave.open(str(combined_path), "wb") as out_w:
        out_w.setparams(params)
        for p in parts:
            with wave.open(str(p), "rb") as in_w:
                out_w.writeframes(in_w.readframes(in_w.getnframes()))

    return combined_path


def get_audio_duration_seconds(audio_path: Path) -> float:
    """Read WAV duration from header."""
    try:
        with wave.open(str(audio_path), "rb") as w:
            frames = w.getnframes()
            rate = w.getframerate()
            return frames / float(rate)
    except Exception:
        return 0.0


async def check_vps_health(base_url: str) -> dict[str, Any]:
    health_url = base_url.replace("/api/v1", "") + "/health"
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(health_url, timeout=5) as res:
                if res.status == 200:
                    return await res.json()
                return {"status": "error", "code": res.status}
    except Exception as e:
        return {"status": "unreachable", "error": str(e)}


async def authenticate_user(
    session: aiohttp.ClientSession,
    base_url: str,
    user_idx: int,
    password: str,
) -> tuple[str | None, float, bool]:
    email = f"loadtest_user_{user_idx}@nexacode.dev"
    name = f"LoadTester {user_idx}"
    start = time.perf_counter()

    # 1. Try Login first
    login_url = f"{base_url}/auth/login"
    try:
        async with session.post(
            login_url,
            json={"email": email, "password": password},
            timeout=8,
        ) as res:
            if res.status == 200:
                data = await res.json()
                latency = (time.perf_counter() - start) * 1000
                return data.get("access_token"), latency, True
    except Exception:
        pass

    # 2. If login fails, try Register
    register_url = f"{base_url}/auth/register"
    try:
        async with session.post(
            register_url,
            json={"name": name, "email": email, "password": password},
            timeout=8,
        ) as res:
            latency = (time.perf_counter() - start) * 1000
            if res.status in (200, 201):
                data = await res.json()
                return data.get("access_token"), latency, True
            else:
                body = await res.text()
                logger.warning(f"⚠️ [User {user_idx}] Register HTTP {res.status}: {body}")
    except Exception as e:
        logger.error(f"❌ [User {user_idx}] Auth Exception: {e}")

    latency = (time.perf_counter() - start) * 1000
    return None, latency, False


async def run_single_user_session(
    user_idx: int,
    base_url: str,
    ws_url: str,
    audio_data_map: dict[str, bytes],
    audio_durations: dict[str, float],
    audio_sequence: list[str],
    password: str,
) -> UserSessionReport:
    email = f"loadtest_user_{user_idx}@nexacode.dev"
    report = UserSessionReport(user_index=user_idx, email=email)
    user_start = time.perf_counter()

    async with aiohttp.ClientSession() as http_client:
        token, auth_lat, auth_ok = await authenticate_user(
            http_client, base_url, user_idx, password
        )
        report.auth_latency_ms = auth_lat
        report.auth_success = auth_ok

        if not auth_ok or not token:
            report.session_error = "Authentication failed"
            report.total_duration_s = time.perf_counter() - user_start
            return report

    logger.info(f"🔑 [User {user_idx:02d}] Authenticated in {auth_lat:.1f}ms")

    # Connect WebSocket
    call_session_id = f"stress-session-u{user_idx}-{int(time.time())}"
    ws_endpoint = f"{ws_url}/{call_session_id}?token={token}"

    ws_start = time.perf_counter()
    try:
        async with websockets.connect(
            ws_endpoint,
            ping_interval=10,
            ping_timeout=15,
            close_timeout=5,
        ) as ws:
            # 1. Handshake: wait for call_connected
            conn_msg = json.loads(await asyncio.wait_for(ws.recv(), timeout=10.0))
            report.ws_connect_latency_ms = (time.perf_counter() - ws_start) * 1000
            report.ws_success = conn_msg.get("type") == "call_connected"

            # 2. Start Call
            await ws.send(json.dumps({"type": "start_call"}))
            await asyncio.wait_for(ws.recv(), timeout=10.0)
            logger.info(
                f"🔌 [User {user_idx:02d}] WebSocket Connected & Call Started in {report.ws_connect_latency_ms:.1f}ms"
            )

            # 3. Process Audio Turns
            for turn_idx, audio_name in enumerate(audio_sequence, 1):
                audio_bytes = audio_data_map[audio_name]
                speech_duration = audio_durations.get(audio_name, 0.0)
                transcript_text = AUDIO_TRANSCRIPTS.get(
                    audio_name,
                    AUDIO_TRANSCRIPTS.get("combined_speech_33s.wav", ""),
                )
                turn_metric = TurnMetric(
                    audio_file=audio_name,
                    audio_bytes_sent=len(audio_bytes),
                    user_speech_duration_s=speech_duration,
                )

                # Send audio binary in 64KB chunks and measure transmission duration
                t_send_start = time.perf_counter()
                chunk_size = 65536
                for offset in range(0, len(audio_bytes), chunk_size):
                    await ws.send(audio_bytes[offset : offset + chunk_size])
                send_duration = time.perf_counter() - t_send_start
                turn_metric.speech_send_duration_s = send_duration

                # Mark turn start right when user finishes sending speech
                turn_start = time.perf_counter()
                first_response_time = None

                # Send STT final segment & user.force_commit
                await ws.send(
                    json.dumps(
                        {
                            "type": "stt.final_segment",
                            "call_id": call_session_id,
                            "user_turn_id": turn_idx,
                            "stt_session_id": turn_idx,
                            "sequence": 1,
                            "text": transcript_text,
                        }
                    )
                )
                await ws.send(
                    json.dumps(
                        {
                            "type": "user.force_commit",
                            "call_id": call_session_id,
                            "user_turn_id": turn_idx,
                        }
                    )
                )

                # Receive response events until turn completed
                while True:
                    try:
                        msg = await asyncio.wait_for(ws.recv(), timeout=35.0)
                        if isinstance(msg, bytes):
                            if first_response_time is None:
                                first_response_time = time.perf_counter()
                            turn_metric.audio_chunks_received += 1
                        else:
                            evt = json.loads(msg)
                            ev_type = evt.get("type")

                            if (
                                ev_type
                                in ("ai.thinking", "ai.transcript_chunk", "ai.audio_chunk")
                                and first_response_time is None
                            ):
                                first_response_time = time.perf_counter()

                            if ev_type == "ai.transcript_chunk":
                                turn_metric.transcript_tokens_received += 1
                            elif ev_type == "ai.audio_chunk":
                                turn_metric.audio_chunks_received += 1
                            elif ev_type in (
                                "ai.speech_finished",
                                "speech_finished",
                                "call_summary",
                            ):
                                turn_metric.success = True
                                break
                    except asyncio.TimeoutError:
                        turn_metric.error = "Timeout waiting for AI turn response"
                        break

                if turn_metric.success:
                    # Notify server that client playback finished to reset state for subsequent turns
                    try:
                        await ws.send(
                            json.dumps(
                                {
                                    "type": "playback.finished",
                                    "call_id": call_session_id,
                                    "assistant_turn_id": turn_idx,
                                }
                            )
                        )
                        while True:
                            try:
                                sync_raw = await asyncio.wait_for(ws.recv(), timeout=2.0)
                                if isinstance(sync_raw, str):
                                    ev = json.loads(sync_raw)
                                    if ev.get("type") == "call.sync_state":
                                        break
                            except (asyncio.TimeoutError, Exception):
                                break
                    except Exception:
                        pass

                total_turn_lat = (time.perf_counter() - turn_start) * 1000
                ttfa_lat = (
                    ((first_response_time - turn_start) * 1000)
                    if first_response_time
                    else total_turn_lat
                )

                turn_metric.turn_latency_ms = total_turn_lat
                turn_metric.ttfa_ms = ttfa_lat
                report.turns.append(turn_metric)

                status_icon = "✅" if turn_metric.success else "⚠️"
                logger.info(
                    f"{status_icon} [User {user_idx:02d} | Turn {turn_idx}/{len(audio_sequence)}] "
                    f"Audio: {audio_name} ({len(audio_bytes) // 1024} KB) | "
                    f"User Bicara: {speech_duration:.1f}s | "
                    f"Waktu Kirim: {send_duration:.2f}s | "
                    f"Jeda Nunggu (TTFA): {ttfa_lat / 1000:.2f}s ({ttfa_lat:.0f}ms) | "
                    f"AI Selesai: {total_turn_lat / 1000:.2f}s ({total_turn_lat:.0f}ms)"
                )

                # Brief natural breathing interval between turns
                await asyncio.sleep(0.5)

            # End call
            try:
                await ws.send(json.dumps({"type": "end_call", "duration_seconds": 60}))
            except Exception:
                pass

    except Exception as e:
        logger.error(f"❌ [User {user_idx:02d}] WebSocket Session Exception: {e}")
        report.session_error = str(e)

    report.total_duration_s = time.perf_counter() - user_start
    return report


def print_summary_report(
    reports: list[UserSessionReport],
    health_before: dict[str, Any],
    health_after: dict[str, Any],
    total_time: float,
    report_file: str | None = None,
):
    total_users = len(reports)
    auth_success_count = sum(1 for r in reports if r.auth_success)
    ws_success_count = sum(1 for r in reports if r.ws_success)

    all_turns = [t for r in reports for t in r.turns]
    successful_turns = [t for t in all_turns if t.success]

    avg_auth_lat = (
        sum(r.auth_latency_ms for r in reports) / total_users if total_users else 0
    )
    avg_ws_lat = (
        sum(r.ws_connect_latency_ms for r in reports if r.ws_success) / ws_success_count
        if ws_success_count
        else 0
    )

    avg_user_speech_s = (
        sum(t.user_speech_duration_s for t in successful_turns) / len(successful_turns)
        if successful_turns
        else 0
    )
    avg_send_dur_s = (
        sum(t.speech_send_duration_s for t in successful_turns) / len(successful_turns)
        if successful_turns
        else 0
    )

    ttfa_list = [t.ttfa_ms for t in successful_turns]
    turn_lat_list = [t.turn_latency_ms for t in successful_turns]

    avg_ttfa = sum(ttfa_list) / len(ttfa_list) if ttfa_list else 0
    min_ttfa = min(ttfa_list) if ttfa_list else 0
    max_ttfa = max(ttfa_list) if ttfa_list else 0

    avg_turn_lat = sum(turn_lat_list) / len(turn_lat_list) if turn_lat_list else 0
    min_turn_lat = min(turn_lat_list) if turn_lat_list else 0
    max_turn_lat = max(turn_lat_list) if turn_lat_list else 0

    total_audio_bytes_sent = sum(t.audio_bytes_sent for t in all_turns)

    output = []
    output.append("\n" + "=" * 75)
    output.append("       📊 LUNA AI VPS CONCURRENCY & STRESS TEST RESULTS")
    output.append("=" * 75)
    output.append(f"⏱️  Total Test Execution Time : {total_time:.2f} seconds")
    output.append(f"👥 Concurrent User Accounts  : {total_users}")
    output.append(f"🔄 Total Turns Processed     : {len(all_turns)} (Success: {len(successful_turns)}/{len(all_turns)})")
    output.append(f"📦 Total Audio Uploaded      : {total_audio_bytes_sent / (1024 * 1024):.2f} MB")
    output.append("-" * 75)
    output.append(f"🔑 Auth (Login/Register)     : {auth_success_count}/{total_users} Success | Avg Latency: {avg_auth_lat:.1f} ms")
    output.append(f"🔌 WebSocket Connections     : {ws_success_count}/{total_users} Connected | Avg Handshake: {avg_ws_lat:.1f} ms")
    output.append("-" * 75)
    output.append("⚡ METRIK RESPON SUARA AI (DeepSeek LLM + EdgeTTS / ElevenLabs):")
    output.append(f"   🗣️  Durasi Mock User Berbicara        : {avg_user_speech_s:.2f} detik")
    output.append(f"   📤  Waktu Pengiriman Audio Mock User   : {avg_send_dur_s:.2f} detik")
    output.append(
        f"   ⏱️  Jeda Menunggu User (User diam s/d AI MULAI bersuara / TTFA):\n"
        f"       • Rata-rata : {avg_ttfa / 1000:.2f} detik ({avg_ttfa:.0f} ms)\n"
        f"       • Tercepat  : {min_ttfa / 1000:.2f} detik ({min_ttfa:.0f} ms)\n"
        f"       • Terlama   : {max_ttfa / 1000:.2f} detik ({max_ttfa:.0f} ms)"
    )
    output.append(
        f"   🔊  Durasi Total Respon AI (Waktu sampai AI SELESAI seluruh kalimat):\n"
        f"       • Rata-rata : {avg_turn_lat / 1000:.2f} detik ({avg_turn_lat:.0f} ms)\n"
        f"       • Tercepat  : {min_turn_lat / 1000:.2f} detik ({min_turn_lat:.0f} ms)\n"
        f"       • Terlama   : {max_turn_lat / 1000:.2f} detik ({max_turn_lat:.0f} ms)"
    )
    output.append("-" * 75)
    output.append(f"🏥 VPS Health Before Test     : {health_before.get('status', 'unknown')} (Database: {health_before.get('database')}, Redis: {health_before.get('redis')}, Qdrant: {health_before.get('qdrant')})")
    output.append(f"🏥 VPS Health After Test      : {health_after.get('status', 'unknown')} (Database: {health_after.get('database')}, Redis: {health_after.get('redis')}, Qdrant: {health_after.get('qdrant')})")
    output.append("=" * 75)

    summary_text = "\n".join(output)
    print(summary_text)

    if report_file:
        with open(report_file, "w", encoding="utf-8") as f:
            f.write("# 📊 Luna AI VPS Concurrency & Stress Test Report\n\n")
            f.write(f"- **Execution Date**: `{time.strftime('%Y-%m-%d %H:%M:%S')}`\n")
            f.write(f"- **Target VPS**: `https://luna.nexacode.dev`\n")
            f.write(f"- **Concurrent Users**: `{total_users}`\n")
            f.write(f"- **Total Turns**: `{len(all_turns)}` (Success rate: `{len(successful_turns) / len(all_turns) * 100:.1f}%`)\n")
            f.write(f"- **Total Audio Uploaded**: `{total_audio_bytes_sent / (1024 * 1024):.2f} MB`\n")
            f.write(f"- **Avg Auth Latency**: `{avg_auth_lat:.1f} ms`\n")
            f.write(f"- **🗣️ Durasi Mock User Berbicara**: `{avg_user_speech_s:.2f} detik`\n")
            f.write(f"- **📤 Waktu Pengiriman Audio Mock User**: `{avg_send_dur_s:.2f} detik`\n")
            f.write(
                f"- **⏱️ Rata-rata Jeda User Menunggu Hingga AI Mulai Bicara (TTFA)**: "
                f"`{avg_ttfa / 1000:.2f} detik` ({avg_ttfa:.0f} ms) *(Min: {min_ttfa / 1000:.2f}s, Max: {max_ttfa / 1000:.2f}s)*\n"
            )
            f.write(
                f"- **🔊 Rata-rata Durasi AI Selesai Seluruh Kalimat**: "
                f"`{avg_turn_lat / 1000:.2f} detik` ({avg_turn_lat:.0f} ms)\n\n"
            )
            f.write("## Per-User Results Breakdown\n\n")
            f.write(
                "| User | Auth (ms) | WS Handshake (ms) | User Bicara | Waktu Kirim | ⏱️ Jeda User Menunggu (TTFA) | 🔊 AI Selesai Bicara |\n"
            )
            f.write("| :--- | :---: | :---: | :---: | :---: | :---: | :---: |\n")
            for r in reports:
                turns_ok = sum(1 for t in r.turns if t.success)
                avg_speech_u = (
                    sum(t.user_speech_duration_s for t in r.turns if t.success) / turns_ok
                    if turns_ok
                    else 0
                )
                avg_send_u = (
                    sum(t.speech_send_duration_s for t in r.turns if t.success) / turns_ok
                    if turns_ok
                    else 0
                )
                avg_ttfa_user = (
                    sum(t.ttfa_ms for t in r.turns if t.success) / turns_ok
                    if turns_ok
                    else 0
                )
                avg_lat = (
                    sum(t.turn_latency_ms for t in r.turns if t.success) / turns_ok
                    if turns_ok
                    else 0
                )
                f.write(
                    f"| User {r.user_index:02d} | {r.auth_latency_ms:.1f} | {r.ws_connect_latency_ms:.1f} | {avg_speech_u:.1f}s | {avg_send_u:.2f}s | **{avg_ttfa_user / 1000:.2f}s** ({avg_ttfa_user:.0f} ms) | {avg_lat / 1000:.2f}s ({avg_lat:.0f} ms) |\n"
                )
            f.write("\n")
        logger.info(f"📝 Markdown report saved to: {report_file}")


async def main():
    parser = argparse.ArgumentParser(description="Luna AI VPS Concurrency Stress Tester")
    parser.add_argument("--users", type=int, default=10, help="Number of concurrent users (default: 10)")
    parser.add_argument(
        "--turns",
        type=int,
        default=1,
        help="Number of turns per user (default: 1 for combined 33s speech)",
    )
    parser.add_argument(
        "--mode",
        type=str,
        choices=["combined", "cycle"],
        default="combined",
        help="Speech mode: 'combined' (30s–1min merged speech) or 'cycle' (1.wav..5.wav)",
    )
    parser.add_argument(
        "--base-url",
        type=str,
        default="https://luna.nexacode.dev/api/v1",
        help="Base REST API URL",
    )
    parser.add_argument(
        "--ws-url",
        type=str,
        default="wss://luna.nexacode.dev/api/v1/call/ws",
        help="WebSocket Base URL",
    )
    parser.add_argument(
        "--audio-dir",
        type=str,
        default="tests/test_emotion",
        help="Directory containing 1.wav..5.wav",
    )
    parser.add_argument(
        "--password",
        type=str,
        default="Password123!",
        help="Password for test user accounts",
    )
    parser.add_argument(
        "--report",
        type=str,
        default="tests/load_test/stress_test_report.md",
        help="Path to output markdown report",
    )
    args = parser.parse_args()

    audio_dir = Path(args.audio_dir)
    audio_data_map: dict[str, bytes] = {}
    audio_durations: dict[str, float] = {}

    if args.mode == "combined":
        combined_file = ensure_combined_audio(audio_dir)
        audio_name = combined_file.name
        audio_data_map[audio_name] = combined_file.read_bytes()
        audio_durations[audio_name] = get_audio_duration_seconds(combined_file)
        sequence = [audio_name] * args.turns
    else:
        audio_files = ["1.wav", "2.wav", "3.wav", "4.wav", "5.wav"]
        for f in audio_files:
            p = audio_dir / f
            if not p.exists():
                logger.error(f"❌ Audio file not found: {p}")
                sys.exit(1)
            audio_data_map[f] = p.read_bytes()
            audio_durations[f] = get_audio_duration_seconds(p)
        sequence = [audio_files[(i - 1) % len(audio_files)] for i in range(1, args.turns + 1)]

    print("=" * 75)
    print(" 🚀 LUNA AI VPS CONCURRENCY & STRESS TEST RUNNER")
    print("=" * 75)
    print(f"🎯 Target VPS REST   : {args.base_url}")
    print(f"🎯 Target VPS WS     : {args.ws_url}")
    print(f"👥 Concurrent Users  : {args.users}")
    print(f"🔄 Mode              : {args.mode.upper()} ({len(sequence)} turn(s) per user)")
    for name, dur in audio_durations.items():
        print(f"🎵 Audio File        : {name} (Durasi: {dur:.2f}s, Ukuran: {len(audio_data_map[name]) // 1024} KB)")
    print("=" * 75)

    # 1. Health check before
    logger.info("🔍 Performing preliminary health check on VPS...")
    health_before = await check_vps_health(args.base_url)
    logger.info(f"Health Before: {health_before}")

    start_total = time.perf_counter()

    # 2. Launch concurrent user tasks
    logger.info(f"⚡ Spawning {args.users} concurrent asynchronous user tasks...")
    tasks = [
        run_single_user_session(
            user_idx=i,
            base_url=args.base_url,
            ws_url=args.ws_url,
            audio_data_map=audio_data_map,
            audio_durations=audio_durations,
            audio_sequence=sequence,
            password=args.password,
        )
        for i in range(1, args.users + 1)
    ]

    reports: list[UserSessionReport] = await asyncio.gather(*tasks)
    total_time = time.perf_counter() - start_total

    # 3. Health check after
    logger.info("🔍 Performing post-test health check on VPS...")
    health_after = await check_vps_health(args.base_url)
    logger.info(f"Health After: {health_after}")

    # 4. Print Summary
    print_summary_report(
        reports=reports,
        health_before=health_before,
        health_after=health_after,
        total_time=total_time,
        report_file=args.report,
    )


if __name__ == "__main__":
    asyncio.run(main())

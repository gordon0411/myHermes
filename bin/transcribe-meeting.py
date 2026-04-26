from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
from datetime import datetime
from pathlib import Path


SUMMARY_HEADING = "## AI会议总结"
RECORDING_HEADING = "## 录音"
TRANSCRIPT_HEADING = "## 转写全文"


def read_text_with_fallback(path: Path) -> str:
    for encoding in ("utf-8", "utf-8-sig", "gbk"):
        try:
            return path.read_text(encoding=encoding)
        except UnicodeDecodeError:
            continue
    raise UnicodeDecodeError("unknown", b"", 0, 1, f"Unable to decode file: {path}")


def load_env_file(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values
    for raw_line in read_text_with_fallback(path).splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()
    return values


def env_value(key: str, fallback: str = "") -> str:
    if key in os.environ and os.environ[key]:
        return os.environ[key]
    env_file = Path(__file__).resolve().parents[1] / ".env"
    return load_env_file(env_file).get(key, fallback)


def load_template() -> str:
    template_path = Path(__file__).resolve().parents[1] / "templates" / "obsidian-meeting-note.md"
    if template_path.exists():
        return read_text_with_fallback(template_path)
    return (
        "# <%TITLE%>\n\n"
        "日期：<%DATE%>\n"
        "时间：<%TIME%>\n"
        "参与人：<%PARTICIPANTS%>\n"
        "主题：<%TOPIC%>\n"
        "标签：会议记录\n\n"
        "## AI会议总结\n\n"
        "等待生成。\n\n"
        "## 录音\n\n"
        "- 录音文件：待补充\n\n"
        "## 转写全文\n\n"
        "等待转写。\n"
    )


def render_template(template: str, title: str, participants: str, topic: str, now: datetime) -> str:
    values = {
        "<%TITLE%>": title,
        "<%DATE%>": now.strftime("%Y-%m-%d"),
        "<%TIME%>": now.strftime("%H:%M"),
        "<%PARTICIPANTS%>": participants or "待补充",
        "<%TOPIC%>": topic or title,
    }
    output = template
    for key, value in values.items():
        output = output.replace(key, value)
    return output


def slugify(title: str) -> str:
    safe = title.strip().replace("/", "-").replace("\\", "-").replace(":", "-")
    return safe or "未命名会议"


def normalize_audio_path(vault: Path, audio_path: str) -> Path:
    path = Path(audio_path)
    if path.is_absolute():
        return path
    return vault / path


def normalize_note_path(vault: Path, note_path: str) -> Path:
    path = Path(note_path)
    if path.is_absolute():
        return path
    if not note_path.endswith(".md"):
        path = Path(f"{note_path}.md")
    return vault / path


def relative_link(vault: Path, path: Path) -> str:
    try:
        return path.relative_to(vault).as_posix()
    except ValueError:
        return str(path)


def replace_or_append_section(text: str, heading: str, body: str) -> str:
    block = f"{heading}\n\n{body.strip()}\n"
    escaped = re.escape(heading)
    pattern = re.compile(rf"(?ms)^{escaped}\s*\n+.*?(?=^##\s|\Z)")
    if pattern.search(text):
        return pattern.sub(block + "\n", text, count=1).rstrip() + "\n"
    trimmed = text.rstrip() + "\n\n" if text.strip() else ""
    return trimmed + block + "\n"


def resolve_ffmpeg() -> str:
    workspace_root = Path(__file__).resolve().parents[1]
    candidates = [
        workspace_root / "tools" / "ffmpeg" / "bin" / "ffmpeg.exe",
        Path("ffmpeg"),
    ]
    for candidate in candidates:
        if candidate == Path("ffmpeg") or candidate.exists():
            return str(candidate)
    raise FileNotFoundError("ffmpeg executable not found.")


def convert_audio_to_wav(audio_path: Path, wav_path: Path) -> None:
    ffmpeg = resolve_ffmpeg()
    wav_path.parent.mkdir(parents=True, exist_ok=True)
    cmd = [
        ffmpeg,
        "-y",
        "-i",
        str(audio_path),
        "-ar",
        "16000",
        "-ac",
        "1",
        "-c:a",
        "pcm_s16le",
        str(wav_path),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode != 0:
        raise RuntimeError(f"ffmpeg conversion failed: {result.stderr.strip() or result.stdout.strip()}")


def transcribe_via_local_whisper(wav_path: Path, language: str) -> str:
    curl_exe = "curl.exe"
    cmd = [
        curl_exe,
        "-s",
        "-X",
        "POST",
        "http://127.0.0.1:8080/inference",
        "-F",
        f"file=@{wav_path}",
        "-F",
        "response_format=json",
    ]
    if language and language != "auto":
        cmd += ["-F", f"language={language}"]

    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if result.returncode != 0:
        raise RuntimeError(f"Local whisper request failed: {result.stderr.strip() or result.stdout.strip()}")

    payload = result.stdout.strip()
    if not payload:
        raise RuntimeError("Local whisper returned an empty response.")

    try:
        data = json.loads(payload)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Local whisper returned invalid JSON: {payload}") from exc

    text = str(data.get("text", "")).strip()
    if not text:
        raise RuntimeError(f"Local whisper returned no transcript text: {payload}")
    return text


def build_note(
    note_path: Path,
    title: str,
    participants: str,
    topic: str,
    recording_link: str,
    transcript: str,
) -> str:
    now = datetime.now()
    if note_path.exists():
        content = read_text_with_fallback(note_path)
    else:
        content = render_template(load_template(), title, participants, topic, now)

    recording_body = f"- 录音文件：![[{recording_link}]]"
    content = replace_or_append_section(content, RECORDING_HEADING, recording_body)
    content = replace_or_append_section(content, TRANSCRIPT_HEADING, transcript)
    return content


def main() -> int:
    parser = argparse.ArgumentParser(description="Convert a recorded meeting audio file into an Obsidian meeting note.")
    parser.add_argument("audio_path", help="Path to the recorded audio file, relative to the vault or absolute.")
    parser.add_argument("--title", default="", help="Meeting title. Defaults to the audio file stem.")
    parser.add_argument("--participants", default="", help="Optional participants shown in the note header.")
    parser.add_argument("--topic", default="", help="Optional topic shown in the note header.")
    parser.add_argument("--note-path", default="", help="Optional meeting note path, relative to the vault or absolute.")
    parser.add_argument(
        "--note-dir",
        default=env_value("OBSIDIAN_MEETING_NOTE_DIR", "26子不语/会议记录"),
        help="Destination directory inside the Obsidian vault when creating a new note.",
    )
    parser.add_argument(
        "--vault",
        default=env_value("OBSIDIAN_VAULT_PATH", str(Path.home() / "Documents" / "Obsidian Vault")),
        help="Obsidian vault path.",
    )
    parser.add_argument(
        "--language",
        default="zh",
        help="Language hint passed to local whisper.",
    )
    args = parser.parse_args()

    vault = Path(args.vault)
    audio_path = normalize_audio_path(vault, args.audio_path)
    if not audio_path.exists():
        raise FileNotFoundError(f"Audio file not found: {audio_path}")

    title = args.title.strip() or audio_path.stem

    if args.note_path:
        note_path = normalize_note_path(vault, args.note_path)
    else:
        note_dir = vault / Path(args.note_dir)
        note_dir.mkdir(parents=True, exist_ok=True)
        filename = f"{datetime.now().strftime('%Y-%m-%d')}-{slugify(title)}.md"
        note_path = note_dir / filename

    wav_path = Path(__file__).resolve().parents[1] / "cache" / f"{audio_path.stem}.wav"
    convert_audio_to_wav(audio_path, wav_path)
    transcript = transcribe_via_local_whisper(wav_path, args.language)

    content = build_note(
        note_path=note_path,
        title=title,
        participants=args.participants.strip(),
        topic=args.topic.strip(),
        recording_link=relative_link(vault, audio_path),
        transcript=transcript,
    )
    note_path.write_text(content, encoding="utf-8", newline="\n")
    print(str(note_path))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

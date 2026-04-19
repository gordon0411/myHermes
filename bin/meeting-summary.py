from __future__ import annotations

import argparse
import json
import os
import re
import urllib.error
import urllib.request
from pathlib import Path


SUMMARY_HEADING = "## AI会议总结"
TRANSCRIPT_HEADING = "## 转写全文"


def load_env_file(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values
    for raw_line in path.read_text(encoding="utf-8").splitlines():
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


def read_config_model(config_path: Path) -> str:
    if not config_path.exists():
        return "MiniMax-M2.7"
    pattern = re.compile(r"^\s*default:\s*(.+?)\s*$")
    for line in config_path.read_text(encoding="utf-8").splitlines():
        match = pattern.match(line)
        if match:
            return match.group(1).strip().strip("'\"")
    return "MiniMax-M2.7"


def extract_section(text: str, heading: str) -> str:
    escaped = re.escape(heading)
    pattern = re.compile(rf"(?ms)^{escaped}\s*\n+(.*?)(?=^##\s|\Z)")
    match = pattern.search(text)
    return match.group(1).strip() if match else ""


def replace_or_append_section(text: str, heading: str, body: str) -> str:
    block = f"{heading}\n\n{body.strip()}\n"
    escaped = re.escape(heading)
    pattern = re.compile(rf"(?ms)^{escaped}\s*\n+.*?(?=^##\s|\Z)")
    if pattern.search(text):
        return pattern.sub(block + "\n", text, count=1).rstrip() + "\n"
    trimmed = text.rstrip() + "\n\n" if text.strip() else ""
    return trimmed + block + "\n"


def build_system_prompt() -> str:
    return (
        "你是专业的中文会议纪要助手。"
        "你需要根据会议或访谈转写稿，输出简洁、可执行、适合直接写入 Obsidian 的 Markdown。"
        "不要输出代码块，不要编造未提及的结论。"
        "待办事项要尽量写成可执行动作。"
    )


def build_user_prompt(note_title: str, transcript: str) -> str:
    return f"""
请根据下面的会议转写稿，生成一份中文会议总结。

输出要求：
1. 只输出 Markdown 正文，不要加代码块。
2. 按下面结构输出：
### 一句话总结
### 核心结论
- ...
### 待办事项
- [ ] ...
### 风险与分歧
- ...
### 关键原话
- "..."
3. 如果转写稿信息不足，就明确写“转写信息不足”。
4. 尽量保留访谈对象的关键观点，不要空泛。

笔记标题：{note_title}

转写稿：
{transcript}
""".strip()


def call_minimax(prompt: str, system_prompt: str, model: str) -> str:
    base_url = env_value("MINIMAX_CN_BASE_URL", "https://api.minimax.io/anthropic").rstrip("/")
    api_key = env_value("MINIMAX_CN_API_KEY")
    if not api_key:
        raise RuntimeError("MINIMAX_CN_API_KEY is not configured.")

    url = f"{base_url}/v1/messages"
    payload = {
        "model": model,
        "max_tokens": 2200,
        "temperature": 0.2,
        "system": system_prompt,
        "messages": [
            {
                "role": "user",
                "content": [{"type": "text", "text": prompt}],
            }
        ],
    }
    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "content-type": "application/json",
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=180) as response:
            data = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"MiniMax API error: {exc.code} {detail}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"MiniMax API request failed: {exc}") from exc

    parts = []
    for block in data.get("content", []):
        if block.get("type") == "text" and block.get("text"):
            parts.append(block["text"])

    summary = "\n".join(parts).strip()
    if not summary:
        raise RuntimeError("MiniMax API returned an empty summary.")
    return summary


def normalize_note_path(vault: Path, note_path: str) -> Path:
    path = Path(note_path)
    if path.is_absolute():
        return path
    if not note_path.endswith(".md"):
        path = Path(f"{note_path}.md")
    return vault / path


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate an AI meeting summary and write it back to an Obsidian note.")
    parser.add_argument("note_path", help="Path to the meeting note, relative to the vault or absolute.")
    parser.add_argument("--transcript-file", default="", help="Optional transcript file. When omitted, read from the note.")
    parser.add_argument(
        "--vault",
        default=env_value("OBSIDIAN_VAULT_PATH", str(Path.home() / "Documents" / "Obsidian Vault")),
        help="Obsidian vault path.",
    )
    parser.add_argument("--print-only", action="store_true", help="Print the summary without writing the note.")
    args = parser.parse_args()

    vault = Path(args.vault)
    note_path = normalize_note_path(vault, args.note_path)
    if not note_path.exists():
        raise FileNotFoundError(f"Meeting note not found: {note_path}")

    note_text = note_path.read_text(encoding="utf-8")
    transcript = ""
    if args.transcript_file:
        transcript = Path(args.transcript_file).read_text(encoding="utf-8").strip()
    else:
        transcript = extract_section(note_text, TRANSCRIPT_HEADING)

    if not transcript or transcript in {"等待转写。", "待补充"}:
        raise ValueError("No transcript content found. Please add the transcript first.")

    model = read_config_model(Path(__file__).resolve().parents[1] / "config.yaml")
    summary = call_minimax(
        build_user_prompt(note_path.stem, transcript),
        build_system_prompt(),
        model,
    )

    if args.print_only:
        print(summary)
        return 0

    updated = replace_or_append_section(note_text, SUMMARY_HEADING, summary)
    note_path.write_text(updated, encoding="utf-8", newline="\n")
    print(str(note_path))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

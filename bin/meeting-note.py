from __future__ import annotations

import argparse
import os
from datetime import datetime
from pathlib import Path


DEFAULT_TEMPLATE = """# <%TITLE%>

日期：<%DATE%>
时间：<%TIME%>
参与人：<%PARTICIPANTS%>
主题：<%TOPIC%>
标签：会议记录

## AI会议总结

等待生成。

## 录音

- 录音文件：待补充

## 转写全文

等待转写。
"""


def load_template() -> str:
    template_path = Path(__file__).resolve().parents[1] / "templates" / "obsidian-meeting-note.md"
    if template_path.exists():
        return template_path.read_text(encoding="utf-8")
    return DEFAULT_TEMPLATE


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


def main() -> int:
    parser = argparse.ArgumentParser(description="Create an Obsidian meeting note from a template.")
    parser.add_argument("title", help="Meeting title.")
    parser.add_argument("--participants", default="", help="Participants shown in the note header.")
    parser.add_argument("--topic", default="", help="Optional topic. Defaults to the title.")
    parser.add_argument(
        "--dir",
        default=os.getenv("OBSIDIAN_MEETING_NOTE_DIR", "26子不语/会议记录"),
        help="Destination directory inside the Obsidian vault.",
    )
    parser.add_argument(
        "--vault",
        default=os.getenv("OBSIDIAN_VAULT_PATH", str(Path.home() / "Documents" / "Obsidian Vault")),
        help="Obsidian vault path.",
    )
    args = parser.parse_args()

    now = datetime.now()
    vault = Path(args.vault)
    note_dir = vault / Path(args.dir)
    note_dir.mkdir(parents=True, exist_ok=True)

    filename = f"{now.strftime('%Y-%m-%d')}-{slugify(args.title)}.md"
    note_path = note_dir / filename

    if note_path.exists():
        raise FileExistsError(f"Meeting note already exists: {note_path}")

    content = render_template(load_template(), args.title, args.participants, args.topic, now)
    note_path.write_text(content, encoding="utf-8", newline="\n")
    print(str(note_path))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

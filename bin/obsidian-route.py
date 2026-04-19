from __future__ import annotations

import argparse
import json
import os
from pathlib import Path


def _load_routes(route_file: Path) -> dict:
    with route_file.open("r", encoding="utf-8") as fh:
        data = json.load(fh)
    routes = data.get("routes")
    if not isinstance(routes, dict):
        raise ValueError("Invalid route file: missing routes object")
    return routes


def _resolve_note_path(vault: Path, route_value: str) -> Path:
    note_path = route_value if route_value.endswith(".md") else f"{route_value}.md"
    return vault / Path(note_path)


def main() -> int:
    parser = argparse.ArgumentParser(description="Append content to an Obsidian note by route key.")
    parser.add_argument("route_key")
    parser.add_argument("title")
    parser.add_argument("content_file")
    args = parser.parse_args()

    route_file = Path(os.getenv("OBSIDIAN_ROUTE_FILE", Path(__file__).resolve().parents[1] / "obsidian-routes.json"))
    vault = Path(os.getenv("OBSIDIAN_VAULT_PATH", Path.home() / "Documents" / "Obsidian Vault"))

    if not route_file.exists():
        raise FileNotFoundError(f"Obsidian route file not found: {route_file}")
    if not vault.exists():
        raise FileNotFoundError(f"Obsidian vault not found: {vault}")

    routes = _load_routes(route_file)
    route_value = routes.get(args.route_key)
    if not isinstance(route_value, str) or not route_value.strip():
        raise KeyError(f"Unknown Obsidian route: {args.route_key}")

    content_path = Path(args.content_file)
    if not content_path.exists():
        raise FileNotFoundError(f"Content file not found: {content_path}")

    content = content_path.read_text(encoding="utf-8").strip()
    if not content:
        raise ValueError("Route content is required.")

    note_path = _resolve_note_path(vault, route_value.strip())
    note_path.parent.mkdir(parents=True, exist_ok=True)

    entry = f"## {args.title.strip()}\n\n{content}\n\n---\n"
    with note_path.open("a", encoding="utf-8", newline="\n") as fh:
        fh.write(entry)

    print(str(note_path))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

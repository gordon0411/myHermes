import json
import os
import sys
import time
from pathlib import Path

sys.path.insert(0, r"C:\Users\admin.ZBYCORP\AppData\Local\hermes\hermes-agent")

HERMES_HOME = Path(r"d:\GuojinX\xilu")
os.environ["HERMES_HOME"] = str(HERMES_HOME)

original_exit = sys.exit
original_kill = os.kill


def safe_exit(code=0):
    pass


def safe_kill(pid, signal):
    try:
        original_kill(pid, signal)
    except OSError as exc:
        if getattr(exc, "winerror", None) == 87 and signal == 0:
            raise ProcessLookupError(pid)
        raise


def process_exists(pid):
    if not isinstance(pid, int) or pid <= 0:
        return False
    try:
        import ctypes

        PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
        kernel32 = ctypes.windll.kernel32
        handle = kernel32.OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, False, pid)
        if not handle:
            return False
        kernel32.CloseHandle(handle)
        return True
    except Exception:
        try:
            original_kill(pid, 0)
            return True
        except Exception:
            return False


def cleanup_stale_gateway_state():
    cleaned = []
    for path in (HERMES_HOME / "gateway.pid", HERMES_HOME / "gateway_state.json"):
        if not path.exists():
            continue
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            continue
        pid = data.get("pid")
        kind = str(data.get("kind") or "")
        if kind != "hermes-gateway":
            continue
        if process_exists(pid):
            continue
        path.unlink(missing_ok=True)
        cleaned.append(path.name)
    return cleaned


sys.exit = safe_exit
os.kill = safe_kill

SERVICE_MODE = not sys.stdin or not sys.stdin.isatty()
MAX_RESTARTS = 3
RESTART_WINDOW_SECONDS = 600
RESTART_DELAY_SECONDS = 3


def should_retry_keyboard_interrupt(restart_times):
    now = time.time()
    recent = [ts for ts in restart_times if now - ts < RESTART_WINDOW_SECONDS]
    if len(recent) >= MAX_RESTARTS:
        return False, recent
    recent.append(now)
    return True, recent

try:
    from gateway.run import start_gateway
    import asyncio

    cleaned_files = cleanup_stale_gateway_state()
    if cleaned_files:
        print("Cleaned stale gateway state:", ", ".join(cleaned_files))
    restart_times = []

    while True:
        try:
            print("Starting Hermes Gateway with Feishu (safer Windows wrapper)...")
            asyncio.run(start_gateway(replace=False))
            break
        except KeyboardInterrupt:
            if not SERVICE_MODE:
                print("\nGateway stopped by user")
                break

            should_retry, restart_times = should_retry_keyboard_interrupt(restart_times)
            if not should_retry:
                print(
                    "\nGateway interrupted repeatedly in service mode; "
                    "leaving recovery to watchdog."
                )
                break

            print(
                "\nGateway interrupted in service mode; retrying in "
                f"{RESTART_DELAY_SECONDS}s..."
            )
            time.sleep(RESTART_DELAY_SECONDS)
except Exception as e:
    print(f"Error: {e}")
    import traceback

    traceback.print_exc()
    input("Press Enter to exit...")
finally:
    sys.exit = original_exit
    os.kill = original_kill

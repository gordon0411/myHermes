import sys
import os
from pathlib import Path

sys.path.insert(0, r"C:\Users\admin.ZBYCORP\AppData\Local\hermes\hermes-agent")

os.environ["HERMES_HOME"] = r"d:\GuojinX\xilu"

original_exit = sys.exit

def safe_exit(code=0):
    pass

sys.exit = safe_exit

original_kill = os.kill

def safe_kill(pid, signal):
    try:
        original_kill(pid, signal)
    except OSError as e:
        if hasattr(e, 'winerror') and e.winerror == 87:
            pass
        else:
            raise

os.kill = safe_kill

import gateway.status as status_module

original_acquire_scoped_lock = status_module.acquire_scoped_lock

def patched_acquire_scoped_lock(*args, **kwargs):
    return True, None

status_module.acquire_scoped_lock = patched_acquire_scoped_lock

original_get_running_pid = status_module.get_running_pid

def patched_get_running_pid():
    try:
        return original_get_running_pid()
    except OSError as e:
        if hasattr(e, 'winerror') and e.winerror == 87:
            return None
        raise

status_module.get_running_pid = patched_get_running_pid

try:
    from hermes_cli.main import main
    import sys
    
    sys.argv = ['hermes', 'dashboard']
    main()
except KeyboardInterrupt:
    print("\nDashboard stopped by user")
except Exception as e:
    print(f"Error: {e}")
    import traceback
    traceback.print_exc()
    input("Press Enter to exit...")
finally:
    sys.exit = original_exit
    os.kill = original_kill

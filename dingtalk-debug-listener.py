import json
import os
import threading
import time

import dingtalk_stream
from dingtalk_stream import ChatbotHandler


CLIENT_ID = os.environ.get("DINGTALK_CLIENT_ID", "").strip()
CLIENT_SECRET = os.environ.get("DINGTALK_CLIENT_SECRET", "").strip()


class DebugHandler(ChatbotHandler):
    async def process(self, callback_message):
        print(json.dumps(callback_message.data, ensure_ascii=False), flush=True)
        return dingtalk_stream.AckMessage.STATUS_OK, "OK"


def stop_later(seconds: int) -> None:
    time.sleep(seconds)
    os._exit(0)


def main() -> None:
    if not CLIENT_ID or not CLIENT_SECRET:
        raise SystemExit("DINGTALK_CLIENT_ID / DINGTALK_CLIENT_SECRET missing")

    threading.Thread(target=stop_later, args=(180,), daemon=True).start()
    credential = dingtalk_stream.Credential(CLIENT_ID, CLIENT_SECRET)
    client = dingtalk_stream.DingTalkStreamClient(credential)
    client.register_callback_handler(dingtalk_stream.ChatbotMessage.TOPIC, DebugHandler())
    client.start_forever()


if __name__ == "__main__":
    main()

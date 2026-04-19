---
name: hermes-cron-troubleshooting
description: Hermes Agent cron job creation troubleshooting — cron expression fails with "requires croniter" despite local installation
---

# Hermes Cron Job 疑难排错

## 核心问题
创建 cron 表达式任务（如 `0 21 * * 6`）时报错：`Cron expressions require 'croniter' package. Install with: pip install croniter`

即使本地终端和多个 Python venv 中都已安装 croniter，任务仍创建失败。

## 根因
Hermes Gateway 的调度器运行在云端后端容器中，有自己独立的 Python 环境，与本地 terminal 工具的 Python 环境（`/mnt/d/GuojinX/xilu/venv/`）完全隔离。本地安装 croniter 对云端调度器无效。

## 解决方案

### 方案1（推荐）：使用 interval 模式 + 任务内判断星期
创建任务时用 `every Xm` 格式（interval 模式），任务 prompt 内部用 Python 判断是否为目标星期。

```python
from datetime import datetime
if datetime.now().weekday() != 5:  # 5=周六
    print("今日非周六，跳过推送")
    return
```

定时器设置：`every 10080m`（每周 = 7×24×60 分钟）

### 方案2：尝试在更多路径安装 croniter（效果有限）
云端后端可能使用以下路径之一：
- `D:\GuojinX\xilu\venv\Scripts\python.exe`（已验证有 croniter）
- `C:\Users\admin.ZBYCORP\AppData\Local\hermes\hermes-agent\venv\Scripts\python.exe`（已验证有 croniter）

但这些都无法影响云端调度器的 Python 环境，方案1更可靠。

## 已知限制
- cron 表达式模式（`0 21 * * 6`）在云端后端无法使用
- interval 模式（`every Xm`）可正常工作
- WSL Ubuntu 会自动进入 "Stopped" 状态，导致 terminal 超时，需要 `wsl --shutdown` 后重启

## 相关环境
- Gateway 启动脚本：`d:\GuojinX\xilu\start-hermes-gateway-v2.py`
- 本地 Python：`/mnt/d/GuojinX/xilu/venv/Scripts/python.exe`
- cron 配置路径：`/mnt/d/GuojinX/xilu/cron/*.json`
- 现有定时任务：AI资讯早报（every 1440m）、每周工作周报（every 10080m）

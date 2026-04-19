# myHermes

Personal Hermes workspace backup for `xilu`.

## Included

- Hermes startup and watchdog scripts
- Feishu gateway wrapper and scheduled task installer
- Obsidian routing and helper scripts
- Cron job definitions
- Supporting docs and templates

## Excluded

- Secrets and auth state
- Logs, sessions, cache, databases
- Local virtual environments
- Large bundled binaries in `tools/`
- Runtime pairing and memory state

## Quick Start

1. Copy `.env.example` to `.env`
2. Fill in your real API keys and local paths
3. Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\start-hermes.ps1
```

## Feishu Gateway

Manual start:

```powershell
python .\start-hermes-gateway-v2.py
```

Install watchdog scheduled task:

```powershell
powershell -ExecutionPolicy Bypass -File .\install-hermes-service.ps1
```

## Notes

- This repo intentionally does not include runtime state or private tokens.
- If you restore on a new machine, re-login to Hermes providers and recreate `.env`.

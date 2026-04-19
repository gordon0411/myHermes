$workspaceRoot = Split-Path -Parent $PSScriptRoot
$pidFile = Join-Path $workspaceRoot "tools\whispercpp\whisper-server.pid"

if (-not (Test-Path -LiteralPath $pidFile)) {
    Write-Output "whisper-server is not running."
    exit 0
}

$serverPid = Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue
if (-not $serverPid) {
    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
    Write-Output "whisper-server pid file was empty and has been cleaned."
    exit 0
}

$process = Get-Process -Id $serverPid -ErrorAction SilentlyContinue
if (-not $process) {
    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
    Write-Output "whisper-server was not running; stale pid file removed."
    exit 0
}

Stop-Process -Id $serverPid -Force
Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
Write-Output "whisper-server stopped (PID: $serverPid)."

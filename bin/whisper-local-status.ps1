$workspaceRoot = Split-Path -Parent $PSScriptRoot
$runtimeRoot = Join-Path $workspaceRoot "tools\whispercpp"
$pidFile = Join-Path $runtimeRoot "whisper-server.pid"
$outLog = Join-Path $runtimeRoot "logs\server.out.log"
$errLog = Join-Path $runtimeRoot "logs\server.err.log"

if (-not (Test-Path -LiteralPath $pidFile)) {
    Write-Output "whisper-server: stopped"
    exit 0
}

$serverPid = Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue
$process = if ($serverPid) { Get-Process -Id $serverPid -ErrorAction SilentlyContinue } else { $null }
if (-not $process) {
    Write-Output "whisper-server: stale pid file"
    if (Test-Path -LiteralPath $outLog) {
        Write-Output "--- recent stdout ---"
        Get-Content -LiteralPath $outLog -Tail 20
    }
    if (Test-Path -LiteralPath $errLog) {
        Write-Output "--- recent stderr ---"
        Get-Content -LiteralPath $errLog -Tail 20
    }
    exit 0
}

Write-Output "whisper-server: running (PID: $serverPid)"
if (Test-Path -LiteralPath $outLog) {
    Write-Output "--- recent stdout ---"
    Get-Content -LiteralPath $outLog -Tail 20
}
if (Test-Path -LiteralPath $errLog) {
    Write-Output "--- recent stderr ---"
    Get-Content -LiteralPath $errLog -Tail 20
}

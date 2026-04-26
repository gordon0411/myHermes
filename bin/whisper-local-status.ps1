$workspaceRoot = Split-Path -Parent $PSScriptRoot
$runtimeRoot = Join-Path $workspaceRoot "tools\whispercpp"
$pidFile = Join-Path $runtimeRoot "whisper-server.pid"
$outLog = Join-Path $runtimeRoot "logs\server.out.log"
$errLog = Join-Path $runtimeRoot "logs\server.err.log"

function Get-WhisperProcess {
    $process = $null
    if (Test-Path -LiteralPath $pidFile) {
        $serverPid = Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue
        if ($serverPid) {
            $process = Get-Process -Id $serverPid -ErrorAction SilentlyContinue
        }
    }

    if (-not $process) {
        $process = Get-Process whisper-server -ErrorAction SilentlyContinue |
            Sort-Object StartTime -Descending |
            Select-Object -First 1
    }

    if ($process -and (-not (Test-Path -LiteralPath $pidFile))) {
        Set-Content -LiteralPath $pidFile -Value $process.Id -Encoding ascii
    }

    return $process
}

$process = Get-WhisperProcess
if (-not $process) {
    if (Test-Path -LiteralPath $pidFile) {
        Write-Output "whisper-server: stale pid file"
    } else {
        Write-Output "whisper-server: stopped"
    }
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

Write-Output "whisper-server: running (PID: $($process.Id))"
if (Test-Path -LiteralPath $outLog) {
    Write-Output "--- recent stdout ---"
    Get-Content -LiteralPath $outLog -Tail 20
}
if (Test-Path -LiteralPath $errLog) {
    Write-Output "--- recent stderr ---"
    Get-Content -LiteralPath $errLog -Tail 20
}

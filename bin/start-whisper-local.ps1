param(
    [string]$BindHost = "127.0.0.1",
    [int]$Port = 8080,
    [switch]$NoGpu
)

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$runtimeRoot = Join-Path $workspaceRoot "tools\whispercpp"
$serverExe = Join-Path $runtimeRoot "bin\Release\whisper-server.exe"
$modelPath = Join-Path $runtimeRoot "models\ggml-base.bin"
$ffmpegExe = Join-Path $workspaceRoot "tools\ffmpeg\bin\ffmpeg.exe"
$serverDir = Split-Path -Parent $serverExe
$logDir = Join-Path $runtimeRoot "logs"
$pidFile = Join-Path $runtimeRoot "whisper-server.pid"
$outLog = Join-Path $logDir "server.out.log"
$errLog = Join-Path $logDir "server.err.log"

if (-not (Test-Path -LiteralPath $serverExe)) {
    throw "whisper-server.exe not found: $serverExe"
}
if (-not (Test-Path -LiteralPath $modelPath)) {
    throw "Whisper model not found: $modelPath"
}

New-Item -ItemType Directory -Force $logDir | Out-Null
if (Test-Path -LiteralPath $ffmpegExe) {
    Copy-Item -LiteralPath $ffmpegExe -Destination (Join-Path $serverDir "ffmpeg.exe") -Force
}

if (Test-Path -LiteralPath $pidFile) {
    $oldPid = Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue
    if ($oldPid) {
        $existing = Get-Process -Id $oldPid -ErrorAction SilentlyContinue
        if ($existing) {
            Write-Output "whisper-server is already running (PID: $oldPid)."
            exit 0
        }
    }
    Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
}

$args = @(
    "--host", $BindHost,
    "--port", $Port,
    "--model", $modelPath,
    "--language", "auto",
    "--convert",
    "--print-progress"
)

if ($NoGpu) {
    $args += "--no-gpu"
}

Remove-Item -LiteralPath $outLog, $errLog -Force -ErrorAction SilentlyContinue
$before = @(Get-Process whisper-server -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
$argString = [string]::Join(" ", ($args | ForEach-Object { '"{0}"' -f $_ }))
$command = 'cd /d "{0}" && start "" /b "{1}" {2} 1>>"{3}" 2>>"{4}"' -f $serverDir, $serverExe, $argString, $outLog, $errLog
cmd.exe /c $command | Out-Null
Start-Sleep -Seconds 2
$after = @(Get-Process whisper-server -ErrorAction SilentlyContinue | Where-Object { $before -notcontains $_.Id } | Sort-Object StartTime -Descending)
$process = $after | Select-Object -First 1
if (-not $process) {
    throw "whisper-server failed to start."
}

Set-Content -LiteralPath $pidFile -Value $process.Id -Encoding ascii
Write-Output "whisper-server started on http://$BindHost`:$Port (PID: $($process.Id))"

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

function Get-WhisperProcess {
    param(
        [int]$Port = 8080
    )

    $process = Get-Process whisper-server -ErrorAction SilentlyContinue |
        Sort-Object StartTime -Descending |
        Select-Object -First 1
    if ($process) {
        return $process
    }

    $netstat = netstat -ano | Select-String ":$Port\s+.*LISTENING"
    foreach ($match in $netstat) {
        if ($match.Line -match 'LISTENING\s+(\d+)\s*$') {
            $pid = [int]$Matches[1]
            $candidate = Get-Process -Id $pid -ErrorAction SilentlyContinue
            if ($candidate -and $candidate.ProcessName -eq "whisper-server") {
                return $candidate
            }
        }
    }

    return $null
}

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

$existingProcess = Get-WhisperProcess -Port $Port
if ($existingProcess) {
    Set-Content -LiteralPath $pidFile -Value $existingProcess.Id -Encoding ascii
    Write-Output "whisper-server is already running (PID: $($existingProcess.Id))."
    exit 0
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
$process = Start-Process `
    -FilePath $serverExe `
    -ArgumentList $args `
    -WorkingDirectory $serverDir `
    -WindowStyle Hidden `
    -RedirectStandardOutput $outLog `
    -RedirectStandardError $errLog `
    -PassThru

$detectedProcess = $null
for ($i = 0; $i -lt 15; $i++) {
    Start-Sleep -Seconds 1
    $after = @(Get-Process whisper-server -ErrorAction SilentlyContinue | Where-Object { $before -notcontains $_.Id } | Sort-Object StartTime -Descending)
    $detectedProcess = $after | Select-Object -First 1
    if (-not $detectedProcess) {
        $detectedProcess = Get-WhisperProcess -Port $Port
    }
    if ($detectedProcess) {
        break
    }
}

if (-not $detectedProcess) {
    if ($process -and -not $process.HasExited) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
    }
    throw "whisper-server failed to start."
}

Set-Content -LiteralPath $pidFile -Value $detectedProcess.Id -Encoding ascii
Write-Output "whisper-server started on http://$BindHost`:$Port (PID: $($detectedProcess.Id))"

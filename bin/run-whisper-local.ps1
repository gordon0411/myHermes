$workspaceRoot = Split-Path -Parent $PSScriptRoot
$runtimeRoot = Join-Path $workspaceRoot "tools\whispercpp"
$serverExe = Join-Path $runtimeRoot "bin\Release\whisper-server.exe"
$serverDir = Split-Path -Parent $serverExe
$modelPath = Join-Path $runtimeRoot "models\ggml-base.bin"
$ffmpegExe = Join-Path $workspaceRoot "tools\ffmpeg\bin\ffmpeg.exe"

if (-not (Test-Path -LiteralPath $serverExe)) {
    throw "whisper-server.exe not found: $serverExe"
}
if (-not (Test-Path -LiteralPath $modelPath)) {
    throw "Whisper model not found: $modelPath"
}
if (Test-Path -LiteralPath $ffmpegExe) {
    Copy-Item -LiteralPath $ffmpegExe -Destination (Join-Path $serverDir "ffmpeg.exe") -Force
}

Push-Location $serverDir
try {
    & $serverExe `
        --host 127.0.0.1 `
        --port 8080 `
        --model $modelPath `
        --language auto `
        --convert `
        --print-progress `
        --no-gpu
}
finally {
    Pop-Location
}

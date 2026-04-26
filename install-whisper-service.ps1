$ErrorActionPreference = "Stop"

$serviceName = "WhisperLocal"
$taskPath = "\Codex\"
$workingDir = "D:\GuojinX\xilu"
$scriptPath = Join-Path $workingDir "bin\start-whisper-local.ps1"
$runnerScript = Join-Path $workingDir "bin\run-ps-hidden.vbs"
$wscriptExe = Join-Path $env:WINDIR "System32\wscript.exe"
$userId = "$env:USERDOMAIN\$env:USERNAME"

if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Whisper startup script not found: $scriptPath"
}

if (-not (Test-Path -LiteralPath $runnerScript)) {
    throw "Hidden runner script not found: $runnerScript"
}

if (-not (Test-Path -LiteralPath $wscriptExe)) {
    throw "Windows Script Host executable not found: $wscriptExe"
}

$existingTask = Get-ScheduledTask -TaskName $serviceName -TaskPath $taskPath -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $serviceName -TaskPath $taskPath -Confirm:$false
    Write-Host "Removed existing task: $taskPath$serviceName"
}

$action = New-ScheduledTaskAction -Execute $wscriptExe -Argument "`"$runnerScript`" `"$workingDir`" `"$scriptPath`" -NoGpu" -WorkingDirectory $workingDir
$logonTrigger = New-ScheduledTaskTrigger -AtLogOn -User $userId
$watchdogTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 3650)
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1)

Register-ScheduledTask `
    -TaskName $serviceName `
    -TaskPath $taskPath `
    -Action $action `
    -Trigger @($logonTrigger, $watchdogTrigger) `
    -Settings $settings `
    -Principal $principal `
    -Description "Local whisper.cpp server watchdog" | Out-Null

Write-Host "Local whisper watchdog installed successfully."
Write-Host "Task Name: $taskPath$serviceName"
Write-Host "Triggers: At logon, then every 5 minutes"

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "bin\hermes-common.ps1")

$serviceName = "HermesGateway"
$taskPath = "\Codex\"
$workingDir = Get-HermesHome
$ensureScript = Join-Path $workingDir "bin\ensure-hermes-gateway.ps1"
$powershellExe = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
$userId = "$env:USERDOMAIN\$env:USERNAME"

if (-not (Test-Path -LiteralPath $ensureScript)) {
    throw "Gateway watchdog script not found: $ensureScript"
}

if (-not (Test-Path -LiteralPath $powershellExe)) {
    throw "PowerShell executable not found: $powershellExe"
}

$existingTask = Get-ScheduledTask -TaskName $serviceName -TaskPath $taskPath -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $serviceName -TaskPath $taskPath -Confirm:$false
    Write-Host "Removed existing task: $taskPath$serviceName"
}

$action = New-ScheduledTaskAction -Execute $powershellExe -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ensureScript`"" -WorkingDirectory $workingDir
$logonTrigger = New-ScheduledTaskTrigger -AtLogOn -User $userId
$watchdogTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 3650)
$principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable:$false `
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
    -Description "Hermes Agent Gateway watchdog for Feishu" | Out-Null

Write-Host "Hermes gateway watchdog installed successfully."
Write-Host "Task Name: $taskPath$serviceName"
Write-Host "Triggers: At logon, then every 5 minutes"
Write-Host ""
Write-Host "To start immediately, run:"
Write-Host "Start-ScheduledTask -TaskPath '$taskPath' -TaskName '$serviceName'"
Write-Host ""
Write-Host "To view status:"
Write-Host "Get-ScheduledTask -TaskPath '$taskPath' -TaskName '$serviceName' | Get-ScheduledTaskInfo"

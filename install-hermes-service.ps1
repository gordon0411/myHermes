param(
    [switch]$RunAtStartup
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "bin\hermes-common.ps1")

$serviceName = "HermesGateway"
$taskPath = "\Codex\"
$workingDir = Get-HermesHome
$ensureScript = Join-Path $workingDir "bin\ensure-hermes-gateway.ps1"
$runnerScript = Join-Path $workingDir "bin\run-ps-hidden.vbs"
$wscriptExe = Join-Path $env:WINDIR "System32\wscript.exe"
$userId = "$env:USERDOMAIN\$env:USERNAME"

if (-not (Test-Path -LiteralPath $ensureScript)) {
    throw "Gateway watchdog script not found: $ensureScript"
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

$action = New-ScheduledTaskAction -Execute $wscriptExe -Argument "`"$runnerScript`" `"$workingDir`" `"$ensureScript`"" -WorkingDirectory $workingDir
$watchdogTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration (New-TimeSpan -Days 3650)

if ($RunAtStartup) {
    $startupTrigger = New-ScheduledTaskTrigger -AtStartup
    $triggers = @($startupTrigger, $watchdogTrigger)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    $modeDescription = "At startup, then every 1 minute"
}
else {
    $logonTrigger = New-ScheduledTaskTrigger -AtLogOn -User $userId
    $triggers = @($logonTrigger, $watchdogTrigger)
    $principal = New-ScheduledTaskPrincipal -UserId $userId -LogonType Interactive -RunLevel Limited
    $modeDescription = "At logon, then every 1 minute"
}

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
    -Trigger $triggers `
    -Settings $settings `
    -Principal $principal `
    -Description "Hermes Agent Gateway watchdog for Feishu" | Out-Null

Write-Host "Hermes gateway watchdog installed successfully."
Write-Host "Task Name: $taskPath$serviceName"
Write-Host "Triggers: $modeDescription"
if ($RunAtStartup) {
    Write-Host "Run mode: Background startup task under SYSTEM"
}
else {
    Write-Host "Run mode: Interactive logon task under $userId"
}
Write-Host ""
Write-Host "To start immediately, run:"
Write-Host "Start-ScheduledTask -TaskPath '$taskPath' -TaskName '$serviceName'"
Write-Host ""
Write-Host "To view status:"
Write-Host "Get-ScheduledTask -TaskPath '$taskPath' -TaskName '$serviceName' | Get-ScheduledTaskInfo"

param(
    [string]$Title,
    [string]$Summary,
    [string]$Progress,
    [string]$Risks,
    [string]$NextStep
)

$now = Get-Date
if ([string]::IsNullOrWhiteSpace($Title)) {
    $Title = $now.ToString("yyyy-MM-dd work-log")
}

if ([string]::IsNullOrWhiteSpace($Summary)) {
    $Summary = "pending"
}

if ([string]::IsNullOrWhiteSpace($Progress)) {
    $Progress = "pending"
}

if ([string]::IsNullOrWhiteSpace($Risks)) {
    $Risks = "none"
}

if ([string]::IsNullOrWhiteSpace($NextStep)) {
    $NextStep = "pending"
}

$body = @"
Recorded at: $($now.ToString("yyyy-MM-dd HH:mm"))

- Summary: $Summary
- Progress: $Progress
- Risks: $Risks
- Next: $NextStep
"@

$routeScript = Join-Path $PSScriptRoot "obsidian-route.ps1"
& $routeScript "work_log" $Title $body

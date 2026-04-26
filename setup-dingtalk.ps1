param(
    [string]$ClientId,
    [string]$ClientSecret,
    [string]$AllowedUsers,
    [string]$HomeChannel,
    [switch]$OpenAccess,
    [switch]$NoRequireMention,
    [switch]$InstallOnly
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "bin\hermes-common.ps1")

$env:HERMES_HOME = Get-HermesHome
Import-HermesDotEnv
Set-HermesConsoleEncoding

$pythonExe = Resolve-HermesPython -Require
$envPath = Join-Path $env:HERMES_HOME ".env"
$cleanedAllowedUsers = ""

function Test-DingTalkDependency {
    $result = & $pythonExe -c "import importlib.util; print('true' if importlib.util.find_spec('dingtalk_stream') else 'false')"
    return ($result | Select-Object -Last 1).Trim().ToLowerInvariant() -eq "true"
}

function Install-DingTalkDependency {
    Write-Host "Installing DingTalk gateway dependency into Hermes venv..."
    & $pythonExe -m pip install dingtalk-stream httpx
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install dingtalk-stream into Hermes venv."
    }
}

function Set-DotEnvValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [string]$Value,
        [switch]$Remove
    )

    $lines = New-Object System.Collections.Generic.List[string]
    if (Test-Path -LiteralPath $envPath) {
        foreach ($line in Get-Content -LiteralPath $envPath -Encoding UTF8) {
            $lines.Add($line)
        }
    }

    $pattern = '^\s*' + [regex]::Escape($Name) + '\s*='
    for ($idx = $lines.Count - 1; $idx -ge 0; $idx--) {
        if ($lines[$idx] -match $pattern) {
            $lines.RemoveAt($idx)
        }
    }

    if (-not $Remove) {
        $lines.Add("$Name=$Value")
    }

    Set-Content -LiteralPath $envPath -Value $lines -Encoding UTF8
    [Environment]::SetEnvironmentVariable($Name, $(if ($Remove) { $null } else { $Value }), "Process")
}

$hasDependency = Test-DingTalkDependency
if (-not $hasDependency) {
    Install-DingTalkDependency
    $hasDependency = Test-DingTalkDependency
}

if (-not $hasDependency) {
    throw "dingtalk-stream still cannot be imported after installation."
}

if ($InstallOnly) {
    Write-Host "DingTalk dependency is ready in Hermes venv."
    exit 0
}

if (-not $ClientId -or -not $ClientSecret) {
    Write-Host "DingTalk dependency is ready, but credentials were not written."
    Write-Host ""
    Write-Host "Next step:"
    Write-Host "  .\setup-dingtalk.ps1 -ClientId <AppKey> -ClientSecret <AppSecret> [-AllowedUsers staff_id1,staff_id2] [-HomeChannel cidxxxx]"
    Write-Host ""
    Write-Host "Optional:"
    Write-Host "  -OpenAccess         Allow anyone in DingTalk to use the bot"
    Write-Host "  -NoRequireMention   In groups, do not require @mention"
    Write-Host ""
    Write-Host "Official entry:"
    Write-Host "  https://open-dev.dingtalk.com/"
    exit 0
}

Set-DotEnvValue -Name "DINGTALK_CLIENT_ID" -Value $ClientId
Set-DotEnvValue -Name "DINGTALK_CLIENT_SECRET" -Value $ClientSecret
Set-DotEnvValue -Name "DINGTALK_REQUIRE_MENTION" -Value $(if ($NoRequireMention) { "false" } else { "true" })

if ($PSBoundParameters.ContainsKey("AllowedUsers")) {
    if ([string]::IsNullOrWhiteSpace($AllowedUsers)) {
        Set-DotEnvValue -Name "DINGTALK_ALLOWED_USERS" -Remove
    }
    else {
        $cleanedAllowedUsers = (($AllowedUsers -split ",") | ForEach-Object { $_.Trim() } | Where-Object { $_ }) -join ","
        Set-DotEnvValue -Name "DINGTALK_ALLOWED_USERS" -Value $cleanedAllowedUsers
    }
}

if ($OpenAccess) {
    Set-DotEnvValue -Name "DINGTALK_ALLOW_ALL_USERS" -Value "true"
}
elseif ($PSBoundParameters.ContainsKey("AllowedUsers")) {
    Set-DotEnvValue -Name "DINGTALK_ALLOW_ALL_USERS" -Remove
}

if ($PSBoundParameters.ContainsKey("HomeChannel")) {
    if ([string]::IsNullOrWhiteSpace($HomeChannel)) {
        Set-DotEnvValue -Name "DINGTALK_HOME_CHANNEL" -Remove
    }
    else {
        Set-DotEnvValue -Name "DINGTALK_HOME_CHANNEL" -Value $HomeChannel.Trim()
    }
}

Write-Host "DingTalk credentials were written to .env."
Write-Host ""
Write-Host "Current effective switches:"
Write-Host "  DINGTALK_REQUIRE_MENTION=$($(if ($NoRequireMention) { 'false' } else { 'true' }))"
if ($OpenAccess) {
    Write-Host "  DINGTALK_ALLOW_ALL_USERS=true"
}
elseif ($PSBoundParameters.ContainsKey("AllowedUsers")) {
    Write-Host "  DINGTALK_ALLOWED_USERS=$cleanedAllowedUsers"
}
if ($PSBoundParameters.ContainsKey("HomeChannel") -and -not [string]::IsNullOrWhiteSpace($HomeChannel)) {
    Write-Host "  DINGTALK_HOME_CHANNEL=$($HomeChannel.Trim())"
}

Write-Host ""
Write-Host "Next step:"
Write-Host "  Restart the Hermes gateway so DingTalk is loaded."
Write-Host "  Example: python .\start-hermes-gateway-v2.py"
Write-Host ""
Write-Host "Tip:"
Write-Host "  If the gateway is already running as a scheduled task, restart that task after updating .env."

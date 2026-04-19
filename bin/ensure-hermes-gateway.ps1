$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot "hermes-common.ps1")

$hermesHome = Get-HermesHome
$env:HERMES_HOME = $hermesHome
Import-HermesDotEnv

$pythonExe = Resolve-HermesPython -Require
$gatewayScript = Resolve-GatewayScript
$statePath = Join-Path $hermesHome "gateway_state.json"
$pidPath = Join-Path $hermesHome "gateway.pid"
$logPath = Join-Path $hermesHome "logs\gateway.log"

function Get-GatewayState {
    if (-not (Test-Path -LiteralPath $statePath)) {
        return $null
    }

    try {
        return Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
    }
    catch {
        return $null
    }
}

function Test-ProcessAlive {
    param(
        [Parameter(Mandatory = $true)]
        [int]$ProcessId
    )

    try {
        Get-Process -Id $ProcessId -ErrorAction Stop | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

function Test-RecentFatalGatewayError {
    if (-not (Test-Path -LiteralPath $logPath)) {
        return $false
    }

    $fatalPatterns = @(
        "cannot schedule new futures after interpreter shutdown",
        "Executor shutdown has been called",
        "Adapter loop unavailable for 120s"
    )

    $tail = @(Get-Content -LiteralPath $logPath -Tail 400 -ErrorAction SilentlyContinue)
    if ($tail.Count -eq 0) {
        return $false
    }

    $startupIndexes = @(
        for ($i = 0; $i -lt $tail.Count; $i++) {
            if ($tail[$i] -like "*Starting Hermes Gateway*") {
                $i
            }
        }
    )

    if ($startupIndexes.Count -gt 0) {
        $tail = $tail[$startupIndexes[-1]..($tail.Count - 1)]
    }

    foreach ($pattern in $fatalPatterns) {
        if ($tail -match [regex]::Escape($pattern)) {
            return $true
        }
    }

    return $false
}

function Remove-StaleGatewayFiles {
    foreach ($path in @($statePath, $pidPath)) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
        }
    }
}

$state = Get-GatewayState
$isRunning = $false

if ($state -and $state.kind -eq "hermes-gateway" -and $state.pid) {
    $isRunning = Test-ProcessAlive -ProcessId ([int]$state.pid)
}

if ($isRunning -and -not (Test-RecentFatalGatewayError)) {
    Write-Host "Hermes gateway already running with PID $($state.pid)."
    exit 0
}

if ($isRunning) {
    Stop-Process -Id ([int]$state.pid) -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

Remove-StaleGatewayFiles

$process = Start-Process -FilePath $pythonExe -ArgumentList @($gatewayScript) -WorkingDirectory $hermesHome -WindowStyle Hidden -PassThru
Write-Host "Started Hermes gateway with PID $($process.Id)."

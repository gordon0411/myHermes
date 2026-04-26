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
$maxStartingSeconds = 180
$maxConnectingSeconds = 180

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

function ConvertTo-DateTimeOffsetOrNull {
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return $null
    }

    $text = [string]$Value
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    try {
        return [DateTimeOffset]::Parse($text)
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

function Get-ProcessStartTimeOrNull {
    param(
        [Parameter(Mandatory = $true)]
        [int]$ProcessId
    )

    try {
        $process = Get-Process -Id $ProcessId -ErrorAction Stop
        return [DateTimeOffset]$process.StartTime
    }
    catch {
        return $null
    }
}

function Get-LogLineTimestampOrNull {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Line
    )

    if ([string]::IsNullOrEmpty($Line)) {
        return $null
    }

    if ($Line -notmatch '^(?<stamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}),\d{3}') {
        return $null
    }

    try {
        return [DateTimeOffset]::ParseExact(
            $Matches.stamp,
            'yyyy-MM-dd HH:mm:ss',
            [System.Globalization.CultureInfo]::InvariantCulture
        )
    }
    catch {
        return $null
    }
}

function Test-RecentFatalGatewayError {
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [DateTimeOffset]$Since
    )

    $fatalPatterns = @(
        "cannot schedule new futures after shutdown",
        "cannot schedule new futures after interpreter shutdown",
        "Executor shutdown has been called",
        "Adapter loop unavailable for 120s",
        "RecursionError: maximum recursion depth exceeded"
    )

    $logCandidates = @(
        $logPath,
        (Join-Path $hermesHome "logs\errors.log")
    )

    foreach ($candidate in $logCandidates) {
        if (-not (Test-Path -LiteralPath $candidate)) {
            continue
        }

        $tail = @(Get-Content -LiteralPath $candidate -Tail 400 -ErrorAction SilentlyContinue)
        if ($tail.Count -eq 0) {
            continue
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

        if ($Since) {
            $filteredTail = New-Object System.Collections.Generic.List[string]
            $includeLine = $false

            foreach ($line in $tail) {
                $timestamp = Get-LogLineTimestampOrNull -Line $line
                if ($timestamp) {
                    $includeLine = $timestamp -ge $Since
                }

                if ($includeLine) {
                    $filteredTail.Add($line)
                }
            }

            $tail = @($filteredTail)
            if ($tail.Count -eq 0) {
                continue
            }
        }

        foreach ($pattern in $fatalPatterns) {
            if ($tail -match [regex]::Escape($pattern)) {
                return $true
            }
        }
    }

    return $false
}

function Test-StaleGatewayState {
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$State
    )

    if ($null -eq $State) {
        return $false
    }

    $now = [DateTimeOffset]::UtcNow
    $gatewayUpdatedAt = ConvertTo-DateTimeOffsetOrNull $State.updated_at
    $gatewayState = [string]$State.gateway_state

    if ($gatewayState -eq "starting" -and $gatewayUpdatedAt) {
        if (($now - $gatewayUpdatedAt).TotalSeconds -ge $maxStartingSeconds) {
            return $true
        }
    }

    $platforms = $State.platforms
    if ($platforms -and $platforms.feishu) {
        $feishuState = [string]$platforms.feishu.state
        $feishuUpdatedAt = ConvertTo-DateTimeOffsetOrNull $platforms.feishu.updated_at

        if ($feishuState -eq "connecting" -and $feishuUpdatedAt) {
            if (($now - $feishuUpdatedAt).TotalSeconds -ge $maxConnectingSeconds) {
                return $true
            }
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

if ($isRunning) {
    $processStartTime = Get-ProcessStartTimeOrNull -ProcessId ([int]$state.pid)
    $hasFatalError = Test-RecentFatalGatewayError -Since $processStartTime
    $hasStaleState = Test-StaleGatewayState -State $state

    if (-not $hasFatalError -and -not $hasStaleState) {
        Write-Host "Hermes gateway already running with PID $($state.pid)."
        exit 0
    }

    if ($hasFatalError) {
        Write-Host "Restarting Hermes gateway due to recent fatal gateway error."
    }

    if ($hasStaleState) {
        Write-Host "Restarting Hermes gateway because the gateway stayed in starting/connecting too long."
    }
}

if ($isRunning) {
    Stop-Process -Id ([int]$state.pid) -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

Remove-StaleGatewayFiles

$process = Start-Process -FilePath $pythonExe -ArgumentList @($gatewayScript) -WorkingDirectory $hermesHome -WindowStyle Hidden -PassThru
Write-Host "Started Hermes gateway with PID $($process.Id)."

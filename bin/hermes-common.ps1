Set-StrictMode -Version Latest

function Get-HermesHome {
    $resolvedHome = Resolve-Path (Join-Path $PSScriptRoot "..")
    return $resolvedHome.Path
}

function Import-HermesDotEnv {
    param(
        [string]$Path = (Join-Path (Get-HermesHome) ".env")
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith("#")) {
            continue
        }

        $parts = $trimmed -split "=", 2
        if ($parts.Count -ne 2) {
            continue
        }

        $name = $parts[0].Trim()
        if (-not $name) {
            continue
        }

        $value = $parts[1].Trim()
        if (
            $value.Length -ge 2 -and (
                ($value.StartsWith('"') -and $value.EndsWith('"')) -or
                ($value.StartsWith("'") -and $value.EndsWith("'"))
            )
        ) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        [Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}

function Set-HermesConsoleEncoding {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [Console]::InputEncoding = $utf8NoBom
    [Console]::OutputEncoding = $utf8NoBom
    $global:OutputEncoding = $utf8NoBom
    [Environment]::SetEnvironmentVariable("PYTHONIOENCODING", "utf-8", "Process")
}

function Resolve-HermesExecutable {
    param(
        [switch]$Require
    )

    $candidates = @(
        "C:\Users\admin.ZBYCORP\AppData\Local\hermes\hermes-agent\venv\Scripts\hermes.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    $command = Get-Command hermes -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) {
        return $command.Source
    }

    if ($Require) {
        throw "Could not find Hermes CLI. Expected hermes.exe under the local Hermes install or in PATH."
    }

    return $null
}

function Resolve-HermesPython {
    param(
        [switch]$Require
    )

    $candidates = @(
        "C:\Users\admin.ZBYCORP\AppData\Local\hermes\hermes-agent\venv\Scripts\python.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    $command = Get-Command python -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) {
        return $command.Source
    }

    if ($Require) {
        throw "Could not find a Python runtime for Hermes gateway startup."
    }

    return $null
}

function Resolve-GatewayScript {
    return (Join-Path (Get-HermesHome) "start-hermes-gateway-v2.py")
}

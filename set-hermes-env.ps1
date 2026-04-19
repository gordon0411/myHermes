$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "bin\hermes-common.ps1")

$env:HERMES_HOME = Get-HermesHome
Import-HermesDotEnv
Set-HermesConsoleEncoding

$hermesExe = Resolve-HermesExecutable -Require
if ($args.Count -gt 0) {
    & $hermesExe @args
}
else {
    & $hermesExe doctor
}

if ($LASTEXITCODE -ne $null) {
    exit $LASTEXITCODE
}

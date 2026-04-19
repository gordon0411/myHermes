$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "bin\hermes-common.ps1")

$env:HERMES_HOME = Get-HermesHome
Import-HermesDotEnv
Set-HermesConsoleEncoding

$hermesExe = Resolve-HermesExecutable -Require
& $hermesExe @args

if ($LASTEXITCODE -ne $null) {
    exit $LASTEXITCODE
}

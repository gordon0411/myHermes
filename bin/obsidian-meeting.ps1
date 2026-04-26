param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("new", "transcribe", "summarize")]
    [string]$Action,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$TitleOrNote,

    [Parameter(Position = 2)]
    [string]$Extra = "",

    [Parameter(Position = 3)]
    [string]$Extra2 = ""
)

$workspaceRoot = Split-Path -Parent $PSScriptRoot

function Get-WorkingPython {
    $candidates = @()

    $workspacePython = Join-Path $workspaceRoot "venv\Scripts\python.exe"
    if (Test-Path -LiteralPath $workspacePython) {
        $candidates += $workspacePython
    }

    $hermesPython = "C:\Users\admin.ZBYCORP\AppData\Local\hermes\hermes-agent\venv\Scripts\python.exe"
    if (Test-Path -LiteralPath $hermesPython) {
        $candidates += $hermesPython
    }

    $bundled = Get-ChildItem "$HOME\.cache\codex-runtimes" -Recurse -Filter python.exe -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -like "*dependencies\\python\\python.exe" } |
        Select-Object -ExpandProperty FullName -Unique
    if ($bundled) {
        $candidates += $bundled
    }

    $candidates += "python"

    foreach ($candidate in $candidates) {
        try {
            & $candidate -c "import sys; print(sys.executable)" | Out-Null
            return $candidate
        } catch {
            continue
        }
    }

    throw "No working Python runtime found."
}

$python = Get-WorkingPython

switch ($Action) {
    "new" {
        & $python (Join-Path $PSScriptRoot "meeting-note.py") $TitleOrNote --participants $Extra --topic $Extra2
    }
    "transcribe" {
        $cmdArgs = @((Join-Path $PSScriptRoot "transcribe-meeting.py"), $TitleOrNote)
        if (-not [string]::IsNullOrWhiteSpace($Extra)) {
            $cmdArgs += @("--title", $Extra)
        }
        if (-not [string]::IsNullOrWhiteSpace($Extra2)) {
            $cmdArgs += @("--participants", $Extra2)
        }
        & $python @cmdArgs
    }
    "summarize" {
        if ([string]::IsNullOrWhiteSpace($Extra)) {
            & $python (Join-Path $PSScriptRoot "meeting-summary.py") $TitleOrNote
        } else {
            & $python (Join-Path $PSScriptRoot "meeting-summary.py") $TitleOrNote --transcript-file $Extra
        }
    }
}

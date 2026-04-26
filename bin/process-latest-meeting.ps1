param(
    [string]$Title = "",
    [string]$Participants = "",
    [string]$AudioDir = ""
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$meetingScript = Join-Path $PSScriptRoot "obsidian-meeting.ps1"
$vault = $env:OBSIDIAN_VAULT_PATH
if ([string]::IsNullOrWhiteSpace($vault)) {
    $vault = Join-Path $HOME "Documents\Obsidian Vault"
}

if (-not (Test-Path -LiteralPath $vault)) {
    throw "Obsidian vault not found: $vault"
}

$audioExtensions = @(".webm", ".wav", ".mp3", ".m4a", ".ogg", ".mp4")
$latestAudio = $null

if (-not [string]::IsNullOrWhiteSpace($AudioDir)) {
    $audioRoot = if ([System.IO.Path]::IsPathRooted($AudioDir)) {
        $AudioDir
    } else {
        Join-Path $vault $AudioDir
    }

    if (Test-Path -LiteralPath $audioRoot) {
        $latestAudio = Get-ChildItem -LiteralPath $audioRoot -File |
            Where-Object { $_.Extension -in $audioExtensions } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
    }
}

if (-not $latestAudio) {
    $latestAudio = Get-ChildItem -LiteralPath $vault -Recurse -File |
        Where-Object { $_.Extension -in $audioExtensions } |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

if (-not $latestAudio) {
    throw "No meeting audio found in vault: $vault"
}

if ([string]::IsNullOrWhiteSpace($Title)) {
    $Title = $latestAudio.BaseName
}

$beforeLatestNote = Get-ChildItem -LiteralPath $vault -Recurse -File -Filter *.md -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
$beforeLatestNoteTime = if ($beforeLatestNote) { $beforeLatestNote.LastWriteTime } else { [datetime]::MinValue }

$transcribeArgs = @(
    "-NoProfile",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    $meetingScript,
    "transcribe",
    $latestAudio.FullName,
    $Title
)

if (-not [string]::IsNullOrWhiteSpace($Participants)) {
    $transcribeArgs += $Participants
}

$null = & powershell @transcribeArgs
if ($LASTEXITCODE -ne 0) {
    throw "Meeting transcription failed."
}

$note = Get-ChildItem -LiteralPath $vault -Recurse -File -Filter *.md -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -gt $beforeLatestNoteTime } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

if (-not $note) {
    throw "Could not resolve transcribed meeting note path."
}

$notePath = $note.FullName

$summarizeArgs = @(
    "-NoProfile",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    $meetingScript,
    "summarize",
    $notePath
)

$null = & powershell @summarizeArgs
if ($LASTEXITCODE -ne 0) {
    throw "Meeting summary generation failed."
}

Write-Output $notePath

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet("list", "read", "search", "create", "append")]
    [string]$Action,

    [Parameter(Position = 1)]
    [string]$Target,

    [Parameter(Position = 2)]
    [string]$Content
)

$vault = $env:OBSIDIAN_VAULT_PATH
if ([string]::IsNullOrWhiteSpace($vault)) {
    $vault = Join-Path $HOME "Documents\Obsidian Vault"
}

if (-not (Test-Path -LiteralPath $vault)) {
    throw "Obsidian vault not found: $vault"
}

function Resolve-NotePath {
    param([string]$PathValue)

    if ([string]::IsNullOrWhiteSpace($PathValue)) {
        throw "A note path is required for action '$Action'."
    }

    $notePath = $PathValue
    if (-not $notePath.EndsWith(".md")) {
        $notePath = "$notePath.md"
    }
    return Join-Path $vault $notePath
}

switch ($Action) {
    "list" {
        $root = $vault
        if (-not [string]::IsNullOrWhiteSpace($Target)) {
            $root = Join-Path $vault $Target
        }
        Get-ChildItem -LiteralPath $root -Recurse -File -Filter *.md |
            ForEach-Object {
                $_.FullName.Substring($vault.Length).TrimStart('\')
            }
    }
    "read" {
        $path = Resolve-NotePath $Target
        Get-Content -LiteralPath $path
    }
    "search" {
        if ([string]::IsNullOrWhiteSpace($Target)) {
            throw "A search keyword is required."
        }
        Get-ChildItem -LiteralPath $vault -Recurse -File -Filter *.md |
            Select-String -Pattern $Target -SimpleMatch |
            Select-Object -Unique Path, LineNumber, Line
    }
    "create" {
        $path = Resolve-NotePath $Target
        $parent = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        $body = if ($null -ne $Content) { $Content } else { "" }
        Set-Content -LiteralPath $path -Value $body -Encoding UTF8
        Write-Output $path
    }
    "append" {
        $path = Resolve-NotePath $Target
        $parent = Split-Path -Parent $path
        if (-not (Test-Path -LiteralPath $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
        $body = if ($null -ne $Content) { $Content } else { "" }
        Add-Content -LiteralPath $path -Value $body -Encoding UTF8
        Write-Output $path
    }
}

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$RouteKey,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Title,

    [Parameter(Position = 2)]
    [string]$Content,

    [string]$ContentFile
)

$routeFile = $env:OBSIDIAN_ROUTE_FILE
if ([string]::IsNullOrWhiteSpace($routeFile)) {
    $routeFile = Join-Path $PSScriptRoot "..\obsidian-routes.json"
}

if (-not (Test-Path -LiteralPath $routeFile)) {
    throw "Obsidian route file not found: $routeFile"
}

$routeConfig = Get-Content -LiteralPath $routeFile -Raw -Encoding UTF8 | ConvertFrom-Json
$routes = $routeConfig.routes
$notePath = $routes.$RouteKey

if ([string]::IsNullOrWhiteSpace($notePath)) {
    throw "Unknown Obsidian route: $RouteKey"
}

$vault = $env:OBSIDIAN_VAULT_PATH
if ([string]::IsNullOrWhiteSpace($vault)) {
    $vault = Join-Path $HOME "Documents\Obsidian Vault"
}

if (-not (Test-Path -LiteralPath $vault)) {
    throw "Obsidian vault not found: $vault"
}

$resolvedNotePath = $notePath
if (-not $resolvedNotePath.EndsWith(".md")) {
    $resolvedNotePath = "$resolvedNotePath.md"
}

$absoluteNotePath = Join-Path $vault $resolvedNotePath
$parent = Split-Path -Parent $absoluteNotePath
if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}

$trimmedTitle = $Title.Trim()

if ([string]::IsNullOrWhiteSpace($Content)) {
    if (-not [string]::IsNullOrWhiteSpace($ContentFile)) {
        if (-not (Test-Path -LiteralPath $ContentFile)) {
            throw "Content file not found: $ContentFile"
        }
        $Content = Get-Content -LiteralPath $ContentFile -Raw -Encoding UTF8
    }
}

if ([string]::IsNullOrWhiteSpace($Content)) {
    $stdin = [Console]::In.ReadToEnd()
    if (-not [string]::IsNullOrWhiteSpace($stdin)) {
        $Content = $stdin
    }
}

if ([string]::IsNullOrWhiteSpace($Content)) {
    throw "Route content is required."
}

$trimmedContent = $Content.Trim()

$entry = @"
## $trimmedTitle

$trimmedContent

---
"@

Add-Content -LiteralPath $absoluteNotePath -Value $entry -Encoding UTF8
Write-Output $absoluteNotePath

# Standalone Installer for z-vision (Google Antigravity & ZCode)
[CmdletBinding()]
param(
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"
$srcRoot = $PSScriptRoot
$ideRoots = @(
    @{ Name = "Antigravity"; Path = (Join-Path $env:USERPROFILE ".gemini\config\plugins\z-vision") },
    @{ Name = "ZCode";       Path = (Join-Path $env:USERPROFILE ".zcode\plugins\z-vision") }
)

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)

foreach ($ide in $ideRoots) {
    $targetDir = $ide.Path
    if ($Uninstall) {
        if (Test-Path $targetDir) {
            Remove-Item -Path $targetDir -Recurse -Force
            Write-Host "[$($ide.Name)] Removed $targetDir" -ForegroundColor Yellow
        }
        continue
    }

    if (!(Test-Path $targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
    }

    robocopy $srcRoot $targetDir /MIR /XD .git .github tests node_modules .localdata dist /XF *.exe *.pdb *.log /NP /NFL /NDL /NJH /NJS | Out-Null

    if ($ide.Name -eq "Antigravity") {
        $mcpPath = Join-Path $targetDir "mcp_config.json"
        if (Test-Path $mcpPath) {
            $resolvedScript = (Join-Path $targetDir "scripts\mcp-server.mjs") -replace '\\', '/'
            $raw = Get-Content $mcpPath -Raw
            $updated = $raw.Replace('./scripts/mcp-server.mjs', $resolvedScript)
            [System.IO.File]::WriteAllText($mcpPath, $updated, $utf8NoBom)
        }
    }

    Write-Host "[$($ide.Name)] Installed z-vision -> $targetDir" -ForegroundColor Green
}

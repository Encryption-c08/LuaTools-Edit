param(
    [string]$SourceDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path,
    [string]$PluginsDir = 'C:\Program Files (x86)\Steam\plugins',
    [switch]$NoRestart
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $PluginsDir)) {
    throw "Steam plugins directory not found: $PluginsDir"
}

$resolvedSource = (Resolve-Path -LiteralPath $SourceDir).Path
$projectName = Split-Path -Leaf $resolvedSource
$targetDir = Join-Path $PluginsDir $projectName

if (Test-Path -LiteralPath $targetDir) {
    Remove-Item -LiteralPath $targetDir -Recurse -Force
}

Copy-Item -LiteralPath $resolvedSource -Destination $targetDir -Recurse -Force

if (-not $NoRestart) {
    Get-Process -Name steam -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2

    $steamExe = $null
    try {
        $steamPath = (Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam' -Name 'SteamPath' -ErrorAction Stop).SteamPath
        if ($steamPath) {
            $candidate = Join-Path $steamPath 'Steam.exe'
            if (Test-Path -LiteralPath $candidate) {
                $steamExe = $candidate
            }
        }
    } catch {
    }

    if ($steamExe) {
        Start-Process -FilePath $steamExe -ArgumentList '-clearbeta'
    } else {
        Start-Process -FilePath 'steam.exe' -ArgumentList '-clearbeta'
    }
}

Write-Output "Deployed '$projectName' to '$targetDir'$(if ($NoRestart) { ' (no restart)' } else { '' })."

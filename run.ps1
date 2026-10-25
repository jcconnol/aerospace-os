param([switch]$Editor)
$ErrorActionPreference = 'Stop'
$localEngine = Join-Path $PSScriptRoot 'build\tools\Godot_v4.7.2-stable_win64.exe'
if (Test-Path -LiteralPath $localEngine) {
    $engine = $localEngine
} else {
    $installedEngine = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $installedEngine) {
        throw 'Install Godot 4 and import project.godot, or add godot to PATH.'
    }
    $engine = $installedEngine.Source
}
$engineArguments = @('--path', $PSScriptRoot)
if ($Editor) { $engineArguments += '--editor' }
& $engine @engineArguments

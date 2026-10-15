$ErrorActionPreference = 'Stop'
$baseCommit = '7818b33172086d0576456a3acf04e1548ddbed74'
$sourceDir = Join-Path $PSScriptRoot 'upstream'
$patchFile = Join-Path $PSScriptRoot 'celeritas-ltbridge2.patch'

function Invoke-GitChecked {
    param([string[]]$GitArguments)
    & git @GitArguments
    if ($LASTEXITCODE -ne 0) { throw 'Git operation failed; existing source files were left for inspection.' }
}

if (!(Test-Path -LiteralPath $sourceDir)) {
    Invoke-GitChecked -GitArguments @('clone', '--no-checkout', '--filter=blob:none', 'https://git.taumc.org/embeddedt/celeritas.git', $sourceDir)
    Invoke-GitChecked -GitArguments @('-C', $sourceDir, 'fetch', '--depth', '1', 'origin', $baseCommit)
    Invoke-GitChecked -GitArguments @('-C', $sourceDir, 'checkout', '--detach', $baseCommit)
}
if (!(Test-Path -LiteralPath (Join-Path $sourceDir '.git'))) { throw 'The upstream directory is not a Git checkout.' }
$head = (& git -C $sourceDir rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $head -ne $baseCommit) { throw 'The upstream checkout is not at the pinned commit. Inspect it before continuing.' }

& git -C $sourceDir apply --check $patchFile 2>$null
if ($LASTEXITCODE -eq 0) {
    Invoke-GitChecked -GitArguments @('-C', $sourceDir, 'apply', $patchFile)
} else {
    & git -C $sourceDir apply --reverse --check $patchFile 2>$null
    if ($LASTEXITCODE -ne 0) { throw 'The patch neither applies cleanly nor appears already applied. Inspect upstream; no reset was performed.' }
}

Push-Location $sourceDir
try {
    & .\gradlew.bat '-Pceleritas_target_versions=1.12.2' packageJar --no-daemon
    if ($LASTEXITCODE -ne 0) { throw 'Celeritas build failed.' }
} finally {
    Pop-Location
}
$jars = @(Get-ChildItem -LiteralPath (Join-Path $sourceDir 'build\libs') -Recurse -Filter 'celeritas-forge-mc12.2-*.jar')
if ($jars.Count -ne 1) { throw 'Expected one packaged 1.12.2 JAR; inspect upstream/build/libs.' }
$dist = Join-Path $PSScriptRoot 'dist'
New-Item -ItemType Directory -Path $dist -Force | Out-Null
$output = Join-Path $dist 'celeritas-forge-mc12.2-2.5.0-dev-ltbridge2-experimental.jar'
Copy-Item -LiteralPath $jars[0].FullName -Destination $output -Force
Write-Output "Built: $output"
Write-Output 'Experimental build; see QC.md before installing. No Minecraft instance was modified.'

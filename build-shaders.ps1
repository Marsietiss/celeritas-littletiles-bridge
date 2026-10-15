[CmdletBinding()]
param(
    [string] $JavaHome = $env:JAVA_HOME,
    [string] $BuildDirectory = (Join-Path $PSScriptRoot 'build/demonica'),
    [string] $OutputDirectory = (Join-Path $PSScriptRoot 'dist/shaders'),
    [ValidateRange(6, 16)] [int] $HeapGiB = 10
)

$ErrorActionPreference = 'Stop'
$BuildDirectory = [IO.Path]::GetFullPath($BuildDirectory)
$OutputDirectory = [IO.Path]::GetFullPath($OutputDirectory)
$baseCommit = '705f596e7800d3dca20a61dd74753d7586beabc1'
$patchPath = Join-Path $PSScriptRoot 'demonica-0.7.3-dh3.3.3.patch'
$artifactName = 'Demonica-0.7.3-dh333-ltfix.jar'

function Invoke-Checked {
    param([string] $Executable, [string[]] $Arguments)
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $Executable"
    }
}

if (-not $JavaHome) {
    throw 'Set JAVA_HOME to a JDK 25 installation, or pass -JavaHome.'
}
$javaPath = Join-Path $JavaHome 'bin/java.exe'
if (-not (Test-Path -LiteralPath $javaPath)) {
    $javaPath = Join-Path $JavaHome 'bin/java'
}
if (-not (Test-Path -LiteralPath $javaPath)) {
    throw 'The selected JavaHome does not contain bin/java.'
}
$javaVersion = (& $javaPath --version 2>&1 | Out-String)
if ($LASTEXITCODE -ne 0 -or $javaVersion -notmatch '(?m)^(openjdk|java) 25(?:[.\s])') {
    throw 'This build requires JDK 25.'
}
if (-not (Test-Path -LiteralPath $patchPath)) {
    throw "Missing source patch: $patchPath"
}

if (Test-Path -LiteralPath $BuildDirectory) {
    throw 'BuildDirectory already exists. Pass a new empty path to preserve and avoid modifying the existing checkout.'
}
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $BuildDirectory) | Out-Null
Invoke-Checked git @('clone', '--depth', '1', '--branch', 'v0.7.3', '--single-branch',
    'https://github.com/ndellagrotte/Demonica.git', $BuildDirectory)
$actualCommit = (& git -C $BuildDirectory rev-parse HEAD | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $actualCommit -ne $baseCommit) {
    throw "Unexpected upstream commit: $actualCommit"
}
Invoke-Checked git @('-C', $BuildDirectory, 'apply', '--check', $patchPath)
Invoke-Checked git @('-C', $BuildDirectory, 'apply', $patchPath)

# Upstream asks for the latest S8TNLib release. Pin the same library used for the validated build.
$libraryDirectory = Join-Path $BuildDirectory 'build/local-s8tnlib'
New-Item -ItemType Directory -Force -Path $libraryDirectory | Out-Null
$libraries = @{
    's8tnlib-0.3.0.jar' = 'ba70862c038c887adc3827e45398a8dc870b5879be71f7aa2840fb9a74aca146'
    's8tnlib-0.3.0-sources.jar' = 'bfa466abdb19f6e5012ee4374218ae24d3b6ac3fb3c3b1e6cf9a08ba97db4297'
}
foreach ($name in $libraries.Keys) {
    $path = Join-Path $libraryDirectory $name
    Invoke-WebRequest -Uri "https://github.com/ndellagrotte/S8TNLib/releases/download/v0.3.0/$name" -OutFile $path
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $libraries[$name]) {
        throw "S8TNLib checksum mismatch: $name"
    }
}

$previousJavaHome = $env:JAVA_HOME
try {
    $env:JAVA_HOME = $JavaHome
    Push-Location $BuildDirectory
    try {
        $gradle = if ($env:OS -eq 'Windows_NT') { '.\gradlew.bat' } else { './gradlew' }
        Invoke-Checked $gradle @('remapJar', 'test', 'verifyCeleritasPin', 'verifyDistributedJar',
            '--no-daemon', "-Dorg.gradle.jvmargs=-Xmx${HeapGiB}G -XX:+UseG1GC",
            "-Ps8tnlibDir=$libraryDirectory", '-Ps8tnlibVersion=0.3.0')
    } finally {
        Pop-Location
    }
} finally {
    $env:JAVA_HOME = $previousJavaHome
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$artifactPath = Join-Path $BuildDirectory 'build/libs/Demonica-0.7.3.jar'
$outputPath = Join-Path $OutputDirectory $artifactName
Copy-Item -LiteralPath $artifactPath -Destination $outputPath
$sha256 = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText((Join-Path $OutputDirectory 'SHA256SUMS'), "$sha256  $artifactName`n")
Write-Host "Built $outputPath"
Write-Host "SHA-256: $sha256"
Write-Host 'Install only beside the exact Celeritas build recorded in demonica-local-build.md, on Cleanroom 0.6.12 or 0.6.13.'

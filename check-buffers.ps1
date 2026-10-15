$ErrorActionPreference = 'Stop'
$helper = Join-Path $PSScriptRoot 'upstream\forge122\src\main\java\org\taumc\celeritas\impl\compat\littletiles\LittleTilesBufferCopy.java'
if (!(Test-Path -LiteralPath $helper)) { throw 'Prepare the patched source with build.ps1 first.' }
$classes = Join-Path $PSScriptRoot 'build\buffer-checks'
New-Item -ItemType Directory -Path $classes -Force | Out-Null
$javac = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin\javac.exe' } else { 'javac' }
$java = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin\java.exe' } else { 'java' }
& $javac --release 8 -d $classes $helper (Join-Path $PSScriptRoot 'LittleTilesBufferCopyCheck.java')
if ($LASTEXITCODE -ne 0) { throw 'Buffer check compilation failed.' }
& $java -cp $classes LittleTilesBufferCopyCheck
if ($LASTEXITCODE -ne 0) { throw 'Buffer checks failed.' }

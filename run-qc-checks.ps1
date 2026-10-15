param(
    [string]$CeleritasSourceRoot = (Join-Path $PSScriptRoot 'upstream'),
    [string]$LittleTilesSourceRoot = (Join-Path $PSScriptRoot 'littletiles-source')
)
$ErrorActionPreference = 'Stop'
$scratch = Join-Path $PSScriptRoot 'build'
$stubs = Join-Path $scratch 'stubs'
$classes = Join-Path $scratch 'classes'
New-Item -ItemType Directory -Path $stubs,$classes -Force | Out-Null
$sources = @{
    'com/creativemd/creativecore/client/rendering/RenderBox.java' = 'package com.creativemd.creativecore.client.rendering; public class RenderBox { public int countQuads(){ return 1; } }'
    'com/creativemd/creativecore/client/rendering/model/BufferBuilderUtils.java' = 'package com.creativemd.creativecore.client.rendering.model; import net.minecraft.client.renderer.BufferBuilder; public class BufferBuilderUtils { public static int getBufferSizeByte(BufferBuilder b){ return b.getVertexCount()*28; } }'
    'net/minecraft/client/renderer/BufferBuilder.java' = 'package net.minecraft.client.renderer; import java.nio.ByteBuffer; public class BufferBuilder { public BufferBuilder(int n) {} public ByteBuffer getByteBuffer(){ return null; } public int getVertexCount(){ return 0; } }'
    'net/minecraft/client/renderer/vertex/VertexFormat.java' = 'package net.minecraft.client.renderer.vertex; public class VertexFormat { public int getNextOffset(){ return 28; } }'
    'net/minecraft/util/BlockRenderLayer.java' = 'package net.minecraft.util; public enum BlockRenderLayer { SOLID, CUTOUT_MIPPED, CUTOUT, TRANSLUCENT }'
    'net/minecraftforge/fml/relauncher/Side.java' = 'package net.minecraftforge.fml.relauncher; public enum Side { CLIENT, SERVER }'
    'net/minecraftforge/fml/relauncher/SideOnly.java' = 'package net.minecraftforge.fml.relauncher; public @interface SideOnly { Side value(); }'
}
foreach ($entry in $sources.GetEnumerator()) {
    $path = Join-Path $stubs $entry.Key
    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    [System.IO.File]::WriteAllText($path, $entry.Value)
}
$dependencyRoot = Join-Path $env:USERPROFILE '.gradle/caches/modules-2/files-2.1'
$asm = Get-ChildItem -LiteralPath (Join-Path $dependencyRoot 'org.ow2.asm/asm') -Recurse -Filter 'asm-*.jar' | Sort-Object FullName | Select-Object -Last 1
$asmTree = Get-ChildItem -LiteralPath (Join-Path $dependencyRoot 'org.ow2.asm/asm-tree') -Recurse -Filter 'asm-tree-*.jar' | Sort-Object FullName | Select-Object -Last 1
$mixin = Get-ChildItem -LiteralPath (Join-Path $dependencyRoot 'org.spongepowered/mixin') -Recurse -Filter 'mixin-*.jar' | Where-Object { $_.Name -notmatch 'processor' } | Select-Object -First 1
if (!$asm -or !$asmTree -or !$mixin) { throw 'Build Celeritas first to populate ASM/Mixin dependencies.' }
$classpath = @($asm.FullName,$asmTree.FullName,$mixin.FullName) -join [IO.Path]::PathSeparator
$javaSources = @(Get-ChildItem -LiteralPath $stubs -Recurse -Filter '*.java' | ForEach-Object FullName)
$ltCache = Join-Path $LittleTilesSourceRoot 'src/main/java/com/creativemd/littletiles/client/render/cache'
$javaSources += @('IRenderDataCache.java','BufferLink.java','LayeredRenderBufferCache.java') | ForEach-Object { Join-Path $ltCache $_ }
$bridge = Join-Path $CeleritasSourceRoot 'forge122/src/main/java/org/taumc/celeritas/impl'
$javaSources += @(
    (Join-Path $bridge 'compat/littletiles/LittleTilesBufferCopy.java'),
    (Join-Path $bridge 'compat/littletiles/LittleTilesMixinPlugin.java'),
    (Join-Path $bridge 'render/terrain/compile/QuadVertexAlpha.java'),
    (Join-Path $PSScriptRoot 'BridgeQcCheck.java')
)
$javac = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin/javac.exe' } else { 'javac' }
$java = if ($env:JAVA_HOME) { Join-Path $env:JAVA_HOME 'bin/java.exe' } else { 'java' }
& $javac --release 8 -proc:none -cp $classpath -d $classes @javaSources
if ($LASTEXITCODE -ne 0) { throw 'Regression compilation failed.' }
& $java -cp ($classes + [IO.Path]::PathSeparator + $classpath) BridgeQcCheck (Join-Path $classes 'com/creativemd/littletiles/client/render/cache/LayeredRenderBufferCache.class')
if ($LASTEXITCODE -ne 0) { throw 'Regression checks failed.' }

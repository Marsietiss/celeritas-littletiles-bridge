# Celeritas LittleTiles bridge

Experimental LittleTiles 1.12.2 rendering support for a pinned Celeritas 2.5.0-dev build.

This is a **source patch to Celeritas**, not a standalone addon. It connects LittleTiles' cached geometry and asynchronous rebuild notifications to Celeritas' replacement chunk renderer. The working prototype has been tested in gameplay with Supersymmetry 0.2.0, Cleanroom 0.6.13-alpha, LittleTiles 1.5.87 and CreativeCore 1.10.71.

## Status

Basic LittleTiles rendering works in the tested installation. Compilation, buffer-copy checks and API/remapping checks pass. Three independent code reviews found two remaining rendering edge cases: partially transparent painted tiles and synchronization during animation transitions. See [QC.md](QC.md) for evidence, suggested fixes and validation limits. This is an experimental prototype, not a general compatibility guarantee.

The bridge preserves section-local geometry, copied vertex colors/light, ordinary translucent layers and Celeritas' animated-sprite tracking. It forwards completed LittleTiles meshes to Celeritas and cleans up compatibility resources on chunk/world unload.

## Build

Requirements: Git, a Java 25 JDK (the tested build environment), and internet access for Gradle/dependencies/toolchains. Set `JAVA_HOME` to the JDK if it is not already configured. The first build downloads dependencies; subsequent builds use the local cache.

Windows PowerShell:

```powershell
.\build.ps1
.\check-buffers.ps1
```

Linux/macOS:

```sh
bash build.sh
bash check-buffers.sh
```

The scripts fetch [upstream Celeritas](https://git.taumc.org/embeddedt/celeritas) at commit `7818b33172086d0576456a3acf04e1548ddbed74`, apply `celeritas-ltbridge1.patch`, and run the 1.12.2 `packageJar` task. Output goes into `dist/`. They do not install anything into Minecraft or start/stop the game. The Windows upstream build was verified locally. Both wrapper scripts passed parser and mocked build checks, including paths containing spaces and repeated patch application. Both buffer-check wrappers passed all 16 checks on Windows (PowerShell and Git Bash). The shell wrapper uses Bash 3.2-compatible features, but native Linux/macOS builds have not been verified.

## Install and roll back

Save and close Minecraft normally. Back up the existing Celeritas JAR, then **replace** it with the experimental build. Keep only one active Celeritas JAR. Keep the backup outside `mods/`, or with an extension the launcher will not load. Launch the pack normally.

This bridge needs a restart to load; it does not inject code into an already-running JVM. Successful initialization logs:

```text
Experimental LittleTiles mesh bridge enabled (lt-bridge-1)
```

To roll back, close Minecraft and restore the original renderer JAR. The bridge has no save-format changes.

## Test checklist

- View tiles from above/below and across section boundaries, including negative coordinates.
- Place, edit and remove a disposable structure; check immediate updates and ghost geometry.
- Test glass, **partially transparent paint on opaque stone/wood**, overlapping transparency and lighting changes.
- Open/close moving structures repeatedly while nearby chunks rebuild.
- Unload/reload the area, change dimensions, use F3+A and reload resources.

For a rendering report, include mod versions, the triggering action and a screenshot. Remove account identifiers, server addresses and authentication data from logs before sharing them.

## Credits and license

Based on Celeritas by embeddedt and its upstream contributors, licensed under LGPL-3.0; see `COPYING` and `COPYING.LESSER`. The original [Nothirium LittleTiles Patch](https://github.com/V5Minecraft/NothiriumLittleTilesPatch) was inspected as an architectural reference. This project targets Celeritas and does not include or require Nothirium. LittleTiles and CreativeCore are by CreativeMD.

The source patch and pinned upstream repository together provide the corresponding source for the experimental build. See [NOTICE.md](NOTICE.md) for provenance and artifact identity.

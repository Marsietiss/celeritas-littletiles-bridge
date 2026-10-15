# Celeritas LittleTiles bridge

Experimental LittleTiles 1.12.2 rendering support for a pinned Celeritas 2.5.0-dev build.

This is a **source patch to Celeritas**, not a standalone addon. It connects LittleTiles' cached geometry and asynchronous rebuild notifications to Celeritas' replacement chunk renderer. The first prototype was tested in gameplay with Supersymmetry 0.2.0, Cleanroom 0.6.13-alpha, LittleTiles 1.5.87 and CreativeCore 1.10.71.

There is also a separate [Demonica shader/Distant Horizons compatibility patch](demonica-local-build.md). **Choose one route:** the standalone patched renderer, or the exact stock Celeritas required by Demonica plus the patched shader addon. Demonica already provides a LittleTiles bridge; do not combine the two implementations. Its exact renderer pin intentionally rejects modified Celeritas JARs.

## Status

Basic LittleTiles rendering worked in the tested first prototype. Three independent code reviews found partially transparent paint and animation-transition synchronization issues. **ltbridge2 implements both fixes**, with 1,047 targeted regression checks plus 16 buffer-copy checks passing. Full in-game regression coverage of ltbridge2 remains pending. See [QC.md](QC.md). This is an experimental prototype, not a general compatibility guarantee.

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

The scripts fetch [upstream Celeritas](https://git.taumc.org/embeddedt/celeritas) at commit `7818b33172086d0576456a3acf04e1548ddbed74`, apply `celeritas-ltbridge2.patch`, and run the 1.12.2 `packageJar` task. Output goes into `dist/`. They do not install anything into Minecraft or start/stop the game. The Windows upstream build was verified locally. Both wrapper scripts passed parser and mocked build checks, including paths containing spaces and repeated patch application. Both buffer-check wrappers passed all 16 checks on Windows (PowerShell and Git Bash). The shell wrapper uses Bash 3.2-compatible features, but native Linux/macOS builds have not been verified.

The default build now uses `celeritas-ltbridge2.patch`; the first patch is retained for provenance. `BridgeQcCheck.java` and `run-qc-checks.ps1` provide the broader offline regressions. The runner expects patched Celeritas in `upstream/`, CreativeMD/LittleTiles source in `littletiles-source/`, and ASM/Mixin dependencies from the build cache. Tested LittleTiles source: `286a79735bd512629467898d3b67a723a7c0def5` (branch `1.12`).

For the separate shader route, use `build-shaders.ps1` and read [demonica-local-build.md](demonica-local-build.md). It retains Cleanroom 0.6.13 and the exact stock renderer pin, backports DH 3.3.3 registration and includes the same cache synchronization hardening. Disable Celeritas render-pass optimization on that stock-renderer route to preserve partial-alpha tile paint. Shader-stack runtime validation is in progress.

## Install and roll back

Save and close Minecraft normally. Back up the existing Celeritas JAR, then **replace** it with the experimental build. Keep only one active Celeritas JAR. Keep the backup outside `mods/`, or with an extension the launcher will not load. Launch the pack normally.

This bridge needs a restart to load; it does not inject code into an already-running JVM. Successful initialization logs:

```text
Experimental LittleTiles mesh bridge enabled (lt-bridge-2)
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

The separate Demonica patch follows upstream AGPL-3.0; see `DEMONICA-LICENSE-AGPL-3.0.txt` and upstream third-party notices. The source patches and pinned upstream repositories together provide the corresponding source for the experimental builds. See [NOTICE.md](NOTICE.md) and [demonica-local-build.md](demonica-local-build.md) for provenance and artifact identities.

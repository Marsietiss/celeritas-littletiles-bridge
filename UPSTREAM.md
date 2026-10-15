# Local Demonica 0.7.3 compatibility build

Built 2026-10-15 from [Demonica v0.7.3](https://github.com/ndellagrotte/Demonica/tree/v0.7.3), commit `705f596e7800d3dca20a61dd74753d7586beabc1`.

Artifact: `Demonica-0.7.3-dh333-ltfix.jar` (internal mod version remains 0.7.3).
SHA-256: `7042593b9498e2f6ca55dfb496afb0e57803ae9310ba682cb96d8124a52b3a89`.

The [source patch](demonica-0.7.3-dh3.3.3.patch) contains:

- The DH provider-registration hook from [Demonica v0.8.1](https://github.com/ndellagrotte/Demonica/blob/v0.8.1/src/main/java/com/demonica/mixin/mod/distanthorizons/MixinAbstractModInitializer.java). DH 3.3.3 renamed its entry point, so the original 0.7.3 hook no longer applied. The new hook targets the shared initializer and prevents duplicate Iris accessor registration.
- The upstream v0.8.1 build dependency fix selecting CodeChickenLib 3.3.8's published `dev` classifier after its POM changed on 2026-10-15.
- Local LittleTiles cache synchronization hardening: complete its existing cache-monitor protocol; duplicate source cursors during transition-cache combination; hold manager then cache monitors during vertex copying.
- Four regression tests covering DH registration and the actual LittleTiles cache class's synchronized method flags.

Cleanroom 0.6.12/0.6.13 support and the exact Celeritas pin remain unchanged. No Cleanroom 0.7 code was backported. Celeritas stays an unmodified upstream JAR.

## Validation

JDK: Eclipse Temurin 25.0.4.1. Gradle 9.7.1.

`build.ps1` fetches the exact v0.7.3 base commit, applies the combined patch
and runs the production build and checks. It pins the embedded S8TNLib dependency
to the same v0.3.0 release used here, verifying its JAR/source hashes. It writes
only below the requested build/output folders and refuses an existing checkout.
Set `JAVA_HOME` to JDK 25, then run `./build.ps1`; `-HeapGiB` controls its
build-only G1 heap (default 10). The script syntax was checked; the matching Gradle
tasks were run directly in the local checkout rather than cloning a second copy.

```text
gradlew.bat remapJar test verifyCeleritasPin verifyDistributedJar --no-daemon "-Dorg.gradle.jvmargs=-Xmx10G -XX:+UseG1GC"
BUILD SUCCESSFUL in 33s
22 actionable tasks: 14 executed, 8 up-to-date
```

Root test suite: 1,164 tests, zero failures, zero errors, six upstream conditional skips. All four new regression tests passed. The skips belong to TransformCorpusTest (2), GlslCorpusParseSurveyTest (1) and IncludeGraphCaseHintTest (3).

The optional diagnostics JAR was not rebuilt: the first full build exhausted its six-gigabyte Gradle heap while remapping that separate artifact. The production JAR, root test suite and production/pin checks succeeded on the targeted rerun.

Initial runtime validation subsequently passed with 220 mods, DH 3.3.3 and Complementary Reimagined r5.9.3 HIGH on Cleanroom 0.6.13-alpha. DH terrain/water programs compiled, LOD processing advanced, and outdoor day/night/rain and fullscreen 3440 × 1440 rendered successfully. Nearby basic LittleTiles geometry was visible. See [VALIDATION.md](VALIDATION.md) for the exact test scope and remaining limits; no controlled FPS benchmark was performed.

The tested configuration keeps Celeritas `performance.use_render_pass_optimization=false`. Smooth Font requires `runMode=1` in this installation to avoid black menu text with shaders.

The packaged Celeritas pin still accepts only upstream commit `9b661b70ecaf84c39052e8fbc51c875ba37e739d`, with original Maven/release SHA-256 values. Demonica's distribution retains its upstream AGPL-3.0 license and third-party notices.

## Distant Horizons

Use the official [DH 3.3.3 for Minecraft 1.12.2](https://modrinth.com/mod/distanthorizons/version/1PczaQGZ), not the archived VintageHorizons project. Verified artifact SHA-1: `ffe0a2b83c9b1870fa48b8c5295bb3688fe2a9be`.

Its compiled metadata requires MixinBooter 11.8 or newer (Cleanroom's bundled implementation may satisfy this). Its config-file version is `_version = 5`, verified from the release bytecode. DH shader integration also requires a shader pack containing the corresponding DH programs. No separate Iris, Actinium, OptiFine or S8TNLib JAR belongs beside this Demonica build.


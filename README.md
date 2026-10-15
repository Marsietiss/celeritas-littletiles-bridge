# LittleTiles + shaders + Distant Horizons

A tested Minecraft 1.12.2 setup for Supersymmetry on **Cleanroom 0.6.13-alpha**. This repository maintains one compatibility patch to Demonica 0.7.3, used with its exact stock Celeritas build and Distant Horizons 3.3.3.

## Download and install

**[Download the release](https://github.com/Marsietiss/celeritas-littletiles-bridge/releases)** and choose **LittleTiles-Shaders-DH.zip**. No compilation is needed. The ZIP contains the three tested JARs, installation notes, license texts and patch source. The individual JAR assets are the same files for manual installation.

1. Save and close Minecraft. Back up the current renderer mods.
2. Replace active Celeritas, Demonica and Distant Horizons JARs with the three release JARs. Keep the modpack's existing LittleTiles/CreativeCore and other dependencies.
3. Set `performance.use_render_pass_optimization` to `false` in `config/embeddium-options.json` for partially transparent LittleTiles paint.
4. If SmoothFont is installed, set `I:runMode=1` under `common` in `config/smoothfont/smoothfont.cfg`. Its font rendering otherwise produces black menu text in the tested setup.
5. Put a compatible shader pack in `shaderpacks/` and select it in the shader settings. **Complementary Reimagined r5.9.3, HIGH preset** was tested; shader packs are downloaded separately.

Use exactly one active Celeritas JAR. This setup uses Demonica's LittleTiles integration; the old standalone `ltbridge1` / `ltbridge2` renderer builds must not be installed alongside it. The earlier prototypes remain in Git history.

## Included versions

| Component | Version |
| --- | --- |
| Celeritas | Stock 2.5.0-dev, pinned commit `9b661b70ecaf84c39052e8fbc51c875ba37e739d` |
| Demonica | Local `0.7.3-dh333-ltfix` build; internal mod version remains 0.7.3 |
| Distant Horizons | Official 3.3.3 for Forge 1.12.2 |
| Loader tested | Cleanroom 0.6.13-alpha |

The patch backports DH 3.3.3 registration, hardens LittleTiles mesh-cache synchronization and fixes the upstream build dependency selection. Celeritas itself remains unmodified. See [UPSTREAM.md](UPSTREAM.md) for exact source commits, hashes and attribution.

## Validation

The production build and 1,164-test suite passed with six upstream conditional skips. Runtime checks covered 220 loaded mods, basic LittleTiles geometry, shader compilation, active DH LOD processing, outdoor day/night/rain and 3440x1440 fullscreen. This is an **experimental release**: animated structures, painted transparency and long-session stability were not exhaustively tested. See [VALIDATION.md](VALIDATION.md) for observations and remaining warnings.

## Build from source

Only needed for development. Requirements: Git, JDK 25, internet access and enough RAM for the default 10 GiB build heap.

```powershell
$env:JAVA_HOME = 'C:\path\to\jdk-25'
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

The execution-policy override applies only to that PowerShell process. The script clones the pinned upstream source into a new `build/demonica` directory, applies the single patch, verifies dependencies, runs the production build/tests and writes the JAR plus checksum to `dist/`. It does not change Minecraft instances. It refuses an existing checkout; pass a new `-BuildDirectory` for another build.

## License and credits

The Demonica patch follows upstream **AGPL-3.0**; see [LICENSE](LICENSE). Demonica is by ndellagrotte and upstream contributors, Celeritas by embeddedt and contributors, Distant Horizons by its team, and LittleTiles/CreativeCore by CreativeMD. The redistributed stock Celeritas and DH retain their upstream licenses; license texts accompany the binary bundle. This is an unofficial compatibility build.

# Provenance

- Upstream: https://git.taumc.org/embeddedt/celeritas
- Base commit: `7818b33172086d0576456a3acf04e1548ddbed74`
- Patch identifier: `lt-bridge-1`
- Target: Minecraft Forge/Cleanroom 1.12.2
- Celeritas base version: `2.5.0-dev`
- Local prototype prepared and reviewed: 15 October 2026
- License of Celeritas and this patch: LGPL-3.0, with the GPL-3.0 text incorporated as described in `COPYING.LESSER`

The patch is a local modification to Celeritas. It adds two LittleTiles mixins, a mesh-cache bridge and buffer-copy helper, registers the bridge and routes LittleTiles geometry through the existing chunk builder. It is not an official Celeritas or LittleTiles release.

The reviewed prototype binary is named `celeritas-forge-mc12.2-2.5.0-dev-ltbridge1-experimental.jar` and has SHA-256:

`29BACAD420D959979CA5FC624B4A2617E7D7B99A99D7B05D32D7B45A48392337`

Gradle/JAR metadata can make independently rebuilt archives differ byte-for-byte. The hash identifies the tested local artifact, not a reproducible-build guarantee. No Minecraft world, account configuration, game logs or local installation paths are included in this repository.

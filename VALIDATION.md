# Shader stack runtime validation — 15 October 2026

Tested Supersymmetry 0.2.0 on Cleanroom 0.6.13-alpha with the following shader route:

- Unmodified Celeritas commit `9b661b70ecaf84c39052e8fbc51c875ba37e739d`, matching Demonica's exact pin.
- Local Demonica 0.7.3 build `Demonica-0.7.3-dh333-ltfix.jar`, SHA-256 `7042593b9498e2f6ca55dfb496afb0e57803ae9310ba682cb96d8124a52b3a89`.
- Official Distant Horizons 3.3.3 for Minecraft 1.12.2.
- Complementary Reimagined r5.9.3, **HIGH** preset.

This route uses Demonica's LittleTiles integration. The standalone patched Celeritas bridge was not loaded alongside it.

## Observed results

- All **220 mods** loaded. The DH Iris accessor bound successfully, DH terrain/water shader programs compiled, and shader loading completed in approximately seven seconds.
- Outdoor night, day and rain rendered successfully. Fullscreen at **3440 × 1440** rendered cleanly after resizing settled. A local in-game F2 screenshot was captured; private-world screenshots are excluded from this source repository.
- DH reported overworld rendering enabled. Its import/build counters advanced and its SQLite data grew to approximately 18 MB. This establishes active LOD processing; distant-terrain coverage was not exhaustively inspected.
- Nearby basic LittleTiles geometry was visible. Animated transitions, partially transparent paint and dimension changes were not exhaustively tested.
- Process memory was approximately **9 GiB** during observation, without the earlier uncontrolled native-memory growth. No controlled FPS benchmark was performed.

## Required local settings and remaining warnings

`performance.use_render_pass_optimization=false` was retained for partial-alpha tile paint on the stock Celeritas route. Smooth Font `runMode=1` corrected black menu text; changing brightness alone did not fix it.

Observed nonfatal warnings included one initial-frame opaque/translucent mismatch, a DH container base-color fallback, and an unknown `BIOME_SULFUR_CAVES` shader identifier. No corresponding persistent rendering failure was observed in the checks above.

All world-changing validation, including time commands and spectator movement, was performed in a disposable world copy. The original save was not modified by those tests. These observations do not establish long-session stability or complete modpack compatibility.


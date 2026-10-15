# LittleTiles bridge QC — 15 October 2026

Three independent agents reviewed rendering/geometry, threading/resources, and loader/mod compatibility. The primary agent checked the two reported issues against the source and verified that the installed experimental JAR matches the reviewed build (`29BACAD420D959979CA5FC624B4A2617E7D7B99A99D7B05D32D7B45A48392337`).

## Resolution status

Both findings below apply to the first prototype. The standalone `ltbridge2` patch now preserves vertex alpha and synchronizes the cache protocol, with 1,047 targeted regression checks and 16 buffer-copy checks passing. Full in-game regression coverage of this revision remains pending. The separate Demonica route uses the same cache hardening and disables stock Celeritas render-pass optimization as the transparency workaround.

## Findings in ltbridge1

### P2 — Translucent paint can be sent to the opaque render pass

Location: `upstream/forge122/src/main/java/org/taumc/celeritas/impl/render/terrain/compile/VintageChunkBuildContext.java:109`, reached through `ChunkBuilderMeshingTask.java:126`.

The fallback converter selects a material from the texture's alpha classification, ignoring the quad's vertex-color alpha. LittleTiles explicitly puts partially transparent painted stone/wood into the translucent layer (`LittleTileColored.java:90–94`), but an opaque stone texture causes `selectMaterial` to downgrade its mesh to the solid pass. Render-pass optimization is enabled in this instance. Ordinary glass does not exercise this case because the texture itself carries transparency.

Expected symptom: a LittleTile painted at partial opacity becomes opaque or loses correct transparency sorting. Source-confirmed path; not reproduced in the running world during this review.

Recommended correction: preserve the original material when any vertex has alpha below 255. Celeritas's ordinary fast model path already checks this through `ModelQuadFlags`; the fallback converter needs the equivalent protection. Add a regression for an opaque sprite with partial vertex alpha.

### P2 — Animation transition cache changes can race with mesh reads

Location: `upstream/forge122/src/main/java/org/taumc/celeritas/impl/compat/littletiles/LittleTilesCompat.java:87`.

`append()` runs on a Celeritas worker and locks the tile's render manager, which protects normal LittleTiles mesh publication. The transition path uses different synchronization: `LittleAnimationDestroyPacket.remove()` invokes `LayeredRenderBufferCache.additional()` under the cache's lock, while `TileEntityRenderManager.afterClientReceivesUpdate()` clears `additional` without the manager lock. `get()` tests `additional` and later reads it again. A packet may clear it between those operations; `combine()` can also mutate shared source-buffer cursors concurrently with a worker read.

Expected symptom: an animation/door transition can intermittently omit a layer until another rebuild. The reflected exception is caught by the bridge, so this particular failure path skips geometry rather than crashing. Source-confirmed synchronization gap; no live reproduction attempted.

Recommended correction: make transition mutations and mesh snapshots share synchronization, or publish immutable snapshots. Adding a cache lock only around the bridge read is insufficient while `afterUpdate()` remains unsynchronized. Add a transition/read concurrency regression.

## Checks that passed

- LittleTiles 1.5.87 method/field compatibility and SRG-remapped `RenderChunk` overrides.
- Compatibility with the existing Supersymmetry `canRenderInLayer` mask hook.
- Section-local coordinates, including negative positions; regular cached lighting and transparent geometry conversion.
- Animated-sprite tracking and the normal Celeritas translucent sorting path.
- Main-thread GL allocation/deletion, chunk/world cleanup and world-identity filtering of stale callbacks.
- LittleTiles' existing renderer-reload hook and the separate oriented/animated-world overload remain in place.
- All 16 existing buffer-copy checks passed again.

No bridge copy/rebuild errors were found in the current game log at review time. The log does contain repeated GL 1284 stack-underflow errors, but those were observed before this bridge was installed; the review did not establish their cause.

The review was read-only; it did not change implementation, installed files or the running game. Static review and the user's successful gameplay tests do not exhaustively validate every structure or pack interaction.

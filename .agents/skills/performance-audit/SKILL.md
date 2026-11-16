---
name: performance-audit
description: >-
  Optimize Godot 4.3 region rendering and frame pacing using RegionBase static
  ground chunk baking, single-quad water batching, camera frustum culling,
  texture-flipped sprites, and light frustum culling.
---

# Performance Audit Skill

Verify every `RegionBase` scene and draw helper obeys all frame-budget rules:

1. **Bake Static Ground Once:** Use `RegionBase.setup_static_ground_chunks(...)` (`720x720`, `transparent_bg = false` for opaque terrain). Never call `draw_grass_zone`, `draw_varied_tiled_rect`, `draw_dirt_trail_network`, or static scatter loops inside per-frame `_draw()`.
2. **Batched Water Channels:** Use `RegionBase.setup_water_layer(...)` + call `step_water_layer()` inside `step_region()` / `enter_region()` before `queue_redraw()`—never draw tiled water quads inside `_draw()`.
3. **Tight Camera Frustum Culling:** Filter dynamic buildings, props, trees, citizens, particles, and projectiles via `r.get_camera_rect(pad)` before issuing draw calls.
4. **Preserve GL Compatibility Batching:** Use `PixelAssets.get_tex_flipped(...)` inside a positive `Rect2` instead of per-sprite `draw_set_transform(...)` or negative-width `Rect2` (which offsets flipped sprites in Godot 4.3).
5. **Light Culling:** Call `sync_light_frustum(lights, enabled)` inside `update_region_lights()` so off-screen `PointLight2D`s stay disabled.

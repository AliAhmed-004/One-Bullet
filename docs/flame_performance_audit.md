# Flame Runtime Performance Audit (One-Bullet)

This audit focuses strictly on game-loop/runtime hotspots that can cause **progressive lag after 30–60s** (allocation churn + collision growth + audio fan-out), not startup-time cost.

## High-Risk Findings

### 1) Unbounded deflector growth drives collision cost over time
- `WaveManager` keeps spawning deflectors forever in wave 6 (`duration: double.infinity`, `deflectorSpawnInterval: 2.5`, `deflectorsPerSpawn: 2`).
- `OneBulletGame._onSpawnDeflectors` appends each new deflector to `_deflectors` and `world` with no active-cap or density check.
- Deflectors are only removed if hit by the bullet.

**Why this lags later, not immediately:**
- Active collider count rises continuously during long runs.
- Flame collision broadphase/narrowphase workload rises with active hitboxes, so per-frame collision work increases with time.
- This pattern aligns with rising `CollisionProspect` counts in snapshots.

**Relevant lines**
- `lib/components/wave_manager.dart`: wave 6 infinite spawning setup and spawn loop in `update`/`_updateDeflectorSpawning`.
- `lib/one_bullet_game.dart`: `_onSpawnDeflectors` blindly adds all spawned deflectors.

---

### 2) Per-bounce audio player creation can accumulate under high bounce frequency
- Every bounce calls `SoundService.playBulletBounce()`.
- `playBulletBounce()` creates a new `AudioPlayer` via `FlameAudio.play(...)`, stores it in `_activePlayers`, and wires a completion listener.

**Why this lags later, not immediately:**
- Early game has fewer bounces/contacts; later waves increase speed + deflector density.
- Bounce rate rises, causing many short-lived `AudioPlayer` allocations + async completion callbacks.
- If completion events lag under load, `_activePlayers` can temporarily swell, increasing work in `pauseAll()/resumeAll()/stopAll()` and GC pressure.
- This matches the observed growth in `AudioPlayer` instances.

**Relevant lines**
- `lib/components/bullet.dart`: wall bounce path triggers sound each bounce.
- `lib/services/sound_service.dart`: per-event player allocation/listener pattern for each SFX method.

---

### 3) Frame-loop vector allocation in hot paths (movement/collision helper math)
- `Bullet.update()` uses `position += _velocity * dt;` (new temporary vector each frame).
- Deflector reflection computes several temporary vectors (`-surfaceNormal`, `normal * scalar`, `velocity - ...`).
- Deflector collision response for player creates normalized temporary direction each collision tick.
- Joystick drag updates allocate via arithmetic operators (`event.canvasEndPosition - _baseCenter`, `_baseCenter + offset`, `offset.normalized()`).

**Why this lags later, not immediately:**
- At 60 FPS, even small per-frame allocations become thousands/minute.
- As gameplay complexity grows (more contacts, more drag updates, more bounce calculations), allocation volume rises and can trigger more frequent GC pauses.
- This aligns with increasing `Vector2`/`NotifyingVector2` instance counts.

**Relevant lines**
- `lib/components/bullet.dart`: per-frame movement and reflection/bias math.
- `lib/components/deflector.dart`: reflection/push math in collision handlers.
- `lib/components/mobile_joystick.dart`: drag update vector math.

---

### 4) Avoidable object creation in render/update loops
- `AimIndicator.render()` creates `Paint` + `Path` every frame.
- `AimIndicator.update()` builds a new `Vector2` each frame for orbit position.
- `ArenaBoundary.render()` creates multiple `Paint`/`RRect` objects each frame.

**Why this lags later, not immediately:**
- Per-frame UI/component allocations are usually tolerable at low pressure.
- Under sustained gameplay (collisions/audio/physics all rising), these extra allocations contribute to heap churn and GC contention, worsening frame pacing.

**Relevant lines**
- `lib/components/aim_indicator.dart`: dynamic `Paint`/`Path` in `render`, temporary vector in `update`.
- `lib/components/arena_boundary.dart`: new paints in `render` and `_drawCornerAccents`.

---

### 5) Async haptics check on bounce path
- `_handleWallBounce()` triggers `_triggerHaptics()` on every bounce.
- `_triggerHaptics()` is async and invokes vibration calls on hot events.

**Why this lags later, not immediately:**
- Higher wave speed + deflector density = higher bounce frequency.
- Frequent async scheduling/device I/O calls can add jitter and increase event-loop pressure.
- Combined with audio callbacks, this can show up as delayed haptics/audio and frame variance.

**Relevant lines**
- `lib/components/bullet.dart`: bounce path and async haptics.

---

## Optimization Plan (targeted to this codebase)

### A) Cap active deflectors (highest impact)
1. Add a hard cap (e.g., 12–20) before spawning in `_onSpawnDeflectors`.
2. Optionally despawn oldest/farthest deflector when cap reached.
3. In wave 6, adapt spawn rate by current active count.

**Expected effect:** stabilizes collision workload and `CollisionProspect` growth.

### B) Replace per-play `AudioPlayer` with pooled SFX playback
1. Use `AudioPool` for bounce/deflector break/fire/death short SFX.
2. Keep a dedicated single player only for longer warning tone if needed.
3. Remove `_activePlayers` growth path for transient SFX.

**Expected effect:** fewer `AudioPlayer` allocations, lower callback/list churn, tighter audio latency.

### C) Remove hot-path `Vector2` temporaries
1. Replace `position += _velocity * dt` with direct scalar writes:
   - `position.x += _velocity.x * dt;`
   - `position.y += _velocity.y * dt;`
2. Reuse scratch vectors for reflection/joystick math (`setValues`, `setFrom`, `addScaled`).
3. Avoid `normalized()` in tight paths; normalize mutable vectors in place when safe.

**Expected effect:** lower `Vector2` churn and GC pressure.

### D) Cache render resources everywhere hot
1. In `AimIndicator`, cache `Paint`, border `Paint`, and triangle `Path` in `onLoad`.
2. In `ArenaBoundary`, cache paints and possibly corner geometry.
3. Continue the same pattern already used successfully in fragment components.

**Expected effect:** less per-frame allocation noise, smoother frame pacing under load.

### E) Throttle bounce-side effects
1. Rate-limit bounce SFX/haptics to one event per X ms (e.g., 35–60 ms).
2. Skip haptic trigger if one is already in-flight or if last vibration was too recent.

**Expected effect:** reduces event storming in fast late waves.

### F) Lifecycle hygiene checks
1. Ensure deflectors are removed from `_deflectors` whenever destroyed.
2. Verify no retained listeners/players after restart/return-to-menu.
3. Track active counts (`deflectors`, `hitboxes`, `_activePlayers`) in an on-screen debug overlay during soak tests.

---

## Why this likely surfaces after 30–60 seconds
- **Time-dependent growth vectors** in this project:
  1. Infinite deflector spawning in late waves.
  2. Rising collision contacts as arena complexity increases.
  3. Per-bounce audio/haptics fan-out.
  4. Constant frame-level temporary allocations.
- None of these require a classic memory leak to hurt performance; together they increase allocation rate, callback pressure, and collision work until frame budget is exceeded.

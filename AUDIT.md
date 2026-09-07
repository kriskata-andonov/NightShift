# NightShift — Full Codebase Audit

> **Date:** 2026-09-08  
> **Scope:** Every `.gd` script and `.tscn` scene file in the project  
> **Verdict:** The foundation is solid. The architecture is clean and modular. There are no show-stopping bugs remaining, but there are several patterns that will cause pain at scale (especially once the Monster AI and real maps arrive). This document catalogs every issue found, ranked by severity, and explains exactly how to fix each one.

---

## Table of Contents

- [Critical Issues (Fix Before Phase 3)](#critical-issues)
- [Medium Issues (Fix Soon)](#medium-issues)
- [Minor Issues / Code Smell](#minor-issues)
- [Architecture Recommendations](#architecture-recommendations)
- [File-by-File Notes](#file-by-file-notes)

---

## Critical Issues

### 1. `PlayerInventory._process()` polls every frame unnecessarily

**File:** [PlayerInventory.gd](file:///d:/Development/NightShift/scripts/player/PlayerInventory.gd#L17-L21)

**Problem:** The `_process()` function runs 60 times per second on every client, for every player, just to check if `character_class` changed. This was added as a band-aid fix for a race condition but is wasteful and fragile.

**Better approach:** Remove the `_process()` polling entirely. Instead, call `initialize()` from `TestChamber.gd` **after** spawning the player and setting `character_class`. This guarantees the class is set before the inventory reads it.

```gdscript
# In TestChamber.gd, after add_child(p):
var inv = p.get_node_or_null("PlayerInventory")
if inv:
    inv.initialize(pinfo.class)
```

Then remove the `_process()`, `_initialized_class`, and the redundant `initialize()` call in `PlayerMovement._ready()`.

---

### 2. Door RPC allows any client to toggle — no server authority

**File:** [InteractableDoor.gd](file:///d:/Development/NightShift/scripts/interaction/InteractableDoor.gd#L28)

**Problem:** `_rpc_toggle_door` is `"any_peer", "call_local"`. Any client can spam the door open/closed at will, and there's no server-authoritative state. Two players pressing E at the same time can desync the door state (one sees it open, the other sees it closed).

**Fix:** Make the door server-authoritative:

```gdscript
func interact(_player: Node) -> void:
    _rpc_request_toggle.rpc_id(1)  # Ask server

@rpc("any_peer", "reliable")
func _rpc_request_toggle() -> void:
    if not multiplayer.is_server():
        return
    _rpc_set_door_state.rpc(not is_open)  # Server decides

@rpc("authority", "call_local", "reliable")
func _rpc_set_door_state(open: bool) -> void:
    is_open = open
    target_rotation_y = initial_rotation_y + (open_angle if is_open else 0.0)
```

---

### 3. Dropped items have no unique network identity

**File:** [PlayerInventory.gd](file:///d:/Development/NightShift/scripts/player/PlayerInventory.gd#L107-L116)

**Problem:** `_rpc_spawn_drop` instantiates a new `PickupItem` on every client independently. These instances have no shared node name, no `MultiplayerSpawner` tracking, and no `MultiplayerSynchronizer`. This means:
- Two clients may instantiate the item at slightly different positions (floating point drift).
- If a client joins *after* an item was dropped, they will never see it.
- The dropped item's `_rpc_pickup` will fail because the node paths won't match across peers.

**Fix:** Dropped items should be spawned **only on the server** and replicated via the existing `MultiplayerSpawner`. The server should `add_child()` the pickup to the scene, and the spawner will handle replication. This requires:
1. Making `_rpc_spawn_drop` server-only (request -> server spawns).
2. Giving each dropped item a unique name (e.g., `"drop_" + str(Time.get_ticks_msec())`).

---

### 4. `PlayerHealth` has no multiplayer authority checks

**File:** [PlayerHealth.gd](file:///d:/Development/NightShift/scripts/player/PlayerHealth.gd)

**Problem:** `take_damage()`, `heal()`, `revive()`, `_enter_downed()`, `_die()` — none of these check `is_multiplayer_authority()`. The cheat codes (`dmg`, `hlt`, `down`, `dead`, `undie`) also lack authority checks. This means:
- Any client's `_process()` runs the bleedout timer locally, potentially killing the player at different times on different machines.
- The cheat codes can trigger on remote player instances.

**Fix:** Gate `_process()` and `_unhandled_input()` behind `is_multiplayer_authority()`. Damage/healing should be applied via RPCs from the server (important for Phase 3 Monster AI).

---

## Medium Issues

### 5. `Input.mouse_mode = CAPTURED` runs for ALL players

**Files:** [PlayerMovement.gd:55](file:///d:/Development/NightShift/scripts/player/PlayerMovement.gd#L55), [PlayerCamera.gd:10](file:///d:/Development/NightShift/scripts/player/PlayerCamera.gd#L10)

**Problem:** `Input.mouse_mode = Input.MOUSE_MODE_CAPTURED` is called in `_ready()` for every spawned player, including remote ones. While it doesn't crash, it's redundant code executing 4 times when it only needs to run once.

**Fix:** Move it behind the authority check:
```gdscript
if not is_multiplayer_authority():
    # ... remove UI ...
    return

Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
```

---

### 6. Cheat code buffers are duplicated across 3 scripts

**Files:**
- [PlayerModel.gd](file:///d:/Development/NightShift/scripts/player/PlayerModel.gd) — `cheat_buffer`
- [PlayerFear.gd](file:///d:/Development/NightShift/scripts/player/PlayerFear.gd) — `cheat_buffer`
- [PlayerHealth.gd](file:///d:/Development/NightShift/scripts/player/PlayerHealth.gd) — `cheat_buffer`

**Problem:** Each script independently captures keyboard input and maintains its own 20-character rolling buffer. If you type `col1fear`, all three scripts process every keystroke. This is wasteful and error-prone (cheat codes can accidentally collide).

**Fix:** Create a single `CheatCodeManager` autoload or attach it to the player root. It maintains one buffer and dispatches events:
```gdscript
# CheatCodeManager.gd (Autoload or Player child node)
signal cheat_activated(code: String)

var buffer: String = ""

func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed:
        return
    if event.unicode != 0:
        buffer += char(event.unicode).to_lower()
        if buffer.length() > 20:
            buffer = buffer.substr(buffer.length() - 20)
        for code in ["col1","col2","col3","col4","col5","cl1","cl2","cl3","cl4",
                      "fear","crazy","calm","dmg","hlt","down","dead","undie"]:
            if buffer.ends_with(code):
                cheat_activated.emit(code)
                buffer = ""
                return
```

---

### 7. `PlayerFlashlight._ready()` uses fragile parent chain

**File:** [PlayerFlashlight.gd:14](file:///d:/Development/NightShift/scripts/player/PlayerFlashlight.gd#L14)

**Problem:** `get_parent().get_parent().get_parent()` assumes the flashlight is always exactly 3 levels deep (`Camera3D > Head > Player`). If the scene hierarchy ever changes, this silently breaks.

**Fix:** Walk up the tree like other scripts do:
```gdscript
var current: Node = get_parent()
while current:
    if current is CharacterBody3D:
        _is_authority = current.is_multiplayer_authority()
        break
    current = current.get_parent()
```

---

### 8. `PlayerModel` uses raw integers instead of the enum

**File:** [PlayerModel.gd:30-37](file:///d:/Development/NightShift/scripts/player/PlayerModel.gd#L30-L37)

**Problem:** `set_class_visuals()` compares against `0`, `1`, `2`, `3` instead of `PlayerMovement.PlayerClass.ENGINEER`, etc. This is fragile — if the enum order ever changes, every comparison silently breaks.

**Fix:** Reference the enum directly:
```gdscript
if new_class == PlayerMovement.PlayerClass.ATHLETE:
    _build_athlete(body_layer)
elif new_class == PlayerMovement.PlayerClass.ENGINEER:
    _build_engineer(body_layer)
# etc.
```

---

### 9. `NetworkManager` doesn't validate player info from clients

**File:** [NetworkManager.gd:83-87](file:///d:/Development/NightShift/scripts/systems/NetworkManager.gd#L83-L87)

**Problem:** `_register_player` blindly trusts whatever dictionary a client sends. A malicious client could send `{ "name": "HACKER", "class": 999 }` and it would be stored and propagated.

**Fix:** Validate the dictionary fields:
```gdscript
@rpc("any_peer", "reliable")
func _register_player(new_player_info: Dictionary) -> void:
    var new_player_id = multiplayer.get_remote_sender_id()
    var safe_info = {
        "name": str(new_player_info.get("name", "Player")).substr(0, 20),
        "class": clampi(int(new_player_info.get("class", 1)), 0, 3)
    }
    players[new_player_id] = safe_info
    players_updated.emit()
```

---

## Minor Issues

### 10. Debug text in InventoryHUD

**File:** [InventoryHUD.gd:66](file:///d:/Development/NightShift/scripts/ui/InventoryHUD.gd#L66)

The `"[Q] Drop (Max: %d)"` debug text should be reverted to just `"[Q] Drop"` before shipping.

---

### 11. `PlayerModel._build_*` functions use compressed single-line formatting

**File:** [PlayerModel.gd:209-301](file:///d:/Development/NightShift/scripts/player/PlayerModel.gd#L209-L301)

The builder functions for Engineer, Hoarder, and Freshman cram multiple statements onto single lines with semicolons. While GDScript allows this, it makes debugging harder (breakpoints can't target individual statements) and hurts readability. The `_build_athlete()` function is properly formatted — the others should match.

---

### 12. Utility scripts left in project root

**Files:** `add_spawner.gd`, `add_sync.gd`

These one-shot tool scripts should be moved to a `tools/` directory or deleted.

---

### 13. `Interactable` extends `Node3D` but doors are `StaticBody3D`

**File:** [Interactable.gd](file:///d:/Development/NightShift/scripts/interaction/Interactable.gd)

`Interactable` extends `Node3D`, but `InteractableDoor` extends `Interactable` and is instanced as a `StaticBody3D`. This works because of Godot's script-vs-node-type system, but it's conceptually confusing. Consider making `Interactable` extend `StaticBody3D` or using a composition pattern.

---

## Architecture Recommendations

### A. Adopt Server-Authoritative Game State

Currently, the game uses a **peer-to-peer trust model** where every client runs its own logic and broadcasts results. This will cause serious issues with the Monster AI (Phase 3), because:
- Who runs the monster's brain? If only the host does, the monster's position must be replicated. If every client does, the monster will behave differently on each machine.
- Damage from the monster must come from the server to prevent desync.

**Recommendation:** Adopt a model where:
1. The server (host) is the source of truth for all game state.
2. Clients send **requests** (`rpc_id(1, ...)`) and the server **broadcasts results** (`rpc("authority", "call_local", ...)`).

---

### B. Fix Player Scene Initialization Order

The current initialization is fragile because multiple `_ready()` functions compete. Godot calls `_ready()` bottom-up (children first, parent last). This means `PlayerInventory._ready()` fires **before** `PlayerMovement._ready()` sets `character_class`.

**Recommendation:** Use a single explicit initialization flow:
1. `PlayerMovement._enter_tree()` — set authority (already done)
2. `PlayerMovement._ready()` — call `_initialize_subsystems()` which explicitly initializes each child in the correct order

---

### C. Extract `PlayerClass` Enum to a Global

`PlayerClass` is defined inside `PlayerMovement`, forcing other scripts to reference it as `PlayerMovement.PlayerClass.HOARDER` or use raw integers. Since the class system touches inventory, models, fear, and movement, it should be a global autoload.

---

## File-by-File Verdict

| File | Lines | Verdict | Key Issues |
|------|-------|---------|------------|
| `PlayerMovement.gd` | 235 | ✅ Good | Mouse capture runs for remotes (#5) |
| `PlayerCamera.gd` | 37 | ✅ Good | Duplicate mouse capture (#5) |
| `PlayerFlashlight.gd` | 55 | ✅ Good | Fragile parent chain (#7) |
| `PlayerInteraction.gd` | 92 | ✅ Solid | Clean authority checks throughout |
| `PlayerInventory.gd` | 168 | ⚠️ Needs work | Frame polling (#1), drop desync (#3) |
| `PlayerModel.gd` | 305 | ⚠️ Needs cleanup | Raw ints (#8), compressed formatting (#11) |
| `PlayerHealth.gd` | 125 | ⚠️ Needs authority | No MP checks (#4) |
| `PlayerFear.gd` | 205 | ✅ Good | Authority checks present, clean tiers |
| `NetworkManager.gd` | 93 | ✅ Good | No input validation (#9) |
| `TestChamber.gd` | 31 | ✅ Good | Clean spawn logic |
| `MainMenu.gd` | 103 | ✅ Good | Functional lobby |
| `InteractableDoor.gd` | 41 | ⚠️ Needs authority | Any peer can toggle (#2) |
| `PickupItem.gd` | 55 | ✅ Good | Clean RPC pickup flow |
| `Interactable.gd` | 17 | ✅ Good | Clean base class |
| `InventoryHUD.gd` | 71 | ✅ Good | Debug text to remove (#10) |
| `FlashlightHUD.gd` | 80 | ✅ Good | Clean battery display |
| `StaminaHUD.gd` | 97 | ✅ Good | Elegant custom draw |
| `DamageOverlay.gd` | 85 | ✅ Good | Shader-driven, clean |
| `FearOverlay.gd` | 59 | ✅ Good | Shader-driven, clean |
| `DownedHUD.gd` | 94 | ✅ Good | Pulsing text, proper signal hooks |
| `InteractionPrompt.gd` | 32 | ✅ Good | Styling-only, clean |

---

## Summary

The codebase is well-structured for a prototype. The biggest risks going into Phase 3 are:
1. **No server authority on game state** — the Monster AI will need a single source of truth.
2. **Dropped item desync** — items spawned via RPC won't survive late-joiners or reconnects.
3. **Health system has no multiplayer guards** — the monster dealing damage must go through the server.

> [!IMPORTANT]
> Fixing issues **#1 through #4** before starting the Monster AI will save significant debugging time later.

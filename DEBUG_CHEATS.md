# Night Shift — Debug Cheat Codes

During Phase 1 development (before enemies and anomalies are fully implemented), you can use the following cheat codes to test the Player Health and Fear systems. 

These codes are implemented directly in the player scripts and should be removed or disabled before releasing the final game.

## Fear System Cheats
*Implemented in: `PlayerFear.gd`*

These are "classic" style cheat codes — just type the word sequentially on your keyboard while playing.

| Typed Word | Effect | Description |
|---|---|---|
| **`fear`** | Add 25 Fear | Jumps the fear meter up by 25 points, advancing you towards the next threshold (Uneasy → Distressed → Panic). |
| **`crazy`** | Max Fear (100%) | Instantly sends the player into full **Panic**. Triggers heavy tunnel vision, camera jitter, and autonomous flashlight flickering. |
| **`calm`** | Zero Fear (0%) | Instantly resets the fear meter back to 0, removing all visual and audio fear effects. |

## Health & Downed State Cheats
*Implemented in: `PlayerHealth.gd`*

These are also typed cheat codes.

| Typed Word | Effect | Description |
|---|---|---|
| **`hlt`** | Heal 20 HP | Restores 20 points of health. |
| **`dmg`** | Take 20 Damage | Deals 20 points of damage. The screen will flash red, and the red damage vignette will intensify as your health drops below 50%. |
| **`down`** | Instant Down | Instantly drops your health to 0 and puts you in the **Downed** state. The camera will drop to the floor, you'll be forced to crawl, and the 30-second bleedout timer will start. |
| **`dead`** | Instant Death | Bypasses the downed state (or kills you while downed) and instantly triggers the "YOU DIED" death screen. |
| **`undie`** | Revive | While downed or dead, instantly revives you. Resets your camera and movement, and gives you back 30% of your maximum health. |

### Player Customization (Multiplayer Readiness)
These cheats dynamically change the color of the player's Hazmat suit. Note: you must be playing in a scene with a visible `PlayerModel` (like the Dummy in `TestChamber.tscn`) or have multiplayer active to see these changes.

| Typed Word | Effect | Description |
|---|---|---|
| **`col1`** | Yellow Suit | Changes the suit color back to the standard Yellow. |
| **`col2`** | Green Suit | Changes the suit color to Green. |
| **`col3`** | Blue Suit | Changes the suit color to Blue. |
| **`col4`** | Red Suit | Changes the suit color to Red. |
| **`col5`** | Magenta Suit | Changes the suit color to Magenta. |

### Class Switching (Visuals Only)
These cheats dynamically rebuild the `PlayerModel` to show a different class's physical rig. This is currently set up for dev testing on the `DummyModel`.

| Typed Word | Effect | Description |
|---|---|---|
| **`cl1`** | Engineer Rig | Changes the dummy's visual mesh to the Engineering Major build. |
| **`cl2`** | Athlete Rig | Changes the dummy's visual mesh to the Student Athlete build. |
| **`cl3`** | Hoarder Rig | Changes the dummy's visual mesh to the Campus Hoarder build. |
| **`cl4`** | Freshman Rig | Changes the dummy's visual mesh to the Paranoid Freshman build. |

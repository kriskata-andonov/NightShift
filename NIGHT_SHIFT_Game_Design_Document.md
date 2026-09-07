# NIGHT SHIFT
## Game Design Document + Technical Development Brief
### Target Engine: Godot 4
### Genre: Co-op Horror / Comedy / Exploration
### Players: 1–4
### Camera: First-person
### Visual Style: Stylized Low-Poly / PS2-inspired
### Core Features: Proximity Voice Chat, Radio, Dynamic Darkness, Anomalies, AI Horror
### Performance Goal: Strong optimization for older/low-end PC hardware

---

# 1. HIGH-LEVEL VISION

NIGHT SHIFT is a 1–4 player cooperative first-person horror game set in abandoned industrial locations.

Players are night workers sent into dangerous facilities to complete mundane jobs such as restoring power, finding equipment, checking rooms, repairing machinery, and extracting.

The horror comes primarily from:
- darkness
- sound
- uncertainty
- strange environmental behavior
- separation between players
- proximity voice chat
- a creature that observes, follows, imitates voices, and sometimes hunts

The game should also be funny and naturally generate memorable moments between friends.

The target experience is:
"Players enter expecting a simple job, slowly realize something is wrong, start separating, hear impossible voices, panic, and eventually run for extraction."

The game should NOT depend on expensive graphics. Atmosphere, audio, lighting, AI behavior, and player interaction are more important than polygon count.

---

# 2. DESIGN PILLARS

1. CO-OP FIRST
Players should need each other for objectives, information, and survival.

2. HORROR THROUGH UNCERTAINTY
Do not constantly show the monster. Suggest it through sound, movement, shadows, missing objects, and strange behavior.

3. FUNNY PANIC
The game should create situations where friends argue, joke, misunderstand each other, and panic.

4. VOICE CHAT AS GAMEPLAY
Voice communication is a core mechanic, not merely a convenience.

5. REPLAYABILITY
The same map should feel different due to randomized objectives, item locations, anomalies, event timing, and monster behavior.

6. LOW-END PERFORMANCE
Optimization is a design requirement from the beginning, not a final polish step.

7. SHORT REPEATABLE SESSIONS
Target approximately 15–30 minutes per mission.

---

# 3. CORE GAMEPLAY LOOP

Safe Room (Between Floors)
→ Select Next Floor (Difficulty Route)
→ Enter Floor
→ Scavenge for Items & Equipment
→ Complete Objectives (Restore Power / Unlock Elevator)
→ Explore & Survive
→ Experience Anomalies
→ Encounter / Avoid Monster
→ Reach the Elevator (Extraction)
→ Ascend to Next Safe Room

A failed run (total party kill) resets the players back to the bottom of the facility.

---

# 4. THE SAFE ROOM (HUB)

There is no cozy exterior base. The "Hub" is the heavy, reinforced industrial elevator (or small maintenance checkpoint) connecting the massive underground floors. 

It contains:

## Elevator Control Panel (Mission Board)
Shows:
- current depth
- next floor options (e.g., branching paths with varying difficulty)
- floor objectives

## Storage Area
Players can drop and store scavenged equipment here. Since they are carrying this gear up with them, any items left on the floor of the Safe Room persist between levels.

## CCTV
Optional feature for later development. The safe room could have a hacked terminal where players review footage from the previous floor to discover clues about anomalies.

The Safe Room is the only place players can breathe, heal, and plan before the elevator doors open again.

---

# 5. MISSION STRUCTURE

Each mission contains:
- one primary objective chain
- optional secondary objectives
- loot
- random anomalies
- monster behavior
- extraction phase

Example factory mission:

Primary:
1. Find three fuses.
2. Restore generator.
3. Activate main power.
4. Repair elevator.
5. Return to extraction.

Secondary:
- Find missing tools.
- Photograph anomalies.
- Recover employee records.
- Find lost equipment.

---

# 6. MAP DESIGN

Do not start with huge fully procedural maps.

Use modular rooms and corridors.

Example modules:
- entrance
- corridor
- office
- warehouse
- maintenance room
- stairs
- basement
- generator room
- storage room
- control room

Rooms can be assembled in different layouts.

The goal is:
Players recognize the types of spaces but do not know the exact layout every run.

Example:

Layout A:
Entrance → Corridor → Office → Basement

Layout B:
Entrance → Warehouse → Office → Corridor → Basement

This provides replayability without requiring an expensive procedural generation system.

---

# 7. VISUAL STYLE

Target:
Stylized low-poly, PS2-inspired horror with modern lighting and atmospheric effects.

Models should be deliberately simple.

Approximate triangle targets:
- small props: 100–1000
- medium props: 500–2000
- important props: 1000–3000
- monster: keep reasonably simple and optimize carefully

Use:
- simple materials
- small textures
- texture atlases
- modular geometry
- baked/static lighting where appropriate
- fog
- carefully limited dynamic lights

Avoid:
- unnecessary high-resolution textures
- excessive geometry
- large numbers of dynamic shadow-casting lights
- expensive post-processing
- unnecessary physics simulation

Darkness should help performance by limiting how much detail needs to be visible.

---

# 8. LIGHTING

Lighting is a major gameplay system.

Players primarily use flashlights.

World lighting:
- mostly static/baked where possible
- limited dynamic lights
- limited shadow distance

Player flashlight:
- SpotLight3D or optimized equivalent
- limited range
- limited shadow use
- battery consumption

Generators:
- restore parts of the facility
- change lighting state
- create temporary safety/comfort
- can later fail again through events

Power outage sequence:

Lights on
→ flicker
→ flicker
→ power off
→ silence
→ footsteps / audio event
→ eventual restoration

Not every blackout should cause a monster attack.

---

# 9. VOICE CHAT

Voice chat is a signature system.

## Proximity Voice

Voice volume depends on distance.

Close:
- clear
- loud

Medium:
- quieter
- slightly muffled

Far:
- difficult to understand
- eventually inaudible

Possible implementation:
- distance attenuation
- volume falloff
- optional low-pass filtering
- optional occlusion approximation

## Radio

Push-to-talk radio allows long-distance communication.

Radio can have:
- static
- interference
- battery
- signal quality
- temporary disruption

The monster can potentially imitate radio communication.

---

# 10. FAKE PLAYER / VOICE IMITATION

One of the main signature mechanics.

The monster can imitate player voice lines or communication patterns.

Example:

Player A:
"Coming."

Several seconds later from another corridor:
"Coming."

Player B:
"Was that C?"

Player C:
"I'm standing next to you."

The goal is to create uncertainty.

Players can optionally establish a code word before entering.

Example:
Code word = PIZZA

However, the monster may eventually learn or imitate the code word.

Important:
Voice imitation should be used carefully. It should create uncertainty rather than become predictable or annoying.

---

# 11. MONSTER CONCEPT

The monster should not behave like a standard enemy that constantly chases players.

It is an intelligent presence.

Main states:

IDLE
→ OBSERVE
→ FOLLOW
→ HIDE
→ IMITATE
→ HUNT
→ ATTACK
→ RETREAT

## IDLE
Creature is inactive or far away.

## OBSERVE
Creature watches players from a distance.

Players may notice it briefly.

## FOLLOW
Creature follows the group from a distance.

It may generate footsteps.

## HIDE
Creature disappears from sight and changes position.

## IMITATE
Creature reproduces:
- player voice
- radio messages
- footsteps
- environmental sounds

## HUNT
Creature actively tracks players.

## ATTACK
Creature attacks vulnerable / isolated players.

## RETREAT
Creature stops hunting and disappears.

The monster should often choose not to attack.

---

# 12. MONSTER DETECTION

Potential signals:
- player distance
- player noise
- flashlight visibility
- player isolation
- objectives completed
- fear level
- recent anomaly events

Avoid making the AI overly complex initially.

A simple state machine is preferred.

Use Godot NavigationAgent3D where appropriate.

AI should run efficiently and avoid unnecessary expensive calculations every frame.

---

# 13. ANOMALY SYSTEM

Create an EventManager / AnomalyManager.

Example events:
- LightFlicker
- DoorClose
- ObjectMove
- Footsteps
- Whisper
- RadioStatic
- FakeVoice
- Shadow
- PowerOutage
- MonsterObserve
- MonsterFollow
- MonsterHunt

Each event can have parameters such as:
- minimum_time
- maximum_time
- cooldown
- chance
- required_players
- minimum_fear
- maximum_fear
- severity

Events should be data-driven where possible.

The goal is to create unpredictable situations without requiring unique scripted scenes for every event.

---

# 14. ANOMALY INTENSITY

Suggested levels:

LEVEL 1: Unease
- light flicker
- distant noise
- object slightly moved
- door sound

LEVEL 2: Something is wrong
- object relocates
- elevator activates
- radio interference
- footsteps
- distant silhouette
- lights turn off

LEVEL 3: Danger
- locked door
- major blackout
- fake voice
- monster sighting
- pursuit
- player isolation event

Avoid constant high-intensity events.

Silence is important.

---

# 15. FEAR SYSTEM

Do not use a traditional sanity meter that removes player control.

Use an internal Fear value/state.

States:

CALM
→ UNEASY
→ SCARED
→ PANIC

Effects can include:
- breathing
- heartbeat
- subtle camera effects
- audio distortion
- subtle vignette

Do not heavily impair movement or controls.

Fear should support atmosphere rather than frustrate the player.

---

# 16. PLAYER HEALTH / DOWNED STATE

When a player reaches zero health:
- player becomes DOWNED
- teammates can revive
- after a timer, player dies

Example:
30 second revive window.

This creates cooperative decisions:
"Do we save them or continue the objective?"

---

# 17. DEAD PLAYER SYSTEM

Dead players should remain involved.

Possible feature:
Ghost / spectator mode.

The dead player can:
- watch teammates
- observe the monster
- use limited ghost signals

Example ghost communication:
- knock
- static
- beep
- whisper

Do not allow unlimited communication because it would destroy the uncertainty.

---

# 18. EQUIPMENT

Core items:

## Flashlight
Main light source.
Has battery and possible upgrades.

## Battery
Restores flashlight power.

## Glow Stick
Cheap persistent light marker.

## Camera
Can photograph anomalies.

## Motion Sensor
Detects nearby movement.

## Noise Maker
Creates sound to distract the monster.

## Medkit
Revives / heals downed players.

## Repair Kit
Repairs certain objectives.

## Radio
Long-distance voice communication.

---

# 19. PROGRESSION AND SCAVENGING

There is no currency or shop economy. 

Progression relies entirely on **Scavenging**. 
Players start with weak, basic flashlights. Everything else must be found inside the facility.

Found items are extracted and stored in the Hub. If a player dies and is left behind, their carried gear is lost forever. 

Upgrades (like a heavy-duty flashlight or long-range radio) are rare spawns in dangerous areas (like the Control Room or Basement). This forces players to choose between safety (escaping quickly) and progression (exploring deep into the facility for better gear).

---

# 20. REPLAYABILITY

Randomize:
- objective locations
- fuse/item locations
- room layout
- loot
- anomaly timing
- event selection
- monster behavior
- monster spawn/position
- optional objectives
- power state
- environmental events

Do not randomize everything. Some authored structure is important for atmosphere.

---

# 21. DIFFICULTY

Use Shift Levels rather than simply increasing monster HP.

Shift 1:
- few anomalies
- rare monster appearances

Shift 2:
- more environmental events

Shift 3:
- less reliable lighting
- more aggressive AI

Shift 4:
- fake voices
- frequent power outages
- stronger monster behavior

Shift 5:
- active hunting
- more complex anomaly combinations

---

# 22. CO-OP DESIGN

Objectives should naturally encourage players to split up.

Examples:
- two switches must be activated
- one player reads instructions while another operates a machine
- multiple fuses in different sections
- one player watches a control panel
- one player holds a door
- separate search areas

But splitting up should be risky, not mandatory every minute.

The game should create organic decisions:
"Do we stay together or cover more ground?"

---

# 23. SAFE ZONES

Extraction point and hub should feel genuinely safer.

Safe zones:
- brighter
- calmer audio
- minimal anomalies
- no monster attacks

The contrast between safety and the mission increases tension.

---

# 24. AUDIO DESIGN

Audio is one of the highest-priority systems.

Need:
- ambient room loops
- distant machinery
- electrical hum
- footsteps
- doors
- metal impacts
- wind
- pipes
- whispers
- monster sounds
- radio static
- breathing
- heartbeat
- blackout audio

Important principle:
Audio should often communicate danger before visuals do.

Do not overuse loud stingers.

---

# 25. UI

Keep UI minimal.

During missions:
- objective
- interaction prompt
- inventory/equipment
- flashlight battery
- radio status
- optional teammate status

Avoid large permanent HUD elements.

Fear should not feel like the player is playing a spreadsheet.

---

# 26. MULTIPLAYER ARCHITECTURE

Target:
1–4 players.

Preferred initial model:
Host / listen-server.

Host/server authority should control:
- monster AI
- objectives
- loot spawning
- anomaly events
- world state
- mission progression

Clients send:
- movement
- interactions
- item actions
- voice state where appropriate

Use events/RPCs for discrete actions:
- door opened
- fuse inserted
- item picked up
- generator repaired

Do not constantly synchronize unnecessary data.

---

# 27. NETWORK OPTIMIZATION

Avoid sending everything every frame.

Prioritize:
- player position/rotation
- important gameplay state
- objective changes
- item state
- monster state

Use interpolation for remote player movement.

Keep network traffic appropriate for a 4-player game.

---

# 28. GODOT PROJECT STRUCTURE

Suggested:

res://
├── scenes/
│   ├── player/
│   ├── monster/
│   ├── maps/
│   ├── props/
│   ├── items/
│   └── ui/
│
├── scripts/
│   ├── player/
│   ├── monster/
│   ├── networking/
│   ├── interaction/
│   ├── events/
│   └── systems/
│
├── audio/
│   ├── ambience/
│   ├── monster/
│   ├── player/
│   └── ui/
│
├── materials/
├── textures/
└── data/
    ├── items/
    ├── missions/
    └── events/

---

# 29. PLAYER SCENE

Suggested:

Player
├── CharacterBody3D
├── CollisionShape3D
├── Camera3D
├── Head
├── Flashlight
│   └── SpotLight3D
├── InteractionRay
├── AudioListener3D
├── VoiceSource
└── UI

Prefer modular scripts:

PlayerMovement
PlayerInteraction
PlayerInventory
PlayerVoice
PlayerHealth
PlayerEquipment

Avoid one giant Player.gd file.

---

# 30. MONSTER SCENE

Suggested:

Monster
├── CharacterBody3D
├── CollisionShape3D
├── NavigationAgent3D
├── Mesh
├── AnimationTree
├── AudioPlayer
├── DetectionArea
└── AIController

AIController should use a state machine:

IdleState
ObserveState
FollowState
HideState
ImitateState
HuntState
AttackState

---

# 31. INTERACTION SYSTEM

Create a common interaction interface/protocol.

Conceptually:

interact()
can_interact()
get_interaction_text()

Potential interactables:
- generator
- door
- fuse box
- computer
- item
- elevator
- control panel

Keep interaction logic reusable.

---

# 32. DATA-DRIVEN DESIGN

Use Godot Resources for:
- missions
- items
- anomalies/events
- equipment
- difficulty configuration

Example MissionData:
- mission_name
- reward
- objectives
- map
- difficulty
- event_pool

The goal is to add content without rewriting core systems.

---

# 33. PERFORMANCE TARGET

Optimization is a core feature.

Primary goal:
Stable 60 FPS on older/low-end PCs where reasonably possible.

Priorities:
1. low-poly geometry
2. texture atlases
3. reasonable texture sizes
4. static/baked lighting where possible
5. limited dynamic lights
6. limited shadow casting
7. occlusion culling
8. LOD where beneficial
9. simple collision meshes
10. limited physics
11. efficient AI updates
12. object pooling for frequently spawned objects
13. avoid unnecessary per-frame processing
14. profile continuously during development

Use the simplest solution that looks good enough.

---

# 34. MVP

Do NOT start with the full game.

First playable MVP:

MAP:
- one small factory

PLAYERS:
- 1–4

ITEMS:
- flashlight
- battery
- fuse
- medkit

OBJECTIVES:
- find 3 fuses
- activate generator
- escape

MONSTER:
- Observe
- Follow
- Hunt
- Attack

VOICE:
- proximity
- radio

ANOMALIES:
- light flicker
- door close
- footsteps
- power outage
- monster sighting

PROGRESSION:
- item scavenging
- extracting surviving gear

This MVP should already be fun with 2–4 players.

---

# 35. DEVELOPMENT ROADMAP

PHASE 1: Player
- FPS controller
- camera
- movement
- interaction
- flashlight

PHASE 2: Multiplayer
- host
- clients
- movement synchronization
- interaction synchronization

PHASE 3: Voice
- proximity voice
- radio

PHASE 4: First Map
- factory
- rooms
- doors
- generator
- objectives

PHASE 5: Monster
- navigation
- state machine
- detection
- basic hunting

PHASE 6: Anomalies
- EventManager
- lights
- doors
- audio events
- blackouts

PHASE 7: Full Gameplay Loop
- objectives
- extraction
- rewards
- death
- revive

PHASE 8: Polish
- audio
- animation
- UI
- optimization
- settings

PHASE 9: Content
- maps
- missions
- items
- anomalies
- additional monster behavior

---

# 36. FIRST VERTICAL SLICE

The first vertical slice should demonstrate:

1. Two or more players connect.
2. Players can walk around together.
3. Players can see each other.
4. Players can use proximity voice.
5. Players can use radio.
6. Players can use flashlights.
7. Players can interact with a fuse box.
8. Players can find fuses.
9. Generator can be activated.
10. Lights can change.
11. An anomaly can trigger.
12. Monster can observe players.
13. Monster can follow players.
14. Monster can hunt players.
15. Player can become downed.
16. Another player can revive them.
17. Players can escape.
18. Mission reward is calculated.

If this works and is fun, continue.

---

# 37. DESIGN RULES FOR THE AI AGENT

When implementing features:
- Prefer simple, maintainable architecture.
- Avoid premature abstraction.
- Avoid giant scripts.
- Avoid unnecessary dependencies.
- Keep systems modular.
- Use typed GDScript where practical.
- Comment non-obvious logic.
- Keep networking authority clear.
- Never trust clients with critical mission state.
- Profile performance before optimizing blindly.
- Build small test scenes for systems.
- Keep the MVP playable after each major milestone.
- Do not add systems simply because they sound cool if they hurt the core gameplay loop.

When uncertain, prioritize:
1. gameplay
2. stability
3. multiplayer correctness
4. performance
5. maintainability
6. visual polish

---

# 38. EXAMPLE MISSION

MISSION: ABANDONED FACTORY

Players enter.

Objective:
Restore power.

Step 1:
Find 3 fuses.

Step 2:
Insert fuses.

Step 3:
Activate generator.

Step 4:
Wait for power to stabilize.

Step 5:
Repair elevator.

Step 6:
Return to extraction.

Possible events:
- light flicker
- footsteps
- door closes
- object moves
- radio static
- fake player voice
- monster observation
- blackout

Example sequence:

00:00 players enter and joke around.

03:00 players split up.

06:00 one player hears footsteps.

08:00 a player hears an imitation of another player's voice.

10:00 power fails.

11:00 monster is briefly visible.

12:00 objective changes to extraction.

14:00 players run.

15:00 players escape.

Mission reward is calculated.

---

# 39. CORE EXPERIENCE TEST

Before adding new content, ask:

"Does this make playing with friends more fun, more tense, or more unpredictable?"

If no:
Do not prioritize it.

The game should produce stories such as:

"We thought Alex was behind us, but it was the monster."

"We split up to find the fuse and then someone copied my voice."

"The lights went out and nobody knew where anyone was."

"Mark died because he went back for a $20 battery."

These emergent stories are the real product.

---

# 40. FINAL DESIGN SUMMARY

NIGHT SHIFT should feel like:

A group of friends doing a boring night job inside a dark abandoned facility.

The first few minutes are calm.

Then small things become strange.

The players start questioning what they hear.

They separate.

The voice chat becomes part of the horror.

The monster appears rarely.

Eventually something goes very wrong.

The group panics.

They run.

Someone gets downed.

Someone goes back to save them.

The team escapes.

They laugh.

Then they immediately start another mission.

That loop is the heart of NIGHT SHIFT.

---

# 41. EXPANDED DESIGN DETAILS: MVP FACTORY

## Factory Map: Room Modules
To keep the MVP map feeling fresh but grounded, we can categorize rooms into Transit, Objective, and Atmosphere/Loot rooms.

### Transit Modules (Connecting areas)
- **The Catwalks:** Elevated metal walkways over dark, inaccessible lower floors. High tension: nowhere to hide, loud metal footsteps.
- **Decontamination Corridor:** A tight, claustrophobic hallway with heavy plastic flaps that obscure vision and muffle sound.
- **Locker Room:** Rows of tall metal lockers creating a maze-like layout. Good for breaking line-of-sight.

### Objective Modules (Where players must go)
- **The Boiler Room (Generator Location):** Deep in the facility, noisy, with lots of pipes. When the generator is off, it's dead silent.
- **Control Room:** Elevated room overlooking a warehouse floor. Contains the main power switch. Has large windows (players feel exposed, like they are being watched).
- **Maintenance Workshop:** Scattered with tools and shelves. High probability of finding fuses here.

### Atmosphere/Loot Modules (Optional exploration)
- **Employee Breakroom:** Creepy juxtaposition of everyday life. Old vending machines that might suddenly drop a can. Good place for batteries.
- **Shipping Bay:** Large, open warehouse area with towering crates. Lots of dark corners and long sightlines.

## AnomalyManager: Refining Event Data
Defining specific Anomaly data resources under the hood based on the EventManager concept.

### Anomaly: "The Mimic Whisper"
- **Description:** Plays a recorded whisper of a player's voice directly behind a separated player.
- **chance:** 15% 
- **required_players:** 1 (Target must be isolated)
- **minimum_fear:** UNEASY
- **cooldown:** 300 seconds
- **severity:** Level 2 (Something is wrong)
- **Trigger condition:** Player must be > 15 meters away from the nearest teammate.

### Anomaly: "Sudden Slam"
- **Description:** A heavy metal door slams shut violently in an adjacent room.
- **chance:** 40%
- **required_players:** Any
- **minimum_fear:** CALM
- **cooldown:** 120 seconds
- **severity:** Level 1 (Unease)
- **Trigger condition:** Player walks through a doorway connecting two modules.

### Anomaly: "Vending Machine Drop"
- **Description:** A vending machine loudly drops a soda can in a quiet room, followed by the machine's light flickering out.
- **chance:** 20%
- **required_players:** 1-2
- **minimum_fear:** CALM
- **cooldown:** Only happens once per mission
- **severity:** Level 1 (Unease)

## Monster AI: State Transitions & Logic
To ensure the monster feels intelligent rather than like a simple homing missile, it relies on a tension budget and isolation checks.

### Transition Triggers
- **IDLE -> OBSERVE:** Triggered when players enter a new major module or restore a generator. The monster spawns at a distance, preferring elevated areas or long corridors.
- **OBSERVE -> HIDE:** Triggered if a player looks directly at the monster for more than 1.5 seconds, or if a flashlight beam hits it.
- **HIDE -> FOLLOW:** If players move quickly or make noise (sprinting, dropping items), the monster begins tracking them quietly.
- **FOLLOW -> IMITATE:** If the monster has recorded a voice snippet, and the players are separated by at least 1 module, the monster plays the snippet to the isolated player.
- **FOLLOW -> HUNT:** Triggered if the "Tension Budget" is maxed out, a player is completely isolated in the dark for too long, or as a guaranteed event during extraction.
- **HUNT -> RETREAT:** If the monster downs a player, it immediately retreats. It also retreats if players reach a Safe Zone (Hub/Extraction).

## Fear System Mechanics
Fear is an internal float value (0.0 to 100.0) that affects client-side visuals and audio, enhancing the atmosphere without removing control.

### Fear Accumulation
- **+1/sec:** Standing in total darkness.
- **+5:** Witnessing an anomaly.
- **+15:** Seeing the monster.
- **+30:** Being hunted.
- **-2/sec:** Standing near a restored generator/lights.
- **-1/sec:** Standing close to another player.

### Fear Effects (Client-Side)
- **CALM (0-25):** Normal FOV, standard audio mixing.
- **UNEASY (26-50):** Slight vignetting. Ambient background noise volume increases by 10%. Occasional quiet heartbeat audio.
- **SCARED (51-75):** Stronger vignette. Colors slightly desaturated. Heavy breathing audio loop starts. Flashlight beam seems to waver slightly (simulated hand shake).
- **PANIC (76-100):** FOV pulses slightly. Audio is muffled (low-pass filter) except for monster sounds and proximity chat, which become distorted. Heartbeat is loud.

## Scavenged Equipment
Gear must be found and extracted. Stronger gear spawns in high-danger modules.

### Flashlight
- **Tier 1 (Default Start):** Dim, narrow beam. Battery lasts 60s.
- **Tier 2 (Rare Spawn):** Halogen bulb. Wider beam. Battery lasts 90s.
- **Tier 3 (Very Rare Spawn):** Heavy-duty LED. Very bright, long throw. Battery lasts 120s.

### Radio
- **Tier 1 (Common Spawn):** Heavy static. Range limited to 2 modules away.
- **Tier 2 (Rare Spawn):** Reduced static. Range extends to 4 modules.
- **Tier 3 (Very Rare Spawn):** Crystal clear across the entire facility. (Makes monster imitation much more obvious when it happens).

### Consumables
- **Battery (Common Spawn):** Essential. Taking too many limits inventory space for mission items.
- **Glow Stick (Common Spawn):** Lasts 5 minutes. Useful for marking explored rooms or dropping in dark corners to prevent Fear accumulation.
- **Medkit (Very Rare Spawn):** Revives a downed player instantly. Extremely valuable find.

## Network Sync & Architecture Details
To maintain the 60 FPS performance goal on low-end hardware and keep bandwidth low, we strictly define what data is sent.

### What the Host (Server) Sends
- **Reliable RPCs:** Objective state changes, Anomaly triggers, door states, generator states, monster state changes (e.g., "Started Hunt").
- **Unreliable Updates (10-20 ticks/sec):** Monster position and rotation.

### What the Client Sends
- **Reliable RPCs:** Interaction requests (e.g., `request_open_door()`, `request_insert_fuse()`), equipment usage, chat/radio activation state.
- **Unreliable Updates (20-30 ticks/sec):** Player transform (Position, Head Rotation), Flashlight direction.

### Voice Chat Sync
- Proximity voice data is peer-to-peer or relayed through the host if P2P fails.
- Voice buffers are heavily compressed (e.g., using Opus codec).
- The Host manages the Monster's "Imitation Buffer" by caching 3-second snippets of player audio locally and broadcasting them back as a positional AudioStreamPlayer3D attached to the monster when IMITATE is triggered.

---

# 42. NARRATIVE & LORE

## The Setup
The players are broke college students desperate for money. They sign up for a highly-paid late-night "facilities maintenance" job posted by a highly eccentric, reclusive employer (a "mad scientist"). The students didn't question why there was a severe lack of applicants until it was too late.

## The Trap
Upon arriving for their first shift, the elevator malfunctions (or is intentionally dropped), plunging them into the deepest, darkest sub-basement of the scientist's massive, underground research facility. There is no radio contact with the outside world. The only voice they hear is the scientist over the intercom, taking notes on their performance.

## The Ascent (The Experiment)
The players aren't there to actually fix the facility—they are the latest test subjects in a twisted survival experiment. The facility is filled with horrific anomalies and creatures created by the scientist. 

To escape, players must survive a grueling ascent. Each "mission" is a floor of the facility. The students must restore power, bypass security doors, and find the elevator to ascend to the next level, moving from the Deep Sub-Levels all the way up to the Surface, while the mad scientist actively monitors their panic levels and survival strategies.

---

# 43. PLAYER TRAITS (CLASSES)

To add replayability and emphasize the "broke college students" theme, players can select a Background before starting the ascent. Each trait provides a specific utility buff, but comes with a corresponding tradeoff to maintain the survival horror tension.

## 1. The Engineering Major
* **Buff:** Interacts with generators, fuse boxes, and electronic keypads 30% faster.
* **Tradeoff:** Their makeshift tools constantly emit a faint electrical hum, increasing the radius at which the monster can detect them by sound.

## 2. The Student Athlete
* **Buff:** Sprints 15% faster and has a larger stamina pool.
* **Tradeoff:** When out of stamina, they breathe extremely loudly for several seconds. This masks important audio cues (like approaching footsteps) and immediately alerts the monster if it is nearby.

## 3. The Campus Hoarder
* **Buff:** Starts the run with one extra inventory slot, making them the ideal packmule for carrying scavenged batteries, fuses, and medkits.
* **Tradeoff:** Cannot reach maximum sprint speed when their inventory is fully loaded.

## 4. The Paranoid Freshman
* **Buff:** Has heightened senses due to anxiety. Gets a subtle visual warning (e.g., a faint UI shimmer or cold breath particle effect) when the monster is actively observing them from the darkness.
* **Tradeoff:** Their internal Fear meter fills 20% faster than anyone else's when separated from the group by more than one room module.

---

# 44. THE "GHOST" EXPERIENCE (DEAD PLAYERS)

When a player fully bleeds out, they become a Ghost. Ghosts can fly around the facility freely with noclip and watch the horror unfold. To keep dead players engaged in the game loop and discourage them from spoiling the tension over third-party voice chat, they are given tools to interact with the world using a slowly recharging **Ecto-Energy** meter.

Energy recharges very slowly, forcing ghosts to use their abilities strategically to help (or scare) their surviving friends.

## Ghost Abilities
* **Cold Spot (Cost: 25% Energy):** Drop a temporary, faint blue glowing orb on the floor. Useful for guiding a lost teammate to an objective or marking a doorway.
* **Radio Interference (Cost: 50% Energy):** Target a surviving teammate's radio and cause it to burst with aggressive static for 2 seconds. A great way to warn them to run, or to signal that they are going the wrong way.
* **Poltergeist (Cost: 100% Energy):** Slam an open door shut or violently throw a small physics object across the room. Can be used to block the monster's path, distract it with a loud noise, or just troll a friend.

---

# 45. HIGH-FEAR HALLUCINATIONS

When a player hits **100% PANIC** in the internal Fear system, the game begins to aggressively lie to them. Hallucinations are strictly client-side. Only the panicked player experiences these events, creating terrifying and confusing proximity voice chat moments where one player screams about something the rest of the team cannot see or hear.

## Hallucination Event Pool
* **The Decoy:** The player spots a static model of a teammate standing at the end of a long, dark hallway facing the wall. If the player approaches it or shines a light on it for too long, it violently dissolves into black dust.
* **Phantom Chase:** The player suddenly hears incredibly loud, heavy monster footsteps sprinting directly behind them for 5 seconds. If they turn around, absolutely nothing is there.
* **Flashlight Death:** The player's flashlight appears to flicker and die completely, plunging them into pitch blackness. However, on the server and to all other teammates, their flashlight is perfectly fine and still shining.
* **The Whisperer:** The player hears their own voice (using a previously cached imitation audio snippet) whispering directly into their left or right ear, as if something is standing directly next to them.

---

# 46. TECHNICAL VISUAL POLISH (THE PS2 AESTHETIC)

To achieve the nostalgic, unsettling retro vibe while ensuring the game runs smoothly at 60 FPS on low-end hardware, we will utilize specific rendering techniques in Godot 4. The goal is to make the game look like a lost survival horror title from the early 2000s.

## Godot 4 Rendering Settings
* **Internal Resolution Scaling:** We will use Godot's viewport scaling to render the game internally at a very low resolution (e.g., 480p or 360p) and scale it up to the player's native monitor resolution. This creates a chunky, pixelated look without relying on expensive post-processing filters.
* **Point Filtering (Nearest-Neighbor):** All texture filtering will be set to "Nearest" in the project settings. Textures will be deliberately low-resolution, and point filtering ensures they remain perfectly pixelated and sharp rather than blurry or smoothed out.
* **Vertex Snapping (Affine Texture Mapping):** We will implement a custom Vertex Shader for the environment geometry. This shader snaps vertex coordinates to a low-resolution grid based on the camera's position, recreating the iconic "wobbly" geometry and warping textures seen on early 3D consoles.
* **Color Banding & Dithering:** We will use a lightweight post-processing shader to limit the color depth (e.g., simulating 16-bit color). This ensures that shadows don't fade smoothly, but instead step down in visible, noisy bands, making the darkness feel thick, textured, and oppressive.

# 🏟️ Shotput for Brainrot

> A colorful, arcade physics **incremental tycoon** built in **UEFN** with **Verse**.
> Throw a ball as far as you can, earn coins, upgrade everything, and throw it *even farther*. Repeat until your brain is fully rotted. 🧠💥

![status](https://img.shields.io/badge/status-proof--of--concept-orange)
![engine](https://img.shields.io/badge/engine-UEFN-blue)
![language](https://img.shields.io/badge/language-Verse-purple)
![license](https://img.shields.io/badge/license-MIT-green)

---

## 📖 Overview

**Shotput for Brainrot** is a casual, physics-based incremental game. The entire game
is built around one satisfying loop that a new player understands in under 10 seconds:

> **Throw ball → Earn coins → Buy upgrades → Throw farther → Repeat**

Every throw is scored on **distance**, **airtime**, and **bounces**. Coins fund
**player upgrades** (Strength, Charge Speed, Crit Chance, Coin Multiplier) and a
**ball progression** ladder from a humble Stone all the way to the legendary
**Secret Ball**. The visual style is intentionally loud, exaggerated, and funny —
this is arcade candy, not a physics simulator.

### 🎯 Design Success Criteria
| Goal | Target |
|------|--------|
| Player understands the game | < 10 seconds |
| Player completes first throw | < 30 seconds |
| Player feels motivated to continue | Immediate upgrade payoff after throw #1 |

---

## 🕹️ Gameplay Loop

```
        ┌─────────────────────────────────────────────────┐
        │                                                   │
        ▼                                                   │
  ┌───────────┐   charge & release   ┌──────────────┐      │
  │  CHARGE   │ ───────────────────► │   SIMULATE    │      │
  │  METER    │   (perfect window)   │  BALL PHYSICS │      │
  └───────────┘                      └──────┬───────┘      │
                                            │ distance,     │
                                            │ airtime,      │
                                            │ bounces       │
                                            ▼               │
                                     ┌──────────────┐       │
                                     │   ECONOMY    │       │
                                     │  coin reward │       │
                                     └──────┬───────┘       │
                                            │ coins          │
                                            ▼               │
                                     ┌──────────────┐       │
                                     │     SHOP     │───────┘
                                     │  upgrades &  │  throw farther
                                     │    balls     │
                                     └──────────────┘
```

1. **Charge** — Tap the throw button to fill the charge meter. Release inside the
   glowing **perfect window** (top ~8%) for a big speed + coin bonus.
2. **Simulate** — The ball launches on a 42° arc. Gravity, bounces, and friction
   are simulated at 60 Hz for smooth arcade motion.
3. **Score** — Coins are awarded from distance + airtime + bounces, then multiplied
   by your ball, your Coin Multiplier upgrade, and a possible **critical hit**.
4. **Upgrade** — Spend coins on player upgrades or unlock a fancier ball.
5. **Repeat** — Bigger numbers, farther throws, brain fully rotted.

---

## 🏗️ Architecture

The project uses a **modular, single-responsibility** architecture. The
`game_manager` device is the only object placed in the map; it owns and coordinates
seven independent subsystems. See [`Docs/ARCHITECTURE.md`](Docs/ARCHITECTURE.md) for
the full diagram and data flow.

```
                        ┌────────────────────┐
                        │    game_manager     │  (creative_device in map)
                        │  orchestrates all   │
                        └─────────┬──────────┘
        ┌──────────────┬──────────┼──────────┬──────────────┬─────────────┐
        ▼              ▼          ▼          ▼              ▼             ▼
 ┌───────────┐ ┌───────────┐ ┌────────┐ ┌────────┐ ┌────────────┐ ┌──────────┐
 │  throw_   │ │ physics_  │ │economy_│ │ shop_  │ │  distance_ │ │   ui_    │
 │  system   │ │ system    │ │system  │ │ system │ │  tracking  │ │ system   │
 └───────────┘ └───────────┘ └────────┘ └────────┘ └────────────┘ └──────────┘
        │                                    │
        └──────────────► save_system ◄───────┘  (persists player_state)
```

| System | Responsibility |
|--------|----------------|
| **PhysicsSystem** | Ballistic simulation: impulse, gravity, bounces, friction, rest detection |
| **ThrowSystem** | Charge meter, perfect-throw detection, launch speed/direction |
| **EconomySystem** | Coin reward calculation (distance/airtime/bounce/crit) |
| **ShopSystem** | Player upgrade purchases + ball unlock/equip |
| **SaveSystem** | Load/save `player_state` (coins, best distance, ball, upgrades) |
| **DistanceTrackingSystem** | Live distance from the throw circle + 50 m markers |
| **UISystem** | HUD: coins, distance, charge meter, floating reward text |
| **GameManager** | Wires everything, runs the throw loop, exposes shop hooks |

---

## 📁 Folder Structure

```
ShotputForBrainrot/
├── README.md                 ← you are here
├── LICENSE                   ← MIT
├── CHANGELOG.md              ← version history
├── project.json             ← UEFN/Verse project descriptor (reference)
├── Docs/
│   ├── ARCHITECTURE.md       ← system diagram + data flow
│   ├── SETUP.md              ← step-by-step UEFN setup & how to run
│   ├── TECHNICAL.md          ← deep dive on each system + tuning
│   ├── ASSET_SPECS.md        ← stadium, ball, marker & UI asset specs
│   └── SCREENSHOTS.md        ← required screenshot/capture list
├── Verse/
│   ├── Core/
│   │   ├── GameConstants.verse   ← all tunable numbers
│   │   ├── GameTypes.verse       ← shared structs/enums/player_state
│   │   ├── BallCatalog.verse     ← Stone → Secret Ball progression
│   │   └── Localization.verse    ← string→message helper
│   ├── Physics/PhysicsSystem.verse
│   ├── Throw/ThrowSystem.verse
│   ├── Economy/EconomySystem.verse
│   ├── Shop/ShopSystem.verse
│   ├── Save/SaveSystem.verse
│   ├── Distance/DistanceTrackingSystem.verse
│   ├── UI/UISystem.verse
│   └── GameManager.verse         ← main device
├── UI/
│   └── hud_layout.md         ← HUD layout spec + widget map
├── Maps/
│   └── stadium_layout.md     ← stadium blockout & marker placement
└── Assets/
    └── asset_manifest.md     ← concrete Fortnite asset references
```

---

## 🚀 How to Run

> Full, screenshot-friendly instructions live in [`Docs/SETUP.md`](Docs/SETUP.md).

**TL;DR:**
1. Install **UEFN** via the Epic Games Launcher.
2. Create a new **blank island** project.
3. Copy the `Verse/` folder into your project and re-map module folders to match
   (`Core`, `Physics`, `Throw`, …). Run **Verse → Build Verse Code**.
4. Drag the **`game_manager`** device into the map.
5. Assign its editable fields in the Details panel: `BallProp`, `ThrowButton`,
   `ThrowCircleMarker`.
6. Build the stadium + distance markers per [`Maps/stadium_layout.md`](Maps/stadium_layout.md).
7. Press **Launch Session** to playtest.

---

## ✨ Features

- ⚡ **Charge meter** with a skill-based **perfect throw** window (+35% power, +25 coins).
- 🌍 **Custom arcade physics** — exaggerated gravity, energetic bounces, ground friction.
- 📏 **Live distance tracking** with stadium markers every **50 m**.
- 💰 **Layered economy** — distance + airtime + bounces × ball × coin-multiplier × crit.
- 🛒 **Two upgrade tracks:**
  - **Player:** Strength, Charge Speed, Crit Chance, Coin Multiplier (20 levels each).
  - **Balls:** Stone → Iron → Steel → Gold → Diamond → Rainbow → Galaxy → Cosmic → Brainrot → **Secret Ball**.
- 💾 **Save system** for coins, best distance, current ball, and every upgrade level.
- 🎨 **Clean HUD** — coins/ball (top-left), distance (top-right), charge meter (bottom-center), floating reward text (center).

---

## ⚠️ Limitations (Proof of Concept)

- **Save persistence** is in-memory in this POC. `Docs/SETUP.md` shows the exact
  `<persistable>` weak_map pattern to enable true cross-session saves in UEFN.
- **Assets are specified, not bundled.** Fortnite/UEFN assets can't be redistributed
  in a Git repo; `Assets/asset_manifest.md` lists exactly which built-in assets to use.
- **Single ball prop** is teleported per throw rather than pooling multiple balls.
- **Input model** uses a single button (tap to charge, tap to release). Hold-to-charge
  can be enabled by binding press/release separately (noted in code).
- Verse APIs under `/UnrealEngine.com/Temporary/` are subject to change across UEFN releases.

---

## 🗺️ Roadmap

- [ ] Wire real `<persistable>` save data (cross-session progression).
- [ ] Ball pooling + trail VFX per rarity tier.
- [ ] Prestige / rebirth layer (reset for permanent multipliers).
- [ ] Daily challenges + leaderboards (Verse `leaderboard_device`).
- [ ] Cosmetic throw circles and stadium themes.
- [ ] Audio: charge whine, launch boom, coin cha-ching, crit fanfare.
- [ ] Mobile-tuned UI scaling.

---

## 📝 License

MIT — see [LICENSE](LICENSE). Note: this license covers the **original code and docs**
in this repo only, **not** any Epic Games / Fortnite assets, which remain subject to
Epic's EULA and the UEFN content guidelines.

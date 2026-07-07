# 🏟️ Shotput for Brainrot

> A colorful, arcade physics **incremental tycoon** built in **UEFN** with **Verse**.
> Throw a ball to reach a **Brainrot tier**, **become** the Brainrot that spawns, then **run home** before the **Giant Brainrot** eats you. Survive and it joins your base — generating money forever. 🧠💥

![status](https://img.shields.io/badge/status-proof--of--concept-orange)
![engine](https://img.shields.io/badge/engine-UEFN-blue)
![language](https://img.shields.io/badge/language-Verse-purple)
![license](https://img.shields.io/badge/license-MIT-green)

---

## 📖 Overview

**Shotput for Brainrot** is a casual, physics-based incremental game. The entire game
is built around one addictive loop that a new player understands in under 10 seconds:

> **Throw → Reach a Brainrot tier → Become it → Run home from the Giant Brainrot → Add it to your base → Earn passive income → Upgrade → Throw farther → Repeat**

The twist that makes it sticky: **distance is not money.** How far you throw decides
*which tier of Brainrot* spawns at the landing spot — and **better Brainrots are your
long-term income source.** Each captured Brainrot pays coins *every second, forever*.

But there's a catch. The moment your ball lands you **transform into that Brainrot**,
and a **Giant Brainrot** starts chasing you. You must sprint home to your base before
it catches you:

- **Make it home** → the Brainrot joins your base and generates income forever.
- **Get caught** → you lose that Brainrot and have to throw again.

So every throw has real stakes. The excitement is always *"if I can just throw 200 m
farther, I'll unlock **Legendary** Brainrots that pay 100/s…"*

Coins (from your base's passive income) fund **player upgrades** (Strength, Charge
Speed, Crit Chance, Coin Multiplier) and a **ball progression** ladder from a humble
Stone all the way to the legendary **Secret Ball** — better balls fly farther, which
reaches higher Brainrot tiers. The visual style is intentionally loud, exaggerated,
and funny — this is arcade candy, not a physics simulator.

### 🧠 Brainrot Tiers (the real progression driver)

| Distance thrown | Brainrot tier | Passive income |
|-----------------|---------------|----------------|
| 0 – 100 m       | Common        | **$1/s**       |
| 100 – 300 m     | Uncommon      | **$3/s**       |
| 300 – 600 m     | Rare          | **$10/s**      |
| 600 – 1,000 m   | Epic          | **$30/s**      |
| 1,000 – 2,000 m | Legendary     | **$100/s**     |
| 2,000 m+        | Mythic        | **$500/s**     |
| Secret Zone     | Secret        | **$5,000/s**   |

*All thresholds and rates live in [`Verse/Core/GameConstants.verse`](Verse/Core/GameConstants.verse) — tune freely.*

### 🎯 Design Success Criteria
| Goal | Target |
|------|--------|
| Player understands the game | < 10 seconds |
| Player completes first throw | < 30 seconds |
| Player feels motivated to continue | Immediate upgrade payoff after throw #1 |

---

## 🕹️ Gameplay Loop

```
        ┌────────────────────────────────────────────────────────────────┐
        │                                                                  │
        ▼                                                                  │
  ┌───────────┐  charge   ┌──────────────┐  distance   ┌────────────────┐ │
  │  CHARGE   │ ────────► │   SIMULATE    │ ─────────► │  BRAINROT TIER  │ │
  │  METER    │ (perfect) │  BALL PHYSICS │            │  spawns @ land  │ │
  └───────────┘           └──────────────┘            └───────┬─────────┘ │
                                                              │ become it  │
                                                              ▼            │
                                                     ┌────────────────┐   │
                                                     │  GIANT BRAINROT │   │
                                                     │   CHASE HOME    │   │
                                                     │  (tap to sprint)│   │
                                                     └───────┬────────┘   │
                                            caught │          │ escaped     │
                                       (lose it) ◄─┘          ▼             │
                                                     ┌────────────────┐    │
                                                     │      BASE       │    │
                                                     │ +Brainrot, pays │    │
                                                     │   $/s forever   │    │
                                                     └───────┬────────┘    │
                                                             │ coins        │
                                                             ▼             │
                                                     ┌────────────────┐    │
                                                     │      SHOP       │────┘
                                                     │  upgrades &     │ throw farther
                                                     │    balls        │ → higher tiers
                                                     └────────────────┘
```

1. **Charge** — Tap the throw button to fill the charge meter. Release inside the
   glowing **perfect window** (top ~8%) for a big speed bonus (throw farther).
2. **Simulate** — The ball launches on a 42° arc. Gravity, bounces, and friction
   are simulated at 60 Hz for smooth arcade motion.
3. **Spawn** — The distance reached decides **which Brainrot tier** spawns at the
   landing spot. Farther = rarer, richer Brainrot. You instantly **become** it.
4. **Chase** — A **Giant Brainrot** hunts you. **Tap the throw button to sprint**
   and fill the escape bar before the timer runs out. Hungrier (higher) tiers give
   you *less* time — real risk/reward.
5. **Collect** — Reach home and the Brainrot joins your **base**, generating passive
   income **every second, forever** (plus a small welcome bonus). Get caught and it's lost.
6. **Upgrade** — Spend your accumulating coins on player upgrades or unlock a fancier
   ball that flies farther — which reaches **higher Brainrot tiers**.
7. **Repeat** — Bigger income, farther throws, rarer Brainrots, brain fully rotted.

---

## 🏗️ Architecture

The project uses a **modular, single-responsibility** architecture. The
`game_manager` device is the only object placed in the map; it owns and coordinates
nine independent subsystems. See [`Docs/ARCHITECTURE.md`](Docs/ARCHITECTURE.md) for
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
| **BrainrotSystem** | Distance→tier resolution + the Giant Brainrot chase (escape-bar race) |
| **BaseSystem** | Captured-Brainrot collection + passive income (the money source) |
| **ShopSystem** | Player upgrade purchases + ball unlock/equip |
| **SaveSystem** | Load/save `player_state` (coins, best distance, ball, upgrades, Brainrots) |
| **DistanceTrackingSystem** | Live distance from the throw circle + 50 m markers |
| **UISystem** | HUD: coins, income/s, distance, charge/escape meter, chase + reward text |
| **EconomySystem** | *(legacy/optional)* per-throw coin reward calculator — not wired into the Brainrot loop, kept for reference/re-use |
| **GameManager** | Wires everything, runs the throw→chase→collect loop, income ticker, shop hooks |

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
│   │   ├── GameConstants.verse    ← all tunable numbers (tiers, income, chase)
│   │   ├── GameTypes.verse        ← shared structs/enums/player_state
│   │   ├── BallCatalog.verse      ← Stone → Secret Ball progression
│   │   ├── BrainrotCatalog.verse  ← Brainrot tiers, distance thresholds, income
│   │   └── Localization.verse     ← string→message helper
│   ├── Physics/PhysicsSystem.verse
│   ├── Throw/ThrowSystem.verse
│   ├── Brainrot/BrainrotSystem.verse   ← tier resolution + Giant Brainrot chase
│   ├── Base/BaseSystem.verse           ← collection + passive income
│   ├── Economy/EconomySystem.verse     ← (legacy) per-throw reward calculator
│   ├── Shop/ShopSystem.verse
│   ├── Save/SaveSystem.verse
│   ├── Distance/DistanceTrackingSystem.verse
│   ├── UI/UISystem.verse
│   └── GameManager.verse          ← main device
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
   `ThrowCircleMarker` (your base/home), and `GiantBrainrotProp` (the chaser).
6. Build the stadium + distance markers per [`Maps/stadium_layout.md`](Maps/stadium_layout.md).
7. Press **Launch Session** to playtest: charge → throw → watch the Brainrot spawn →
   **tap to sprint home** → capture it → watch your income/s climb.

---

## ✨ Features

- ⚡ **Charge meter** with a skill-based **perfect throw** window (+35% power).
- 🌍 **Custom arcade physics** — exaggerated gravity, energetic bounces, ground friction.
- 📏 **Live distance tracking** with stadium markers every **50 m**.
- 🧠 **Brainrot collection loop** — every throw spawns a distance-tiered Brainrot
  (Common → Mythic + a Secret Zone) that you must bring home.
- 🏃 **Giant Brainrot chase** — after a landing you race an escape bar back to base;
  higher tiers give you less time. Escape = keep it, get caught = lose it.
- 💰 **Passive income economy** — captured Brainrots live at your **base** and generate
  coins **every second** ($1/s Common up to $5000/s Secret). Distance no longer pays
  directly; it *unlocks* better long-term earners.
- 🛒 **Two upgrade tracks** funded entirely by passive income:
  - **Player:** Strength, Charge Speed, Crit Chance, Coin Multiplier (20 levels each).
  - **Balls:** Stone → Iron → Steel → Gold → Diamond → Rainbow → Galaxy → Cosmic → Brainrot → **Secret Ball**.
- 💾 **Save system** for coins, best distance, current ball, upgrade levels, and the
  full collected-Brainrot roster.
- 🎨 **Clean HUD** — coins/ball + **live income/sec** (top-left), distance (top-right),
  charge meter (bottom-center), Brainrot-spawn + chase + capture banners (center).

---

## ⚠️ Limitations (Proof of Concept)

- **Save persistence** is in-memory in this POC. `Docs/SETUP.md` shows the exact
  `<persistable>` weak_map pattern to enable true cross-session saves in UEFN.
- **Assets are specified, not bundled.** Fortnite/UEFN assets can't be redistributed
  in a Git repo; `Assets/asset_manifest.md` lists exactly which built-in assets to use.
- **Single ball prop** is teleported per throw rather than pooling multiple balls.
- **Input model** uses a single button (tap to charge, tap to release). Hold-to-charge
  can be enabled by binding press/release separately (noted in code).
- **The Giant Brainrot chase is modeled as a skill "escape-bar" race** (tap the throw
  button to sprint the bar full before the timer runs out) rather than full character
  transformation + AI pathfinding, which UEFN's current Verse surface can't express in a
  POC. The `GiantBrainrotProp` is a cosmetic prop shown/hidden during the chase.
  `Docs/TECHNICAL.md` describes how to upgrade this to a real transform + NPC pursuer.
- **Brainrots at base are tracked as data + income**, not yet instanced as visible props
  around the base (the count and income are live; the visual "farm" is a roadmap item).
- Verse APIs under `/UnrealEngine.com/Temporary/` are subject to change across UEFN releases.

---

## 🗺️ Roadmap

- [ ] Wire real `<persistable>` save data (cross-session progression + collected roster).
- [ ] Real player→Brainrot **transformation** (skin/prop swap) on landing.
- [ ] Real **Giant Brainrot NPC** with pathfinding pursuit replacing the escape-bar race.
- [ ] Instanced **base "farm"** — captured Brainrots appear as props around your base.
- [ ] Ball pooling + trail VFX per rarity tier.
- [ ] Prestige / rebirth layer (reset for permanent multipliers).
- [ ] Daily challenges + leaderboards (Verse `leaderboard_device`).
- [ ] Audio: charge whine, launch boom, chase heartbeat, capture fanfare, income cha-ching.
- [ ] Mobile-tuned UI scaling.

---

## 📝 License

MIT — see [LICENSE](LICENSE). Note: this license covers the **original code and docs**
in this repo only, **not** any Epic Games / Fortnite assets, which remain subject to
Epic's EULA and the UEFN content guidelines.

# Changelog

All notable changes to **Shotput for Brainrot** are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] — 2026-07-07
### Added — Brainrot Collection & Giant Brainrot Chase
- **BrainrotCatalog** (`Core/BrainrotCatalog.verse`): 7 distance-gated tiers —
  Common ($1/s), Uncommon ($3/s), Rare ($10/s), Epic ($30/s), Legendary ($100/s),
  Mythic ($500/s), and the Secret Zone ($5000/s) — with `GetTierForDistance()` and
  `GetBrainrotByTier()` lookups.
- **BrainrotSystem** (`Brainrot/BrainrotSystem.verse`): resolves the spawned tier from
  landing distance and runs the **Giant Brainrot chase** as a timed escape-bar race
  (per-tier countdown, bar decay, tap-to-sprint) returning a `chase_outcome`.
- **BaseSystem** (`Base/BaseSystem.verse`): the player's home base — `AddBrainrot`,
  `TotalIncomePerSecond`, `TotalBrainrotCount`, and `ApplyIncomeTick` for passive coins.
- **Passive income economy**: captured Brainrots generate coins **every second** via a
  `RunIncomeTicker` loop in GameManager; the HUD shows a live **income/sec** readout.
- **New game types**: `brainrot_tier` enum, `brainrot_def` struct, `chase_outcome`
  struct, and a `CollectedBrainrots` roster (+`GetBrainrotCount()`) on `player_state`.
- **UI additions**: income readout plus Brainrot-spawn, chase-progress, and
  capture-result banners (`UpdateIncome`, `ShowBrainrotSpawn`, `UpdateChase`,
  `ShowCaptureResult`).
- **GameManager rewrite of throw steps 5–9**: spawn tier → become it → chase home →
  capture (added to base + income) or lose it, then persist the roster.
- **Tuning constants** for tier thresholds, income rates, chase timing, income tick
  period, capture bonus, and banner duration (`Core/GameConstants.verse`).

### Changed
- **Distance no longer pays coins directly** — it now *unlocks access* to higher-tier
  Brainrots, which become long-term passive income. This matches the intended loop.
- `EconomySystem` is retained as **legacy/unused** (per-throw coin model) and is no
  longer wired into the loop; it's kept for reference and possible reuse.
- `project.json` bumped to **0.2.0** with the new Brainrot/Base modules and the
  `GiantBrainrotProp` editable reference; description/genre updated.
- Documentation refreshed: README, ARCHITECTURE, TECHNICAL, and asset specs now cover
  the collection loop, chase, and passive economy.

## [0.1.0] — 2026-07-07
### Added — Initial Proof of Concept
- **Core loop**: charge → throw → simulate → reward → upgrade → repeat.
- **PhysicsSystem**: fixed-timestep (60 Hz) ballistic simulation with gravity,
  bounce restitution, ground friction, and rest detection.
- **ThrowSystem**: charge meter (0–100%), configurable charge duration, perfect-throw
  window with power bonus, launch angle + speed mapping, Strength/ChargeSpeed upgrades.
- **EconomySystem**: coin reward from distance + airtime + bounces, ball bonus,
  Coin Multiplier upgrade, and rollable critical hit; returns a detailed breakdown.
- **ShopSystem**: geometric-cost player upgrades (Strength, Charge Speed, Crit Chance,
  Coin Multiplier, 20 levels) and ball unlock/equip against the catalog.
- **SaveSystem**: in-memory `player_state` store (coins, best distance, current ball,
  unlocked balls, upgrade levels) with best-distance recording and reset.
- **DistanceTrackingSystem**: live peak distance from the throw circle, 50 m marker
  detection, and marker position generation for stadium building.
- **UISystem**: UMG-in-Verse HUD — top-left coins/ball, top-right distance/best,
  bottom-center charge meter (with perfect-window flash), center floating reward text.
- **GameManager**: single placeable `creative_device` that wires all systems, handles
  player join, drives the throw cycle, and exposes shop hooks.
- **BallCatalog**: 10-tier progression Stone → Iron → Steel → Gold → Diamond →
  Rainbow → Galaxy → Cosmic → Brainrot → Secret Ball.
- **Documentation**: README, ARCHITECTURE, SETUP, TECHNICAL, ASSET_SPECS, SCREENSHOTS,
  HUD layout, stadium layout, and asset manifest.
- **Project descriptor** (`project.json`) and MIT LICENSE.

### Known Limitations
- Save persistence is in-memory; persistable weak_map wiring documented in SETUP.md.
- Assets are specified via manifests rather than bundled (Epic content cannot be redistributed).

## [Unreleased]
### Planned
- Persistable cross-session save data.
- Ball pooling, per-rarity trail VFX, and audio.
- Prestige/rebirth layer, daily challenges, and leaderboards.

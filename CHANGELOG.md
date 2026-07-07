# Changelog

All notable changes to **Shotput for Brainrot** are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

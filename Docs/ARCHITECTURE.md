# Architecture — Shotput for Brainrot

This document describes how the game is structured, how data flows through a single
throw, and why the code is organized the way it is.

## Design Principles

1. **One device, many systems.** Only `game_manager` (a `creative_device`) is placed
   in the map. Everything else is a plain Verse `class` it constructs and owns. This
   keeps the UEFN map clean and makes the code testable outside the editor.
2. **Single responsibility.** Each system does exactly one job and exposes a small,
   typed API. Systems never reach into each other's internals.
3. **Side-effect isolation.** `EconomySystem` and most of `PhysicsSystem`/`ThrowSystem`
   are pure calculators. Only `GameManager` and `SaveSystem` mutate shared player state.
4. **Data-driven tuning.** Every balance number lives in `Core/GameConstants.verse`
   and every ball in `Core/BallCatalog.verse`. Designers rebalance without touching logic.

## Module / Dependency Graph

```
                         ┌───────────────────────────┐
                         │        GameManager         │
                         │      (creative_device)      │
                         └──────────────┬─────────────┘
      owns & coordinates ───────────────┼──────────────────────────────
        │           │          │        │        │          │         │
        ▼           ▼          ▼        ▼        ▼          ▼         ▼
   ThrowSystem  PhysicsSystem Economy  Shop   Distance   SaveSystem  UISystem
        │           │        System   System  Tracking      │          │
        │           │          │        │        │          │          │
        └───────────┴──────────┴────────┴────────┴──────────┴──────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │   Core (shared, no deps up)     │
                    │  GameConstants · GameTypes ·    │
                    │  BallCatalog · Localization      │
                    └───────────────────────────────┘
```

**Dependency rule:** arrows point *downward only*. Core depends on nothing in the
game; systems depend on Core; the GameManager depends on systems. No cycles.

## Data Flow — Anatomy of One Throw

```
 Player taps ThrowButton
        │
        ▼
 GameManager.OnThrowPressed ──► spawn RunThrowCycle(player)
        │
        │ 1. CHARGE
        ▼
 ThrowSystem.BeginCharge / UpdateCharge(dt, chargeSpeedLvl)
        │  └─► UISystem.UpdateChargeMeter(percent, inPerfectWindow)   [every tick]
        │
        │ 2. RELEASE
        ▼
 ThrowSystem.ReleaseCharge(strengthLvl, yaw) ──► launch_params{speed, dir, wasPerfect}
        │
        │ 3. SIMULATE
        ▼
 PhysicsSystem.Launch(origin, speed, dir, bounceMult, wasPerfect)   [suspends ~60Hz]
        │  └─► teleports BallProp each tick; DistanceTracking.Update feeds HUD
        │  returns ──► throw_result{distanceM, airtimeS, bounces, wasPerfect}
        │
        │ 4. SCORE
        ▼
 EconomySystem.CalculateReward(result, ballCoinMult, coinMultLvl, critLvl)
        │  returns ──► reward_breakdown{..., wasCrit, total}
        │
        │ 5. APPLY + PERSIST
        ▼
 player_state.Coins += reward.Total
 SaveSystem.TryRecordBestDistance / Save
 UISystem.ShowReward(total, perfect, crit)  ──►  clears after 2s
        │
        ▼
 Player spends coins ──► GameManager.BuyUpgrade / BuyBall / EquipBall
        │                      └─► ShopSystem mutates player_state, SaveSystem.Save
        └───────────────────────────────► loop back to a farther throw
```

## Key Types (see `Core/GameTypes.verse`)

| Type | Purpose |
|------|---------|
| `player_state` (class) | The mutable per-player profile: coins, best distance, current ball, owned balls, upgrade levels. |
| `ball_def` (struct) | Static ball definition: name, rarity, unlock cost, speed/bounce/coin multipliers. |
| `throw_result` (struct) | Output of a physics simulation: distance, airtime, bounces, perfect flag. |
| `launch_params` (struct) | Output of a charge release: speed, direction, perfect flag. |
| `reward_breakdown` (struct) | Itemized coin reward for UI + debugging. |
| `player_upgrade_kind` (enum) | Strength / ChargeSpeed / CritChance / CoinMultiplier. |
| `purchase_result` (enum) | Success / NotEnoughCoins / MaxLevelReached / AlreadyOwned / InvalidTarget. |

## Concurrency Model

- `RunThrowCycle` is a `suspends` function run via `spawn`, so each player's throw is
  an independent async task. The physics `Launch` loop `Sleep`s one physics tick between
  integration steps.
- A per-player `BusyPlayers` map prevents overlapping throws for the same player.
- All state mutation happens on the game simulation thread (Verse is cooperative), so
  no locks are required.

## Why folders map to modules

In UEFN, a Verse **module** corresponds to a **folder** inside the project's Verse
content. Each system lives in its own folder so its `using { … }` name is stable and
its files are discoverable. `Core/` holds dependency-free shared code that every other
module imports. See `Docs/SETUP.md` for the exact folder → module mapping you must
reproduce inside UEFN.

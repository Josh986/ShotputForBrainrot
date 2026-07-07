# Architecture — Shotput for Brainrot

This document describes how the game is structured, how data flows through a single
throw, and why the code is organized the way it is.

## Design Principles

1. **One device, many systems.** Only `game_manager` (a `creative_device`) is placed
   in the map. Everything else is a plain Verse `class` it constructs and owns. This
   keeps the UEFN map clean and makes the code testable outside the editor.
2. **Single responsibility.** Each system does exactly one job and exposes a small,
   typed API. Systems never reach into each other's internals.
3. **Side-effect isolation.** Most of `PhysicsSystem`/`ThrowSystem`/`BrainrotSystem`
   are pure calculators. Shared player state is mutated only by `GameManager`,
   `SaveSystem`, and `BaseSystem` (which owns the per-player Brainrot roster + income).
4. **Data-driven tuning.** Every balance number lives in `Core/GameConstants.verse`,
   every ball in `Core/BallCatalog.verse`, and every Brainrot tier in
   `Core/BrainrotCatalog.verse`. Designers rebalance without touching logic.
5. **Distance is an unlock, not a payout.** Landing distance selects which Brainrot
   *tier* spawns; passive income from captured Brainrots is the only coin source.

## Module / Dependency Graph

```
                         ┌───────────────────────────┐
                         │        GameManager         │
                         │      (creative_device)      │
                         └──────────────┬─────────────┘
      owns & coordinates ───────────────┼──────────────────────────────────────
     │        │        │        │        │        │        │        │        │
     ▼        ▼        ▼        ▼        ▼        ▼        ▼        ▼        ▼
  Throw    Physics  Brainrot   Base     Shop   Distance  Save     UI    (Economy
  System   System   System    System   System  Tracking System  System   *legacy*)
     │        │        │        │        │        │        │        │
     └────────┴────────┴────────┴────────┴────────┴────────┴────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────────┐
                    │     Core (shared, no deps up)        │
                    │  GameConstants · GameTypes ·         │
                    │  BallCatalog · BrainrotCatalog ·     │
                    │  Localization                        │
                    └───────────────────────────────────┘
```

**Dependency rule:** arrows point *downward only*. Core depends on nothing in the
game; systems depend on Core; the GameManager depends on systems. No cycles.
`EconomySystem` is retained as legacy reference code and is no longer wired in — the
active coin source is `BaseSystem`'s passive income.

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
        │ 4. SPAWN TIER  (distance → Brainrot tier, NOT coins)
        ▼
 BrainrotSystem.ResolveTier(distanceM) ──► brainrot_def{tier, name, incomePerSec}
        │  └─► UISystem.ShowBrainrotSpawn(def.Name)   ("You are now a <Brainrot>!")
        │
        │ 5. GIANT BRAINROT CHASE  (race home)
        ▼
 GameManager.RunChase(player, def)   [suspends; drives BrainrotSystem each tick]
        │  ├─ BrainrotSystem.BeginChase(def) → Tick(dt) loop → IsResolved()
        │  ├─ taps routed via ChasingPlayers → BrainrotSystem.RegisterTap()
        │  └─► UISystem.UpdateChase(escapeProgress, secondsLeft)   [every tick]
        │  returns ──► BrainrotSystem.GetOutcome() = chase_outcome{escaped, tier}
        │
        │ 6. CAPTURE or LOSE + PERSIST
        ▼
 escaped? ─► BaseSystem.AddBrainrot(state, def.Tier)      (roster[tier] += 1)
        │    player_state.Coins += round(incomePerSec · CaptureBonusSeconds)  (one-time)
        │    UISystem.ShowCaptureResult(true, def.Name, def.IncomePerSecond)
        │  caught? ─► nothing added; UISystem.ShowCaptureResult(false, def.Name, 0)
        │    SaveSystem.Save(player_state)  (coins, best distance, roster)
        │
        │  ── meanwhile, independently ──
        ▼
 RunIncomeTicker (spawned once at OnBegin)  every PassiveIncomeTickPeriod:
        BaseSystem.ApplyIncomeTick(state)  → player_state.Coins += income · period
        UISystem.UpdateIncome(TotalIncomePerSecond, TotalBrainrotCount)
        │
        ▼
 Player spends coins ──► GameManager.BuyUpgrade / BuyBall / EquipBall
        │                      └─► ShopSystem mutates player_state, SaveSystem.Save
        └───────────────────────────────► loop back to a farther throw → better tier
```

## Key Types (see `Core/GameTypes.verse`)

| Type | Purpose |
|------|---------|
| `player_state` (class) | The mutable per-player profile: coins, best distance, current ball, owned balls, upgrade levels, and the collected-Brainrot roster (`GetBrainrotCount()`). |
| `ball_def` (struct) | Static ball definition: name, rarity, unlock cost, speed/bounce/coin multipliers. |
| `brainrot_tier` (enum) | Common / Uncommon / Rare / Epic / Legendary / Mythic / Secret. |
| `brainrot_def` (struct) | Static Brainrot definition: tier, name, min distance, income/sec. |
| `chase_outcome` (struct) | Result of a Giant Brainrot chase: `Escaped` flag + `Tier`. |
| `throw_result` (struct) | Output of a physics simulation: distance, airtime, bounces, perfect flag. |
| `launch_params` (struct) | Output of a charge release: speed, direction, perfect flag. |
| `reward_breakdown` (struct) | Itemized coin reward (used by the legacy EconomySystem). |
| `player_upgrade_kind` (enum) | Strength / ChargeSpeed / CritChance / CoinMultiplier. |
| `purchase_result` (enum) | Success / NotEnoughCoins / MaxLevelReached / AlreadyOwned / InvalidTarget. |

## Concurrency Model

- `RunThrowCycle` is a `suspends` function run via `spawn`, so each player's throw is
  an independent async task. The physics `Launch` loop `Sleep`s one physics tick between
  integration steps.
- `RunChase` (Giant Brainrot race) is likewise a `suspends` loop inside the throw cycle;
  it ticks the escape bar down/up against a countdown and reads the player's taps.
- `RunIncomeTicker` is a separate long-lived `spawn`ed loop started at `OnBegin` that
  `Sleep`s `PassiveIncomeTickPeriod` and credits every player's base income each cycle.
- A per-player `BusyPlayers` map prevents overlapping throws; a `ChasingPlayers`
  `[player]logic` map routes throw-button taps to the active chase instead of a new throw.
- All state mutation happens on the game simulation thread (Verse is cooperative), so
  no locks are required.

## Why folders map to modules

In UEFN, a Verse **module** corresponds to a **folder** inside the project's Verse
content. Each system lives in its own folder so its `using { … }` name is stable and
its files are discoverable. `Core/` holds dependency-free shared code that every other
module imports. See `Docs/SETUP.md` for the exact folder → module mapping you must
reproduce inside UEFN.

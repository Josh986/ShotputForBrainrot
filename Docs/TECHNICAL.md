# Technical Deep Dive — Shotput for Brainrot

A per-system reference covering algorithms, formulas, tuning knobs, and extension
points. All tuning constants referenced here live in `Verse/Core/GameConstants.verse`.

> **Units.** World space is in **centimeters** (UEFN default). Distances shown to the
> player are **meters** (1 m = 100 cm). Time is in **seconds**.

---

## PhysicsSystem (`Verse/Physics/PhysicsSystem.verse`)

**Integration.** Semi-implicit (symplectic) Euler at a fixed `PhysicsTickPeriod`
(0.0166 s ≈ 60 Hz):

```
v.z ← v.z − GravityAcceleration · dt
p   ← p + v · dt
```

**Bounce.** When `p.z ≤ groundZ`:

```
bounces      += 1
v.x, v.y     ← v.x, v.y · GroundFriction     # horizontal energy loss
v.z          ← |v.z| · (BounceRestitution · ballBounceMult)   # reflect + dampen
p.z          ← groundZ                        # clamp to field
```

**Rest detection.** The throw ends when the ball is on the ground
(`p.z ≤ groundZ + 5`) **and** `speed(v) < RestSpeedThreshold`. `Launch` is a
`suspends` function: it loops, stepping + sleeping one tick, until rest, then returns a
`throw_result`.

**Tuning:**
| Constant | Effect |
|----------|--------|
| `GravityAcceleration` | Higher = shorter, snappier arcs. |
| `BounceRestitution` | Higher = livelier, longer-rolling bounces. |
| `GroundFriction` | Lower = ball stops sooner after landing. |
| `RestSpeedThreshold` | Higher = throws end sooner. |

**Extension ideas:** wind (add constant to horizontal accel), air drag
(`v *= (1 − drag·dt)`), spin/Magnus, or terrain height sampling for hills.

---

## ThrowSystem (`Verse/Throw/ThrowSystem.verse`)

**Charge.** A normalized `Charge ∈ [0,1]` accumulates over an effective duration:

```
duration = BaseChargeDuration / (1 + ChargeSpeedPerLevel · chargeSpeedLevel)
charge   = clamp(elapsed / duration, 0, 1)     # holds at 1.0 (no overshoot to 0)
```

**Release → speed.**

```
baseSpeed   = MinLaunchSpeed + (MaxLaunchSpeed − MinLaunchSpeed) · charge
perfect     = charge ≥ PerfectThrowWindowStart              # top ~8%
perfectMult = perfect ? PerfectThrowBonusMultiplier : 1
strength    = 1 + StrengthPerLevel · strengthLevel
finalSpeed  = baseSpeed · perfectMult · strength
```

**Direction.** From a horizontal `yaw` and the fixed `LaunchAngleDegrees` pitch:

```
pitch = rad(LaunchAngleDegrees)
dir   = ( cos(pitch)·cos(yaw), cos(pitch)·sin(yaw), sin(pitch) )   # unit vector
```

`LaunchAngleDegrees = 42°` is near the vacuum-optimal 45° but tuned down slightly for
the game's bounce model. UI reads `GetChargePercent()` and `IsInPerfectWindow()`.

---

## EconomySystem (`Verse/Economy/EconomySystem.verse`) — *legacy, not wired in*

> ⚠️ **As of v0.2.0 this system is retained for reference only.** Coins now come from
> passive Brainrot income (see **BaseSystem** below), so `CalculateReward` is no longer
> called by `GameManager`. It's kept because the per-throw reward math is a useful base
> for optional bonuses and is fully unit-testable.

Pure function `CalculateReward` → `reward_breakdown`:

```
distanceCoins = round(distanceM  · CoinsPerMeter)
airtimeCoins  = round(airtimeS   · CoinsPerAirtimeSecond)
bounceCoins   = bounces          · CoinsPerBounce
perfectBonus  = wasPerfect ? PerfectThrowCoinBonus : 0
subtotal      = distanceCoins + airtimeCoins + bounceCoins + perfectBonus

coinMult      = 1 + CoinMultPerLevel · coinMultLevel
boosted       = subtotal · ballCoinMult · coinMult

critChance    = CritChancePerLevel · critChanceLevel        # clamped [0,1]
wasCrit       = rand(0,1) < critChance
total         = round(boosted · (wasCrit ? CritRewardMultiplier : 1))
```

The breakdown is itemized so the HUD can explain the reward and so values are easy to
unit test. `GetRandomFloat` comes from `/Verse.org/Random`.

---

## BrainrotCatalog (`Verse/Core/BrainrotCatalog.verse`)

Static, data-driven tier table built by `MakeBrainrotCatalog()`. Each `brainrot_def`
carries a `Tier`, display `Name`, `MinDistanceMeters` gate, and `IncomePerSecond`.
Two pure lookups:

```
GetTierForDistance(catalog, distanceM)<transacts> : brainrot_def
    # walks strongest→weakest, returns the best tier whose MinDistanceMeters ≤ distanceM
    # (falls back to Common so a throw always spawns something)
GetBrainrotByTier(catalog, tier)<computes> : brainrot_def
```

| Tier | Distance gate | Income |
|------|---------------|--------|
| Common | 0–100 m | $1/s |
| Uncommon | 100–300 m | $3/s |
| Rare | 300–600 m | $10/s |
| Epic | 600–1000 m | $30/s |
| Legendary | 1000–2000 m | $100/s |
| Mythic | 2000 m+ | $500/s |
| Secret | Secret Zone | $5000/s |

All numbers (distance thresholds + income rates) live in `Core/GameConstants.verse` so
the whole progression is tunable in one place. The chase difficulty per tier is derived
separately in `BrainrotSystem` (see below), not stored on the `brainrot_def`.

---

## BrainrotSystem (`Verse/Brainrot/BrainrotSystem.verse`)

Owns tier resolution and the **Giant Brainrot chase** state machine. It holds one race
at a time (`EscapeProgress` 0→1, `TimeRemaining`, `ActiveTier`, `Running`) and is driven
tick-by-tick by `GameManager.RunChase` (a `suspends` loop), which keeps the race pure and
testable. API:

- `ResolveTier(distanceM)<transacts> : brainrot_def` — maps a landing distance to the
  Brainrot you become (delegates to `GetTierForDistance`).
- `BeginChase(def)` — starts a race: resets the escape bar to 0, sets `TimeRemaining` to
  `ComputeChaseTime(def.Tier)`, flips `Running` on.
- `Tick(dt)` — advances one step: `EscapeProgress -= ChaseDecayPerSecond·dt` (floored at
  0), `TimeRemaining -= dt`; resolves (`Running := false`) if the bar hit 1.0 or time hit 0.
- `RegisterTap()` — the sprint input: `EscapeProgress += ChaseTapProgress` (capped at 1.0).
- `IsResolved()<transacts> : logic` / `GetOutcome()<transacts> : chase_outcome` —
  finished? and the result (`Escaped := EscapeProgress ≥ 1.0`, plus `Tier`).
- `GetEscapeProgress()` / `GetTimeRemaining()` / `GetActiveTier()` — `<transacts>` HUD reads.

`GameManager.RunChase` loop (simplified):

```
BrainrotSystem.BeginChase(def)
loop:
    Sleep(ChaseTickPeriod)
    BrainrotSystem.Tick(ChaseTickPeriod)
    UI.UpdateChase(GetEscapeProgress(), GetTimeRemaining())
    if BrainrotSystem.IsResolved()? { break }
return BrainrotSystem.GetOutcome()
```

Taps are delivered by `RegisterTap()`, which `GameManager` calls when the throw button is
pressed *during* a chase (routed via the `ChasingPlayers` map instead of starting a new
throw). The per-tier escape window is `ComputeChaseTime(tier) =
max(ChaseMinTimeSeconds, ChaseBaseTimeSeconds − ChaseTimePenaltyPerTier · tierIndex)`, so
richer (higher-index) Brainrots give you less time and are genuinely harder to bring home.

> **Upgrading to a real chase.** Replace the bar race with (a) a player→Brainrot
> transform (skin/prop swap on landing) and (b) a `npc_spawner`-driven Giant Brainrot
> that pathfinds to the player; escape = reach the base volume before contact. The
> `chase_outcome` contract stays the same, so `GameManager` needs no changes.

---

## BaseSystem (`Verse/Base/BaseSystem.verse`)

The player's **home base** — the persistent collection and the only coin source. It's
stateless w.r.t. players: every method operates on the `player_state` it's handed, so
`SaveSystem` stays the single source of truth. It holds an injected `Catalog` to convert
collected tiers → income rates.

- `AddBrainrot(state, tier)` — increments `state.CollectedBrainrots[tier]` (the roster is
  a `[brainrot_tier]int` count map on `player_state`).
- `TotalIncomePerSecond(state)<transacts> : int` — sums `IncomePerSecond × count` across
  every tier in the catalog.
- `TotalBrainrotCount(state)<transacts> : int` — total captured, for the HUD.
- `ApplyIncomeTick(state) : int` — credits `round(TotalIncomePerSecond ·
  PassiveIncomeTickPeriod)` coins and returns the payout; called by
  `GameManager.RunIncomeTicker` every `PassiveIncomeTickPeriod`. Scaling by the period
  means changing the tick cadence doesn't change the effective rate.

---

## ShopSystem (`Verse/Shop/ShopSystem.verse`)

**Player upgrade cost curve** (geometric):

```
cost(level) = floor( BaseUpgradeCost · UpgradeCostGrowth ^ level )
```

With defaults (`Base=50`, `Growth=1.55`): 50, 77, 120, 186, 288, … per level, capped at
`MaxUpgradeLevel = 20`. `PurchaseUpgrade` validates coins + cap, deducts, bumps the level.

**Balls.** `PurchaseBall` checks ownership + coins against `ball_def.UnlockCost`, then
appends to `UnlockedBallIds`. `EquipBall` sets `CurrentBallId` if owned. All return a
`purchase_result` enum so the UI can show the right message.

---

## SaveSystem (`Verse/Save/SaveSystem.verse`)

POC uses an in-memory `[player]player_state` map. API: `Load` (creates default on first
play), `Save`, `TryRecordBestDistance` (returns true on a new record so UI can
celebrate), and `ResetProgress`. See `SETUP.md` §7 for swapping in a persistable
`weak_map(player, saved_profile)` for real cross-session saves.

---

## DistanceTrackingSystem (`Verse/Distance/DistanceTrackingSystem.verse`)

Tracks the **peak** horizontal (XY) distance from the throw circle so a ball rolling
backward after a bounce never lowers the score:

```
meters = |ball.xy − circle.xy| / 100
current = max(current, meters)
```

`GetLastPassedMarker` = `floor(current / 50) · 50`. `GenerateMarkerPositions` emits a
world position every `MarkerIntervalMeters` up to `StadiumLengthMeters` for stadium
building.

---

## UISystem (`Verse/UI/UISystem.verse`)

UMG-in-Verse (`/UnrealEngine.com/Temporary/UI` + `/Fortnite.com/UI`). A `canvas` with
four anchored slots (see `UI/hud_layout.md`):

| Widget | Anchor | Update method |
|--------|--------|---------------|
| Coins + Ball + **Income/sec** (`text_block` ×3) | top-left | `UpdateCoins(coins, ballName)` · `UpdateIncome(perSec, totalBrainrots)` |
| Distance + Best (`text_block` ×2) | top-right | `UpdateDistance(cur, best)` |
| Charge meter (`progress_bar`) | bottom-center | `UpdateChargeMeter(pct, inPerfect)` — flashes lime in the perfect window |
| Center banner (`text_block`) | center | `ShowBrainrotSpawn(def)` · `UpdateChase(barPct, secsLeft)` · `ShowCaptureResult(escaped, def)` · `ShowReward(...)` / `ClearReward()` |

Dynamic strings become `message` values via `Core/Localization.verse`'s `ToMessage`.
The center banner is reused across the throw lifecycle: spawn announcement → live chase
progress → capture/lose result, each clearing after `BannerDisplaySeconds`.

---

## GameManager (`Verse/GameManager.verse`)

The only placed `creative_device`. `OnBegin` builds the shop (injecting the catalog) and
the Brainrot/Base systems, initializes physics + distance from the throw-circle marker,
subscribes to the throw button and player-join events, and `spawn`s `RunIncomeTicker`
(the passive coin loop). `RunThrowCycle` (spawned per press, guarded by `BusyPlayers`)
now runs charge → release → simulate → **spawn tier → chase home → capture/lose → save**.
While a chase is active the player's throw-button taps are routed to
`Brainrot.RegisterTap()` via the `ChasingPlayers` map instead of starting a new throw.
`BuyUpgrade` / `BuyBall` / `EquipBall` remain public hooks that map button devices call.

### Balancing Cheat-Sheet
| Want… | Change |
|-------|--------|
| Longer throws | ↑ `MaxLaunchSpeed`, ↓ `GravityAcceleration` |
| Reach a tier sooner | ↓ that tier's `MinDistanceMeters` (BrainrotCatalog) |
| Faster passive income | ↑ tier `IncomePerSecond`, ↓ `PassiveIncomeTickPeriod` |
| Easier chases | ↑ `ChaseSeconds` / `ChaseTapGain`, ↓ `ChaseDecayPerSecond` |
| Harder high-tier captures | ↓ high-tier `ChaseSeconds` |
| Faster progression | ↓ `UpgradeCostGrowth`, ↓ ball `UnlockCost`s |
| Bigger capture head-start | ↑ `CaptureBonusSeconds` (one-time welcome income) |
| Rewarding skill | ↑ `PerfectThrowBonusMultiplier`, ↑ `ChaseTapGain` |

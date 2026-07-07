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

## EconomySystem (`Verse/Economy/EconomySystem.verse`)

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
| Coins + Ball (`text_block` ×2) | top-left | `UpdateCoins(coins, ballName)` |
| Distance + Best (`text_block` ×2) | top-right | `UpdateDistance(cur, best)` |
| Charge meter (`progress_bar`) | bottom-center | `UpdateChargeMeter(pct, inPerfect)` — flashes lime in the perfect window |
| Reward (`text_block`) | center | `ShowReward(coins, perfect, crit)` / `ClearReward()` |

Dynamic strings become `message` values via `Core/Localization.verse`'s `ToMessage`.

---

## GameManager (`Verse/GameManager.verse`)

The only placed `creative_device`. `OnBegin` builds the shop (injecting the catalog),
initializes physics + distance from the throw-circle marker, subscribes to the throw
button and player-join events. `RunThrowCycle` (spawned per press, guarded by
`BusyPlayers`) executes the full charge → release → simulate → reward → save sequence.
`BuyUpgrade` / `BuyBall` / `EquipBall` are public hooks that map button devices call.

### Balancing Cheat-Sheet
| Want… | Change |
|-------|--------|
| Longer throws | ↑ `MaxLaunchSpeed`, ↓ `GravityAcceleration` |
| More coins early | ↑ `CoinsPerMeter` / `CoinsPerBounce` |
| Faster progression | ↓ `UpgradeCostGrowth`, ↓ ball `UnlockCost`s |
| Rewarding skill | ↑ `PerfectThrowBonusMultiplier` / `PerfectThrowCoinBonus` |
| Slower, grindier economy | ↑ `UpgradeCostGrowth`, ↓ `CoinMultPerLevel` |

# Stadium Layout — Shotput for Brainrot

Blockout guide for building the playable map in UEFN. Coordinates are in centimeters;
the runway runs along **+X** from the throw circle. 1 m = 100 cm.

## Top-Down Blockout

```
        Y
        ▲
        │      side rail (bumper) ──────────────────────────────────►
        │
   ┌────┴────┐   50m   100m  150m  200m ...                    2000m
   │ THROW   │    │      │     │     │                            │
   │ CIRCLE  ●────┼──────┼─────┼─────┼───────── runway ───────────┼──►  X
   │ (0,0)   │    │      │     │     │                            │
   └────┬────┘  marker markers ...                          end banner
        │
        │      side rail (bumper) ──────────────────────────────────►
        │
   SHOP ZONE (behind the circle, −X): upgrade + ball-unlock buttons
```

## Key Placements

| Object | Location (cm) | Notes |
|--------|---------------|-------|
| **Throw circle marker** | `(0, 0, 0)` | Assign to `game_manager.ThrowCircleMarker`. Launch origin = this + `LaunchHeight` (120 cm). |
| **Ball prop spawn** | `(0, 0, 120)` | Assign to `game_manager.BallProp`. |
| **Throw button** | `(-200, 0, 0)` | Assign to `game_manager.ThrowButton`; within reach of the circle. |
| **Distance markers** | `(50m·i·100, 0, 0)` for i=1..40 | Every 5000 cm to 2000 m. Positions match `DistanceTrackingSystem.GenerateMarkerPositions()`. |
| **Milestone banners** | every 500 m | Larger arches; color shift bronze→silver→gold→rainbow. |
| **Side rails** | along ±Y at the runway edges | Low bumpers to frame distance visually. |
| **Shop buttons** | behind circle (−X) | One `button_device` per upgrade/ball, each calling a `game_manager` hook. |

## Runway Dimensions

| Property | Value |
|----------|-------|
| Length | ≥ 200,000 cm (2000 m) — covers late-game balls |
| Width | ~1,500–2,500 cm (15–25 m) — generous, readable |
| Ground Z | 0 cm (flat). `PhysicsSystem` uses `groundZ = originZ − LaunchHeight`. |
| Marker spacing | 5,000 cm (50 m) |

## Shop Zone Wiring

Place a `button_device` for each action and, in its `InteractedWithEvent`, call the
matching `game_manager` hook with the interacting player:

| Button | Calls |
|--------|-------|
| "Upgrade Strength" | `BuyUpgrade(player, player_upgrade_kind.Strength)` |
| "Upgrade Charge Speed" | `BuyUpgrade(player, player_upgrade_kind.ChargeSpeed)` |
| "Upgrade Crit Chance" | `BuyUpgrade(player, player_upgrade_kind.CritChance)` |
| "Upgrade Coin Multiplier" | `BuyUpgrade(player, player_upgrade_kind.CoinMultiplier)` |
| "Buy <Ball>" | `BuyBall(player, ballId)` |
| "Equip <Ball>" | `EquipBall(player, ballId)` |

> In UEFN you typically add a thin wrapper device that references `game_manager` and
> forwards these button events, since `button_device` events pass an `agent` you cast
> to `player`.

## Decor Checklist (see Docs/ASSET_SPECS.md)

- [ ] Bright turf material on runway
- [ ] Glowing throw-circle ring
- [ ] Colorful bleachers + crowd behind the circle
- [ ] Balloons / pennants for arcade vibe
- [ ] High-key lighting, bright skybox
- [ ] Distance signs with large bold numbers

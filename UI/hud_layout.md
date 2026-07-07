# HUD Layout — Shotput for Brainrot

Exact widget layout for `Verse/UI/UISystem.verse`. All slots live on a single
full-screen `canvas` added to each player's HUD via `GetPlayerUI[player].AddWidget`.

## Screen Map

```
┌───────────────────────────────────────────────────────────────┐
│ ┌───────────────┐                            ┌───────────────┐ │
│ │  1,240 coins  │  ← top-left cluster        │      337 m    │ │
│ │  Ball: Gold   │                            │  Best: 512 m  │ │  ← top-right cluster
│ └───────────────┘                            └───────────────┘ │
│                                                                 │
│                                                                 │
│                       ┌─────────────────┐                       │
│                       │  +1,240 coins!  │  ← center reward pop  │
│                       └─────────────────┘                       │
│                                                                 │
│                                                                 │
│                   ▂▂▂▂▂▂▂▂▂▂▓▓▓▓▓▓▓░░░  ← charge meter          │
│                   (bottom-center, above safe zone)              │
└───────────────────────────────────────────────────────────────┘
```

## Slot Specification

| Slot | Widget(s) | Anchor (min=max) | Alignment | Offset (px) |
|------|-----------|------------------|-----------|-------------|
| Coins/Ball | `stack_box(vertical)` of `CoinsText`, `BallText` | (0.0, 0.0) top-left | (0,0) | L40, T40 |
| Distance/Best | `stack_box(vertical)` of `DistanceText`, `BestText` | (1.0, 0.0) top-right | (1,0) | R40, T40 |
| Charge meter | `progress_bar` `ChargeBar` | (0.5, 1.0) bottom-center | (0.5,1) | B60 |
| Reward | `text_block` `RewardText` | (0.5, 0.4) center-ish | (0.5,0.5) | — |

## Widget State & Update Methods

| Widget | Field | Updated by | When |
|--------|-------|-----------|------|
| `CoinsText` | coins total | `UpdateCoins(coins, ballName)` | on coin change / join |
| `BallText` | equipped ball name | `UpdateCoins(...)` | on equip / join |
| `DistanceText` | live/final distance | `UpdateDistance(cur, best)` | each physics tick + on land |
| `BestText` | best distance | `UpdateDistance(cur, best)` | on land / new record |
| `ChargeBar` | fill 0..1 + color | `UpdateChargeMeter(pct, inPerfect)` | each charge tick |
| `RewardText` | reward string + color | `ShowReward` / `ClearReward` | on land / after 2 s |

## Color Rules

- Charge bar: **yellow** normally, **lime** while `inPerfectWindow`.
- Reward text: **white** normal, **lime** on perfect, **magenta** on crit.
- Best distance: flash **gold** for ~1 s when a new record is set (roadmap polish).

## Responsiveness Notes

- Anchors are normalized so the HUD scales across resolutions.
- Corner clusters use 40 px insets to respect TV title-safe areas.
- Charge meter sits 60 px above the bottom edge to clear mobile gesture zones.

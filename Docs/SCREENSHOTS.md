# Screenshot & Capture Specifications — Shotput for Brainrot

Use this checklist when capturing media for the GitHub README, store page, or a
playtest report. Store captures under `Docs/media/` (create it) and reference them
from `README.md`.

## Required Screenshots

| # | Filename | Shows | Framing notes |
|---|----------|-------|---------------|
| 1 | `01_hero.png` | Wide shot of the stadium with a ball mid-flight and trail | Landscape 16:9; ball at arc apex; markers visible receding into distance |
| 2 | `02_hud_charge.png` | HUD during charge, meter partly full | Show top-left coins/ball, top-right distance, bottom charge meter |
| 3 | `03_perfect_window.png` | Charge meter flashing lime in the perfect window | Capture the lime flash + "perfect zone" band |
| 4 | `04_reward_popup.png` | Center floating reward "+N coins!" after landing | Include a CRIT or PERFECT variant if possible |
| 5 | `05_distance_markers.png` | Ground-level view down the runway showing 50 m markers | Emphasize milestone banners (500 m color shift) |
| 6 | `06_shop_upgrades.png` | Player upgrade shop UI (Strength/ChargeSpeed/Crit/CoinMult) | Show costs + current levels |
| 7 | `07_ball_catalog.png` | Ball progression Stone → Secret Ball with rarity colors | Lock icons on unaffordable balls |
| 8 | `08_new_record.png` | Top-right "Best" flashing gold on a new record | |

## Required Clips (GIF/MP4 for README)

| # | Filename | Content | Length |
|---|----------|---------|--------|
| A | `loop_first_throw.mp4` | Full first throw: charge → release → flight → reward | ≤ 15 s |
| B | `loop_upgrade.mp4` | Buy an upgrade, then a visibly farther throw | ≤ 12 s |
| C | `loop_ball_swap.mp4` | Equip a fancier ball and show its trail/VFX | ≤ 10 s |

## Capture Settings

- Resolution: 1920×1080, 60 fps for clips.
- Hide the UEFN editor gizmos; capture from **Launch Session** (play mode).
- Keep the HUD visible in gameplay captures.
- For GIFs, target < 8 MB so GitHub renders them inline.

## Suggested README Placement

```
[hero shot 01]                     ← top of README
... Overview ...
[gif A: first throw]               ← under Gameplay Loop
[hud 02] [perfect 03] [reward 04]  ← under Features (row)
[shop 06] [catalog 07]             ← under Shop/Progression
```

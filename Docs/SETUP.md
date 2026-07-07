# Setup & How to Run — Shotput for Brainrot

This guide takes you from a fresh UEFN install to playtesting the game.

## 1. Prerequisites

| Requirement | Notes |
|-------------|-------|
| Epic Games Launcher | https://www.epicgames.com/store/download |
| **UEFN** (Unreal Editor for Fortnite) | Installed via the Launcher's "Unreal Editor for Fortnite" tab |
| An Epic account with **Creator** access | Accept the Island Creator Program agreement |
| ~20 GB free disk | UEFN + Fortnite content |
| Windows 10/11 (UEFN is Windows-only) | macOS is not supported by UEFN |

## 2. Create the Project

1. Launch **UEFN**.
2. Choose **New Project → Blank** (an empty island).
3. Name it `ShotputForBrainrot` and let it open.

## 3. Import the Verse Code

UEFN maps each **folder** under your project's Verse root to a **module**. You must
recreate this repo's `Verse/` folder layout inside your project so the `using { … }`
statements resolve.

1. In UEFN open the **Verse Explorer** (Verse → Verse Explorer).
2. Create a Verse device project if prompted (**Verse → Create Verse File**), which
   generates the `<ProjectName>/` Verse content folder on disk.
3. On disk, copy the contents of this repo's `Verse/` into that folder, preserving
   subfolders:

   ```
   <YourProject>/Content/... (assets)
   <YourProject>/<ProjectName>/        ← Verse root
       Core/GameConstants.verse
       Core/GameTypes.verse
       Core/BallCatalog.verse
       Core/Localization.verse
       Physics/PhysicsSystem.verse
       Throw/ThrowSystem.verse
       Economy/EconomySystem.verse
       Shop/ShopSystem.verse
       Save/SaveSystem.verse
       Distance/DistanceTrackingSystem.verse
       UI/UISystem.verse
       GameManager.verse
   ```

   > **Module names.** Each folder (`Core`, `Physics`, `Throw`, …) becomes a module.
   > The code uses bare `using { GameConstants }` etc. If your generated Verse root
   > path differs, either (a) keep these folder names exactly, or (b) update the
   > `using` lines to your fully-qualified module paths.

4. Run **Verse → Build Verse Code** (or press the Build button). Fix any path/module
   mismatches the compiler reports. A clean build produces the `game_manager` device
   in the **Content Browser**.

## 4. Place & Configure the Game Manager

1. Drag the **`game_manager`** device from the Content Browser into the map.
2. Select it and open the **Details** panel. Assign the `@editable` references:
   - **BallProp** — a prop that will fly (e.g. a sphere/boulder prop). See
     `Assets/asset_manifest.md`.
   - **ThrowButton** — a `button_device` placed near the throw circle.
   - **ThrowCircleMarker** — a prop marking the launch point (its location defines
     the throw origin).

## 5. Build the Stadium

Follow `Maps/stadium_layout.md`:
- Lay a long, flat field extending in +X from the throw circle.
- Place distance-marker props every **50 m** (5000 cm). You can drive placement from
  `DistanceTrackingSystem.GenerateMarkerPositions()` values, or place them by hand.
- Decorate with colorful, arcade-style props (see `Assets/asset_manifest.md`).

## 6. Playtest

1. Click **Launch Session**.
2. Walk to the throw circle, tap the throw button to start charging, tap again to
   release. Aim for the glowing perfect window!
3. Watch the HUD: coins/ball (top-left), distance/best (top-right), charge meter
   (bottom-center), floating reward (center).

## 7. (Optional) Enable Real Cross-Session Saves

The POC's `SaveSystem` keeps state in memory. To persist across sessions, use UEFN's
persistable data. Sketch:

```verse
# In a dedicated persistence module:
using { /Verse.org/Simulation }

# 1. Mark the saved shape as persistable (only supported field types allowed).
saved_profile := class<final><persistable>:
    var Coins:int = 0
    var BestDistanceMeters:float = 0.0
    var CurrentBallId:int = 0
    # ... store upgrade levels as parallel arrays or a persistable-friendly shape.

# 2. Declare a module-scoped persistent weak_map keyed on player.
var Profiles : weak_map(player, saved_profile) = map{}

# 3. On join: read `Profiles[player]` (create default if absent).
# 4. On change: write back `set Profiles[player] = updated`.
```

Then adapt `SaveSystem.Load/Save` to read/write this weak_map instead of the in-memory
`Store`, converting between `saved_profile` and the runtime `player_state`.

> Persistable rules to remember: only certain types persist (int, float, logic,
> string, enums, and persistable structs/classes + arrays/maps of them), the data
> shape must be stable, and the project must have persistence enabled in its settings.

## 8. Publish to GitHub

From the repo root:

```bash
git init
git add .
git commit -m "Shotput for Brainrot — initial POC"
git branch -M main
git remote add origin https://github.com/<you>/ShotputForBrainrot.git
git push -u origin main
```

> Do **not** commit Fortnite/UEFN binary content or Epic assets. This repo ships code
> + docs + asset *specifications* only. A `.gitignore` is provided for typical UEFN
> build artifacts.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `Unknown identifier 'GameConstants'` | Folder/module name doesn't match a `using`. Rename folder or update the `using`. |
| Ball doesn't move | `BallProp` not assigned, or the prop has collision that blocks teleport. Use a simple prop. |
| Charge meter never fills | `ThrowButton` not assigned or not wired to `InteractedWithEvent`. |
| No HUD | Ensure `/UnrealEngine.com/Temporary/UI` and `/Fortnite.com/UI` are available in your UEFN version; the API is under active change. |
| Distances look tiny/huge | Remember 1 m = 100 cm. Check `LaunchHeight` and marker spacing use cm. |

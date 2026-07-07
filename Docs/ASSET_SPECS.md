# Asset Specifications — Shotput for Brainrot

Fortnite/UEFN assets can't be redistributed in this repo, so this document specifies
exactly what to build/use in-editor to achieve the intended colorful, exaggerated,
arcade look. Pair this with `Assets/asset_manifest.md` (concrete asset picks) and
`Maps/stadium_layout.md` (placement).

Art direction in one line: **loud, chunky, saturated, and funny** — think mobile
hyper-casual, not a sports sim. Big readable shapes, bold outlines, playful VFX.

---

## 1. Stadium

| Element | Spec |
|---------|------|
| **Field** | Long flat runway extending +X from the throw circle. Length ≥ `StadiumLengthMeters` (2000 m = 200,000 cm) for late-game balls. Use a tiled bright-green "turf" material or a checker of two greens. |
| **Throw circle** | A glowing ring/disc prop at the launch point (Ø ~4 m). Emissive cyan/white. Its transform drives `ThrowCircleMarker`. |
| **Side rails** | Low bumper walls in a saturated accent (orange/blue) framing the runway to read the distance visually. |
| **Backdrop** | Cartoon stands/bleachers with simple crowd decals; oversized, low-poly. Optional floating balloons and pennant bunting. |
| **Skybox** | Bright, high-contrast daytime; exaggerated fluffy clouds. |
| **Lighting** | Even, high-key, minimal shadows so colors pop. Add a subtle vignette-free bloom for that arcade sheen. |

## 2. Distance Markers (every 50 m)

| Element | Spec |
|---------|------|
| **Marker post** | A tall thin sign/pillar beside the runway at each 50 m (5000 cm) increment. |
| **Label** | Large bold number ("50", "100", … "2000") + "m". High contrast (white on dark or black on yellow). Readable from the throw circle. |
| **Milestone flair** | Every 500 m use a bigger arch/banner and a color shift (bronze→silver→gold→rainbow) to reward reaching farther zones. |
| **Alignment** | Centered along the runway's +X axis at the field's Y; Z at ground level. Positions come from `DistanceTrackingSystem.GenerateMarkerPositions()`. |

## 3. Ball Visuals (progression tiers)

One `BallProp` is teleported per throw; swap its **mesh/material/VFX** by equipped
ball. Keep silhouettes chunky and oversized (Ø ~1–1.5 m) for readability.

| # | Ball | Look | VFX / Trail |
|---|------|------|-------------|
| 0 | **Stone** | Grey rocky sphere, matte | none |
| 1 | **Iron** | Dark metallic, subtle scratches | faint grey dust |
| 2 | **Steel** | Bright polished chrome | light spark trail |
| 3 | **Gold** | Saturated gold, glossy | gold sparkle trail |
| 4 | **Diamond** | Faceted, translucent cyan | prismatic glints |
| 5 | **Rainbow** | Animated rainbow gradient | rainbow ribbon trail |
| 6 | **Galaxy** | Deep purple/blue with stars | swirling starfield trail |
| 7 | **Cosmic** | Nebula emissive, pulsing | comet tail + glow |
| 8 | **Brainrot** | Absurd meme texture, wobbly, googly-eyes decal | glitchy neon trail + emojis |
| 9 | **Secret Ball** | Hidden/holographic, shifting | screen-shake-worthy radiant burst |

**Impact/bounce FX:** a small dust puff + squash-and-stretch scale pop on each bounce
sells the arcade feel. Escalate FX intensity with rarity.

## 4. UI Elements

See `UI/hud_layout.md` for exact anchors. Visual style:

| Element | Spec |
|---------|------|
| **Coin readout (top-left)** | Coin icon + big bold number with thousands separators. Gold text, dark outline. Ball name beneath in a smaller pill/badge tinted by rarity color. |
| **Distance readout (top-right)** | Big number + "m", plus a smaller "Best: N m". White with dark outline; flash gold on a new record. |
| **Charge meter (bottom-center)** | Horizontal chunky progress bar. Fill yellow→orange; when inside the perfect window it flashes **lime** and pulses. Add a marked "perfect zone" band near the top. |
| **Floating reward (center)** | Punchy pop-in text: "+1,240 coins!". "PERFECT!" prefix in lime, "CRIT x2!" in magenta. Scale-bounce in, drift up, fade out over ~2 s. |
| **Fonts** | Heavy rounded display font; large sizes; strong outlines/drop shadow for readability over any background. |

**Rarity color key (reuse across balls + shop):**
Common `#B0B0B0` · Uncommon `#4CD137` · Rare `#00A8FF` · Epic `#9C88FF` ·
Legendary `#FBC531` · Mythic `#E84118` · Secret `#FF00E5`.

## 5. Audio (specification for roadmap)

| Cue | Feel |
|-----|------|
| Charge | Rising whine/whoosh that pitches up with charge % |
| Perfect release | Bright "ding!" confirmation |
| Launch | Cartoon "boing"/boom |
| Bounce | Soft comedic "bonk", pitch varies with speed |
| Coin reward | Satisfying cha-ching; bigger sparkle for crits |
| Upgrade purchase | Positive power-up chime |

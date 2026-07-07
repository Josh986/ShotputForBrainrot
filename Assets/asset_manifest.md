# Asset Manifest — Shotput for Brainrot

Concrete, editor-ready asset picks. Because Fortnite/UEFN content can't be
redistributed in Git, this manifest names the **built-in / marketplace** assets to use
and how to configure them. Cross-reference `Docs/ASSET_SPECS.md` for the art direction
and `Maps/stadium_layout.md` for placement.

> Asset paths vary slightly by UEFN version. Use the **Content Browser search terms**
> below and pick the closest match. Prefer Fab/UEFN "Starter/Creative" content that is
> licensed for use in your published island.

## Devices (Verse + Creative)

| Role | Device | Notes |
|------|--------|-------|
| Game logic | **`game_manager`** (this project's Verse device) | Place once; assign editables. |
| Throw input | **Button Device** (`button_device`) | Near the throw circle. |
| Shop actions | **Button Device** ×N | One per upgrade/ball; forwards to `game_manager` hooks. |
| Ball | **Prop Manipulator / Creative Prop** | A single movable sphere-like prop, teleported by physics. |
| Player start | **Player Spawn Pad** | Near the throw circle. |

## Props

| Purpose | Search terms | Config |
|---------|--------------|--------|
| Ball (base) | "sphere", "boulder", "ball", "orb" | Scale to Ø ~1–1.5 m; disable blocking collision that would stop teleports. |
| Throw circle | "ring", "hologram", "disc", "beacon" | Emissive cyan; flat on ground. |
| Distance signs | "sign", "billboard", "pillar" | Large number decals; place every 50 m. |
| Milestone arch | "arch", "gate", "banner" | Every 500 m; color-tier it. |
| Side rails | "barrier", "bumper", "fence" | Low, bright; line the runway. |
| Bleachers | "bleacher", "stands", "seats" | Behind the circle. |
| Decor | "balloon", "pennant", "confetti" | Arcade flair. |

## Materials

| Surface | Search terms | Config |
|---------|--------------|--------|
| Turf | "grass", "turf", "green" | Tiled; consider a two-tone checker. |
| Ball tiers | "metal", "gold", "chrome", "crystal", "holographic", "emissive" | See ball table in ASSET_SPECS §3. |
| Signage | "emissive", "unlit" | High-contrast numbers. |

## VFX (per ball rarity)

| Effect | Search terms | Applied to |
|--------|--------------|-----------|
| Sparkle/trail | "sparkle", "trail", "ribbon", "niagara trail" | Steel+ balls |
| Rainbow ribbon | "rainbow", "gradient trail" | Rainbow |
| Starfield/comet | "star", "nebula", "comet" | Galaxy / Cosmic |
| Glitch/neon | "glitch", "neon", "emoji" | Brainrot |
| Radiant burst | "burst", "shockwave", "aura" | Secret Ball + all impacts |
| Bounce puff | "dust", "impact", "poof" | every bounce |

## UI Assets

| Element | Source | Notes |
|---------|--------|-------|
| Coin icon | UI icon set / imported texture | Gold coin, bold outline. |
| Charge bar fill | `progress_bar` style | Yellow→orange; lime in perfect window. |
| Fonts | Heavy rounded display font | Large, outlined for readability. |
| Rarity colors | (defined in ASSET_SPECS §4) | Reuse across balls + shop badges. |

## Audio (roadmap)

| Cue | Search terms |
|-----|--------------|
| Charge whine | "charge", "power up", "whoosh" |
| Launch | "boing", "boom", "cartoon launch" |
| Bounce | "bonk", "bounce", "thud" |
| Coins | "coin", "cha-ching", "sparkle chime" |
| Upgrade | "power up", "success chime" |

## Licensing Reminder

Only use assets you're licensed to publish in a Fortnite island (Epic-provided,
Fab content cleared for UEFN, or your own originals). Do not commit Epic binary
content into this repository — reference it here instead.

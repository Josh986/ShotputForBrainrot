# Shotput for Brainrot — Brainrot & Giant Brainrot Chase System
#
# This system owns the second half of the core loop — the part that gives every
# throw real stakes:
#
#   Ball lands  ->  a Brainrot of that tier spawns  ->  you BECOME it  ->
#   the Giant Brainrot wakes up and chases  ->  RUN HOME before it eats you  ->
#   survive = the Brainrot joins your base and pays income forever;
#   caught  = you lose it and must throw again.
#
# Because a POC can't ship full character-transformation + NPC pathfinding, the
# chase is modelled as a tight skill-race the GameManager drives each tick:
#
#   * A capture countdown ticks down (shorter for higher, hungrier tiers).
#   * The player fills an "escape bar" by tapping the run input (RegisterTap).
#   * The bar also decays slightly each second, keeping the pressure on.
#   * Reach 100% before the countdown hits zero  ->  Escaped.
#   * Countdown expires first                     ->  Caught.
#
# The GameManager binds this to real input + drives the visible Giant Brainrot prop
# and the transformed player; here we keep the pure race state so it stays testable.

using { /Verse.org/Simulation }
using { GameConstants }
using { GameTypes }
using { BrainrotCatalog }

brainrot_system<public> := class:

    # Injected catalog used to resolve distance -> tier and tier -> income.
    Catalog<public>:[]brainrot_def = MakeBrainrotCatalog()

    # --- Live chase state (one race at a time per system instance) ---------------

    # Escape bar fill, 0..1. Reaching 1.0 means the player made it home.
    var EscapeProgress<private>:float = 0.0

    # Seconds left before the Giant Brainrot catches up. Reaching 0 = caught.
    var TimeRemaining<private>:float = 0.0

    # The tier currently at stake in this chase.
    var ActiveTier<private>:brainrot_tier = brainrot_tier.Common

    # Whether a chase is currently running.
    var Running<private>:logic = false

    # --- Tier resolution ---------------------------------------------------------

    # Which Brainrot spawns for a throw that reached DistanceMeters.
    ResolveTier<public>(DistanceMeters:float)<transacts>:brainrot_def=
        GetTierForDistance(Catalog, DistanceMeters)

    # --- Chase lifecycle ---------------------------------------------------------

    # Start a chase for the given tier. Computes the escape window from the tier's
    # difficulty index — hungrier (higher) tiers give you less time to get home.
    BeginChase<public>(Def:brainrot_def):void=
        set ActiveTier = Def.Tier
        set EscapeProgress = 0.0
        set TimeRemaining = ComputeChaseTime(Def.Tier)
        set Running = true

    # Advance the chase by DeltaSeconds. Applies passive escape-bar decay and ticks
    # the capture countdown down. Returns the still-running state; call IsResolved
    # afterwards to see if the chase ended this tick.
    Tick<public>(DeltaSeconds:float):void=
        if (Running?):
            # Escape bar slowly slips if the player stops running.
            Decayed := EscapeProgress - ChaseDecayPerSecond * DeltaSeconds
            set EscapeProgress = Max(0.0, Decayed)
            set TimeRemaining -= DeltaSeconds
            # Resolve if the player got home or ran out of time.
            if (EscapeProgress >= 1.0 || TimeRemaining <= 0.0):
                set Running = false

    # The player pressed the run input: nudge the escape bar toward home.
    RegisterTap<public>():void=
        if (Running?):
            set EscapeProgress = Min(1.0, EscapeProgress + ChaseTapProgress)

    # Whether the chase has finished (escaped or caught).
    IsResolved<public>()<transacts>:logic=
        not Running?

    # Final result once resolved. Escaped if the bar filled before time ran out.
    GetOutcome<public>()<transacts>:chase_outcome=
        chase_outcome:
            Escaped := EscapeProgress >= 1.0
            Tier := ActiveTier

    # --- Read-only accessors for the HUD -----------------------------------------
    # (Marked <transacts> because they read mutable chase state.)

    GetEscapeProgress<public>()<transacts>:float= EscapeProgress
    GetTimeRemaining<public>()<transacts>:float= TimeRemaining
    GetActiveTier<public>()<transacts>:brainrot_tier= ActiveTier

    # --- Helpers -----------------------------------------------------------------

    # Escape window for a tier = base time minus a per-tier penalty, floored so the
    # top tiers stay hard-but-fair. TierIndex(Common)=0 ... TierIndex(Secret)=6.
    ComputeChaseTime<private>(Tier:brainrot_tier)<computes>:float=
        Penalty := ChaseTimePenaltyPerTier * Int2Float(TierIndex(Tier))
        Raw := ChaseBaseTimeSeconds - Penalty
        Max(ChaseMinTimeSeconds, Raw)

    # Stable difficulty index for a tier (weakest 0 -> strongest 6).
    TierIndex<private>(Tier:brainrot_tier)<computes>:int=
        case (Tier):
            brainrot_tier.Common    => 0
            brainrot_tier.Uncommon  => 1
            brainrot_tier.Rare      => 2
            brainrot_tier.Epic      => 3
            brainrot_tier.Legendary => 4
            brainrot_tier.Mythic    => 5
            brainrot_tier.Secret    => 6

    Max<private>(A:float, B:float)<computes>:float=
        if (A > B) { A } else { B }

    Min<private>(A:float, B:float)<computes>:float=
        if (A < B) { A } else { B }

    Int2Float<private>(I:int)<computes>:float= 1.0 * I

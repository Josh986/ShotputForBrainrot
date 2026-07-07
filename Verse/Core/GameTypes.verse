# Shotput for Brainrot — Shared Types
#
# Common data structures and enums used across every system. Centralizing these
# avoids circular dependencies between gameplay modules.

using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }

# The four player upgrade tracks. Used as a stable key for save data and shop UI.
player_upgrade_kind<public> := enum:
    Strength      # Increases launch speed (throw farther).
    ChargeSpeed   # Fills the charge meter faster.
    CritChance    # Raises chance of a coin-doubling critical throw.
    CoinMultiplier# Multiplies all coins earned.

# Rarity tiers used for coloring UI and gating ball unlocks.
ball_rarity<public> := enum:
    Common
    Uncommon
    Rare
    Epic
    Legendary
    Mythic
    Secret

# Static definition of a throwable ball. Populated from the ball catalog.
# `SpeedMultiplier` and `BounceMultiplier` let heavier/fancier balls behave differently.
ball_def<public> := struct:
    Id<public>:int                         # Stable index (0-based) in the catalog.
    Name<public>:string                    # Display name, e.g. "Diamond".
    Rarity<public>:ball_rarity             # Visual/rarity tier.
    UnlockCost<public>:int                 # Coins required to purchase.
    SpeedMultiplier<public>:float          # Multiplies launch speed.
    BounceMultiplier<public>:float         # Multiplies bounce restitution.
    CoinBonusMultiplier<public>:float      # Multiplies coin reward.

# The Brainrot tiers you can capture. The tier you get is decided by how far your
# ball travels (see BrainrotCatalog + GameConstants thresholds). Ordered weakest
# to strongest so the enum's ordinal doubles as a difficulty index for the chase.
brainrot_tier<public> := enum:
    Common
    Uncommon
    Rare
    Epic
    Legendary
    Mythic
    Secret

# Static definition of a Brainrot tier: what it's called, the distance needed to
# spawn it, and how much passive income each captured one pays per second.
brainrot_def<public> := struct:
    Tier<public>:brainrot_tier             # Which tier this describes.
    Name<public>:string                    # Display name, e.g. "Legendary Brainrot".
    MinDistanceMeters<public>:float        # Throw must reach this far to spawn it.
    IncomePerSecond<public>:int            # Coins/sec each captured one generates.

# Result of the Giant Brainrot chase (the run home after a throw).
chase_outcome<public> := struct:
    Escaped<public>:logic                  # Did the player reach base in time?
    Tier<public>:brainrot_tier             # Which Brainrot was at stake.

# Snapshot of a single completed throw. Passed from PhysicsSystem to EconomySystem.
throw_result<public> := struct:
    DistanceMeters<public>:float           # Horizontal distance from launch circle.
    AirtimeSeconds<public>:float           # Total time the ball was airborne.
    Bounces<public>:int                    # Number of ground bounces.
    WasPerfect<public>:logic               # Was this a perfect-window release?

# The full persistent state of a player. Mirrors what SaveSystem stores.
player_state<public> := class<final>:
    var Coins<public>:int = 0
    var BestDistanceMeters<public>:float = 0.0
    var CurrentBallId<public>:int = 0
    var UnlockedBallIds<public>:[]int = array{0}   # Stone owned by default.

    # Upgrade level per track. Missing key implies level 0.
    var UpgradeLevels<public>:[player_upgrade_kind]int = map{}

    # The player's base collection: how many Brainrots of each tier they've captured.
    # This is the long-term income engine — every entry pays out every second.
    var CollectedBrainrots<public>:[brainrot_tier]int = map{}

    # Returns current level of an upgrade track (0 if never purchased).
    GetUpgradeLevel<public>(Kind:player_upgrade_kind)<transacts>:int=
        if (Level := UpgradeLevels[Kind]) { return Level }
        return 0

    # Returns how many Brainrots of a tier are in the base (0 if none captured).
    GetBrainrotCount<public>(Tier:brainrot_tier)<transacts>:int=
        if (Count := CollectedBrainrots[Tier]) { return Count }
        return 0

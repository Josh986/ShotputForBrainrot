# Shotput for Brainrot — Core Game Constants
#
# Central, tunable configuration for the whole game. Keeping every "magic number"
# here means designers can rebalance the game without touching gameplay logic.
#
# Verse note: `<constructor><computes>` free functions are used so these values can
# be referenced from any module by importing GameConstants.

using { /Verse.org/Simulation }

# --------------------------------------------------------------------------------------
# PHYSICS TUNING
# --------------------------------------------------------------------------------------
# All physics values are in centimeters (UEFN world unit) unless otherwise noted.
# Distances displayed to the player are converted to "meters" (1 m = 100 cm).

# Base downward acceleration applied to a live ball (cm/s^2). Exaggerated for arcade feel.
GravityAcceleration<public>:float = 1400.0

# Multiplier applied to velocity when the ball bounces off the ground (0..1).
# Higher = ball keeps more energy and bounces further.
BounceRestitution<public>:float = 0.55

# Ground friction applied to horizontal velocity each bounce (0..1). 1 = no friction.
GroundFriction<public>:float = 0.82

# Ball is considered "at rest" (throw over) when its speed drops below this (cm/s).
RestSpeedThreshold<public>:float = 40.0

# Physics simulation tick period (seconds). 60Hz gives smooth arcade motion.
PhysicsTickPeriod<public>:float = 0.0166

# Height (cm) of the launch/throw circle above the ground where the ball starts.
LaunchHeight<public>:float = 120.0

# --------------------------------------------------------------------------------------
# THROW / CHARGE TUNING
# --------------------------------------------------------------------------------------
# Time (seconds) for the charge meter to travel from 0% to 100%.
BaseChargeDuration<public>:float = 1.6

# Minimum and maximum launch speed (cm/s) mapped from charge 0%..100%.
MinLaunchSpeed<public>:float = 600.0
MaxLaunchSpeed<public>:float = 3200.0

# Launch angle in degrees above horizontal. 45 is optimal-range for projectile motion.
LaunchAngleDegrees<public>:float = 42.0

# "Perfect throw" window: releasing charge within this band around 100% grants a bonus.
# e.g. 0.92 means releasing between 92% and 100% charge = perfect.
PerfectThrowWindowStart<public>:float = 0.92

# Speed bonus multiplier granted on a perfect throw.
PerfectThrowBonusMultiplier<public>:float = 1.35

# --------------------------------------------------------------------------------------
# ECONOMY TUNING
# --------------------------------------------------------------------------------------
# Coins awarded per meter of distance travelled.
CoinsPerMeter<public>:float = 1.0

# Coins awarded per second the ball spent airborne.
CoinsPerAirtimeSecond<public>:float = 8.0

# Coins awarded per bounce.
CoinsPerBounce<public>:int = 5

# Flat bonus coins for landing a perfect throw.
PerfectThrowCoinBonus<public>:int = 25

# Critical hit chance is rolled per throw; a crit multiplies total coin reward.
CritRewardMultiplier<public>:float = 2.0

# --------------------------------------------------------------------------------------
# UPGRADE TUNING
# --------------------------------------------------------------------------------------
# Max level each player upgrade can reach.
MaxUpgradeLevel<public>:int = 20

# Base cost of the first level of any player upgrade (coins).
BaseUpgradeCost<public>:int = 50

# Each subsequent upgrade level costs BaseCost * (CostGrowth ^ level).
UpgradeCostGrowth<public>:float = 1.55

# Per-level effect magnitudes:
StrengthPerLevel<public>:float    = 0.06   # +6% launch speed per level
ChargeSpeedPerLevel<public>:float = 0.05   # +5% charge speed per level
CritChancePerLevel<public>:float  = 0.02   # +2% crit chance per level
CoinMultPerLevel<public>:float    = 0.10   # +10% coin gain per level

# --------------------------------------------------------------------------------------
# DISTANCE MARKERS
# --------------------------------------------------------------------------------------
# Distance markers are placed every N meters down the stadium field.
MarkerIntervalMeters<public>:int = 50

# Maximum field length in meters (used for stadium sizing / marker generation).
StadiumLengthMeters<public>:int = 2000

# --------------------------------------------------------------------------------------
# BRAINROT TIER THRESHOLDS (the *real* progression driver)
# --------------------------------------------------------------------------------------
# Distance no longer pays coins directly. Instead the distance your ball reaches
# decides WHICH Brainrot tier spawns at the landing spot. Capture it (survive the
# chase home) and it joins your base as a permanent income source.
#
# Minimum distance (meters) required to spawn each tier. A throw awards the highest
# tier whose threshold it meets.
BrainrotCommonMinMeters<public>:float    = 0.0      # 0 - 100 m
BrainrotUncommonMinMeters<public>:float  = 100.0    # 100 - 300 m
BrainrotRareMinMeters<public>:float      = 300.0    # 300 - 600 m
BrainrotEpicMinMeters<public>:float      = 600.0    # 600 - 1000 m
BrainrotLegendaryMinMeters<public>:float = 1000.0   # 1000 - 2000 m
BrainrotMythicMinMeters<public>:float    = 2000.0   # 2000 m +
BrainrotSecretMinMeters<public>:float    = 5000.0   # Secret Zone

# Passive income each captured Brainrot of a tier generates, per second.
BrainrotCommonIncome<public>:int    = 1
BrainrotUncommonIncome<public>:int  = 3
BrainrotRareIncome<public>:int      = 10
BrainrotEpicIncome<public>:int      = 30
BrainrotLegendaryIncome<public>:int = 100
BrainrotMythicIncome<public>:int    = 500
BrainrotSecretIncome<public>:int    = 5000

# --------------------------------------------------------------------------------------
# GIANT BRAINROT CHASE (the "return trip" that gives every throw real stakes)
# --------------------------------------------------------------------------------------
# After you transform into the freshly-spawned Brainrot you must run home before the
# Giant Brainrot catches you. We model the run as a short skill race: a countdown
# ticks toward capture while the player taps/holds the run input to fill an escape
# bar. Higher tiers = a hungrier, faster Giant = harder escape.

# Seconds the player has to escape at the lowest tier (Common). Higher tiers subtract.
ChaseBaseTimeSeconds<public>:float = 6.0

# Seconds removed from the escape window per tier index (Common=0 ... Secret=6).
ChaseTimePenaltyPerTier<public>:float = 0.55

# Minimum escape window regardless of tier, so the top tiers stay *hard* but fair.
ChaseMinTimeSeconds<public>:float = 2.5

# How much one run-input tap advances the escape bar (0..1 of the bar).
ChaseTapProgress<public>:float = 0.12

# The escape bar passively decays this much per second (keeps the pressure on).
ChaseDecayPerSecond<public>:float = 0.10

# Tick period (seconds) for the chase countdown/decay loop.
ChaseTickPeriod<public>:float = 0.1

# --------------------------------------------------------------------------------------
# PASSIVE INCOME
# --------------------------------------------------------------------------------------
# How often (seconds) collected Brainrots pay out into the player's wallet.
PassiveIncomeTickPeriod<public>:float = 1.0

# On a successful capture, immediately grant this many SECONDS' worth of the new
# Brainrot's income as a one-time "welcome" bonus. Makes capturing feel rewarding
# instantly and bootstraps the economy — set to 0 for pure passive-only income.
CaptureBonusSeconds<public>:float = 8.0

# How long (seconds) the reward / capture-result banner stays on screen.
BannerDisplaySeconds<public>:float = 2.2

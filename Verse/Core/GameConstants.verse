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

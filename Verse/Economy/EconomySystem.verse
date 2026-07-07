# Shotput for Brainrot — Economy System
#
# Pure calculation module that turns a throw_result into a coin reward. Factors in
# distance, airtime, bounces, perfect-throw bonuses, the equipped ball's bonus,
# the player's CoinMultiplier upgrade, and a rollable critical hit.
#
# Kept side-effect free (no state mutation) so rewards are easy to unit-test and
# reason about. The GameManager applies the result to the player's coin balance.

using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { GameConstants }
using { GameTypes }

# Detailed breakdown of a reward so the UI can show players *why* they earned coins.
reward_breakdown<public> := struct:
    DistanceCoins<public>:int    # From distance travelled.
    AirtimeCoins<public>:int     # From time airborne.
    BounceCoins<public>:int      # From bounces.
    PerfectBonus<public>:int     # Flat perfect-throw bonus.
    WasCrit<public>:logic        # Did this throw crit?
    Total<public>:int            # Final coins after all multipliers.

economy_system<public> := class:

    # Compute the coin reward for a completed throw.
    #
    # Params:
    #   Result           - the physics outcome of the throw.
    #   BallCoinMult     - equipped ball's CoinBonusMultiplier.
    #   CoinMultLevel    - player's CoinMultiplier upgrade level.
    #   CritChanceLevel  - player's CritChance upgrade level (rolled here).
    CalculateReward<public>(
        Result:throw_result,
        BallCoinMult:float,
        CoinMultLevel:int,
        CritChanceLevel:int
    ):reward_breakdown=

        # 1. Component coins (pre-multiplier).
        DistanceCoins := Round(Result.DistanceMeters * CoinsPerMeter)
        AirtimeCoins  := Round(Result.AirtimeSeconds * CoinsPerAirtimeSecond)
        BounceCoins   := Result.Bounces * CoinsPerBounce
        PerfectBonus  := if (Result.WasPerfect?) { PerfectThrowCoinBonus } else { 0 }

        Subtotal := DistanceCoins + AirtimeCoins + BounceCoins + PerfectBonus

        # 2. Apply ball bonus and player CoinMultiplier upgrade.
        CoinMult := 1.0 + CoinMultPerLevel * Int2Float(CoinMultLevel)
        Boosted := Int2Float(Subtotal) * BallCoinMult * CoinMult

        # 3. Roll for a critical throw.
        CritChance := CritChancePerLevel * Int2Float(CritChanceLevel)
        WasCrit := RollCrit(CritChance)
        CritMult := if (WasCrit?) { CritRewardMultiplier } else { 1.0 }

        Total := Round(Boosted * CritMult)

        return reward_breakdown:
            DistanceCoins := DistanceCoins
            AirtimeCoins := AirtimeCoins
            BounceCoins := BounceCoins
            PerfectBonus := PerfectBonus
            WasCrit := WasCrit
            Total := Total

    # --- Helpers -----------------------------------------------------------------

    # Roll a 0..1 random number; crit if below the chance. GetRandomFloat is from
    # /Verse.org/Random. Chance is clamped to [0,1].
    RollCrit<private>(Chance:float):logic=
        Clamped := if (Chance > 1.0) { 1.0 } else if (Chance < 0.0) { 0.0 } else { Chance }
        Roll := GetRandomFloat(0.0, 1.0)
        return Roll < Clamped

    # Round a float to the nearest int (Verse Floor + 0.5 trick).
    Round<private>(X:float)<computes>:int=
        Floor[X + 0.5]

    Int2Float<private>(I:int)<computes>:float= 1.0 * I

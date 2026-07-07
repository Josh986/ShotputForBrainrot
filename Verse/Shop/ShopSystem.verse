# Shotput for Brainrot — Shop System
#
# Handles purchasing of the two upgrade categories:
#   1. Player upgrades (Strength, ChargeSpeed, CritChance, CoinMultiplier) that
#      level up along a geometric cost curve.
#   2. Ball upgrades (unlocking + equipping balls from the catalog).
#
# All purchases mutate the shared player_state and are validated against the
# player's coin balance. Returns typed results so the UI can react appropriately.

using { /Verse.org/Simulation }
using { GameConstants }
using { GameTypes }
using { BallCatalog }

# Outcome of any purchase attempt.
purchase_result<public> := enum:
    Success
    NotEnoughCoins
    MaxLevelReached
    AlreadyOwned
    InvalidTarget

shop_system<public> := class:

    # The ball catalog, injected at construction so the shop can price ball unlocks.
    Catalog<public>:[]ball_def

    # --- Player upgrades ---------------------------------------------------------

    # Cost of the *next* level of a player upgrade given its current level.
    # Cost = BaseUpgradeCost * (UpgradeCostGrowth ^ currentLevel).
    GetUpgradeCost<public>(CurrentLevel:int)<computes>:int=
        Floor[Int2Float(BaseUpgradeCost) * Pow(UpgradeCostGrowth, Int2Float(CurrentLevel))]

    # Attempt to buy one level of a player upgrade. Mutates State on success.
    PurchaseUpgrade<public>(State:player_state, Kind:player_upgrade_kind):purchase_result=
        CurrentLevel := State.GetUpgradeLevel(Kind)

        if (CurrentLevel >= MaxUpgradeLevel):
            return purchase_result.MaxLevelReached

        Cost := GetUpgradeCost(CurrentLevel)
        if (State.Coins < Cost):
            return purchase_result.NotEnoughCoins

        # Deduct coins and bump the level.
        set State.Coins -= Cost
        if (set State.UpgradeLevels[Kind] = CurrentLevel + 1) {}
        return purchase_result.Success

    # --- Ball upgrades / unlocks -------------------------------------------------

    # Does the player already own this ball?
    OwnsBall<public>(State:player_state, BallId:int)<computes>:logic=
        for (Owned : State.UnlockedBallIds, Owned = BallId):
            return true
        return false

    # Attempt to unlock (buy) a ball from the catalog. Mutates State on success.
    PurchaseBall<public>(State:player_state, BallId:int):purchase_result=
        if (Ball := Catalog[BallId]):
            if (OwnsBall(State, BallId)?):
                return purchase_result.AlreadyOwned
            if (State.Coins < Ball.UnlockCost):
                return purchase_result.NotEnoughCoins
            set State.Coins -= Ball.UnlockCost
            set State.UnlockedBallIds += array{BallId}
            return purchase_result.Success
        return purchase_result.InvalidTarget

    # Equip an owned ball as the active throwing ball.
    EquipBall<public>(State:player_state, BallId:int):purchase_result=
        if (Catalog[BallId], OwnsBall(State, BallId)?):
            set State.CurrentBallId = BallId
            return purchase_result.Success
        return purchase_result.InvalidTarget

    # --- Helpers -----------------------------------------------------------------

    Int2Float<private>(I:int)<computes>:float= 1.0 * I

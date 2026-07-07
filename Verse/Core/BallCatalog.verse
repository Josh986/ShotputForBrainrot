# Shotput for Brainrot — Ball Catalog
#
# The full ball progression from Stone to the Secret Ball. Each entry defines its
# unlock cost and how it modifies physics + economy. Balancing knobs live here.
#
# Progression: Stone -> Iron -> Steel -> Gold -> Diamond -> Rainbow -> Galaxy ->
#              Cosmic -> Brainrot -> Secret Ball

using { /Verse.org/Simulation }
using { GameTypes }

# Returns the ordered list of all balls in the game. Index == ball_def.Id.
MakeBallCatalog<public>()<computes>:[]ball_def=
    array:
        ball_def{ Id := 0, Name := "Stone",       Rarity := ball_rarity.Common,    UnlockCost := 0,        SpeedMultiplier := 1.00, BounceMultiplier := 1.00, CoinBonusMultiplier := 1.00 }
        ball_def{ Id := 1, Name := "Iron",        Rarity := ball_rarity.Common,    UnlockCost := 250,      SpeedMultiplier := 1.08, BounceMultiplier := 1.05, CoinBonusMultiplier := 1.10 }
        ball_def{ Id := 2, Name := "Steel",       Rarity := ball_rarity.Uncommon,  UnlockCost := 1000,     SpeedMultiplier := 1.16, BounceMultiplier := 1.10, CoinBonusMultiplier := 1.25 }
        ball_def{ Id := 3, Name := "Gold",        Rarity := ball_rarity.Rare,      UnlockCost := 5000,     SpeedMultiplier := 1.25, BounceMultiplier := 1.15, CoinBonusMultiplier := 1.50 }
        ball_def{ Id := 4, Name := "Diamond",     Rarity := ball_rarity.Epic,      UnlockCost := 25000,    SpeedMultiplier := 1.38, BounceMultiplier := 1.22, CoinBonusMultiplier := 1.85 }
        ball_def{ Id := 5, Name := "Rainbow",     Rarity := ball_rarity.Epic,      UnlockCost := 100000,   SpeedMultiplier := 1.55, BounceMultiplier := 1.30, CoinBonusMultiplier := 2.30 }
        ball_def{ Id := 6, Name := "Galaxy",      Rarity := ball_rarity.Legendary, UnlockCost := 500000,   SpeedMultiplier := 1.80, BounceMultiplier := 1.40, CoinBonusMultiplier := 3.00 }
        ball_def{ Id := 7, Name := "Cosmic",      Rarity := ball_rarity.Legendary, UnlockCost := 2500000,  SpeedMultiplier := 2.10, BounceMultiplier := 1.55, CoinBonusMultiplier := 4.00 }
        ball_def{ Id := 8, Name := "Brainrot",    Rarity := ball_rarity.Mythic,    UnlockCost := 15000000, SpeedMultiplier := 2.60, BounceMultiplier := 1.75, CoinBonusMultiplier := 6.00 }
        ball_def{ Id := 9, Name := "Secret Ball", Rarity := ball_rarity.Secret,    UnlockCost := 99999999, SpeedMultiplier := 3.50, BounceMultiplier := 2.10, CoinBonusMultiplier := 10.00 }

# Safe lookup of a ball by id. Falls back to Stone (index 0) if the id is invalid,
# so gameplay never crashes on bad save data.
GetBallById<public>(Catalog:[]ball_def, Id:int)<computes>:ball_def=
    if (Ball := Catalog[Id]) { return Ball }
    if (Stone := Catalog[0]) { return Stone }
    # Ultimate fallback (empty catalog should never happen).
    return ball_def{ Id := 0, Name := "Stone", Rarity := ball_rarity.Common, UnlockCost := 0, SpeedMultiplier := 1.0, BounceMultiplier := 1.0, CoinBonusMultiplier := 1.0 }

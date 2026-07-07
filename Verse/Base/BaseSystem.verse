# Shotput for Brainrot — Base / Collection & Passive Income System
#
# Your base is the long-term heart of the game. Every Brainrot you carry home
# safely (survived the Giant Brainrot chase) is added here, and from then on it
# generates coins every second — forever, even while you line up your next throw.
#
#   Capture a Brainrot  ->  AddBrainrot() puts it in the base
#   Every second        ->  TotalIncomePerSecond() is credited to the wallet
#   Coins               ->  spent on throw upgrades + better balls
#   Better throws       ->  reach farther  ->  unlock higher tiers  ->  more income
#
# This module is pure/stateless with respect to players: it operates on the
# player_state it's handed, so the SaveSystem remains the single source of truth.

using { /Verse.org/Simulation }
using { GameConstants }
using { GameTypes }
using { BrainrotCatalog }

base_system<public> := class:

    # Injected Brainrot catalog, used to convert collected tiers into income rates.
    Catalog<public>:[]brainrot_def = MakeBrainrotCatalog()

    # Add one captured Brainrot of the given tier to the player's base. Mutates and
    # returns the state so the caller can persist it.
    AddBrainrot<public>(State:player_state, Tier:brainrot_tier):void=
        Current := State.GetBrainrotCount(Tier)
        if (set State.CollectedBrainrots[Tier] = Current + 1) {}

    # Total passive income per second across every Brainrot in the base. This is the
    # value the income ticker pays out each PassiveIncomeTickPeriod. Marked
    # <transacts> because it reads the player's mutable collection state.
    TotalIncomePerSecond<public>(State:player_state)<transacts>:int=
        var Sum:int = 0
        for (Def : Catalog):
            Count := State.GetBrainrotCount(Def.Tier)
            set Sum += Count * Def.IncomePerSecond
        return Sum

    # Total number of Brainrots collected across all tiers (for HUD / achievements).
    TotalBrainrotCount<public>(State:player_state)<transacts>:int=
        var Sum:int = 0
        for (Def : Catalog):
            set Sum += State.GetBrainrotCount(Def.Tier)
        return Sum

    # Credit one income tick to the player's wallet. Returns the amount added so the
    # UI can flash it. The GameManager calls this once per PassiveIncomeTickPeriod.
    ApplyIncomeTick<public>(State:player_state):int=
        PerSecond := TotalIncomePerSecond(State)
        # Scale by the tick period so changing the cadence doesn't change the rate.
        Payout := Round(Int2Float(PerSecond) * PassiveIncomeTickPeriod)
        set State.Coins += Payout
        return Payout

    # --- Helpers -----------------------------------------------------------------

    Round<private>(X:float)<computes>:int= Floor[X + 0.5]
    Int2Float<private>(I:int)<computes>:float= 1.0 * I

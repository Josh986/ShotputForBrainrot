# Shotput for Brainrot — UI System
#
# Builds and updates the on-screen HUD using UEFN's UMG-in-Verse API
# (/UnrealEngine.com/Temporary/UI). Layout matches the design spec:
#
#   Top-Left    : Coins + equipped ball name
#   Top-Right   : Live distance + best distance
#   Bottom-Center: Charge meter (progress bar) with perfect-window flash
#   Center      : Floating reward text ("+1,240 coins!", "PERFECT!", "CRIT x2!")
#
# The UISystem holds references to the mutable widgets and exposes typed update
# methods that the GameManager calls each frame / on events.

using { /Verse.org/Simulation }
using { /Verse.org/Colors }
using { /UnrealEngine.com/Temporary/UI }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/UI }
using { GameTypes }
using { Localization }

ui_system<public> := class:

    # Mutable text/bar widgets, created in Build() and updated at runtime.
    var CoinsText<private>:text_block = text_block{DefaultText := "0 coins"}
    var BallText<private>:text_block = text_block{DefaultText := "Stone"}
    var IncomeText<private>:text_block = text_block{DefaultText := "Income: 0/s  (0 Brainrots)"}
    var DistanceText<private>:text_block = text_block{DefaultText := "0 m"}
    var BestText<private>:text_block = text_block{DefaultText := "Best: 0 m"}
    var RewardText<private>:text_block = text_block{DefaultText := ""}
    # The bottom-center bar doubles as the charge meter (before a throw) AND the
    # Giant Brainrot escape bar (during the run home).
    var ChargeBar<private>:progress_bar = progress_bar{}

    # The canvas holding everything, added to each player's HUD.
    var MaybeCanvas<private>:?canvas = false

    # --- Build -------------------------------------------------------------------

    # Construct the HUD hierarchy and attach it to the given player's screen.
    # Call once per player when they join.
    Build<public>(Player:player):void=
        if (PlayerUI := GetPlayerUI[Player]):
            NewCanvas := MakeCanvas()
            set MaybeCanvas = option{NewCanvas}
            PlayerUI.AddWidget(canvas_add_data{Widget := NewCanvas})

    # Assemble the anchored canvas slots described in the layout spec.
    MakeCanvas<private>():canvas=
        canvas:
            Slots := array:
                # Top-left cluster: coins + ball.
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.0, Y := 0.0}, Maximum := vector2{X := 0.0, Y := 0.0}}
                    Offsets := margin{Left := 40.0, Top := 40.0, Right := 0.0, Bottom := 0.0}
                    Alignment := vector2{X := 0.0, Y := 0.0}
                    Widget := MakeVerticalStack(array{CoinsText, BallText, IncomeText})
                # Top-right cluster: live distance + best.
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 1.0, Y := 0.0}, Maximum := vector2{X := 1.0, Y := 0.0}}
                    Offsets := margin{Left := 0.0, Top := 40.0, Right := 40.0, Bottom := 0.0}
                    Alignment := vector2{X := 1.0, Y := 0.0}
                    Widget := MakeVerticalStack(array{DistanceText, BestText})
                # Bottom-center: charge meter.
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 1.0}, Maximum := vector2{X := 0.5, Y := 1.0}}
                    Offsets := margin{Left := 0.0, Top := 0.0, Right := 0.0, Bottom := 60.0}
                    Alignment := vector2{X := 0.5, Y := 1.0}
                    Widget := ChargeBar
                # Center: floating reward text.
                canvas_slot:
                    Anchors := anchors{Minimum := vector2{X := 0.5, Y := 0.4}, Maximum := vector2{X := 0.5, Y := 0.4}}
                    Alignment := vector2{X := 0.5, Y := 0.5}
                    Widget := RewardText

    # Stack widgets vertically (used for the top corner clusters).
    MakeVerticalStack<private>(Widgets:[]widget):stack_box=
        var Slots:[]stack_box_slot = array{}
        for (W : Widgets):
            set Slots += array{ stack_box_slot{ Widget := W } }
        stack_box{ Orientation := orientation.Vertical, Slots := Slots }

    # --- Runtime updates ---------------------------------------------------------

    # Update the top-left coin + ball readout.
    UpdateCoins<public>(Coins:int, BallName:string):void=
        CoinsText.SetText(FormatCoins(Coins))
        BallText.SetText(ToMessage("Ball: {BallName}"))

    # Update the top-left passive-income readout (coins/sec + base population).
    UpdateIncome<public>(PerSecond:int, TotalBrainrots:int):void=
        IncomeText.SetText(ToMessage("Income: {PerSecond}/s  ({TotalBrainrots} Brainrots)"))

    # Announce which Brainrot just spawned and that the chase is on. Shown center.
    ShowBrainrotSpawn<public>(BrainrotName:string):void=
        RewardText.SetText(ToMessage("You are a {BrainrotName}!  RUN HOME — tap to sprint!"))
        RewardText.SetTextColor(NamedColors.Yellow)

    # Drive the escape bar + live countdown during the Giant Brainrot chase. The
    # bottom-center bar is repurposed as the escape meter; it flashes red when time
    # is nearly up so the danger reads instantly.
    UpdateChase<public>(EscapeProgress:float, TimeRemaining:float):void=
        ChargeBar.SetProgress(EscapeProgress)
        BarColor := if (TimeRemaining < 1.5) { NamedColors.Red } else { NamedColors.Lime }
        ChargeBar.SetBarFillColor(BarColor)
        RewardText.SetText(ToMessage("RUN!  {FloatToMeters(TimeRemaining * 10.0)} — tap to sprint!"))

    # Show the outcome of a chase: captured (joined base) or eaten (lost it).
    ShowCaptureResult<public>(Escaped:logic, BrainrotName:string, IncomeAdded:int):void=
        ChargeBar.SetProgress(0.0)
        if (Escaped?):
            RewardText.SetText(ToMessage("CAPTURED {BrainrotName}!  +{IncomeAdded}/s income"))
            RewardText.SetTextColor(NamedColors.Lime)
        else:
            RewardText.SetText(ToMessage("EATEN!  The Giant Brainrot got your {BrainrotName}"))
            RewardText.SetTextColor(NamedColors.Red)

    # Update the top-right distance readout during flight.
    UpdateDistance<public>(CurrentMeters:float, BestMeters:float):void=
        DistanceText.SetText(ToMessage("{FloatToMeters(CurrentMeters)} m"))
        BestText.SetText(ToMessage("Best: {FloatToMeters(BestMeters)} m"))

    # Update the charge meter fill (0..1) and flash color inside the perfect window.
    UpdateChargeMeter<public>(Percent:float, InPerfectWindow:logic):void=
        ChargeBar.SetProgress(Percent)
        BarColor := if (InPerfectWindow?) { NamedColors.Lime } else { NamedColors.Yellow }
        ChargeBar.SetBarFillColor(BarColor)

    # Pop floating reward text after a throw. `Crit` and `Perfect` change styling.
    ShowReward<public>(Coins:int, Perfect:logic, Crit:logic):void=
        Prefix := if (Crit?) { "CRIT x2!  " } else if (Perfect?) { "PERFECT!  " } else { "" }
        RewardText.SetText(ToMessage("{Prefix}+{Coins} coins!"))
        Color := if (Crit?) { NamedColors.Magenta } else if (Perfect?) { NamedColors.Lime } else { NamedColors.White }
        RewardText.SetTextColor(Color)

    # Clear the floating reward text (call after its animation window).
    ClearReward<public>():void=
        RewardText.SetText(ToMessage(""))

    # --- Formatting helpers ------------------------------------------------------

    # Pretty-print coins (rounded, no decimals).
    FormatCoins<private>(Coins:int):message=
        ToMessage("{Coins} coins")

    # Meters shown as a whole number for a clean arcade readout.
    FloatToMeters<private>(M:float)<computes>:int=
        Floor[M + 0.5]

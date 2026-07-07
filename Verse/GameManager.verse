# Shotput for Brainrot — Game Manager
#
# The top-level orchestrator and the single Verse device you place in the UEFN map.
# It wires every subsystem together and drives the core gameplay loop:
#
#     Throw ball  ->  Earn coins  ->  Upgrade  ->  Throw farther  ->  Repeat
#
# Responsibilities:
#   * Spawn/own each subsystem (physics, throw, economy, shop, save, distance, UI).
#   * Handle player join: load save, build HUD, bind input.
#   * Run the per-player charge -> release -> simulate -> reward -> save cycle.
#   * Expose shop hooks (button devices in the map call these).
#
# Place this device in the map and assign its editable references (ball prop,
# throw button, ground/throw-circle markers) in the Details panel.

using { /Verse.org/Simulation }
using { /Verse.org/Simulation/Tags }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Playspaces }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { GameConstants }
using { GameTypes }
using { BallCatalog }
using { PhysicsSystem }
using { ThrowSystem }
using { ShopSystem }
using { SaveSystem }
using { DistanceTrackingSystem }
using { BrainrotSystem }
using { BaseSystem }
using { UISystem }

game_manager<public> := class(creative_device):

    # --- Editable references (assign in the UEFN Details panel) ------------------

    # The prop used as the flying ball. A single shared prop is teleported per throw.
    @editable
    var BallProp:creative_prop = creative_prop{}

    # Button the player presses to charge/throw (press = charge, release = throw).
    @editable
    var ThrowButton:button_device = button_device{}

    # Marker prop whose location defines the throw circle / launch origin.
    @editable
    var ThrowCircleMarker:creative_prop = creative_prop{}

    # Optional visual for the Giant Brainrot that chases the player home. Toggled
    # visible during the chase and hidden otherwise. Purely cosmetic for the POC.
    @editable
    var GiantBrainrotProp:creative_prop = creative_prop{}

    # --- Subsystems --------------------------------------------------------------

    Catalog<private>:[]ball_def = MakeBallCatalog()

    var Physics<private>:physics_system = physics_system{}
    var Throw<private>:throw_system = throw_system{}
    var Save<private>:save_system = save_system{}
    var Distance<private>:distance_tracking_system = distance_tracking_system{}
    var Brainrot<private>:brainrot_system = brainrot_system{}
    var Base<private>:base_system = base_system{}
    var UI<private>:ui_system = ui_system{}
    # Shop needs the catalog, so it is built in OnBegin once Catalog is available.
    var MaybeShop<private>:?shop_system = false

    # Per-player runtime flag so a player can't start a second charge mid-throw.
    var BusyPlayers<private>:[player]logic = map{}

    # Flags players who are mid-chase, so their throw-button presses become sprint
    # taps instead of starting a new throw. (One active chase at a time in this POC.)
    var ChasingPlayers<private>:[player]logic = map{}

    # --- Lifecycle ---------------------------------------------------------------

    # UEFN entry point. Sets up subsystems and subscribes to player + input events.
    OnBegin<override>()<suspends>:void=
        # Build the shop with the catalog injected.
        set MaybeShop = option{ shop_system{ Catalog := Catalog } }

        # Locate the launch origin from the marker prop (raised to launch height).
        Origin := MakeLaunchOrigin()
        Physics.Initialize(BallProp, Origin.Z - LaunchHeight)
        Distance.SetThrowCircle(Origin)

        # Hide the Giant Brainrot until a chase begins.
        GiantBrainrotProp.Hide()

        # Wire the throw button.
        ThrowButton.InteractedWithEvent.Subscribe(OnThrowPressed)

        # Handle everyone already present, then future joiners.
        for (Player : GetPlayspace().GetPlayers()):
            OnPlayerJoin(Player)
        GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerJoin)

        # Start the passive-income heartbeat: every tick, each collected Brainrot
        # pays into its owner's wallet. This is the game's long-term money source.
        spawn { RunIncomeTicker() }

    # Passive income loop. Runs forever, crediting every player's base income once
    # per PassiveIncomeTickPeriod and refreshing their coin/income HUD.
    RunIncomeTicker<private>()<suspends>:void=
        loop:
            Sleep(PassiveIncomeTickPeriod)
            for (Player : GetPlayspace().GetPlayers()):
                State := Save.Load(Player)
                Payout := Base.ApplyIncomeTick(State)
                if (Payout > 0):
                    Save.Save(Player, State)
                    RefreshCoinUI(Player, State)

    # Compute the launch origin from the throw-circle marker + configured height.
    MakeLaunchOrigin<private>():vector3=
        T := ThrowCircleMarker.GetTransform()
        vector3:
            X := T.Translation.X
            Y := T.Translation.Y
            Z := T.Translation.Z + LaunchHeight

    # Set up a newly joined player: load save + build their HUD + refresh readouts.
    OnPlayerJoin<private>(Player:player):void=
        State := Save.Load(Player)
        UI.Build(Player)
        RefreshCoinUI(Player, State)
        UI.UpdateDistance(0.0, State.BestDistanceMeters)

    # --- Core throw loop ---------------------------------------------------------

    # Fired when a player interacts with the throw button. Because the button uses
    # a single interaction, we model "press to charge, auto-release at nice power":
    # the player taps to start charging and taps again to release. This keeps input
    # simple on all platforms. (For hold-to-charge, bind press/release separately.)
    OnThrowPressed<private>(Agent:agent):void=
        if (Player := player[Agent]):
            # If this player is currently fleeing the Giant Brainrot, the button is a
            # sprint tap that fills their escape bar rather than a new throw.
            if (IsChasing := ChasingPlayers[Player], IsChasing?):
                Brainrot.RegisterTap()
            else if (not IsBusy(Player)?):
                spawn { RunThrowCycle(Player) }

    # Whether the player currently has a throw in progress.
    IsBusy<private>(Player:player)<computes>:logic=
        if (Busy := BusyPlayers[Player], Busy?) { return true }
        return false

    # The full charge -> release -> simulate -> reward -> save sequence for one throw.
    RunThrowCycle<private>(Player:player)<suspends>:void=
        if (set BusyPlayers[Player] = true) {}
        State := Save.Load(Player)
        Ball := GetBallById(Catalog, State.CurrentBallId)

        # 1. Charge phase: fill the meter, updating the HUD until it tops out.
        Throw.BeginCharge()
        ChargeLevel := State.GetUpgradeLevel(player_upgrade_kind.ChargeSpeed)
        loop:
            Throw.UpdateCharge(PhysicsTickPeriod, ChargeLevel)
            UI.UpdateChargeMeter(Throw.GetChargePercent(), Throw.IsInPerfectWindow())
            if (Throw.GetChargePercent() >= 1.0) { break }
            Sleep(PhysicsTickPeriod)

        # 2. Release: compute launch parameters (Strength upgrade applied inside).
        StrengthLevel := State.GetUpgradeLevel(player_upgrade_kind.Strength)
        Params := Throw.ReleaseCharge(StrengthLevel, 0.0)  # yaw 0 = down +X field
        Throw.Reset()
        UI.UpdateChargeMeter(0.0, false)

        # 3. Simulate flight. Physics returns the completed throw_result.
        Distance.BeginTracking()
        Origin := MakeLaunchOrigin()
        Result := Physics.Launch(
            Origin,
            Params.Speed,
            Params.Direction,
            Ball.BounceMultiplier,
            Params.WasPerfect)

        # 4. Update distance HUD + best-distance record.
        _ = Distance.Update(vector3{X := Origin.X + Result.DistanceMeters * 100.0, Y := Origin.Y, Z := Origin.Z})
        _ = Save.TryRecordBestDistance(State, Result.DistanceMeters)
        UI.UpdateDistance(Result.DistanceMeters, State.BestDistanceMeters)

        # 5. The distance decides WHICH Brainrot spawns at the landing spot. Distance
        #    is not money — it is access. Farther throws unlock hungrier, richer tiers.
        SpawnedDef := Brainrot.ResolveTier(Result.DistanceMeters)
        UI.ShowBrainrotSpawn(SpawnedDef.Name)
        Sleep(1.2)   # Beat so the player reads "You are a <Tier> Brainrot!".

        # 6. THE CHASE. You have become the Brainrot; the Giant Brainrot wakes up and
        #    hunts you. Run home (tap the throw button to sprint) before time runs out.
        Outcome := RunChase(Player, SpawnedDef)

        # 7. Resolve the chase. Survive -> the Brainrot joins your base and pays income
        #    forever, plus a one-time welcome bonus. Caught -> you lose it entirely.
        if (Outcome.Escaped?):
            Base.AddBrainrot(State, SpawnedDef.Tier)
            Bonus := Round(Int2Float(SpawnedDef.IncomePerSecond) * CaptureBonusSeconds)
            set State.Coins += Bonus
            UI.ShowCaptureResult(true, SpawnedDef.Name, SpawnedDef.IncomePerSecond)
        else:
            UI.ShowCaptureResult(false, SpawnedDef.Name, 0)

        # 8. Persist + refresh the wallet/income HUD.
        RefreshCoinUI(Player, State)
        Save.Save(Player, State)

        # 9. Brief result window, then clear and free the player for the next throw.
        Sleep(BannerDisplaySeconds)
        UI.ClearReward()
        if (set BusyPlayers[Player] = false) {}

    # Drive the Giant Brainrot chase for one throw. Shows the Giant, runs the
    # countdown/escape-bar race (fed by sprint taps via OnThrowPressed), updates the
    # HUD each tick, and returns whether the player made it home. Marked <suspends>
    # because it awaits real time while the player reacts.
    RunChase<private>(Player:player, Def:brainrot_def)<suspends>:chase_outcome=
        if (set ChasingPlayers[Player] = true) {}
        GiantBrainrotProp.Show()
        Brainrot.BeginChase(Def)
        loop:
            Brainrot.Tick(ChaseTickPeriod)
            UI.UpdateChase(Brainrot.GetEscapeProgress(), Brainrot.GetTimeRemaining())
            if (Brainrot.IsResolved()?) { break }
            Sleep(ChaseTickPeriod)
        # Chase finished — clean up shared chase state.
        GiantBrainrotProp.Hide()
        if (set ChasingPlayers[Player] = false) {}
        UI.UpdateChargeMeter(0.0, false)
        return Brainrot.GetOutcome()

    # --- Shop hooks (call these from button devices in the map) ------------------

    # Buy one level of a player upgrade for the given player.
    BuyUpgrade<public>(Player:player, Kind:player_upgrade_kind):purchase_result=
        if (Shop := MaybeShop?):
            State := Save.Load(Player)
            Outcome := Shop.PurchaseUpgrade(State, Kind)
            if (Outcome = purchase_result.Success):
                RefreshCoinUI(Player, State)
                Save.Save(Player, State)
            return Outcome
        return purchase_result.InvalidTarget

    # Unlock a ball from the catalog for the given player.
    BuyBall<public>(Player:player, BallId:int):purchase_result=
        if (Shop := MaybeShop?):
            State := Save.Load(Player)
            Outcome := Shop.PurchaseBall(State, BallId)
            if (Outcome = purchase_result.Success):
                RefreshCoinUI(Player, State)
                Save.Save(Player, State)
            return Outcome
        return purchase_result.InvalidTarget

    # Equip an already-owned ball for the given player.
    EquipBall<public>(Player:player, BallId:int):purchase_result=
        if (Shop := MaybeShop?):
            State := Save.Load(Player)
            Outcome := Shop.EquipBall(State, BallId)
            if (Outcome = purchase_result.Success):
                RefreshCoinUI(Player, State)
                Save.Save(Player, State)
            return Outcome
        return purchase_result.InvalidTarget

    # --- Helpers -----------------------------------------------------------------

    # Refresh the top-left coins + equipped-ball readout AND the passive-income line
    # for a player. Called after throws, captures, purchases, and every income tick.
    RefreshCoinUI<private>(Player:player, State:player_state):void=
        Ball := GetBallById(Catalog, State.CurrentBallId)
        UI.UpdateCoins(State.Coins, Ball.Name)
        UI.UpdateIncome(Base.TotalIncomePerSecond(State), Base.TotalBrainrotCount(State))

    # Round a float to the nearest int.
    Round<private>(X:float)<computes>:int= Floor[X + 0.5]

    Int2Float<private>(I:int)<computes>:float= 1.0 * I

# Shotput for Brainrot — Throw System
#
# Manages the charge meter and converts a player's charge release into launch
# parameters (speed + direction). Handles perfect-throw detection and applies the
# player's Strength and ChargeSpeed upgrades.
#
# Flow:
#   1. Player presses throw -> BeginCharge() starts filling the meter (0..1).
#   2. UI polls GetChargePercent() each frame to draw the meter.
#   3. Player releases -> ReleaseCharge() returns a launch_params snapshot.
#   4. GameManager feeds launch_params into PhysicsSystem.Launch().

using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { GameConstants }
using { GameTypes }

# Everything the physics system needs to launch a ball, plus perfect-throw flag.
launch_params<public> := struct:
    Speed<public>:float          # Launch speed in cm/s (already upgrade-boosted).
    Direction<public>:vector3    # Unit launch direction (angle applied).
    WasPerfect<public>:logic     # Released inside the perfect window?

throw_system<public> := class:

    # Charge progress from 0.0 (empty) to 1.0 (full). Read by the UI.
    var Charge<private>:float = 0.0

    # Whether the meter is currently filling.
    var IsCharging<private>:logic = false

    # Elapsed charge time this cycle (seconds).
    var ChargeElapsed<private>:float = 0.0

    # --- Public API --------------------------------------------------------------

    # Begin filling the charge meter. Safe to call repeatedly (no-op if charging).
    BeginCharge<public>():void=
        if (not IsCharging?):
            set IsCharging = true
            set ChargeElapsed = 0.0
            set Charge = 0.0

    # Advance the charge meter. Call every frame while charging. `ChargeSpeedLevel`
    # is the player's ChargeSpeed upgrade level (fills faster at higher levels).
    # The meter ping-pongs at 100% so a distracted player never overshoots to 0.
    UpdateCharge<public>(DeltaSeconds:float, ChargeSpeedLevel:int):void=
        if (IsCharging?):
            SpeedMult := 1.0 + ChargeSpeedPerLevel * Int2Float(ChargeSpeedLevel)
            Duration := BaseChargeDuration / SpeedMult
            set ChargeElapsed += DeltaSeconds
            # Normalized 0..1 progress, clamped so it holds at full charge.
            RawCharge := ChargeElapsed / Duration
            set Charge = Clamp(RawCharge, 0.0, 1.0)

    # Release the charge and compute launch parameters. `StrengthLevel` is the
    # player's Strength upgrade level. Returns launch_params for the physics system.
    ReleaseCharge<public>(StrengthLevel:int, LaunchYaw:float)<computes>:launch_params=
        # Map charge 0..1 onto the launch speed band.
        BaseSpeed := MinLaunchSpeed + (MaxLaunchSpeed - MinLaunchSpeed) * Charge

        # Perfect-throw detection + bonus.
        Perfect := Charge >= PerfectThrowWindowStart
        PerfectMult := if (Perfect?) { PerfectThrowBonusMultiplier } else { 1.0 }

        # Apply Strength upgrade.
        StrengthMult := 1.0 + StrengthPerLevel * Int2Float(StrengthLevel)

        FinalSpeed := BaseSpeed * PerfectMult * StrengthMult

        # Reset meter state for the next throw.
        Dir := ComputeLaunchDirection(LaunchYaw)

        return launch_params:
            Speed := FinalSpeed
            Direction := Dir
            WasPerfect := Perfect

    # Reset the meter after a throw completes.
    Reset<public>():void=
        set IsCharging = false
        set Charge = 0.0
        set ChargeElapsed = 0.0

    # Current charge for the UI (0..1).
    GetChargePercent<public>()<computes>:float= Charge

    # Is the player inside the perfect window right now? (UI can flash the meter.)
    IsInPerfectWindow<public>()<computes>:logic= Charge >= PerfectThrowWindowStart

    # --- Internal helpers --------------------------------------------------------

    # Build a unit launch direction from a horizontal yaw (radians) and the fixed
    # launch angle. Yaw lets the stadium face any direction; pitch controls arc.
    ComputeLaunchDirection<private>(Yaw:float)<computes>:vector3=
        Pitch := DegreesToRadians(LaunchAngleDegrees)
        CosP := Cos(Pitch)
        vector3:
            X := CosP * Cos(Yaw)
            Y := CosP * Sin(Yaw)
            Z := Sin(Pitch)

    DegreesToRadians<private>(Deg:float)<computes>:float= Deg * 3.14159265 / 180.0

    Clamp<private>(V:float, Lo:float, Hi:float)<computes>:float=
        if (V < Lo) { return Lo }
        if (V > Hi) { return Hi }
        return V

    Int2Float<private>(I:int)<computes>:float= 1.0 * I

# Shotput for Brainrot — Physics System
#
# Owns the ballistic simulation of a live ball: applying an initial impulse,
# integrating gravity, detecting/handling ground bounces, and reporting when the
# ball comes to rest. Runs a fixed-timestep loop for deterministic arcade feel.
#
# Design: This module is intentionally self-contained. It knows nothing about
# coins, UI, or upgrades — it only simulates motion and returns a throw_result.

using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { GameConstants }
using { GameTypes }

physics_system<public> := class:

    # The moving prop that visually represents the ball (a creative_prop or similar).
    # Assigned by the GameManager when a ball is spawned.
    var MaybeBallProp<private>:?creative_prop = false

    # Live simulation state.
    var Position<private>:vector3 = vector3{}
    var Velocity<private>:vector3 = vector3{}
    var LaunchOrigin<private>:vector3 = vector3{}
    var GroundZ<private>:float = 0.0
    var Bounces<private>:int = 0
    var Airtime<private>:float = 0.0
    var IsLive<private>:logic = false

    # Ground bounce energy for the ball currently in flight (ball-modified).
    var ActiveRestitution<private>:float = BounceRestitution

    # --- Public API --------------------------------------------------------------

    # Bind the ball prop and record where the ground plane sits for this stadium.
    Initialize<public>(BallProp:creative_prop, GroundHeight:float):void=
        set MaybeBallProp = option{BallProp}
        set GroundZ = GroundHeight

    # Launch the ball. `LaunchSpeed` (cm/s) and `LaunchDir` (unit vector) come from
    # the ThrowSystem; `RestitutionMult` lets fancier balls bounce more.
    # This is a suspends function: it runs the physics loop until the ball rests,
    # then returns the completed throw_result to the caller.
    Launch<public>(
        Origin:vector3,
        LaunchSpeed:float,
        LaunchDir:vector3,
        RestitutionMult:float,
        WasPerfect:logic
    )<suspends>:throw_result=

        # Reset per-throw state.
        set LaunchOrigin = Origin
        set Position = Origin
        set Velocity = LaunchDir * LaunchSpeed
        set Bounces = 0
        set Airtime = 0.0
        set IsLive = true
        set ActiveRestitution = BounceRestitution * RestitutionMult

        # Fixed-timestep integration loop.
        loop:
            if (not IsLive?):
                break
            Step(PhysicsTickPeriod)
            Sleep(PhysicsTickPeriod)

        # Build and return the result for this throw.
        Distance := HorizontalDistance(LaunchOrigin, Position) / 100.0  # cm -> meters
        return throw_result:
            DistanceMeters := Distance
            AirtimeSeconds := Airtime
            Bounces := Bounces
            WasPerfect := WasPerfect

    # --- Internal simulation -----------------------------------------------------

    # Advance the simulation by DeltaSeconds using semi-implicit Euler integration.
    Step<private>(DeltaSeconds:float):void=
        # 1. Apply gravity to vertical velocity.
        set Velocity = vector3:
            X := Velocity.X
            Y := Velocity.Y
            Z := Velocity.Z - GravityAcceleration * DeltaSeconds

        # 2. Integrate position.
        var NewPosition:vector3 = Position + Velocity * DeltaSeconds

        # 3. Ground collision + bounce handling.
        if (NewPosition.Z <= GroundZ):
            set NewPosition = HandleBounce(NewPosition)

        set Position = NewPosition
        set Airtime += DeltaSeconds

        # 4. Push the visual prop to the new position (best-effort; ignore failure).
        if (Ball := MaybeBallProp?):
            MoveResult := Ball.TeleportTo[NewPosition, Ball.GetTransform().Rotation]

        # 5. Rest detection: low overall speed while on/near the ground ends the throw.
        if (NewPosition.Z <= GroundZ + 5.0, Speed(Velocity) < RestSpeedThreshold):
            set IsLive = false

    # Reflect + dampen velocity on a ground bounce, clamp to ground plane, count it.
    HandleBounce<private>(HitPosition:vector3):vector3=
        set Bounces += 1
        set Velocity = vector3:
            # Horizontal velocity loses energy to friction each bounce.
            X := Velocity.X * GroundFriction
            Y := Velocity.Y * GroundFriction
            # Vertical velocity reflects upward, scaled by restitution.
            Z := Abs(Velocity.Z) * ActiveRestitution
        # Snap back to the ground plane so the ball never sinks below the field.
        return vector3{ X := HitPosition.X, Y := HitPosition.Y, Z := GroundZ }

    # --- Math helpers ------------------------------------------------------------

    # Magnitude of a 3D vector.
    Speed<private>(V:vector3)<computes>:float=
        Sqrt(V.X * V.X + V.Y * V.Y + V.Z * V.Z)

    # Absolute value helper (Verse has no built-in for float here).
    Abs<private>(X:float)<computes>:float=
        if (X < 0.0) { return -X }
        return X

    # Horizontal (XY-plane) distance between two points, ignoring height.
    HorizontalDistance<private>(A:vector3, B:vector3)<computes>:float=
        DX := B.X - A.X
        DY := B.Y - A.Y
        Sqrt(DX * DX + DY * DY)

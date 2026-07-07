# Shotput for Brainrot — Distance Tracking System
#
# Continuously measures the horizontal distance of the ball from the throw circle
# while a throw is live, feeding the top-right distance HUD in real time and
# reporting the final landed distance. Also maps distance to the nearest passed
# stadium marker (every 50 m) for "You reached the 300m marker!" feedback.

using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { GameConstants }

distance_tracking_system<public> := class:

    # World-space location of the throw circle (launch origin, XY used).
    var ThrowCircleOrigin<private>:vector3 = vector3{}

    # Peak horizontal distance reached during the current throw (meters).
    var CurrentDistanceMeters<private>:float = 0.0

    # --- Public API --------------------------------------------------------------

    # Set the throw circle location. Called once when the stadium is built.
    SetThrowCircle<public>(Origin:vector3):void=
        set ThrowCircleOrigin = Origin

    # Reset the live distance at the start of each throw.
    BeginTracking<public>():void=
        set CurrentDistanceMeters = 0.0

    # Update from the ball's current world position. Keeps the *max* distance so a
    # ball that rolls backward after a bounce doesn't reduce the displayed score.
    # Returns the current (peak) distance in meters for the HUD.
    Update<public>(BallPosition:vector3):float=
        DX := BallPosition.X - ThrowCircleOrigin.X
        DY := BallPosition.Y - ThrowCircleOrigin.Y
        Meters := Sqrt(DX * DX + DY * DY) / 100.0   # cm -> meters
        if (Meters > CurrentDistanceMeters):
            set CurrentDistanceMeters = Meters
        return CurrentDistanceMeters

    # Current tracked distance (meters).
    GetDistanceMeters<public>()<computes>:float= CurrentDistanceMeters

    # The highest 50 m marker the ball has passed (e.g. 337 m -> 300).
    GetLastPassedMarker<public>()<computes>:int=
        Interval := MarkerIntervalMeters
        MarkerCount := Floor[CurrentDistanceMeters / (1.0 * Interval)]
        return MarkerCount * Interval

    # World positions of every distance marker, laid out along +X from the circle.
    # Used by the stadium builder to place marker props. Returns meters + position.
    GenerateMarkerPositions<public>()<computes>:[]vector3=
        var Markers:[]vector3 = array{}
        var M:int = MarkerIntervalMeters
        loop:
            if (M > StadiumLengthMeters) { break }
            set Markers += array:
                vector3:
                    X := ThrowCircleOrigin.X + Int2Float(M) * 100.0
                    Y := ThrowCircleOrigin.Y
                    Z := ThrowCircleOrigin.Z
            set M += MarkerIntervalMeters
        return Markers

    Int2Float<private>(I:int)<computes>:float= 1.0 * I

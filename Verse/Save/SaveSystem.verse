# Shotput for Brainrot — Save System
#
# Persists per-player progress using UEFN's `player_scoped_stat` style storage via
# the weak_map keyed on `player`. In UEFN, true cross-session persistence is done
# with a `persistable` module + verse-authored persistent data; this POC wraps that
# behind a simple interface so the storage backend can be swapped later.
#
# What we persist: coins, best distance, current ball, unlocked balls, upgrade levels.
#
# NOTE: Full disk/cloud persistence in UEFN requires marking data classes with
# `<persistable>` and declaring a module-level `var` weak_map. That syntax is shown
# in Docs/SETUP.md. Here we keep an in-memory store that mirrors that shape so the
# rest of the game compiles and runs in a test map.

using { /Verse.org/Simulation }
using { GameTypes }

save_system<public> := class:

    # In-memory store mapping each player to their saved state. Swap this for a
    # persistent weak_map (see Docs) to enable cross-session saves.
    var Store<private>:[player]player_state = map{}

    # Load a player's state, creating a fresh default profile on first play.
    Load<public>(Player:player):player_state=
        if (Existing := Store[Player]):
            return Existing
        NewState := player_state{}
        if (set Store[Player] = NewState) {}
        return NewState

    # Persist a player's state. In this POC this simply writes to the in-memory
    # store; wire this to a persistable weak_map for real saves (see SETUP.md).
    Save<public>(Player:player, State:player_state):void=
        if (set Store[Player] = State) {}

    # Convenience: record a new best distance if it beats the stored one.
    # Returns true if a new record was set (UI can celebrate it).
    TryRecordBestDistance<public>(State:player_state, DistanceMeters:float):logic=
        if (DistanceMeters > State.BestDistanceMeters):
            set State.BestDistanceMeters = DistanceMeters
            return true
        return false

    # Reset a player's progress back to defaults (used by a debug/reset button).
    ResetProgress<public>(Player:player):player_state=
        Fresh := player_state{}
        if (set Store[Player] = Fresh) {}
        return Fresh

using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

# Fires a sequence of cinematics based on REAL-WORLD time.
# Cinematic 0 plays at StartEpochSeconds, then each following cinematic plays
# DelayBetweenSeconds after the previous one. The correct point in the schedule
# is computed from the wall clock on every boot, so a server restart never
# desyncs the timeline and nothing needs to be persisted.
cinematic_event_array_device := class(creative_device):

    # The cinematic sequence devices to play, in order.
    # Each device should be set to "Everyone" so Play() works without an agent.
    @editable Sequences : []cinematic_sequence_device = array{}

    # Unix timestamp (seconds since Jan 1 1970 UTC) at which the FIRST cinematic
    # plays. This is the anchor for the whole schedule.
    # use https://www.epochconverter.com
    @editable StartEpochSeconds : float = 0.0

    # Real seconds between each cinematic (86400 = 24 hours).
    @editable DelayBetweenSeconds : float = 86400.0

    # On boot, immediately play the most recent cinematic whose time has already
    # passed — useful if a cinematic leaves the world in a lasting state you want
    # reflected after a restart. Set to false to only play cinematics live.
    @editable PlayMostRecentOnBoot : logic = true

    OnBegin<override>()<suspends> : void =
        Sleep(0.0) # Let the scene finish loading

        # How many cinematics are already "due" based on the real-world clock.
        DueCount := ComputeDueCount()

        # 1. Optionally reflect current state by jumping the last due cinematic to
        #    its final frame — the world ends up in the state that cinematic leaves
        #    behind, without replaying the animation.
        if (PlayMostRecentOnBoot?, DueCount > 0, Seq := Sequences[DueCount - 1]):
            Seq.GoToEndAndStop()
            Print("Boot: sought cinematic #{DueCount - 1} to its end frame.")

        # 2. Walk a boundary marker to the fire time of the NEXT cinematic.
        #    NextTime = StartEpochSeconds + NextIndex * DelayBetweenSeconds,
        #    built by repeated addition (Verse has no implicit int*float).
        var NextIndex : int = DueCount
        var NextTime : float = StartEpochSeconds
        for (I := 0..NextIndex - 1):
            set NextTime += DelayBetweenSeconds

        # 3. Stay running and fire each remaining cinematic on schedule.
        loop:
            if (NextIndex >= Sequences.Length):
                break # The whole timeline has played

            WaitSeconds := NextTime - GetSecondsSinceEpoch()
            if (WaitSeconds > 0.0):
                Print("Cinematic #{NextIndex} in {WaitSeconds} seconds.")
                Sleep(WaitSeconds)

            if (Seq := Sequences[NextIndex]):
                Seq.Play()
                Print("Playing cinematic #{NextIndex}.")
            set NextIndex += 1
            set NextTime += DelayBetweenSeconds

    # Returns how many cinematics should already have played for the current real
    # time, clamped to the number of sequences available.
    ComputeDueCount()<transacts> : int =
        Elapsed := GetSecondsSinceEpoch() - StartEpochSeconds
        var Count : int = 0
        if (Elapsed >= 0.0, Steps := Floor[Elapsed / DelayBetweenSeconds]):
            set Count = Steps + 1 # Steps is the index of the latest due cinematic
        if (Count > Sequences.Length):
            set Count = Sequences.Length
        Count

using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

# A human-readable UTC date/time you can fill in from the Details panel,
# instead of hunting for a raw Unix timestamp.
event_date := class<concrete>:
    @editable Year : int = 2026
    @editable Month : int = 1   # 1 = January
    @editable Day : int = 1     # 1 = first of the month
    @editable Hour : int = 0    # 0-23, UTC
    @editable Minute : int = 0
    @editable Second : int = 0

# Fires a sequence of cinematics based on REAL-WORLD time.
# Cinematic 0 plays at StartDate, then each following cinematic plays
# DelayBetweenSeconds after the previous one. The correct point in the schedule
# is computed from the wall clock on every boot, so a server restart never
# desyncs the timeline and nothing needs to be persisted.
cinematic_event_array_device := class(creative_device):

    # --- Calendar constants (all UTC, leap seconds ignored) ---
    SecondsInAMinute : int = 60
    SecondsInAnHour : int = 3600
    SecondsInADay : int = 86400
    SecondsInAYear : int = 31536000     # 365 days
    SecondsInALeapYear : int = 31622400 # 366 days
    DaysInMonth : []int = array{31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}

    # The cinematic sequence devices to play, in order.
    # Each device should be set to "Everyone" so Play() works without an agent.
    @editable Sequences : []cinematic_sequence_device = array{}

    # Calendar date/time (UTC) at which the FIRST cinematic plays.
    @editable StartDate : event_date = event_date{}

    # Real seconds between each cinematic (86400 = 24 hours).
    @editable DelayBetweenSeconds : int = 86400

    # On boot, immediately play the most recent cinematic whose time has already
    # passed — useful if a cinematic leaves the world in a lasting state you want
    # reflected after a restart. Set to false to only play cinematics live.
    @editable PlayMostRecentOnBoot : logic = true

    # Playback rate for the boot "catch-up" play. Because some cinematic tracks
    # only apply while actually playing, we fast-forward through the sequence
    # instead of snapping to the end. High = near-instant. Set to 1.0 for normal.
    @editable BootPlaybackRate : float = 50.0

    # Unix epoch (seconds) of cinematic 0, computed from StartDate in OnBegin.
    var StartEpoch : int = 0

    OnBegin<override>()<suspends> : void =
        Sleep(0.0) # Let the scene finish loading

        # Convert the human-readable StartDate into the epoch anchor.
        set StartEpoch = GetEpochFromDate(StartDate)
        Print("Schedule anchored at epoch {StartEpoch}.")

        # How many cinematics are already "due" based on the real-world clock.
        DueCount := ComputeDueCount()

        # 1. Optionally reflect current state by fast-forwarding the last due
        #    cinematic to its end. Playing it at a high rate actually runs the
        #    animation (so all tracks apply) but reaches the end near-instantly.
        if (PlayMostRecentOnBoot?, DueCount > 0, Seq := Sequences[DueCount - 1]):
            Seq.SetPlayRate(BootPlaybackRate)
            Seq.Play()
            Print("Boot: fast-forwarding cinematic #{DueCount - 1} to its end.")

        # 2. Fire each remaining cinematic when the clock reaches its target time.
        var NextIndex : int = DueCount
        loop:
            if (NextIndex >= Sequences.Length):
                break # The whole timeline has played

            TargetEpoch := StartEpoch + NextIndex * DelayBetweenSeconds

            # Poll once per second until real time reaches this cinematic's slot.
            loop:
                if (Now := Int[GetSecondsSinceEpoch()], Now >= TargetEpoch):
                    break
                Sleep(1.0)

            if (Seq := Sequences[NextIndex]):
                Seq.Play()
                Print("Playing cinematic #{NextIndex}.")
            set NextIndex += 1

    # Returns how many cinematics should already have played for the current real
    # time, clamped to the number of sequences available.
    ComputeDueCount()<transacts> : int =
        var Count : int = 0
        if (Now := Int[GetSecondsSinceEpoch()]):
            var TargetEpoch : int = StartEpoch
            loop:
                if (Count >= Sequences.Length):
                    break
                if (TargetEpoch > Now):
                    break # This cinematic's time hasn't arrived yet
                set Count += 1
                set TargetEpoch += DelayBetweenSeconds
        Count

    # Converts a calendar date/time (UTC) into Unix epoch seconds.
    # Sums whole years 1970..Year-1 and whole months January..Month-1, so it is
    # accurate for every month and leap year.
    GetEpochFromDate(D : event_date)<transacts> : int =
        var Total : int = 0

        # Whole years from 1970 up to (but not including) the target year.
        var Y : int = 1970
        loop:
            if (Y >= D.Year):
                break
            set Total += (if (IsLeapYear(Y)?) { SecondsInALeapYear } else { SecondsInAYear })
            set Y += 1

        # Whole months from January up to (but not including) the target month,
        # using base lengths (February counted as 28 here).
        var M : int = 1
        loop:
            if (M >= D.Month):
                break
            if (Days := DaysInMonth[M - 1]):
                set Total += Days * SecondsInADay
            set M += 1

        # Add February's leap day if the target date is in/after March of a leap year.
        if (IsLeapYear(D.Year)?, D.Month > 2):
            set Total += SecondsInADay

        # Remaining days within the month, then the time of day.
        set Total += (D.Day - 1) * SecondsInADay
        set Total += D.Hour * SecondsInAnHour
        set Total += D.Minute * SecondsInAMinute
        set Total += D.Second
        Total

    # Standard Gregorian leap-year test.
    IsLeapYear(Year : int)<transacts> : logic =
        if (Mod[Year, 4] = 0, Mod[Year, 100] <> 0):
            true
        else if (Mod[Year, 400] = 0):
            true
        else:
            false

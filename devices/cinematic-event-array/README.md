This Verse device enables a collection of cinematic sequences to be activated based on real-world time.

Sequences → add your array of cinematic sequence devices, in the order they should play. Each sequence device should be set to "Everyone."

StartDate → the UTC date and time the FIRST cinematic fires. Fill in Year / Month / Day / Hour / Minute / Second directly. These are in UTC, so use this site to convert your local time to UTC: "https://dateful.com/convert/utc" — make sure to switch it to the "24" hour clock so the Hour field (0–23) matches.

DelayBetweenSeconds → the number of seconds between each cinematic (24 hours = 86400 seconds).

PlayMostRecentOnBoot → should always be true if you want your cinematic to persist between sessions.

BootPlaybackRate → used to achieve a "snapping" effect so the cinematic stays up-to-date. Higher values like 50 will play the cinematic at an increased speed to snap it to the end. Refrain from setting this past 100.

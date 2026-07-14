This verse device enables a collection of cinematic sequences to be activated based on real world time.

Sequences -> add array of sequences in the verse device.
StartEpochSeconds -> use this site "https://www.epochconverter.com/" to translate a date for the first event to fire
DelayBetweenSeconds -> enter amount of seconds between each cinematic. (24 hours - 86400 seconds)
PlayMostRecentOnBoot -> Should always be true if you want your cinematic to persist between sessions.
BootPlaybackRate -> used to achieve a "snapping" effect so the cinematic stays up-to-date. Higher values like 50 will play the cinematic at an increased speed to snap it to the end. Refrain from setting this past 100.

# audio

Ambient background sound player for relaxation.

## Service
- **AmbientSoundService** (`ChangeNotifier`) — singleton that owns an `AudioPlayer`. Supports three looping tracks: Birds, Waterfall, Forest. `togglePlay(trackName)` pauses the current track or switches to a new one.

## Widget
- **AmbientSoundWidget** — compact UI rendered on the Entry (home) screen that lets the user pick a track and toggle playback.

## Tracks
| Name      | Asset path                        |
|-----------|-----------------------------------|
| Birds     | `assets/music/birds-relaxing.mp3` |
| Waterfall | `assets/music/waterfall.mp3`      |
| Forest    | `assets/music/forest-music.mp3`   |

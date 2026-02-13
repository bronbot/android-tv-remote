# android-tv-remote

An [OpenClaw](https://github.com/openclaw/openclaw) skill for controlling Android/Google TV via ADB over your local network.

Launch streaming apps, search for content, control playback, take screenshots — all through your AI assistant.

## What it does

- **Launch apps**: Netflix, Max, Disney+, Hulu, Prime Video, YouTube, Peacock, Apple TV+, and more
- **Search & play content**: Type search queries, navigate results, hit play
- **Remote control**: Volume, power, home, back, directional navigation
- **Screenshots**: Capture what's on screen for the AI to analyze and navigate
- **Smart navigation**: Screenshot → analyze → navigate → screenshot loop ensures the agent never navigates blind

## Requirements

- `adb` installed on the host machine (`sudo apt install adb`)
- Android/Google TV with **Developer Options → ADB Debugging** enabled
- TV and host on the same network
- First connection requires approving the RSA key popup on the TV

## Setup

1. Install the skill in your OpenClaw workspace under `skills/android-tv-remote/`
2. Add your TV details to `TOOLS.md`:
   ```markdown
   ### TV
   - IP: 192.168.0.6
   - Brand: Sony
   - Model: BRAVIA 4K VH2
   - Profile: YourName
   ```
3. Connect: `scripts/tv-remote.sh 192.168.0.6 connect`
4. Approve the ADB connection on your TV when prompted

## Usage

The skill includes a helper script (`scripts/tv-remote.sh`) and a reference file for streaming app package names.

```bash
# Connect to TV
scripts/tv-remote.sh $TV connect

# Launch Max
scripts/tv-remote.sh $TV launch com.wbd.stream

# Search for a show
scripts/tv-remote.sh $TV type "ten year old tom"

# Navigate the UI
scripts/tv-remote.sh $TV navigate left up up enter

# Take a screenshot
scripts/tv-remote.sh $TV screenshot /tmp/tv.png

# Volume / power
scripts/tv-remote.sh $TV volume up 5
scripts/tv-remote.sh $TV power
```

## How it works

TV UIs can't be scraped like web pages. The skill uses a **screenshot-navigate loop**:

1. Take a screenshot of the current TV screen
2. Send it to a vision model to understand the UI state
3. Determine the next navigation steps
4. Execute them via ADB key events
5. Screenshot again to confirm
6. Repeat until the target is reached

This makes navigation reliable even across different apps with different layouts.

## Supported apps

See [`references/app-packages.md`](references/app-packages.md) for the full list of package names (Netflix, Max, Disney+, Hulu, Prime Video, YouTube, Peacock, Apple TV+, Crunchyroll, Plex, Spotify, Twitch, Tubi, Pluto TV, and more).

## License

MIT

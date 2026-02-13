---
name: android-tv-remote
description: "Control Android/Google TV via ADB over network. Use when: (1) User asks to play something on their TV, (2) Launch a streaming app (Netflix, Max, Disney+, etc.), (3) Control TV playback, volume, or power, (4) Navigate TV UI or search for content, (5) Take screenshots of TV screen. Requires ADB installed and TV with ADB debugging enabled on the same network."
---

# Android TV Remote Control

Control Android/Google TV devices via ADB over the local network. Navigate UIs, launch apps, search for content, and play shows — all through text commands.

## Prerequisites

- `adb` installed (`sudo apt install adb`)
- TV with **Developer Options > ADB Debugging** enabled
- TV and agent on same network (or reachable via Tailscale)
- First connection requires approving the ADB auth popup on the TV

## Quick Reference

Helper script at `scripts/tv-remote.sh`:

```bash
TV=192.168.0.6  # Set to TV's IP

# Connect
scripts/tv-remote.sh $TV connect

# List installed streaming apps
scripts/tv-remote.sh $TV apps

# Launch an app
scripts/tv-remote.sh $TV launch com.wbd.stream

# Take screenshot (returns file path)
scripts/tv-remote.sh $TV screenshot /tmp/tv.png

# Navigate UI
scripts/tv-remote.sh $TV navigate left up up up enter

# Type text in search
scripts/tv-remote.sh $TV type "ten year old tom"

# Volume control
scripts/tv-remote.sh $TV volume up 5
scripts/tv-remote.sh $TV volume mute

# Send key
scripts/tv-remote.sh $TV key HOME
scripts/tv-remote.sh $TV key PLAY

# Power on/off
scripts/tv-remote.sh $TV power
```

## The Screenshot-Navigate Loop

**Critical pattern**: TV UIs cannot be navigated blind. Always use a screenshot → analyze → navigate → screenshot loop.

1. Take screenshot: `scripts/tv-remote.sh $TV screenshot /tmp/tv.png`
2. Analyze with vision model (image tool) to understand current UI state
3. Determine navigation steps needed
4. Execute navigation: `scripts/tv-remote.sh $TV navigate <directions>`
5. Screenshot again to confirm result
6. Repeat until target reached

## Play Content Workflow

To play a show/movie on a streaming app:

1. **Connect**: `scripts/tv-remote.sh $TV connect`
2. **Launch app**: `scripts/tv-remote.sh $TV launch <package>` — see `references/app-packages.md` for package names
3. **Wait + Screenshot**: `sleep 5 && scripts/tv-remote.sh $TV screenshot /tmp/tv.png`
4. **Handle profile picker**: If "Who's Watching?" screen, the user's profile is usually pre-selected. Press enter: `scripts/tv-remote.sh $TV key ENTER`
5. **Wait for home screen**: `sleep 8` — streaming apps are slow to load
6. **Navigate to search**: Use screenshot loop to find and select search icon
7. **Type search query**: `scripts/tv-remote.sh $TV type "show name"`
8. **Wait for results**: `sleep 3`
9. **Screenshot + navigate to result**: Use screenshot loop to find and select the show
10. **Select + play**: Navigate to play button and press enter

## Key Lessons

- **Streaming apps are slow** — always wait 5-10 seconds after launching apps or changing screens
- **Profile pickers are persistent** — some apps (Max, Netflix) return to profile picker if the app restarts. Avoid force-stopping apps unnecessarily
- **Netflix steals focus** — on some TVs, Netflix auto-launches or hijacks foreground. Force-stop it if it interferes: `adb -s $TV:5555 shell am force-stop com.netflix.ninja`
- **ADB text input** — spaces must be `%s` when using raw `adb shell input text`. The helper script handles this automatically
- **Screenshots are your eyes** — never navigate more than 2-3 steps without taking a screenshot to confirm position
- **HOME is your reset** — if lost, press HOME and start the navigation over

## TV Configuration (per-user)

Store TV details in TOOLS.md:

```markdown
### TV
- IP: 192.168.0.6
- Brand: Sony
- Model: BRAVIA 4K VH2
- Profile: Jorge
```

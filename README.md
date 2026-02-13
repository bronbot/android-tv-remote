<div align="center">

# 📺 android-tv-remote

**Control your Android/Google TV with AI — via ADB over your local network.**

Launch apps · Search content · Control playback · Navigate UIs

[![OpenClaw Skill](https://img.shields.io/badge/OpenClaw-Skill-blue?style=flat-square)](https://github.com/openclaw/openclaw)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

</div>

## ✨ Features

| | |
|---|---|
| 🚀 **Launch Apps** | Netflix, Max, Disney+, Hulu, Prime Video, YouTube, Peacock, Apple TV+, and [16+ more](references/app-packages.md) |
| 🔍 **Search & Play** | Type queries, navigate results, hit play — hands free |
| 🎮 **Remote Control** | Volume, power, home, back, DPAD navigation |
| 📸 **Smart Vision** | Screenshot the TV and let the AI figure out what's on screen |
| 🧠 **Navigate Loop** | Screenshot → analyze → navigate → confirm — never navigates blind |

## 📋 Requirements

- `adb` on the host machine (`sudo apt install adb`)
- Android/Google TV with **Developer Options → ADB Debugging** enabled
- TV and host on the same local network
- Approve the RSA key popup on first connection

## 🚀 Quick Start

**1. Add the skill** to your OpenClaw workspace under `skills/android-tv-remote/`

**2. Configure your TV** in `TOOLS.md`:

```markdown
### TV
- IP: 192.168.0.6
- Brand: Sony
- Model: BRAVIA 4K VH2
- Profile: YourName
```

**3. Connect:**

```bash
scripts/tv-remote.sh 192.168.0.6 connect
```

**4. Start talking to your assistant:**

> "put on ten year old tom on max"

## 🛠️ Commands

```bash
TV=192.168.0.6

# Connection
scripts/tv-remote.sh $TV connect

# Launch a streaming app
scripts/tv-remote.sh $TV launch com.wbd.stream        # Max
scripts/tv-remote.sh $TV launch com.netflix.ninja      # Netflix
scripts/tv-remote.sh $TV launch com.disney.disneyplus  # Disney+

# Search for content
scripts/tv-remote.sh $TV type "breaking bad"

# Navigate the UI
scripts/tv-remote.sh $TV navigate left up up enter

# Screenshot (for AI vision analysis)
scripts/tv-remote.sh $TV screenshot /tmp/tv.png

# Volume
scripts/tv-remote.sh $TV volume up 5
scripts/tv-remote.sh $TV volume mute

# Power on/off
scripts/tv-remote.sh $TV power

# List installed streaming apps
scripts/tv-remote.sh $TV apps
```

## 🧠 How It Works

TV UIs can't be scraped like web pages. This skill uses a **screenshot-navigate loop**:

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Screenshot  │────▶│   Analyze   │────▶│  Navigate   │
│   TV screen  │     │  with vision│     │  via ADB    │
└─────────────┘     └─────────────┘     └──────┬──────┘
       ▲                                        │
       └────────────────────────────────────────┘
                    repeat until done
```

The AI sees exactly what you'd see on the TV, figures out where things are, and sends the right button presses to get there. No guessing.

## 📦 Supported Apps

Full list in [`references/app-packages.md`](references/app-packages.md):

> Netflix · Max · Disney+ · Hulu · Prime Video · YouTube · YouTube TV · Peacock · Paramount+ · Apple TV+ · Crunchyroll · Plex · Spotify · Twitch · Tubi · Pluto TV

## 💡 Tips

- **Streaming apps are slow** — the skill waits 5-10 seconds after launches and transitions
- **Profile pickers** — apps like Max and Netflix show "Who's Watching?" on launch; the skill handles it
- **If lost, press HOME** — reset and start navigation over
- **Screenshots are your eyes** — never go more than 2-3 navigation steps without confirming position

## 📄 License

MIT

---

<div align="center">

Built for [OpenClaw](https://github.com/openclaw/openclaw) 🐾

</div>

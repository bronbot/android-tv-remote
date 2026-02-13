# Common Streaming App Package Names

| App | Package Name |
|-----|-------------|
| Netflix | com.netflix.ninja |
| HBO Max / Max | com.wbd.stream |
| Disney+ | com.disney.disneyplus |
| Hulu | com.hulu.livingroomplus |
| Amazon Prime Video | com.amazon.amazonvideo.livingroom |
| YouTube | com.google.android.youtube.tv |
| YouTube TV | com.google.android.youtube.tvunplugged |
| Peacock | com.peacocktv.peacockandroid |
| Paramount+ | com.cbs.ott |
| Apple TV+ | com.apple.atve.androidtv.appletv |
| Crunchyroll | com.crunchyroll.crunchyroid |
| Plex | com.plexapp.android |
| Spotify | com.spotify.tv.android |
| Twitch | tv.twitch.android.app |
| Tubi | com.tubitv |
| Pluto TV | tv.pluto.android |

# Profile Selection Behavior

Most streaming apps show a "Who's Watching?" profile picker on launch. After selecting a profile with DPAD_CENTER, wait 5-10 seconds for the home screen to load before navigating.

Apps that commonly require profile selection:
- Netflix (com.netflix.ninja)
- Max (com.wbd.stream)
- Disney+ (com.disney.disneyplus)
- Hulu (com.hulu.livingroomplus)
- Amazon Prime Video

# Search Patterns

Most TV apps have search accessible via:
1. Left sidebar navigation (navigate left, then up to search icon)
2. KEYCODE_SEARCH keyevent (works on some apps)
3. Google TV global search (home screen search bar)

After opening search, use `input text` to type the query. Spaces must be encoded as `%s` for ADB.

# Navigation Tips

- TV UIs use DPAD navigation (up/down/left/right/center)
- Always take screenshots to confirm position before and after navigation
- Wait 2-5 seconds after app launches and page transitions
- If lost, press HOME and start over
- Profile pickers: Jorge profile is typically the first/leftmost — just press ENTER

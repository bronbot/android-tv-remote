#!/bin/bash
# Android TV Remote Control via ADB
# Usage: tv-remote.sh <tv_ip> <action> [args...]

set -euo pipefail

TV_IP="${1:?Usage: tv-remote.sh <tv_ip> <action> [args...]}"
TV_PORT="${TV_PORT:-5555}"
TV="$TV_IP:$TV_PORT"
ACTION="${2:?Specify action: connect|screenshot|launch|search|navigate|key|type|volume|power|apps|current}"
shift 2

adb_cmd() { adb -s "$TV" "$@"; }

case "$ACTION" in
  connect)
    adb connect "$TV" 2>&1
    adb_cmd shell getprop ro.product.brand 2>/dev/null && echo "---"
    adb_cmd shell getprop ro.product.model 2>/dev/null
    ;;

  screenshot)
    OUT="${1:-/tmp/tv_screenshot.png}"
    adb_cmd exec-out screencap -p > "$OUT"
    echo "$OUT"
    ;;

  launch)
    PACKAGE="${1:?Specify package name}"
    # Get the launcher activity
    ACTIVITY=$(adb_cmd shell dumpsys package "$PACKAGE" 2>/dev/null | grep -A1 "android.intent.action.MAIN" | grep -oP '[a-zA-Z0-9_.]+/[a-zA-Z0-9_.]+' | head -1)
    if [ -n "$ACTIVITY" ]; then
      adb_cmd shell am force-stop "$PACKAGE" 2>/dev/null
      sleep 1
      adb_cmd shell am start -n "$ACTIVITY" 2>&1
    else
      echo "Could not find launcher activity for $PACKAGE"
      exit 1
    fi
    ;;

  apps)
    # List installed streaming apps
    adb_cmd shell pm list packages 2>/dev/null | grep -iE "netflix|hbo|wbd|disney|hulu|prime|amazon|youtube|peacock|paramount|appletv|crunchyroll|plex|spotify|twitch" | sed 's/package://' | sort
    ;;

  current)
    # Show currently focused app
    adb_cmd shell dumpsys window | grep -i "mCurrentFocus\|mFocusedApp" 2>/dev/null | head -2
    ;;

  key)
    # Send keyevent(s): tv-remote.sh <ip> key HOME BACK ENTER
    for KEY in "$@"; do
      # Map common names to keycodes
      case "$(echo "$KEY" | tr '[:lower:]' '[:upper:]')" in
        HOME) adb_cmd shell input keyevent KEYCODE_HOME ;;
        BACK) adb_cmd shell input keyevent KEYCODE_BACK ;;
        ENTER|SELECT|OK) adb_cmd shell input keyevent KEYCODE_DPAD_CENTER ;;
        UP) adb_cmd shell input keyevent KEYCODE_DPAD_UP ;;
        DOWN) adb_cmd shell input keyevent KEYCODE_DPAD_DOWN ;;
        LEFT) adb_cmd shell input keyevent KEYCODE_DPAD_LEFT ;;
        RIGHT) adb_cmd shell input keyevent KEYCODE_DPAD_RIGHT ;;
        PLAY|PAUSE) adb_cmd shell input keyevent KEYCODE_MEDIA_PLAY_PAUSE ;;
        STOP) adb_cmd shell input keyevent KEYCODE_MEDIA_STOP ;;
        NEXT) adb_cmd shell input keyevent KEYCODE_MEDIA_NEXT ;;
        PREV) adb_cmd shell input keyevent KEYCODE_MEDIA_PREVIOUS ;;
        VOLUP) adb_cmd shell input keyevent KEYCODE_VOLUME_UP ;;
        VOLDOWN) adb_cmd shell input keyevent KEYCODE_VOLUME_DOWN ;;
        MUTE) adb_cmd shell input keyevent KEYCODE_VOLUME_MUTE ;;
        SEARCH) adb_cmd shell input keyevent KEYCODE_SEARCH ;;
        POWER) adb_cmd shell input keyevent KEYCODE_POWER ;;
        *) adb_cmd shell input keyevent "KEYCODE_$KEY" 2>/dev/null || adb_cmd shell input keyevent "$KEY" ;;
      esac
      sleep 0.3
    done
    ;;

  type)
    # Type text (spaces as %s for adb)
    TEXT="${*// /%s}"
    adb_cmd shell input text "$TEXT"
    ;;

  navigate)
    # Navigate: sequence of directions. e.g. tv-remote.sh <ip> navigate up up left enter
    for DIR in "$@"; do
      case "$(echo "$DIR" | tr '[:lower:]' '[:upper:]')" in
        UP) adb_cmd shell input keyevent KEYCODE_DPAD_UP ;;
        DOWN) adb_cmd shell input keyevent KEYCODE_DPAD_DOWN ;;
        LEFT) adb_cmd shell input keyevent KEYCODE_DPAD_LEFT ;;
        RIGHT) adb_cmd shell input keyevent KEYCODE_DPAD_RIGHT ;;
        ENTER|SELECT|OK) adb_cmd shell input keyevent KEYCODE_DPAD_CENTER ;;
        BACK) adb_cmd shell input keyevent KEYCODE_BACK ;;
        HOME) adb_cmd shell input keyevent KEYCODE_HOME ;;
        WAIT|W) sleep 2 ;;
        *) echo "Unknown direction: $DIR" ;;
      esac
      sleep 0.5
    done
    ;;

  volume)
    DIRECTION="${1:?Specify up, down, or mute}"
    AMOUNT="${2:-1}"
    case "$(echo "$DIRECTION" | tr '[:lower:]' '[:upper:]')" in
      UP) for i in $(seq 1 "$AMOUNT"); do adb_cmd shell input keyevent KEYCODE_VOLUME_UP; sleep 0.2; done ;;
      DOWN) for i in $(seq 1 "$AMOUNT"); do adb_cmd shell input keyevent KEYCODE_VOLUME_DOWN; sleep 0.2; done ;;
      MUTE) adb_cmd shell input keyevent KEYCODE_VOLUME_MUTE ;;
    esac
    ;;

  power)
    adb_cmd shell input keyevent KEYCODE_POWER
    ;;

  *)
    echo "Unknown action: $ACTION"
    echo "Actions: connect screenshot launch search navigate key type volume power apps current"
    exit 1
    ;;
esac

#!/bin/bash
# quick-play.sh — Fast playback using learned navigation sequences
# Usage: quick-play.sh <TV_IP> <action> [args...]
#
# Actions:
#   play <show>          - Play a show using learned sequence (falls back to search)
#   learn <show> <app>   - Record a new navigation sequence interactively
#   catalog              - List all known shows
#   update <show> <json> - Update show entry (season, episode, etc.)
#   app-info <package>   - Show learned patterns for an app
#   deep-link <show> <url> - Save a deep link for a show

set -euo pipefail

TV="${1:?Usage: quick-play.sh <TV_IP> <action> [args...]}"
ACTION="${2:?Missing action}"
shift 2

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CATALOG="$SKILL_DIR/data/tv-catalog.json"
TV_REMOTE="$SCRIPT_DIR/tv-remote.sh"
ADB_TARGET="$TV:5555"

# Ensure connected
adb connect "$ADB_TARGET" >/dev/null 2>&1

send_key() {
    adb -s "$ADB_TARGET" shell input keyevent "KEYCODE_$1"
}

wait_ms() {
    sleep "$(echo "scale=2; $1/1000" | bc)"
}

# Execute a learned navigation sequence from catalog
exec_sequence() {
    local show_key="$1"
    local steps
    steps=$(jq -r ".shows[\"$show_key\"].navSequence.steps[]" "$CATALOG" 2>/dev/null)
    
    if [ -z "$steps" ]; then
        echo "NO_SEQUENCE"
        return 1
    fi

    local step_count
    step_count=$(jq ".shows[\"$show_key\"].navSequence.steps | length" "$CATALOG")
    
    echo "Executing $step_count-step sequence for '$show_key'..."
    
    for i in $(seq 0 $((step_count - 1))); do
        local action key package wait_time note
        action=$(jq -r ".shows[\"$show_key\"].navSequence.steps[$i].action" "$CATALOG")
        wait_time=$(jq -r ".shows[\"$show_key\"].navSequence.steps[$i].waitMs // 1000" "$CATALOG")
        note=$(jq -r ".shows[\"$show_key\"].navSequence.steps[$i].note // \"\"" "$CATALOG")
        
        case "$action" in
            launch)
                package=$(jq -r ".shows[\"$show_key\"].navSequence.steps[$i].package" "$CATALOG")
                echo "  [$((i+1))/$step_count] Launching $package..."
                "$TV_REMOTE" "$TV" launch "$package"
                ;;
            key)
                key=$(jq -r ".shows[\"$show_key\"].navSequence.steps[$i].key" "$CATALOG")
                [ -n "$note" ] && echo "  [$((i+1))/$step_count] $key ($note)" || echo "  [$((i+1))/$step_count] $key"
                send_key "$key"
                ;;
            navigate)
                local dirs
                dirs=$(jq -r ".shows[\"$show_key\"].navSequence.steps[$i].directions[]" "$CATALOG")
                echo "  [$((i+1))/$step_count] Navigate: $dirs"
                for dir in $dirs; do
                    send_key "DPAD_$(echo "$dir" | tr '[:lower:]' '[:upper:]')"
                    sleep 0.3
                done
                ;;
            type)
                local text
                text=$(jq -r ".shows[\"$show_key\"].navSequence.steps[$i].text" "$CATALOG")
                echo "  [$((i+1))/$step_count] Typing: $text"
                "$TV_REMOTE" "$TV" type "$text"
                ;;
            deep-link)
                local url
                url=$(jq -r ".shows[\"$show_key\"].navSequence.steps[$i].url" "$CATALOG")
                echo "  [$((i+1))/$step_count] Deep link: $url"
                adb -s "$ADB_TARGET" shell am start -a android.intent.action.VIEW -d "$url"
                ;;
        esac
        
        echo "    waiting ${wait_time}ms..."
        wait_ms "$wait_time"
    done
    
    # Update usage stats
    local now
    now=$(date -Idate)
    local tmp
    tmp=$(mktemp)
    jq ".shows[\"$show_key\"].navSequence.timesUsed += 1 | .shows[\"$show_key\"].navSequence.lastUsed = \"$now\" | .shows[\"$show_key\"].lastPlayed = \"$now\"" "$CATALOG" > "$tmp" && mv "$tmp" "$CATALOG"
    
    echo "DONE"
}

case "$ACTION" in
    play)
        QUERY=$(echo "$*" | tr '[:upper:]' '[:lower:]')
        
        # Search catalog by name or alias
        MATCH=$(jq -r --arg q "$QUERY" '
            .shows | to_entries[] | 
            select(
                .key == $q or 
                (.value.aliases // [] | any(. == $q))
            ) | .key' "$CATALOG" 2>/dev/null | head -1)
        
        if [ -n "$MATCH" ]; then
            CONFIDENCE=$(jq -r ".shows[\"$MATCH\"].navSequence.confidence // 0" "$CATALOG")
            echo "Found '$MATCH' in catalog (confidence: $CONFIDENCE)"
            
            # Check for deep link first
            DEEP_LINK=$(jq -r ".shows[\"$MATCH\"].deepLink // \"null\"" "$CATALOG")
            if [ "$DEEP_LINK" != "null" ]; then
                echo "Using deep link: $DEEP_LINK"
                adb -s "$ADB_TARGET" shell am start -a android.intent.action.VIEW -d "$DEEP_LINK"
                echo "DONE"
            else
                exec_sequence "$MATCH"
            fi
        else
            echo "NOT_FOUND: '$QUERY' not in catalog. Use the screenshot-navigate loop to find it, then save with 'learn'."
            exit 1
        fi
        ;;
    
    catalog)
        echo "=== TV Catalog ==="
        jq -r '.shows | to_entries[] | "\(.value.title) [\(.value.appName)] - S\(.value.lastSeason // "?")E\(.value.lastEpisode // "?") - confidence: \(.value.navSequence.confidence // "?") - played: \(.value.navSequence.timesUsed // 0)x"' "$CATALOG"
        echo ""
        echo "=== App Patterns ==="
        jq -r '.appPatterns | to_entries[] | "\(.value.name) [\(.key)] - profile: \(.value.hasProfilePicker) - load: \(.value.loadTimeMs)ms"' "$CATALOG"
        ;;
    
    update)
        SHOW_KEY=$(echo "$1" | tr '[:upper:]' '[:lower:]')
        shift
        JSON_PATCH="$*"
        tmp=$(mktemp)
        jq --arg key "$SHOW_KEY" --argjson patch "$JSON_PATCH" '.shows[$key] *= $patch' "$CATALOG" > "$tmp" && mv "$tmp" "$CATALOG"
        echo "Updated '$SHOW_KEY'"
        ;;
    
    add-show)
        # Usage: add-show <key> <app-package> <title> [aliases...]
        KEY=$(echo "$1" | tr '[:upper:]' '[:lower:]')
        APP="$2"
        TITLE="$3"
        shift 3
        ALIASES="$*"
        
        ALIAS_JSON=$(echo "$KEY $ALIASES" | tr ' ' '\n' | jq -R . | jq -s .)
        APP_NAME=$(jq -r --arg pkg "$APP" '.appPatterns[$pkg].name // "Unknown"' "$CATALOG")
        
        tmp=$(mktemp)
        jq --arg key "$KEY" --arg app "$APP" --arg title "$TITLE" --arg appName "$APP_NAME" --argjson aliases "$ALIAS_JSON" '
            .shows[$key] = {
                "app": $app,
                "appName": $appName,
                "title": $title,
                "lastPlayed": null,
                "lastSeason": null,
                "lastEpisode": null,
                "aliases": $aliases,
                "deepLink": null,
                "navSequence": {
                    "fromHome": "unknown - use screenshot loop first time",
                    "steps": [],
                    "confidence": 0,
                    "timesUsed": 0,
                    "lastUsed": null
                }
            }' "$CATALOG" > "$tmp" && mv "$tmp" "$CATALOG"
        echo "Added '$TITLE' to catalog"
        ;;
    
    save-sequence)
        # Usage: save-sequence <show-key> <steps-json>
        KEY=$(echo "$1" | tr '[:upper:]' '[:lower:]')
        shift
        STEPS_JSON="$*"
        NOW=$(date -Idate)
        tmp=$(mktemp)
        jq --arg key "$KEY" --argjson steps "$STEPS_JSON" --arg now "$NOW" '
            .shows[$key].navSequence.steps = $steps |
            .shows[$key].navSequence.confidence = 0.5 |
            .shows[$key].navSequence.lastUsed = $now
        ' "$CATALOG" > "$tmp" && mv "$tmp" "$CATALOG"
        echo "Saved navigation sequence for '$KEY'"
        ;;
    
    boost-confidence)
        # Call after a successful play to increase confidence
        KEY=$(echo "$1" | tr '[:upper:]' '[:lower:]')
        tmp=$(mktemp)
        jq --arg key "$KEY" '
            .shows[$key].navSequence.confidence = ([.shows[$key].navSequence.confidence + 0.1, 1.0] | min)
        ' "$CATALOG" > "$tmp" && mv "$tmp" "$CATALOG"
        CONF=$(jq -r --arg key "$KEY" '.shows[$key].navSequence.confidence' "$CATALOG")
        echo "Confidence for '$KEY' boosted to $CONF"
        ;;

    deep-link)
        KEY=$(echo "$1" | tr '[:upper:]' '[:lower:]')
        URL="$2"
        tmp=$(mktemp)
        jq --arg key "$KEY" --arg url "$URL" '.shows[$key].deepLink = $url' "$CATALOG" > "$tmp" && mv "$tmp" "$CATALOG"
        echo "Deep link saved for '$KEY': $URL"
        ;;
    
    app-info)
        PKG="$1"
        jq --arg pkg "$PKG" '.appPatterns[$pkg] // "Not found"' "$CATALOG"
        ;;

    *)
        echo "Unknown action: $ACTION"
        echo "Actions: play, catalog, update, add-show, save-sequence, boost-confidence, deep-link, app-info"
        exit 1
        ;;
esac

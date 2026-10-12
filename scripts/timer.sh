#!/usr/bin/env bash

# Status Bar Countdown Timer Module
# State file: ~/.cache/waybar-timer.json
# Schema: {"end": <epoch_timestamp>, "label": "<string>"}

STATE_FILE="$HOME/.cache/waybar-timer.json"

# Timer icon glyph via unicode escape sequence (\uf017 = nf-fa-clock)
ICON=$(printf "%b" "\uf017")

# Fallback output when no active timer state exists
if [ ! -f "$STATE_FILE" ]; then
    echo "{\"text\": \"${ICON} 00:00\", \"tooltip\": \"No active timer\\nUsage: timer <duration>\\nExample: timer 25m / timer 1h30m\", \"class\": \"inactive\"}"
    exit 0
fi

END=$(jq -r '.end' "$STATE_FILE" 2>/dev/null)
LABEL=$(jq -r '.label // ""' "$STATE_FILE" 2>/dev/null)

if [ -z "$END" ] || [ "$END" = "null" ]; then
    echo "{\"text\": \"${ICON} 00:00\", \"tooltip\": \"Invalid timer state\", \"class\": \"inactive\"}"
    exit 0
fi

NOW=$(date +%s)
REMAINING=$((END - NOW))

# Timer expiration handling
if [ "$REMAINING" -le 0 ]; then
    FLAG_FILE="$HOME/.cache/waybar-timer.notified"
    if [ ! -f "$FLAG_FILE" ]; then
        touch "$FLAG_FILE"
        MSG="${LABEL:-Timer}"
        notify-send -u critical -i "alarm-clock" "Timer Completed" "${MSG} has elapsed" 2>/dev/null || true
    fi
    echo "{\"text\": \"${ICON} 00:00\", \"tooltip\": \"${LABEL:-Timer} completed\", \"class\": \"done\"}"
    exit 0
fi

# Calculate hours, minutes, and seconds from remaining duration
HOURS=$((REMAINING / 3600))
MINS=$(( (REMAINING % 3600) / 60 ))
SECS=$((REMAINING % 60))

# Format formatted display string
if [ "$HOURS" -gt 0 ]; then
    DISPLAY=$(printf "%d:%02d:%02d" "$HOURS" "$MINS" "$SECS")
else
    DISPLAY=$(printf "%02d:%02d" "$MINS" "$SECS")
fi

# Class determination based on remaining time thresholds
if [ "$REMAINING" -le 60 ]; then
    CLASS="urgent"       # Under 1 minute remaining
elif [ "$REMAINING" -le 300 ]; then
    CLASS="warning"      # Under 5 minutes remaining
else
    CLASS="active"       # Normal countdown
fi

TOOLTIP="${LABEL:+$LABEL\n}Remaining: $DISPLAY\nFinished: $(date -d @"$END" '+%H:%M:%S')"

echo "{\"text\": \"${ICON} ${DISPLAY}\", \"tooltip\": \"${TOOLTIP}\", \"class\": \"${CLASS}\"}"

#!/usr/bin/env bash

# Combined CPU & GPU Temperature script for Waybar
# Supported modes:
#   "text"        -> CPU 55° | GPU 50°
#   "weather"     -> [Weather Icon] CPU 55° | GPU 50°
#   "icons"       -> [Hardware Icon] 55° | [Hardware Icon] 50°
#   "weather_raw" -> [Weather Icon] 55° | 50°

MODE="${1:-text}"

# Find CPU hwmon
HWMON_CPU=""
for h in /sys/class/hwmon/hwmon*; do
    [ -f "$h/name" ] || continue
    name=$(<"$h/name")
    if [[ "$name" == "k10temp" || "$name" == "coretemp" || "$name" == "zenpower" ]]; then
        HWMON_CPU="$h"
        CPU_NAME="$name"
        break
    fi
done

# Read CPU Temperature
CPU_TEMP="N/A"
CPU_VAL=0
TCTL=""
TCCD1=""

if [ -n "$HWMON_CPU" ]; then
    for lbl in "$HWMON_CPU"/temp*_label; do
        [ -f "$lbl" ] || continue
        label=$(<"$lbl")
        inp="${lbl%_label}_input"
        if [[ "$label" == "Tctl" || "$label" == "Package id 0" ]]; then
            if [ -f "$inp" ]; then
                raw=$(<"$inp")
                CPU_VAL=$(( raw / 1000 ))
                CPU_TEMP="${CPU_VAL}°"
                TCTL="${CPU_VAL}°C"
            fi
        elif [[ "$label" == "Tccd1" ]]; then
            if [ -f "$inp" ]; then
                TCCD1="$(( $(<"$inp") / 1000 ))°C"
            fi
        fi
    done
    if [ "$CPU_TEMP" == "N/A" ] && [ -f "$HWMON_CPU/temp1_input" ]; then
        CPU_VAL=$(( $(<"$HWMON_CPU/temp1_input") / 1000 ))
        CPU_TEMP="${CPU_VAL}°"
        TCTL="${CPU_VAL}°C"
    fi
fi

# =======================================================
# 1. GPU (Dedicated / NVIDIA) - [AKTIF / DITAMPILKAN]
# =======================================================
GPU_TEMP="N/A"
GPU_VAL=0
GPU_NAME=""
GPU_TEMP_DISPLAY=""
GPU_FAN_RPM=""
GPU_FAN_PCT=""

if command -v nvidia-smi &>/dev/null; then
    NV_INFO=$(nvidia-smi --query-gpu=temperature.gpu,name,fan.speed --format=csv,noheader,nounits 2>/dev/null | head -n 1)
    if [ -n "$NV_INFO" ]; then
        GPU_VAL=$(echo "$NV_INFO" | awk -F', ' '{print $1}')
        GPU_NAME=$(echo "$NV_INFO" | awk -F', ' '{print $2}')
        GPU_FAN_PCT=$(echo "$NV_INFO" | awk -F', ' '{print $3}' | tr -d ' ')
        if [ -n "$GPU_VAL" ] && [ "$GPU_VAL" -eq "$GPU_VAL" ] 2>/dev/null; then
            GPU_TEMP="${GPU_VAL}°"
            GPU_TEMP_DISPLAY="${GPU_VAL}°C"
        fi
    fi
    # Get fan RPM via nvidia-settings
    if command -v nvidia-settings &>/dev/null; then
        GPU_FAN_RPM=$(nvidia-settings -t -q '[fan:0]/GPUCurrentFanSpeedRPM' 2>/dev/null | tr -d ' ')
    fi
fi

# =======================================================
# 2. iGPU (Integrated GPU / AMD APU) - [DIKOMENTARI / NONAKTIF]
# =======================================================
# HWMON_IGPU=""
# for h in /sys/class/hwmon/hwmon*; do
#     [ -f "$h/name" ] || continue
#     name=$(<"$h/name")
#     if [[ "$name" == "amdgpu" || "$name" == "nouveau" || "$name" == "i915" ]]; then
#         HWMON_IGPU="$h"
#         IGPU_NAME="$name"
#         break
#     fi
# done
# 
# IGPU_TEMP="N/A"
# IGPU_VAL=0
# EDGE=""
# JUNCTION=""
# 
# if [ -n "$HWMON_IGPU" ]; then
#     for lbl in "$HWMON_IGPU"/temp*_label; do
#         [ -f "$lbl" ] || continue
#         label=$(<"$lbl")
#         inp="${lbl%_label}_input"
#         if [[ "$label" == "edge" ]]; then
#             if [ -f "$inp" ]; then
#                 raw=$(<"$inp")
#                 IGPU_VAL=$(( raw / 1000 ))
#                 IGPU_TEMP="${IGPU_VAL}°"
#                 EDGE="${IGPU_VAL}°C"
#             fi
#         elif [[ "$label" == "junction" ]]; then
#             if [ -f "$inp" ]; then
#                 JUNCTION="$(( $(<"$inp") / 1000 ))°C"
#             fi
#         fi
#     done
#     if [ "$IGPU_TEMP" == "N/A" ] && [ -f "$HWMON_IGPU/temp1_input" ]; then
#         IGPU_VAL=$(( $(<"$HWMON_IGPU/temp1_input") / 1000 ))
#         IGPU_TEMP="${IGPU_VAL}°"
#         EDGE="${IGPU_VAL}°C"
#     fi
# fi

# Determine CSS class based on maximum temperature
MAX_TEMP=$(( CPU_VAL > GPU_VAL ? CPU_VAL : GPU_VAL ))
if [ "$MAX_TEMP" -ge 80 ]; then
    CLASS="hot"
elif [ "$MAX_TEMP" -le 40 ] && [ "$MAX_TEMP" -gt 0 ]; then
    CLASS="cold"
else
    CLASS="normal"
fi

# Format Text
WI_THERM=$(printf "%b" "\ue350")
RPM_DISPLAY=""
if [ -n "$GPU_FAN_RPM" ]; then
    RPM_DISPLAY=" ${GPU_FAN_RPM} RPM"
fi

case "$MODE" in
    weather)
        # --- iGPU Format (Nonaktif) ---
        # TEXT="${WI_THERM} CPU ${CPU_TEMP} | iGPU ${IGPU_TEMP}"
        # --- GPU Format (Aktif) ---
        TEXT="${WI_THERM} CPU ${CPU_TEMP} | GPU ${GPU_TEMP}${RPM_DISPLAY}"
        ;;
    icons)
        TEXT=" ${CPU_TEMP} | 󰢮 ${GPU_TEMP}${RPM_DISPLAY}"
        ;;
    weather_raw)
        TEXT="${WI_THERM} ${CPU_TEMP} | ${GPU_TEMP}${RPM_DISPLAY}"
        ;;
    text|*)
        # --- iGPU Format (Nonaktif) ---
        # TEXT="CPU ${CPU_TEMP} | iGPU ${IGPU_TEMP}"
        # --- GPU Format (Aktif) ---
        TEXT="CPU ${CPU_TEMP} | GPU ${GPU_TEMP}${RPM_DISPLAY}"
        ;;
esac

TOOLTIP="CPU: ${TCTL:-${CPU_TEMP}} (${CPU_NAME:-unknown})"
[ -n "$TCCD1" ] && TOOLTIP="${TOOLTIP}\n   ↳ Tccd1: ${TCCD1}"

# Dedicated GPU tooltip entries
TOOLTIP="${TOOLTIP}\nGPU: ${GPU_TEMP_DISPLAY:-${GPU_TEMP}} (${GPU_NAME:-unknown})"
[ -n "$GPU_FAN_RPM" ] && TOOLTIP="${TOOLTIP}\n   ↳ Fan: ${GPU_FAN_RPM} RPM (${GPU_FAN_PCT:-?}%)"
[ -z "$GPU_FAN_RPM" ] && [ -n "$GPU_FAN_PCT" ] && TOOLTIP="${TOOLTIP}\n   ↳ Fan: ${GPU_FAN_PCT}%"

echo "{\"text\": \"${TEXT}\", \"tooltip\": \"${TOOLTIP}\", \"class\": \"${CLASS}\"}"

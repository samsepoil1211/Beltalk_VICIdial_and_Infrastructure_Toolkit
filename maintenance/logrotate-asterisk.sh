#!/bin/bash
# -----------------------------------------------------------
# VICIdial Log & Database Cleanup Script (Self-Installing)
# Author: Debjit (Beltalk Technology)
#
# Run once as root/privileged user. It will:
#   1. Copy itself to a stable path (/root/vicibox-toolkit/)
#   2. Install its own nightly cron job (if not already installed)
#   3. Run the actual cleanup immediately
#
# Re-running is safe - it will not duplicate the cron entry.
# -----------------------------------------------------------

# --- Self-install block ---
INSTALL_DIR="/root/vicibox-toolkit"
INSTALL_PATH="${INSTALL_DIR}/cleanup-final.sh"
# Runs 3x daily at 6:00 AM, 10:00 AM, and 2:00 PM IST - all inside the
# 5:30AM-6PM IST quiet window, before dialing resumes at 6PM IST.
# CRON_TZ pins this to IST regardless of the server's own system
# timezone (America/New_York) or US daylight saving changes.
# NOTE: CRON_TZ must be its own crontab line, not inline with the
# schedule - it applies to every entry below it in the crontab.
CRON_TZ_LINE="CRON_TZ=Asia/Kolkata"
CRON_SCHEDULE="0 6,10,14 * * *"
CRON_MARKER="# vicidial-cleanup-auto"

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Must run as root (use sudo)."
    exit 1
fi

mkdir -p "$INSTALL_DIR"

# Copy this script to the stable install path if not already running from there
SCRIPT_SOURCE="$(readlink -f "$0")"
if [ "$SCRIPT_SOURCE" != "$(readlink -f "$INSTALL_PATH")" ]; then
    cp -f "$SCRIPT_SOURCE" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"
    echo "Installed script to: $INSTALL_PATH"
fi

# Install cron job only if not already present
EXISTING_CRON=$(crontab -l 2>/dev/null | grep -F "$CRON_MARKER")
if [ -z "$EXISTING_CRON" ]; then
    # Check whether this cron implementation supports CRON_TZ (cronie 1.5+).
    # If unsupported, cron will silently ignore the line or error depending
    # on version - safer to detect and fall back to EDT-equivalent times.
    CRON_VERSION_STRING=$(crontab -V 2>&1 || cronie -V 2>&1 || echo "unknown")
    if echo "$CRON_VERSION_STRING" | grep -qi "cronie"; then
        SUPPORTS_CRON_TZ=1
    else
        SUPPORTS_CRON_TZ=0
    fi

    if [ "$SUPPORTS_CRON_TZ" -eq 1 ]; then
        (crontab -l 2>/dev/null; echo "$CRON_TZ_LINE"; echo "${CRON_SCHEDULE} ${INSTALL_PATH} ${CRON_MARKER}") | crontab -
        echo "Cron job installed (CRON_TZ supported): runs at 6AM/10AM/2PM IST daily."
    else
        # Fallback: EDT-equivalent times, valid only while US observes DST.
        # 6AM/10AM/2PM IST -> 8:30PM(prev day)/12:30AM/4:30AM EDT
        FALLBACK_SCHEDULE="30 20,0,4 * * *"
        (crontab -l 2>/dev/null; echo "${FALLBACK_SCHEDULE} ${INSTALL_PATH} ${CRON_MARKER}") | crontab -
        echo "WARNING: CRON_TZ not supported by this cron version."
        echo "Installed using EDT-equivalent times instead (valid only during US DST)."
        echo "Re-check this schedule in November when US falls back to EST."
    fi
else
    echo "Cron job already installed - skipping."
fi

echo "----------------------------------------"
echo "Running cleanup now..."
echo "----------------------------------------"

# --- Actual cleanup logic ---
LOGFILE="/cleanup-logs.txt"
THRESHOLD_MB=500
THRESHOLD_BYTES=$((THRESHOLD_MB * 1024 * 1024))

if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        opensuse*|sles*)
            APACHE_LOG_DIR="/var/log/apache2"
            ;;
        almalinux*|rhel*|centos*)
            APACHE_LOG_DIR="/var/log/httpd"
            ;;
        *)
            APACHE_LOG_DIR="/var/log/httpd"
            ;;
    esac
else
    ID="unknown"
    APACHE_LOG_DIR="/var/log/httpd"
fi

# NOTE: /var/log/amd removed from this list - confirmed not present on
# server202 and was a dead path in the original script (did nothing).
# If your box does use a different AMD log path, add it here.
LOG_DIRS=(
    "/var/log/asterisk"
    "/var/log/astguiclient"
    "$APACHE_LOG_DIR"
)

{
echo "----------------------------------------"
echo "VICIdial System Cleanup Script Started"
echo "----------------------------------------"
echo "Detected OS: $ID"
echo "Apache log directory: $APACHE_LOG_DIR"
echo "Start time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo

# --- Phase 1: File System Cleanup ---
TOTAL_SIZE=0
for DIR in "${LOG_DIRS[@]}"; do
    if [ -d "$DIR" ]; then
        DIR_SIZE=$(du -sb "$DIR" | awk '{print $1}')
        TOTAL_SIZE=$((TOTAL_SIZE + DIR_SIZE))
        HUMAN_SIZE=$(du -sh "$DIR" | awk '{print $1}')
        echo "• $DIR → $HUMAN_SIZE"
    fi
done
TOTAL_MB=$(echo "scale=2; $TOTAL_SIZE/1024/1024" | bc)
echo
echo "Total file log size: ${TOTAL_MB} MB"

if (( TOTAL_SIZE > THRESHOLD_BYTES )); then
    echo "File log size exceeded ${THRESHOLD_MB}MB. Cleaning up files..."
    for DIR in "${LOG_DIRS[@]}"; do
        if [ -d "$DIR" ]; then
            # Live *.log files: truncate in place, do not delete.
            find "$DIR" -type f -name "*.log" -exec truncate -s 0 {} \;

            # Rotated/rsyslog-style files (messages.*, messages.0, etc.)
            # that are NOT already compressed - truncate in place too,
            # since these can also be actively held open by syslog/rsyslog.
            find "$DIR" -type f -name "messages.*" ! -name "*.xz" ! -name "*.gz" \
                -exec truncate -s 0 {} \;

            # Already-compressed/archived files and known junk patterns:
            # safe to delete outright, nothing has these open.
            find "$DIR" -type f \( \
                -name "*.old" -o \
                -name "*.gz" -o \
                -name "*.xz" -o \
                -name "screenlog.*" -o \
                -name "agiout.*" -o \
                -name "safe_*" -o \
                -name "go_*" \
            \) -delete
        fi
    done
    echo "All junk file logs cleared (live/open files truncated, archived ones deleted)."
else
    echo "File log size under ${THRESHOLD_MB}MB. No file cleanup needed."
fi

# --- Phase 2: MySQL Archive Truncation ---
echo
echo "Wiping MySQL Archive Tables..."
mysql -e "
TRUNCATE TABLE asterisk.call_log_archive;
TRUNCATE TABLE asterisk.vicidial_log_archive;
TRUNCATE TABLE asterisk.vicidial_log_extended_archive;
TRUNCATE TABLE asterisk.vicidial_dial_log_archive;
TRUNCATE TABLE asterisk.vicidial_dial_cid_log_archive;
TRUNCATE TABLE asterisk.vicidial_carrier_log_archive;
TRUNCATE TABLE asterisk.vicidial_agent_log_archive;
TRUNCATE TABLE asterisk.vicidial_agent_visibility_log_archive;
TRUNCATE TABLE asterisk.vicidial_amd_log_archive;
"
echo "MySQL Archive tables successfully truncated."

echo
echo "Cleanup completed at $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "----------------------------------------"
} >> "$LOGFILE" 2>&1

echo "Done. Output logged to $LOGFILE"
echo "Cron job will run this automatically every night at 3:00 AM from now on."

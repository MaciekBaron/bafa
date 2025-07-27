#!/bin/bash

# This script checks the user's idle time on macOS. If the user has been
# idle for more than X seconds, it sends a push notification via ntfy.sh.

# --- Configuration ---
# The idle time threshold in seconds.
IDLE_THRESHOLD_SECONDS="${IDLE_THRESHOLD_SECONDS:-60}"

# The topic for the ntfy.sh notification.
NTFY_TOPIC="${NTFY_CLAUDE_TOPIC:-mytopic}"

# The message to send in the notification.
SUCCESS_MESSAGE="Claude needs your attention"

# --- Script Logic ---

echo "Checking user idle time..."

# Get the idle time in milliseconds using ioreg.
# The '-l' flag is used for compatibility with modern macOS versions.
# We divide by 1000000 to get milliseconds from nanoseconds.
idle_time_ms=$(ioreg -l -c IOHIDSystem | awk '/HIDIdleTime/ { print int($NF/1000000); exit }')

# Check if we successfully retrieved the idle time.
# If not, ioreg might have failed or the output format changed.
if [ -z "$idle_time_ms" ]; then
  echo "Error: Could not retrieve idle time. Exiting."
  exit 1
fi

# Convert idle time from milliseconds to seconds.
idle_time_seconds=$((idle_time_ms / 1000))

echo "User has been idle for $idle_time_seconds seconds."

# Compare the user's idle time with the threshold.
if [ "$idle_time_seconds" -gt "$IDLE_THRESHOLD_SECONDS" ]; then
  echo "Idle time ($idle_time_seconds s) is greater than the threshold ($IDLE_THRESHOLD_SECONDS s)."
  echo "Sending notification to ntfy.sh/$NTFY_TOPIC..."

  # Use curl to send the notification.
  # The -d flag sends the specified data as the request body.
  curl -d "$SUCCESS_MESSAGE" "ntfy.sh/$NTFY_TOPIC"

  # Add a newline for cleaner terminal output after curl.
  echo
  echo "Notification sent."
else
  echo "User is active. No notification sent."
fi

exit 0


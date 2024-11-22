#!/bin/bash

# Set the time thresholds
DELETE_THRESHOLD_DAYS=2  # Snapshots older than 2 days will be deleted
WARNING_THRESHOLD_DAYS=1 # Snapshots older than 1 day will get a warning

# Get the current date in seconds since epoch
CURRENT_TIME=$(date -u +%s)

# Log the thresholds for debugging
echo "Delete snapshots older than $DELETE_THRESHOLD_DAYS days."
echo "Warn about snapshots older than $WARNING_THRESHOLD_DAYS day(s)."

# Fetch all snapshots owned by the current account
ALL_SNAPSHOTS=$(aws ec2 describe-snapshots \
    --owner-ids self \
    --query "Snapshots[*].[SnapshotId,StartTime]" \
    --output json)

# Check if any snapshots were returned
if [ "$(echo "$ALL_SNAPSHOTS" | jq -r '. | length')" -eq 0 ]; then
    echo "No snapshots found."
    exit 0
fi

# Parse the JSON response
echo "$ALL_SNAPSHOTS" | jq -c '.[]' | while read SNAPSHOT; do 
    # Extract

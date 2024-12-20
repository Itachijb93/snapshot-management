#!/bin/bash

# Variables
AWS_REGION="us-east-1" # Update to your AWS region
TODAY=$(date -u +%Y-%m-%d)

# Fetch all snapshots owned by this account
echo "Fetching snapshots..."
ALL_SNAPSHOTS=$(aws ec2 describe-snapshots --owner-ids self --region $AWS_REGION --query 'Snapshots[*].[SnapshotId,StartTime]' --output text)

if [ -z "$ALL_SNAPSHOTS" ]; then
    echo "No snapshots found."
    exit 0
fi

# Initialize counters
TOTAL_SNAPSHOTS=0
DELETE_COUNT=0
TOMORROW_COUNT=0
TODAY_COUNT=0
SNAPSHOTS_FOUND=false

# List all snapshots with ages
echo "Listing all snapshots with their ages..."
echo "-----------------------------------------"
printf "%-20s %-20s %-10s\n" "Snapshot ID" "Creation Date" "Age (Days)"
echo "-----------------------------------------"

while read -r SNAPSHOT_ID START_TIME; do
    TOTAL_SNAPSHOTS=$((TOTAL_SNAPSHOTS + 1))

    # Parse the start time into days
    START_DATE=$(echo $START_TIME | cut -d'T' -f1)
    SNAPSHOT_AGE=$(( ($(date -u -d "$TODAY" +%s) - $(date -u -d "$START_DATE" +%s)) / 86400 ))

    printf "%-20s %-20s %-10s\n" "$SNAPSHOT_ID" "$START_DATE" "$SNAPSHOT_AGE"

    if [ $SNAPSHOT_AGE -gt 2 ]; then
        # Delete snapshots older than 2 days
        echo "Deleting snapshot: $SNAPSHOT_ID (Created: $START_DATE)"
        aws ec2 delete-snapshot --snapshot-id $SNAPSHOT_ID --region $AWS_REGION
        if [ $? -eq 0 ]; then
            DELETE_COUNT=$((DELETE_COUNT + 1))
        else
            echo "Error deleting snapshot: $SNAPSHOT_ID"
        fi
        SNAPSHOTS_FOUND=true
    elif [ $SNAPSHOT_AGE -eq 2 ]; then
        # Snapshots 1 day younger than 2 days
        echo "Snapshot $SNAPSHOT_ID (Created: $START_DATE) will be deleted tomorrow."
        TOMORROW_COUNT=$((TOMORROW_COUNT + 1))
    elif [ $SNAPSHOT_AGE -eq 0 ]; then
        # Snapshots created today
        echo "Snapshot $SNAPSHOT_ID (Created: $START_DATE) will be deleted in 2 days."
        TODAY_COUNT=$((TODAY_COUNT + 1))
    fi
done <<< "$ALL_SNAPSHOTS"

# Display a message if no snapshots were found older than two days
if ! $SNAPSHOTS_FOUND; then
    echo "No snapshots found older than two days to delete."
fi

# Summary
echo "-----------------------------------------"
echo "Summary:"
echo "Total snapshots found: $TOTAL_SNAPSHOTS"
echo "Snapshots deleted (older than 2 days): $DELETE_COUNT"
echo "Snapshots to be deleted tomorrow (age = 2 days): $TOMORROW_COUNT"
echo "Snapshots created today (age = 0 days): $TODAY_COUNT"

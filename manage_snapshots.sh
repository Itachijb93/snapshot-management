#!/bin/bash

# Variables
AWS_REGION="us-east-1" # Update to your AWS region
TODAY=$(date -u +%Y-%m-%d)

# Fetch all snapshots owned by this account
echo "Fetching snapshots..."
ALL_SNAPSHOTS=$(aws ec2 describe-snapshots --owner-ids self --region $AWS_REGION --query 'Snapshots[*].[SnapshotId,StartTime]' --output text)

# Initialize counters
TOTAL_SNAPSHOTS=0
DELETE_COUNT=0
TOMORROW_COUNT=0
TODAY_COUNT=0

# Process snapshots
echo "Processing snapshots..."
while read -r SNAPSHOT_ID START_TIME; do
    TOTAL_SNAPSHOTS=$((TOTAL_SNAPSHOTS ))
    
    # Parse the start time into days
    START_DATE=$(echo $START_TIME | cut -d'T' -f1)
    SNAPSHOT_AGE=$(( ($(date -u -d "$TODAY" +%s) - $(date -u -d "$START_DATE" +%s)) / 86400 ))

    if [ $SNAPSHOT_AGE -gt 2 ]; then
        # Delete snapshots older than 2 days
        echo "Deleting snapshot: $SNAPSHOT_ID (Created: $START_DATE)"
        aws ec2 delete-snapshot --snapshot-id $SNAPSHOT_ID --region $AWS_REGION
        if [ $? -eq 0 ]; then
            DELETE_COUNT=$((DELETE_COUNT ))
        else
            echo "Error deleting snapshot: $SNAPSHOT_ID"
        fi
    elif [ $SNAPSHOT_AGE -eq 2 ]; then
        # Snapshots 1 day younger than 2 days
        echo "Snapshot $SNAPSHOT_ID (Created: $START_DATE) will be deleted tomorrow."
        TOMORROW_COUNT=$((TOMORROW_COUNT ))
    elif [ $SNAPSHOT_AGE -eq 0 ]; then
        # Snapshots created today
        echo "Snapshot $SNAPSHOT_ID (Created: $START_DATE) will be deleted in 2 days."
        TODAY_COUNT=$((TODAY_COUNT ))
    fi
done <<< "$ALL_SNAPSHOTS"

# Display summary
echo "Summary:"
echo "Total snapshots: $TOTAL_SNAPSHOTS"
echo "Snapshots deleted: $DELETE_COUNT"
echo "Snapshots to be deleted tomorrow: $TOMORROW_COUNT"
echo "Snapshots created today: $TODAY_COUNT"

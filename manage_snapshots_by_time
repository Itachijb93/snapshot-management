#!/bin/bash

# Variables
AWS_REGION="us-east-1" # Update to your AWS region
NOW=$(date -u +%s) # Current time in seconds (UNIX timestamp)

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

# List all snapshots with ages
echo "Listing all snapshots with their ages in minutes..."
echo "------------------------------------------------------"
printf "%-20s %-20s %-15s\n" "Snapshot ID" "Creation Date" "Age (Minutes)"
echo "------------------------------------------------------"

while read -r SNAPSHOT_ID START_TIME; do
    TOTAL_SNAPSHOTS=$((TOTAL_SNAPSHOTS + 1))

    # Parse the start time into UNIX timestamp
    START_TIMESTAMP=$(date -u -d "$START_TIME" +%s)
    SNAPSHOT_AGE=$((($NOW - $START_TIMESTAMP) / 60)) # Age in minutes

    # List snapshot ID, creation date, and age in minutes
    printf "%-20s %-20s %-15s\n" "$SNAPSHOT_ID" "$START_TIME" "$SNAPSHOT_AGE"

    if [ $SNAPSHOT_AGE -gt 10 ]; then
        # Delete snapshots older than 10 minutes
        echo "Deleting snapshot: $SNAPSHOT_ID (Created: $START_TIME, Age: $SNAPSHOT_AGE minutes)"
        aws ec2 delete-snapshot --snapshot-id $SNAPSHOT_ID --region $AWS_REGION
        if [ $? -eq 0 ]; then
            DELETE_COUNT=$((DELETE_COUNT + 1))
        else
            echo "Error deleting snapshot: $SNAPSHOT_ID"
        fi
    fi
done <<< "$ALL_SNAPSHOTS"

# Display summary
echo "------------------------------------------------------"
echo "Summary:"
echo "Total snapshots found: $TOTAL_SNAPSHOTS"
echo "Snapshots deleted (older than 10 minutes): $DELETE_COUNT"

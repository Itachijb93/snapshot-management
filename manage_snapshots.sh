#!/bin/bash

# Set variables
REGION="us-east-1"  # Replace with your desired AWS region
DELETE_OLDER_THAN_DAYS=2  # Snapshots older than this will be deleted
WARN_OLDER_THAN_DAYS=1    # Snapshots older than this will generate a warning

# Function to calculate days between two dates
calculate_days() {
    local snapshot_date=$1
    local current_date=$(date +%Y-%m-%d)
    echo $(( ( $(date -d "$current_date" +%s) - $(date -d "$snapshot_date" +%s) ) / 86400 ))
}

# Fetch all snapshots owned by the account
SNAPSHOTS=$(aws ec2 describe-snapshots --owner-ids self --query 'Snapshots[*].[SnapshotId,StartTime]' --region "$REGION" --output text)

# Initialize counters
TOTAL_SNAPSHOTS=0
DELETE_COUNT=0
WARN_COUNT=0
SKIPPED_COUNT=0

# Process each snapshot
while IFS=$'\t' read -r SNAPSHOT_ID START_TIME; do
    TOTAL_SNAPSHOTS=$((TOTAL_SNAPSHOTS + 1))
    
    # Extract the date in YYYY-MM-DD format
    SNAPSHOT_DATE=$(echo "$START_TIME" | cut -d'T' -f1)
    
    # Calculate the age of the snapshot in days
    SNAPSHOT_AGE=$(calculate_days "$SNAPSHOT_DATE")

    echo "Snapshot: $SNAPSHOT_ID is $SNAPSHOT_AGE days old."

    # Handle 0-day-old snapshots
    if [[ $SNAPSHOT_AGE -eq 0 ]]; then
        echo "Snapshot $SNAPSHOT_ID is 0 days old. $((DELETE_OLDER_THAN_DAYS - SNAPSHOT_AGE)) day(s) left before deletion."
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        continue
    fi

    # Warn if the snapshot is older than the warning threshold but not yet for deletion
    if [[ $SNAPSHOT_AGE -ge $WARN_OLDER_THAN_DAYS && $SNAPSHOT_AGE -lt $DELETE_OLDER_THAN_DAYS ]]; then
        echo "Warning: Snapshot $SNAPSHOT_ID is $SNAPSHOT_AGE days old. $((DELETE_OLDER_THAN_DAYS - SNAPSHOT_AGE)) day(s) left before deletion."
        WARN_COUNT=$((WARN_COUNT + 1))
    fi

    # Delete if the snapshot is older than the delete threshold
    if [[ $SNAPSHOT_AGE -ge $DELETE_OLDER_THAN_DAYS ]]; then
        echo "Deleting snapshot: $SNAPSHOT_ID (Age: $SNAPSHOT_AGE days)"
        
        # Attempt to delete the snapshot
        DELETE_OUTPUT=$(aws ec2 delete-snapshot --snapshot-id "$SNAPSHOT_ID" --region "$REGION" 2>&1)
        if echo "$DELETE_OUTPUT" | grep -q "InvalidSnapshot.NotFound"; then
            echo "Error: Snapshot $SNAPSHOT_ID does not exist. Skipping."
        elif [[ $? -ne 0 ]]; then
            echo "Error deleting snapshot $SNAPSHOT_ID: $DELETE_OUTPUT"
        else
            echo "Successfully deleted snapshot: $SNAPSHOT_ID"
            DELETE_COUNT=$((DELETE_COUNT + 1))
        fi
    fi

done <<< "$SNAPSHOTS"

# Summary
echo
echo "Snapshot management completed."
echo "Total snapshots processed: $TOTAL_SNAPSHOTS"
echo "Snapshots deleted: $DELETE_COUNT"
echo "Snapshots warned: $WARN_COUNT"
echo "Snapshots skipped (0 days old): $SKIPPED_COUNT"

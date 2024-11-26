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

# Process each snapshot
while IFS=$'\t' read -r SNAPSHOT_ID START_TIME; do
    # Extract the date in YYYY-MM-DD format
    SNAPSHOT_DATE=$(echo "$START_TIME" | cut -d'T' -f1)
    
    # Calculate the age of the snapshot in days
    SNAPSHOT_AGE=$(calculate_days "$SNAPSHOT_DATE")

    echo "Snapshot: $SNAPSHOT_ID is $SNAPSHOT_AGE days old."

    # Warn if the snapshot is older than the warning threshold
    if [[ $SNAPSHOT_AGE -ge $WARN_OLDER_THAN_DAYS && $SNAPSHOT_AGE -lt $DELETE_OLDER_THAN_DAYS ]]; then
        echo "Warning: Snapshot $SNAPSHOT_ID is $SNAPSHOT_AGE days old. $((DELETE_OLDER_THAN_DAYS - SNAPSHOT_AGE)) day(s) left before deletion."
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
        fi
    fi

done <<< "$SNAPSHOTS"

echo "Snapshot management completed."

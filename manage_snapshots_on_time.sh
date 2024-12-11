#!/bin/bash

# ----------------------------------------------------------
# This script manages AWS EC2 snapshots based on their age.
# Snapshots older than a specified threshold (in minutes)
# will be deleted automatically.
# ----------------------------------------------------------

# Set the time threshold in minutes
DELETE_THRESHOLD_MINUTES=10  # Snapshots older than this value will be deleted

# Get the current time in seconds since the epoch
CURRENT_TIME=$(date -u +%s)  # Capture current UTC time in epoch format

# Log the threshold for debugging purposes
echo "Delete snapshots older than $DELETE_THRESHOLD_MINUTES minutes."

# Fetch all snapshots owned by the current account
ALL_SNAPSHOTS=$(aws ec2 describe-snapshots \
    --owner-ids self \               # Fetch snapshots owned by the current AWS account only
    --query "Snapshots[*].[SnapshotId,StartTime]" \  # Extract SnapshotId and StartTime fields
    --output json)                   # Output the data in JSON format for easy parsing

# Check if any snapshots were returned
if [ "$(echo "$ALL_SNAPSHOTS" | jq -r '. | length')" -eq 0 ]; then
    # If no snapshots are found, log a message and exit
    echo "No snapshots found."
    exit 0
fi

# Parse the JSON response and process each snapshot individually
echo "$ALL_SNAPSHOTS" | jq -c '.[]' | while read SNAPSHOT; do 
    # Extract snapshot ID and start time from the JSON data
    SNAPSHOT_ID=$(echo "$SNAPSHOT" | jq -r '.[0]')  # Extract the SnapshotId
    SNAPSHOT_TIME=$(echo "$SNAPSHOT" | jq -r '.[1]')  # Extract the StartTime

    # Convert the snapshot start time to seconds since epoch for comparison
    SNAPSHOT_TIME_EPOCH=$(date -d "$SNAPSHOT_TIME" +%s)  # Convert StartTime to epoch

    # Calculate the age of the snapshot in minutes
    SNAPSHOT_AGE_MINUTES=$(( (CURRENT_TIME - SNAPSHOT_TIME_EPOCH) / 60 ))

    # Check if the snapshot age exceeds the delete threshold
    if [ "$SNAPSHOT_AGE_MINUTES" -ge "$DELETE_THRESHOLD_MINUTES" ]; then
        # Log the deletion process
        echo "Deleting snapshot: $SNAPSHOT_ID (Age: $SNAPSHOT_AGE_MINUTES minutes)"
        
        # Attempt to delete the snapshot and capture the output
        DELETE_OUTPUT=$(aws ec2 delete-snapshot --snapshot-id "$SNAPSHOT_ID" 2>&1)
        if [ $? -eq 0 ]; then
            # Log success if the deletion command was successful
            echo "Successfully deleted snapshot: $SNAPSHOT_ID"
        else
            # Log failure if the deletion command failed
            echo "Failed to delete snapshot: $SNAPSHOT_ID"
            echo "Reason: $DELETE_OUTPUT"  # Include the error message for debugging
        fi
    else
        # Calculate the remaining time until the snapshot is eligible for deletion
        REMAINING_MINUTES=$((DELETE_THRESHOLD_MINUTES - SNAPSHOT_AGE_MINUTES))
        # Log the snapshot's age and remaining time
        echo "Snapshot: $SNAPSHOT_ID is $SNAPSHOT_AGE_MINUTES minutes old. $REMAINING_MINUTES minute(s) left to delete."
    fi
done

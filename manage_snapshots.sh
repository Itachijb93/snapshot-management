#!/bin/bash

# Specify the AWS region
AWS_REGION="us-east-1"  # Change this to your desired region

# Set the time thresholds
DELETE_THRESHOLD_DAYS=2  # Snapshots older than 2 days will be deleted
WARNING_THRESHOLD_DAYS=1 # Snapshots older than 1 day will get a warning 

# Get the current date in seconds since epoch
CURRENT_TIME=$(date -u +%s)

# Log the thresholds and region for debugging
echo "Region: $AWS_REGION"
echo "Delete snapshots older than $DELETE_THRESHOLD_DAYS days."
echo "Warn about snapshots older than $WARNING_THRESHOLD_DAYS day(s)."

# Fetch all snapshots in the specified region
ALL_SNAPSHOTS=$(aws ec2 describe-snapshots \
    --region "$AWS_REGION" \
    --query "Snapshots[*].[SnapshotId,StartTime]" \
    --output json)

# Check if any snapshots were returned
if [ "$(echo "$ALL_SNAPSHOTS" | jq -r '. | length')" -eq 0 ]; then
    echo "No snapshots found in region $AWS_REGION."
    exit 0
fi

# Parse the JSON response
echo "$ALL_SNAPSHOTS" | jq -c '.[]' | while read SNAPSHOT; do 
    # Extract snapshot ID and start time
    SNAPSHOT_ID=$(echo "$SNAPSHOT" | jq -r '.[0]')
    SNAPSHOT_TIME=$(echo "$SNAPSHOT" | jq -r '.[1]')

    # Convert snapshot start time to seconds since epoch
    SNAPSHOT_TIME_EPOCH=$(date -d "$SNAPSHOT_TIME" +%s)

    # Calculate the age of the snapshot in days
    SNAPSHOT_AGE_DAYS=$(( (CURRENT_TIME - SNAPSHOT_TIME_EPOCH) / 86400 ))

    # Logic for handling snapshots based on age
    if [ "$SNAPSHOT_AGE_DAYS" -ge "$DELETE_THRESHOLD_DAYS" ]; then
        echo "Deleting snapshot: $SNAPSHOT_ID (Age: $SNAPSHOT_AGE_DAYS days)"
        aws ec2 delete-snapshot --region "$AWS_REGION" --snapshot-id "$SNAPSHOT_ID"
        if [ $? -eq 0 ]; then
            echo "Successfully deleted snapshot: $SNAPSHOT_ID"
        else
            echo "Failed to delete snapshot: $SNAPSHOT_ID"
        fi
    elif [ "$SNAPSHOT_AGE_DAYS" -ge "$WARNING_THRESHOLD_DAYS" ]; then
        REMAINING_DAYS=$((DELETE_THRESHOLD_DAYS - SNAPSHOT_AGE_DAYS))
        echo "Snapshot: $SNAPSHOT_ID is $SNAPSHOT_AGE_DAYS days old. $REMAINING_DAYS day(s) left to delete."
    else
        REMAINING_DAYS=$((DELETE_THRESHOLD_DAYS - SNAPSHOT_AGE_DAYS))
        echo "Snapshot: $SNAPSHOT_ID is $SNAPSHOT_AGE_DAYS day(s) old. $REMAINING_DAYS day(s) left to delete."
    fi
done

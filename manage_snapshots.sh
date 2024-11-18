#!/bin/bash

# Set the number of days to filter snapshots
#DAYS=1

# Calculate the date for filtering snapshots (ISO 8601 format)
#FILTER_DATE=$(date -u -d "-$DAYS days" +%Y-%m-%dT%H:%M:%SZ)

# Log the filter date for debugging
#echo "Filtering snapshots older than: $FILTER_DATE"

# Fetch snapshot IDs older than the filter date
SNAPSHOT_IDS=$(aws ec2 describe-snapshots \
    --filters "Name=start-time,Values=='2024-11-18'" \
    --query "Snapshots[*].SnapshotId" \
    --output text)

# Check if any snapshots were found
if [ -z "$SNAPSHOT_IDS" ]; then
    echo "No snapshots older than today's found."
else
    echo "Found the following snapshots:"
    echo "$SNAPSHOT_IDS"

    # Iterate over each snapshot and delete it
    for SNAPSHOT_ID in $SNAPSHOT_IDS; do
        echo "Attempting to delete snapshot: $SNAPSHOT_ID"
        aws ec2 delete-snapshot --snapshot-id "$SNAPSHOT_ID"
        if [ $? -eq 0 ]; then
            echo "Successfully deleted snapshot: $SNAPSHOT_ID"
        else
            echo "Failed to delete snapshot: $SNAPSHOT_ID"
        fi
    done
fi

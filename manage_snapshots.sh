#!/bin/bash

# List and delete snapshots older than 1 day
aws ec2 describe-snapshots --owner-ids self \
    --query "Snapshots[?StartTime<=\`$(date -d '1 day ago' --utc +%Y-%m-%dT%H:%M:%SZ)\`].SnapshotId" \
    --output text | while read snapshot_id; do
    echo "Deleting snapshot $snapshot_id"
    aws ec2 delete-snapshot --snapshot-id $snapshot_id
done

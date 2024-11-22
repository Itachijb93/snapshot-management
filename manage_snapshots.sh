#!/bin/bash

# Set the number of days to filter snapshots
#DAYS=1
#Set the time threshold
DELETE_THRESHOLD_DAYS=2 #Snapshots older than 2 days will be deleted
WARNING_THRESHOLD_DAYS=1 #snapshots older than 1 day will get a warning 

#Get the current date in seconds 
CURRENT_TIME=$(date -u +%s)

#Log the thresholds for debugging
echo "Delete snapshots older than $DELETE_THRESHOLD_DAYS days."
echo "Warn about snapshots older than $WARNING_THRESHOLD_DAYS day(s)."

#Fetch all snapshots
ALL_SNAPSHOTS=$(aws ec2 describe-snapshots \ --query "Snapshots[*]. [SnapshotId,StartTime]" \ --output json)
#Parse the json response
echo "$ALL_SNAPSHOTS" | jq -c '.[]' | while read SNAPSHOT; do 
SNAPSHOT_ID=$(echo "$SNAPSHOT" | jq -r '.[0]')
SNAPSHOT_TIME=$(echo "$SNAPSHOT" | jq -r '.[1]')

#Convert snapshot time to seconds since epoch
SNAPSHOT_TIME_EPOCH=$(date -d "$SNAPSHOT_TIME +%s)
#Calculate the age of the snapshot in days
SNAPSHOT_AGE_DAYS=$(( (CURRENT_TIME - SNAPSHOT_TIME_EPOCH) / 86400 ))
#Logic for handling snapshot based on age 
if["$SANPSHOT_AGE_DAYS" -ge "$DELETE_THRESHOLD_DAYS"];
   then 
     echo "Deleting snapshot: $SNAPSHOT_ID(Age:$SNAPSHOT_AGE_DAYS days)"
        aws ec2 delete-snapshot --snapshot-id "$SNAPSHOT_ID"
        if[$? -eq 0]; then
           echo "Successfully deleted snapshot: $SNAPSHOT_ID"
        else
            echo "Failed to delete snapshot: $SNAPSHOT_ID"
        fi
        elif["$SNAPSHOT_AGE-DAYS" -ge "$WARNING_THRESHOLD_DAYS" ];
        then 
            REMAINING_DAYS=$((DELETE_THRESHOLD_DAYS - SNAPSHOT_AGE_DAYS))
            echo "Snapshot:$SNAPSHOT_ID is $SNAPSHOT_AGE_DAYS days old. $REMAINING_DAYS day(s) left to delete."
        else 
            REMAINING_DAYS=$((DELETE_THRESHOLD_DAYS - SNAPSHOT_AGE_DAYS))
            echo "Snapshot:$SNAPSHOT_ID is $SNAPSHOT_AGE_DAYS days(s) old.$REMAINING_DAYS day(s) left to delete."
        fi
      done
            
# Fetch snapshot IDs older than the filter date
#SNAPSHOT_IDS=snap-07badfaa62e99e4c9

# Check if any snapshots were found
#if [ -z "$SNAPSHOT_IDS" ]; then
 #   echo "No snapshots were found with the value passed."
#else
#    echo "Found the following snapshots:"
 #   echo "$SNAPSHOT_IDS"

    # Iterate over each snapshot and delete it
  #  for SNAPSHOT_ID in $SNAPSHOT_IDS; do
   #     echo "Attempting to delete snapshot: $SNAPSHOT_ID"
    #    aws ec2 delete-snapshot --snapshot-id "$SNAPSHOT_ID"
     #   if [ $? -eq 0 ]; then
      #      echo "Successfully deleted snapshot: $SNAPSHOT_ID"
       # else
        #    echo "Failed to delete snapshot: $SNAPSHOT_ID"
        #fi
    #done
#fi

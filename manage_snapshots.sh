pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'us-east-1' // Set the AWS region
    }
    stages {
        stage('Display Snapshots Older than 1 Day') {
            steps {
                script {
                    def filterDate = sh(
                        script: "date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S",
                        returnStdout: true
                    ).trim()

                    def snapshots = sh(
                        script: "aws ec2 describe-snapshots --query \"Snapshots[?StartTime<\\`${filterDate}\\`].{ID:SnapshotId,Start:StartTime}\" --output json",
                        returnStdout: true
                    ).trim()

                    if (snapshots == "[]") {
                        echo "No snapshots older than 1 day found."
                    } else {
                        echo "Snapshots older than 1 day: ${snapshots}"
                    }
                }
            }
        }
        stage('Delete Snapshots Older than 1 Day') {
            steps {
                script {
                    def filterDate = sh(
                        script: "date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%S",
                        returnStdout: true
                    ).trim()

                    def snapshotIds = sh(
                        script: "aws ec2 describe-snapshots --query \"Snapshots[?StartTime<\\`${filterDate}\\`].SnapshotId\" --output text",
                        returnStdout: true
                    ).trim().split()

                    if (snapshotIds.isEmpty()) {
                        echo "No snapshots to delete."
                    } else {
                        snapshotIds.each { snapshotId ->
                            sh "aws ec2 delete-snapshot --snapshot-id ${snapshotId}"
                            echo "Deleted snapshot: ${snapshotId}"
                        }
                    }
                }
            }
        }
    }
}

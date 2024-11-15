pipeline {
    agent any
    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
    }
    stages {
        stage('Display Snapshots Older than 1 Day') {
            steps {
                script {
                    def snapshots = sh(
                        script: "aws ec2 describe-snapshots --query 'Snapshots[?StartTime<`$(date -d '1 day ago' +%Y-%m-%d)`]'",
                        returnStdout: true
                    )
                    echo "Snapshots older than 1 day: ${snapshots}"
                }
            }
        }
        stage('Delete Snapshots Older than 1 Day') {
            steps {
                script {
                    def snapshotIds = sh(
                        script: "aws ec2 describe-snapshots --query 'Snapshots[?StartTime<`$(date -d '1 day ago' +%Y-%m-%d)`].SnapshotId' --output text",
                        returnStdout: true
                    ).trim().split()

                    snapshotIds.each { snapshotId ->
                        sh "aws ec2 delete-snapshot --snapshot-id ${snapshotId}"
                        echo "Deleted snapshot: ${snapshotId}"
                    }
                }
            }
        }
    }
}

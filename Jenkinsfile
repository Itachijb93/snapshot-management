pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID = credentials('aws-access-key')  // Replace with Jenkins credentials ID for access key
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')  // Replace with Jenkins credentials ID for secret key
        AWS_DEFAULT_REGION = 'us-east-1'  // Specify the AWS region
    }
    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/Itachijb93/snapshot-management.git'  // Ensure this URL is correct
            }
        }
        stage('Run manage_snapshots.sh') {
            steps {
                script {
                    sh 'chmod +x manage_snapshots.sh'  // Grant execution permissions to the script
                    sh './manage_snapshots.sh'  // Execute the script
                }
            }
        }
    }
    post {
        always {
            echo 'Pipeline execution complete.'
        }
        failure {
            echo 'Pipeline failed. Check the logs for details.'
        }
    }
}

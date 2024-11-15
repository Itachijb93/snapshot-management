pipeline {
    agent any
    environment {
        // Set AWS credentials and region as environment variables
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')  // Replace with Jenkins credentials ID
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')  // Replace with Jenkins credentials ID
        AWS_DEFAULT_REGION = 'us-east-1'  // Set your preferred AWS region
    }
    stages {
        stage('Clone Repository') {
            steps {
                // Clone the repository containing the manage_snapshots.sh script
                git branch: 'main', url: 'https://github.com/Itachijb93/snapshot-management.git'
            }
        }
        stage('Run manage_snapshots.sh') {
            steps {
                script {
                    // Ensure the script has execute permissions
                    sh 'chmod +x manage_snapshots.sh'
                    // Run the manage_snapshots.sh script
                    sh './manage_snapshots.sh'
                }
            }
        }
    }
    post {
        always {
            echo 'Pipeline execution complete.'
        }
        failure {
            echo 'Pipeline failed. Please check the logs.'
        }
    }
}

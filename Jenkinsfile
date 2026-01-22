pipeline {
    agent any

    environment {
        NAMESPACE = "agro-drones"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Fazalshareef/project-agro-drones.git'
            }
        }

        stage('Verify Kubernetes Access') {
            steps {
                sh '''
                  echo "Checking Kubernetes connectivity..."
                  kubectl get nodes
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                  echo "Deploying Kubernetes manifests..."
                  cd kubernetes
                  chmod +x scripts/deploy-all.sh
                  ./scripts/deploy-all.sh
                '''
            }
        }
hg
        stage('Verify Deployment') {
            steps {
                sh '''
                  echo "Checking pods and services..."
                  kubectl get pods -n ${NAMESPACE}
                  kubectl get svc -n ${NAMESPACE}
                '''
            }
        }
    }

    post {

        success {
            emailext(
                subject: "✅ SUCCESS: Agro-Drones Kubernetes Deployment",
                body: """
                    <h3>Deployment Successful 🎉</h3>
                    <p><b>Project:</b> Agro-Drones</p>
                    <p><b>Namespace:</b> ${NAMESPACE}</p>
                    <p><b>Job:</b> ${JOB_NAME}</p>
                    <p><b>Build Number:</b> ${BUILD_NUMBER}</p>
                    <p><b>Status:</b> SUCCESS</p>
                """,
                to: "your-email@gmail.com"
            )
        }

        failure {
            emailext(
                subject: "❌ FAILED: Agro-Drones Kubernetes Deployment",
                body: """
                    <h3>Deployment Failed ❌</h3>
                    <p><b>Project:</b> Agro-Drones</p>
                    <p><b>Job:</b> ${JOB_NAME}</p>
                    <p><b>Build Number:</b> ${BUILD_NUMBER}</p>
                    <p>Please check Jenkins console logs.</p>
                """,
                to: "your-email@gmail.com"
            )
        }
    }
}


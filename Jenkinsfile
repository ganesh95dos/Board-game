@Library('share@main') _
pipeline {
    agent any

    environment {
        IMAGE_NAME = 'ganeshmestry21/bord-game-dev'
        IMAGE_TAG = 'latest'
        DOCKER_REGISTRY_CREDENTIALS = 'dockerhub-credentials'  // Jenkins credentials ID
        SONAR_HOME = tool'sonar'
    }

    stages {
        stage('Clone'){
            steps {
                git branch: 'main', url: 'https://github.com/ganesh95dos/Board-game.git'
                }
        }

        stage('SonarQube Quality Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    script {
                        def scannerHome = tool name: 'sonar', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
                        sh "${scannerHome}/bin/sonar-scanner -Dsonar.projectName=Bord-Game -Dsonar.projectKey=Bord-game"
                    }
                 }
            }
        }

        stage('OWASP Dependency Check') {
            steps {
                dependencyCheck additionalArguments: '--scan ./', odcInstallation: 'dc'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage('SonarQube Quality Gate Scan') {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }
        
        stage('Trivy File System Scan') {
            steps {
                sh 'trivy fs --format table -o trivy-fs-report.html .'
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

       
        stage("Build and Test"){
            steps{
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Build and Push Image to Docker Hub') {
        steps {
            withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
            sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
            sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
            echo '✅ Image pushed to Docker Hub successfully!'
                 }
            }
        }
       
        stage('Deploy with Docker Compose') {
            steps {
                sh 'docker-compose down -v || true'
                sh 'docker-compose pull'
                sh 'docker-compose up -d'
            }
        }
    }

    post {
        success {
            echo '✅ Deployment successful!'
        }
        failure {
            echo '❌ Build or deployment failed.'
        }
    }
}

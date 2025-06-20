@Library('Shared@main') _
pipeline {
    agent any
    environment {
        SONAR_HOME = tool "sonar"
    }
    stages {
        stage('Clone') {
            steps {
                git url: 'https://github.com/ganesh95dos/Bord_Game.git', branch: 'main'
            }
        }
        stage('SonarQube Quality Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh "${SONAR_HOME}/bin/sonar-scanner -Dsonar.projectName=Bord-Game -Dsonar.projectKey=Bord-game"
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

         stage("Build and Test"){
            steps{
               docker_build("board-app", "latest")
              }
        }

        stage('Build and Push Image to Docker Hub') {
            steps {
                docker_push("board-app", "latest", "ganeshmestry21")
                echo 'Hello, this image has been pushed to Docker Hub successfully'
            }
        }

        stage('Deploy Code') {
            steps{
                deploy()
            }
        }
    }
}

@Library('share@main') _
pipeline {
    agent any

    environment {
        SONAR_HOME = tool 'sonar'
    }
    
    parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: '', description: 'Docker image tag for frontend (e.g., v1, latest)')
    }

    stages {
        stage("Validate Parameters") {
            steps {
                script {
                    if (params.FRONTEND_DOCKER_TAG.trim() == '') {
                        error("❌ FRONTEND_DOCKER_TAG cannot be empty.")
                    }
                }
            }
        }

        stage("Workspace Cleanup") {
            steps {
                cleanWs()
            }
        }

        stage("Clone") {
            steps {
                git branch: 'main', url: 'https://github.com/ganesh95dos/Board-game.git'
            }
        }

        stage("SonarQube Quality Analysis") {
            steps {
                withSonarQubeEnv('sonar') {
                    script {
                        def scannerHome = tool name: 'sonar', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=Bord-game \
                            -Dsonar.projectName=Bord-Game \
                            -Dsonar.sources=. \
                            -Dsonar.java.binaries=target
                        """
                    }
                }
            }
        }

        stage("OWASP Dependency Check") {
            steps {
                dependencyCheck additionalArguments: '--scan ./', odcInstallation: 'dc'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }

        stage("SonarQube Quality Gate Scan") {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }

        stage("Trivy File System Scan") {
            steps {
                sh 'trivy fs --format table -o trivy-fs-report.html .'
            }
        }

        stage("Build with Maven") {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage("Build, Test, and Push Image to Docker Hub") {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker build -t ganeshmestry21/bord-game-dev:${FRONTEND_DOCKER_TAG} .
                        docker push ganeshmestry21/bord-game-dev:${FRONTEND_DOCKER_TAG}
                    '''
                    echo "✅ Image ganeshmestry21/bord-game-dev:${FRONTEND_DOCKER_TAG} pushed successfully!"
                }
            }
        }

        stage('Deploy with Docker Compose') {
            steps {
                sh 'docker-compose down -v --remove-orphans || true'
                sh 'docker system prune -af --volumes || true'
                sh 'docker rm -f h2-database || true' 
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

        always {
        archiveArtifacts artifacts: '**/dependency-check-report.xml, trivy-fs-report.html', fingerprint: true
          }
    }
}

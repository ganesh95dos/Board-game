@Library('share@main') _
pipeline {
    agent any

    environment {
        IMAGE_NAME = 'ganeshmestry21/bord-game-dev'
        DOCKER_REGISTRY_CREDENTIALS = 'dockerhub-credentials'  // Jenkins credentials ID
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

        stage("Clone Repository") {
            steps {
                git branch: 'main', url: 'https://github.com/ganesh95dos/Board-game.git'
            }
        }

        stage("SonarQube Quality Analysis") {
            steps {
                withSonarQubeEnv('sonar') {
                    script {
                        def scannerHome = tool name: 'sonar', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
                        sh "${SONAR_HOME}/bin/sonar-scanner -Dsonar.projectName=Board-Game -Dsonar.projectKey=Board-Game"
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

        stage("SonarQube Quality Gate") {
            steps {
                timeout(time: 2, unit: 'MINUTES') {
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

        stage("Build & Push Docker Image") {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_REGISTRY_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    docker build -t ${IMAGE_NAME}:${FRONTEND_DOCKER_TAG} .
                    docker push ${IMAGE_NAME}:${FRONTEND_DOCKER_TAG}
                    '''
                    echo "✅ Image pushed: ${IMAGE_NAME}:${FRONTEND_DOCKER_TAG}"
                }
            }
        }

        stage("Deploy with Docker Compose") {
            steps {
                sh '''
                docker-compose down -v --remove-orphans || true
                docker system prune -af --volumes || true
                docker rm -f h2-database || true
                docker-compose pull
                docker-compose up -d
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }
        failure {
            echo '❌ Build or deployment failed.'
        }
    }
}

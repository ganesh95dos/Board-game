@Library('share@main') _
pipeline {
    agent any

    environment {
        IMAGE_NAME = 'ganeshmestry21/bord-game-dev'
        DOCKER_REGISTRY_CREDENTIALS = 'dockerhub-credentials'  // Jenkins credentials ID
        SONAR_HOME = tool 'sonar'
    }

     parameters {
        string(name: 'FRONTEND_DOCKER_TAG', defaultValue: '', description: 'Setting docker image for latest push')
    }

    stages {
        stage("Validate Parameters") {
            steps {
                script {
                    if (params.FRONTEND_DOCKER_TAG == '') {
                        error("FRONTEND_DOCKER_TAG .")
                    }
                }
            }
        }
        stage("Workspace cleanup"){
            steps{
                script{
                    cleanWs()
                }
            }
        }

        

    stages {
        stage('Clone') {
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

        stage("Build, Test, and Push Image to Docker Hub") {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                    sh "docker build -t ${IMAGE_NAME}:"${params.FRONTEND_DOCKER_TAG}" ."
                    sh "docker push ${IMAGE_NAME}:"${params.FRONTEND_DOCKER_TAG}""
                    echo '✅ Image pushed to Docker Hub successfully!'
                }
            }
        }

        stage('Deploy with Docker Compose') {
            steps {
                sh 'docker-compose down -v --remove-orphans || true'
                sh 'docker system prune -af --volumes || true'
                sh 'docker rm -f h2-database || true' // <- Prevent name conflict
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

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

        stage("Clear cache"){
            steps{
                script{
                    sh 'echo "🧹 Clearing SonarQube, OWASP DC, and Trivy caches..."'
                    sh 'rm -rf ~/.sonar/cache || true' //clearing cache
                    sh 'rm -rf ~/.m2/repository/org/owasp/dependency-check-data || true'
                    sh 'rm -rf /var/lib/jenkins/.cache/trivy || true'
                    sh 'rm -rf .scannerwork || true'

                }
            }
        }

        stage("SonarQube Quality Analysis") {
            steps {
                withSonarQubeEnv('sonar') {
                    script {
                        def scannerHome = tool name: 'sonar', type: 'hudson.plugins.sonar.SonarRunnerInstallation'

                        sh """
                            ${scannerHome}/bin/sonar-scanner \
                            -Dsonar.projectKey=Board-Game \
                            -Dsonar.projectName=Board-Game \
                            -Dsonar.sources=src/main/java \
                            -Dsonar.java.binaries=target \
                            -Dsonar.exclusions=**/target/**,**/node_modules/**,**/frontend/node_modules/**,**/frontend/dist/**
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

        stage("Trivy File System Scan") {
            steps {
                sh 'trivy fs --format table -o trivy-fs-report.html .'
            }
        }

        stage("SonarQube Quality Gate Scan") {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false                
                }
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

         stage("Update Image Tag") {
             steps {
                script {
                    sh 'ls -a'
                  if (fileExists('docker-compose.yaml')) {
                    echo "🔄 Updating image tag to: ${params.FRONTEND_DOCKER_TAG}"
                      
                    sh """
                      sed -i 's|ganeshmestry21/bord-game-dev:.*|ganeshmestry21/bord-game-dev:${params.FRONTEND_DOCKER_TAG}|' ./docker-compose.yaml
                      sed -i 's|ganeshmestry21/bord-game-dev:.*|ganeshmestry21/bord-game-dev:${params.FRONTEND_DOCKER_TAG}|' ./kubernetes/boardgame-app/boardgameDep.yml
                      sed -i 's|ganeshmestry21/bord-game-dev:.*|ganeshmestry21/bord-game-dev:${params.FRONTEND_DOCKER_TAG}|' ./kubernetes/boardgameDep.yml
                    """
              } else {
            echo "⚠️ docker-compose.yml not found — skipping tag update."
                  }
            }
          }
        }

        stage("Commit and Push Updated Compose File") {
            steps {
                withCredentials([usernamePassword(credentialsId: 'ganesh95dos', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                    sh '''
                        # Configure Git locally (not globally)
                        git config user.name "$GIT_USER"
                        git config user.email "ganeshmestry95@gmail.com"

                        # Stage and commit changes
                        git add docker-compose.yaml
                        git add ./kubernetes/boardgame-app/boardgameDep.yml

                        # Commit only if there are changes
                        git diff --cached --quiet || git commit -m "Update Docker tag to ${FRONTEND_DOCKER_TAG}"

                        # Set remote with credentials and push
                        git remote set-url origin https://${GIT_USER}:${GIT_PASS}@github.com/ganesh95dos/Board-game.git
                        git push origin main
                    '''
                    }
                }
            }
    }

    post {

        always {
            archiveArtifacts artifacts: '**/dependency-check-report.xml, trivy-fs-report.html', fingerprint: true
        }
        
        success {

            build job: "Board-Game-CD", parameters: [
                string(name: 'FRONTEND_DOCKER_TAG', value: "${params.FRONTEND_DOCKER_TAG}"),
             ]

            
            script {               
                emailext attachLog: true,
                from: 'ganeshmestry95@gmail.com',
                subject: "Board-Game Application has been updated and deployed - '${currentBuild.result}'",
                body: """
                    <html>
                    <body>
                        <div style="background-color: #FFA07A; padding: 10px; margin-bottom: 10px;">
                            <p style="color: black; font-weight: bold;">Project: ${env.JOB_NAME}</p>
                        </div>
                        <div style="background-color: #90EE90; padding: 10px; margin-bottom: 10px;">
                            <p style="color: black; font-weight: bold;">Build Number: ${env.BUILD_NUMBER}</p>
                        </div>
                        <div style="background-color: #87CEEB; padding: 10px; margin-bottom: 10px;">
                            <p style="color: black; font-weight: bold;">URL: ${env.BUILD_URL}</p>
                        </div>
                    </body>
                    </html>
            """,
            to: 'ganeshmestry95@gmail.com',
            mimeType: 'text/html'
            }
        }
      failure {
            script {
                emailext attachLog: true,
                from: 'ganeshmestry95@gmail.com',
                subject: "Board-Game Application build failed - '${currentBuild.result}'",
                body: """
                    <html>
                    <body>
                        <div style="background-color: #FFA07A; padding: 10px; margin-bottom: 10px;">
                            <p style="color: black; font-weight: bold;">Project: ${env.JOB_NAME}</p>
                        </div>
                        <div style="background-color: #90EE90; padding: 10px; margin-bottom: 10px;">
                            <p style="color: black; font-weight: bold;">Build Number: ${env.BUILD_NUMBER}</p>
                        </div>
                    </body>
                    </html>
            """,
            to: 'ganeshmestry95@gmail.com',
            mimeType: 'text/html'
            }
        }
    }
}


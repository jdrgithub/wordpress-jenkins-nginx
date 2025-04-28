pipeline {
  agent any

  environment {
    IMAGE_NAME = "****/wordpress-astra"
    IMAGE_TAG = "build-${env.BUILD_NUMBER}"
    REGISTRY = "docker.io"
    REPO = "jdrdock"
    FULL_IMAGE = "${REGISTRY}/${REPO}/${IMAGE_NAME}:${IMAGE_TAG}"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build Image') {
      steps {
        sh "docker build -t ${REPO}/${IMAGE_NAME}:${IMAGE_TAG} -f images/wordpress/Dockerfile ."
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
          sh """
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin $REGISTRY
            sh "docker push ${REPO}/${IMAGE_NAME}:${IMAGE_TAG}"
          """
        }
      }
    }
  }
}


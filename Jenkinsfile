pipeline {
  agent any

  environment {
    IMAGE_NAME = "wordpress-astra"
    IMAGE_TAG = "build-${env.BUILD_NUMBER}"
    REGISTRY = "docker.io"
    REPO = "jdrdock"
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
            docker tag ${REPO}/${IMAGE_NAME}:${IMAGE_TAG} ${REPO}/${IMAGE_NAME}:latest
            docker push ${REPO}/${IMAGE_NAME}:latest
            docker push ${REPO}/${IMAGE_NAME}:${IMAGE_TAG}
          """
        }
      }
    }
  
    stage('Deploy to Prod') {
      steps {
        sh """
          # Sync wp-content first (dev -> prod)
          rsync -a --delete /opt/webapps/envs/dev/wp-content/ /opt/webapps/envs/prod/wp-content/

          # Pull the latest WordPress image
          cd /opt/webapps/envs/prod
          docker-compose pull wordpress

          # Restart only the wordpress service
          docker-compose up -d wordpress
        """
    }
  }
}
}



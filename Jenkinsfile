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

    stage('Sync wp-content') {
      steps {
        sh """
          docker run --rm \
            -v /opt/webapps:/opt/webapps \
            alpine sh -c "apk add --no-cache rsync && rsync -a --delete /opt/webapps/envs/dev/wp-content/ /opt/webapps/envs/prod/wp-content/"
        """
      }
    }

    stage('Deploy to Prod') {
      steps {
        sh """
          docker-compose -f /opt/webapps/envs/prod/docker-compose.yml --project-name prod pull wordpress
          docker-compose -f /opt/webapps/envs/prod/docker-compose.yml --project-name prod up -d wordpress
        """
      }
    }
  }
}


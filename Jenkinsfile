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

    stage('Promote Dev Database to Prod') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'mysql-root-password-id', usernameVariable: 'DB_USER', passwordVariable: 'DB_PASS')]) {
          script {
            def timestamp = new Date().format("yyyyMMdd-HHmmss")
            sh """
              # Backup Prod Database
              docker exec prod_db mysqldump -u $DB_USER -p"$DB_PASS" wordpress > /opt/webapps/prod-db-backup-${timestamp}.sql

              # Dump Dev DB and Import into Prod
              docker exec dev_db mysqldump -u $DB_USER -p"$DB_PASS" wordpress | docker exec -i prod_db mysql -u $DB_USER -p"$DB_PASS" wordpress

              # Fix siteurl and home URLs in Prod
              docker exec -i prod_db mysql -u $DB_USER -p"$DB_PASS" wordpress -e "
                UPDATE wp_options SET option_value = 'https://nimbledev.io' WHERE option_name IN ('siteurl', 'home');
              "
            """
          }
        }
      }
    }

    stage('Deploy to Prod') {
      steps {
        sh """
          docker compose -f /opt/webapps/envs/prod/docker-compose.yml --project-name prod pull wordpress
          docker compose -f /opt/webapps/envs/prod/docker-compose.yml --project-name prod up -d wordpress
        """
      }
    }
  }
}


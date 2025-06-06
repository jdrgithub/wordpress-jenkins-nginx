pipeline {
  agent any

  parameters {
    string(
      name: 'CHANGE_MESSAGE',
      defaultValue: 'No change message provided',
      description: 'Enter the deployment change description'
    )
  }

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

    stage('Determine Change Message') {
      steps {
        script {
          if (!params.CHANGE_MESSAGE || params.CHANGE_MESSAGE == 'No change message provided') {
            env.CHANGE_MESSAGE = sh(script: 'git log -1 --pretty=%B', returnStdout: true).trim()
          } else {
            env.CHANGE_MESSAGE = params.CHANGE_MESSAGE
          }
        }
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
          echo 'Syncing wp-content from dev to prod...'
          docker run --rm --user root \
            -v /opt/webapps:/opt/webapps \
            alpine sh -c '
              set -e
              apk add --no-cache rsync
              rsync -a --no-perms --no-owner --no-group --delete /opt/webapps/envs/dev/wp-content/ /opt/webapps/envs/prod/wp-content/ || echo "rsync failed"
              echo "Chowning content to 33:33"
              chown -R 33:33 /opt/webapps/envs/prod/wp-content
            '
        """
      }
    }

    stage('Promote Dev Database to Prod') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'mysql-root-password-id', usernameVariable: 'DB_USER', passwordVariable: 'DB_PASS')]) {   
          script {
            def timestamp = new Date().format("yyyyMMdd-HHmmss")
            sh """
              set -eu
              set -x

              rm /opt/webapps/prod-db-backup-* || true
              echo 'Backing up prod DB to /opt/webapps/prod-db-backup-${timestamp}.sql'
              docker exec prod_db mysqldump -u "$DB_USER" -p"$DB_PASS" wordpress > /opt/webapps/prod-db-backup-${timestamp}.sql

              echo 'Dumping dev DB to /opt/webapps/dev-db-dump.sql'
              docker exec dev_db mysqldump -u "$DB_USER" -p"$DB_PASS" wordpress > /opt/webapps/dev-db-dump.sql
              ls -lh /opt/webapps/dev-db-dump.sql

              echo 'Importing into prod DB...'
              docker exec -i prod_db mysql -u "$DB_USER" -p"$DB_PASS" wordpress < /opt/webapps/dev-db-dump.sql

              echo 'Updating wp_options siteurl/home directly in DB...'
              docker exec prod_db mysql -u "$DB_USER" -p"$DB_PASS" wordpress -e "UPDATE wp_options SET option_value = 'https://nimbledev.io' WHERE option_name IN ('siteurl', 'home');"

              echo 'Running WP-CLI search-replace on prod...'
              docker exec wordpress wp search-replace 'https://dev.nimbledev.io' 'https://nimbledev.io' --precise --recurse-objects --all-tables --allow-root
            """
          }
        }
      }
    }

    stage('Replace Elementor Image URLs') {
      steps {
        sh '''
          echo "Fixing Elementor image URLs..."

          # Write the JSON export inside the container to a temp file
          docker exec dev_wordpress sh -c 'wp post meta get 17 _elementor_data --format=json --allow-root > /var/www/html/wp-content/tmp/_elementor_data.json'

          # Determine if the input is a string or already a JSON array/object
          if jq -e 'type == "string"' /opt/webapps/envs/dev/wp-content/tmp/_elementor_data.json > /dev/null; then
            echo "Decoding stringified JSON..."
            jq -r 'fromjson' /opt/webapps/envs/dev/wp-content/tmp/_elementor_data.json > /tmp/_elementor_data_decoded.json
          else
            echo "Already parsed JSON; copying as-is..."
            cp /opt/webapps/envs/dev/wp-content/tmp/_elementor_data.json /tmp/_elementor_data_decoded.json
          fi


          sed -i 's|dev.nimbledev.io|nimbledev.io|g' /tmp/_elementor_data_decoded.json
          jq -R -s '.' /tmp/_elementor_data_decoded.json > /tmp/_elementor_data.json
          docker cp /tmp/_elementor_data.json wordpress:/var/www/html/wp-content/tmp/_elementor_data.json
          docker exec wordpress wp eval "$(
            cat <<'PHP'
$raw = file_get_contents("/var/www/html/wp-content/tmp/_elementor_data.json");
$data = json_decode($raw, true);
if (is_string($data)) $data = json_decode($data, true);
update_post_meta(17, "_elementor_data", $data);
PHP
          )" --allow-root
        '''

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

    stage('Finalize Prod Cleanup') {
      steps {
        sh """
          echo '🔁 Final rewrite and cache flush on live production site...'
          docker exec wordpress find /var/www/html/wp-content/uploads/elementor -type f -exec sed -i "s|https://dev.nimbledev.io|https://nimbledev.io|g" {} + 2>&1 || echo "No substitutions needed or permissions denied."

          docker exec wordpress wp elementor flush_css --allow-root || echo "Elementor flush failed"
          docker exec wordpress wp cache flush --allow-root || echo "WP cache flush failed"
        """
      }
    }

    stage('Commit and Push Deployment Log') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'github-creds', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
          sh """
            cd /opt/webapps
            git config user.name "Jenkins CI"
            git config user.email "jenkins@nimbledev.io"
            git fetch origin main
            git rebase origin/main || echo 'Rebase failed or not needed'
            git add deployment-logs/
            git commit -m "Update deployment logs: auto-commit from Jenkins for build ${IMAGE_TAG}" || echo "No changes to commit"
            git push https://${GIT_USER}:${GIT_TOKEN}@github.com/jdrgithub/wordpress-jenkins-nginx.git main
          """
        }
      }
    }

    stage('Tag Deployment in Git') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'github-creds', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
          sh """
            cd /opt/webapps
            git tag deploy-${IMAGE_TAG}
            git push https://${GIT_USER}:${GIT_TOKEN}@github.com/jdrgithub/wordpress-jenkins-nginx.git deploy-${IMAGE_TAG}
          """
        }
      }
    }
  }
}


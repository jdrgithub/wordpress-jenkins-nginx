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
              docker exec prod_db mysqldump -u $DB_USER -p"$DB_PASS" wordpress > /opt/webapps/prod-db-backup-${timestamp}.sql
              docker exec dev_db mysqldump -u $DB_USER -p"$DB_PASS" wordpress | docker exec -i prod_db mysql -u $DB_USER -p"$DB_PASS" wordpress    
              docker exec -i prod_db mysql -u $DB_USER -p"$DB_PASS" wordpress -e \
                \\"UPDATE wp_options SET option_value = 'https://nimbledev.io' WHERE option_name IN ('siteurl', 'home');\\"
              docker exec wordpress wp search-replace 'https://dev.nimbledev.io' 'https://nimbledev.io' --precise --recurse-objects --all-tables --allow-root
            """
          }
        }
      }
    }

    // This is for a specific problem with how an image loads after promotion to prod
    // I am not sure why this happens to this image only. 
    // It could be an artifact resulting from using a template
    // Basically you decode the json from elementor about the home page and then use sed to get rid of dev reference and import to prod
    stage('Replace Elementor Image URLs') {
      steps {
        sh """
          echo 'Fixing Elementor image URLs...'
          docker exec dev_wordpress wp post meta get 17 _elementor_data --format=json --allow-root > /opt/webapps/envs/dev/wp-content/tmp/_elementor_data.json
          jq -r 'fromjson' /opt/webapps/envs/dev/wp-content/tmp/_elementor_data.json > /opt/webapps/envs/dev/wp-content/tmp/_elementor_data_decoded.json
          sed -i 's|dev.nimbledev.io|nimbledev.io|g' /opt/webapps/envs/dev/wp-content/tmp/_elementor_data_decoded.json
          jq -R -s '.' /opt/webapps/envs/dev/wp-content/tmp/_elementor_data_decoded.json > /opt/webapps/envs/prod/wp-content/tmp/_elementor_data.json
          docker exec wordpress wp eval '
            $raw = file_get_contents("/var/www/html/wp-content/tmp/_elementor_data.json");
            $data = json_decode($raw, true);
            if (is_string($data)) $data = json_decode($data, true);
            update_post_meta(17, "_elementor_data", $data);
          ' --allow-root
        """
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


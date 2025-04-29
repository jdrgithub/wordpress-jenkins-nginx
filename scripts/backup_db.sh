#!/bin/bash
set -e

# Load DB_PASSWORD from .env file
if [ -f /opt/webapps/scripts/.env ]; then
  export $(cat /opt/webapps/scripts/.env | xargs)
fi

DB_CONTAINER_NAME="prod_db"
DB_NAME="wordpress"
DB_USER="wordpress"

BACKUP_FILE="backup.sql.gz"

docker exec "$DB_CONTAINER_NAME" sh -c "exec mysqldump -u$DB_USER -p$DB_PASSWORD $DB_NAME" | gzip > "$BACKUP_FILE"


# === CONFIGURATION ===
DB_CONTAINER_NAME="prod_db_1"   # name of your running MySQL container
BACKUP_DIR="/opt/webapps/backups/mysql"  # where you want backups to live
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/wordpress_backup_$TIMESTAMP.sql.gz"

# === SCRIPT START ===
echo "Starting MySQL backup..."

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Dump the database and compress it
docker exec "$DB_CONTAINER_NAME" sh -c "exec mysqldump -u$DB_USER -p$DB_PASSWORD $DB_NAME" | gzip > "$BACKUP_FILE"

# Verify if the backup was created
if [ -f "$BACKUP_FILE" ]; then
    echo "✅ Backup successful: $BACKUP_FILE"
else
    echo "Backup failed."
fi


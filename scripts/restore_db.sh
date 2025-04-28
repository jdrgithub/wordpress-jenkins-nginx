#!/bin/bash

# === CONFIGURATION ===
DB_CONTAINER_NAME="prod_db_1"  # name of your running MySQL container
DB_USER="wordpress"            # database user
DB_PASSWORD="yourpass"          # database password
DB_NAME="wordpress"             # database name to restore into
BACKUP_DIR="/opt/webapps/backups/mysql"  # where your backups are stored

# === SCRIPT START ===
echo "Starting MySQL restore..."

# Prompt for backup file
echo "Available backup files:"
ls "$BACKUP_DIR"/*.sql.gz
echo ""
read -p "Enter the exact backup filename to restore (example: wordpress_backup_20250428_013215.sql.gz): " BACKUP_FILE

# Full path
FULL_BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"

# Validate file exists
if [ ! -f "$FULL_BACKUP_PATH" ]; then
  echo "❌ Backup file does not exist: $FULL_BACKUP_PATH"
  exit 1
fi

# Confirm with user
read -p "⚠️  WARNING: This will overwrite your current '$DB_NAME' database. Continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
  echo "❌ Restore cancelled."
  exit 1
fi

# Restore the database
gunzip < "$FULL_BACKUP_PATH" | docker exec -i "$DB_CONTAINER_NAME" sh -c "exec mysql -u$DB_USER -p$DB_PASSWORD $DB_NAME"

if [ $? -eq 0 ]; then
    echo "✅ Restore completed successfully."
else
    echo "❌ Restore failed."
fi


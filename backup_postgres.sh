#!/bin/bash

# Configuration
DB_NAME="mydb"
DB_USER="myuser"
BACKUP_DIR="/backups"
LOG_FILE="/var/log/postgres_backup.log"
RETENTION_DAYS=7

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Get current date for backup filename
DATE=$(date +%Y-%m-%d)
BACKUP_FILE="$BACKUP_DIR/backup-$DATE.sql.gz"

# Log function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Start backup
log "Starting backup of $DB_NAME"

# Perform backup with compression
if pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_FILE"; then
    log "Backup completed successfully: $BACKUP_FILE"
else
    log "ERROR: Backup failed!"
    exit 1
fi

# Cleanup old backups
log "Cleaning up backups older than $RETENTION_DAYS days"
find "$BACKUP_DIR" -name "backup-*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete

# Verify backup file exists and has content
if [ -s "$BACKUP_FILE" ]; then
    log "Backup verification successful"
else
    log "ERROR: Backup file is empty or does not exist!"
    exit 1
fi

log "Backup process completed" 
#!/bin/bash
# AGIS Hybrid Auto-Sync Script
# Fully upgraded persistent backup + GitHub push

PROJECT_DIR=~/agis-hybrid
BACKUP_DIR=~/agis-hybrid-backups
LOG_FILE=~/agis-hybrid-sync.log
GIT_CMD=$(which git)
SLEEP_INTERVAL=15
MAX_BACKUPS=50

mkdir -p "$BACKUP_DIR"
echo "[$(date '+%H:%M:%S')] ✓ Auto-sync script started" >> "$LOG_FILE"

while true; do
    cd "$PROJECT_DIR" || exit

    # Detect real file changes
    if [ -n "$($GIT_CMD status --porcelain)" ]; then
        TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')

        # Create timestamped backup
        BACKUP_PATH="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"
        tar -czf "$BACKUP_PATH" . >/dev/null 2>&1

        # Keep only last $MAX_BACKUPS backups
        ls -1t "$BACKUP_DIR" | tail -n +$((MAX_BACKUPS+1)) | xargs -I {} rm -f "$BACKUP_DIR/{}"

        # Commit and push changes
        $GIT_CMD add .
        COMMIT_OUTPUT=$($GIT_CMD commit -m "auto-sync $TIMESTAMP" 2>&1)
        
        if [[ "$COMMIT_OUTPUT" == *"nothing to commit"* ]]; then
            echo "[$(date '+%H:%M:%S')] ⚠ No changes detected" >> "$LOG_FILE"
        else
            PUSH_OUTPUT=$($GIT_CMD push origin main 2>&1)
            if [[ "$PUSH_OUTPUT" == *"Everything up-to-date"* ]]; then
                echo "[$(date '+%H:%M:%S')] ✓ Synced + Backup created: $BACKUP_PATH" >> "$LOG_FILE"
            else
                echo "[$(date '+%H:%M:%S')] ⚠ Push failed, retrying next cycle" >> "$LOG_FILE"
            fi
        fi
    fi

    sleep $SLEEP_INTERVAL
done

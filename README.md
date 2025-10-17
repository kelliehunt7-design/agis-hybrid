#!/bin/bash

# === AGIS Master Sync Script (Auto-create + auto-sync) ===
BASE_DIR=/home/akay
BACKUP_DIR=$BASE_DIR/agis-master-backups
LOG_FILE=$BASE_DIR/agis-master-sync.log
GIT=/usr/bin/git

mkdir -p "$BACKUP_DIR"
echo "[$(date '+%H:%M:%S')] ✓ Master sync script started" >> "$LOG_FILE"

# Infinite loop
while true; do
    # Detect AGIS modules automatically
    MODULES=("AGISECO" "AGISECO_PROD" "AGISECO_BUNDLE" "AGIS_HYBRID")
    
    for MODULE in "${MODULES[@]}"; do
        MODULE_PATH="$BASE_DIR/$MODULE"

        # Auto-create missing module folders
        if [ ! -d "$MODULE_PATH" ]; then
            echo "[$(date '+%H:%M:%S')] ✗ Module folder missing, creating: $MODULE_PATH" >> "$LOG_FILE"
            mkdir -p "$MODULE_PATH"
            cd "$MODULE_PATH" || continue
            echo "# $MODULE" > README.md
            $GIT init -b main >/dev/null 2>&1
            $GIT add README.md >/dev/null 2>&1
            $GIT commit -m "Initial commit for $MODULE" >/dev/null 2>&1
            $GIT remote add origin git@github.com:kelliehunt7-design/$(echo $MODULE | tr '[:upper:]' '[:lower:]').git 2>/dev/null
            $GIT push -u origin main >/dev/null 2>&1
        else
            cd "$MODULE_PATH" || continue
        fi

        # Create backup
        TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
        BACKUP_PATH="$BACKUP_DIR/${MODULE}_backup_$TIMESTAMP.tar.gz"
        tar -czf "$BACKUP_PATH" . >/dev/null 2>&1
        ls -1t "$BACKUP_DIR" | grep "$MODULE" | tail -n +21 | xargs -I {} rm -f "$BACKUP_DIR/{}" 2>/dev/null

        # Commit & push if changes exist
        if [ -n "$($GIT status --porcelain)" ]; then
            $GIT add .
            $GIT commit -m "auto-sync $TIMESTAMP" >/dev/null 2>&1
            $GIT push origin main >/dev/null 2>&1
            echo "[$(date '+%H:%M:%S')] ✓ Synced + Backup created: $BACKUP_PATH" >> "$LOG_FILE"
        else
            echo "[$(date '+%H:%M:%S')] ✓ No changes for $MODULE, backup created: $BACKUP_PATH" >> "$LOG_FILE"
        fi
    done

    sleep 15
done

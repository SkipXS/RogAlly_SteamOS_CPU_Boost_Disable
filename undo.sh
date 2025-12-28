#!/bin/bash
# UNDO für das alte "Balance Power" Script

GREEN='\033[0;32m'
NC='\033[0m'

# 1. Root Check
if [ "$EUID" -ne 0 ]; then
  echo "Bitte mit sudo ausführen."
  exit 1
fi

echo -e "${GREEN}=== Entferne altes Setup ===${NC}"

# 2. Filesystem entsperren (Wichtig bei SteamOS/Bazzite)
steamos-readonly disable

# 3. Dienst stoppen und deaktivieren
SERVICE_NAME="rog-ally-epp-balance.service"
FILE_PATH="/etc/systemd/system/$SERVICE_NAME"

if systemctl list-units --full -all | grep -Fq "$SERVICE_NAME"; then
    echo "Stoppe Service..."
    systemctl stop "$SERVICE_NAME"
    systemctl disable "$SERVICE_NAME"
fi

# 4. Datei löschen
if [ -f "$FILE_PATH" ]; then
    echo "Lösche Service-Datei: $FILE_PATH"
    rm "$FILE_PATH"
else
    echo "Service-Datei war bereits weg."
fi

# 5. Systemd neu laden
systemctl daemon-reload

# 6. Filesystem wieder sperren
steamos-readonly enable

echo -e "${GREEN}=== Fertig! Altes Setup ist gelöscht. ===${NC}"

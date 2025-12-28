#!/bin/bash
# UNDO-SCRIPT für setup_epp_balance_power.sh

echo "Suche und entferne altes 'Balance Power' Setup..."

# 1. Dienst stoppen und deaktivieren
# Wir prüfen auf den wahrscheinlichsten Namen, den das GitHub-Script erstellt hat
SERVICE_NAME="set_epp_balance_power.service"

if systemctl list-units --full -all | grep -Fq "$SERVICE_NAME"; then
    echo "Dienst $SERVICE_NAME gefunden. Stoppe ihn..."
    sudo systemctl stop "$SERVICE_NAME"
    sudo systemctl disable "$SERVICE_NAME"
    
    # 2. Service-Datei löschen
    echo "Lösche Service-Datei..."
    sudo rm "/etc/systemd/system/$SERVICE_NAME"
else
    echo "Service '$SERVICE_NAME' nicht aktiv oder nicht gefunden."
fi

# 3. Das eigentliche Skript löschen
SCRIPT_PATH="/usr/local/bin/set_epp_balance_power.sh"
if [ -f "$SCRIPT_PATH" ]; then
    echo "Lösche Skript-Datei unter $SCRIPT_PATH..."
    sudo rm "$SCRIPT_PATH"
else
    echo "Kein Skript unter $SCRIPT_PATH gefunden."
fi

# 4. Systemd neu laden
sudo systemctl daemon-reload

echo "Bereinigung abgeschlossen."

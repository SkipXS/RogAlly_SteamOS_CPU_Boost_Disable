#!/bin/bash
# undo_legacy_boost.sh
# Macht die Änderungen (GRUB & Service) rückgängig.

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then echo -e "${RED}Bitte mit sudo ausführen.${NC}"; exit 1; fi

echo -e "${GREEN}=== Start Cleanup / Undo ===${NC}"

# 1. Filesystem entsperren
steamos-readonly disable

# 2. Service stoppen und löschen
OLD_SERVICE="/etc/systemd/system/disable-cpu-boost.service"
if [ -f "$OLD_SERVICE" ]; then
    echo "Lösche alten Service..."
    systemctl stop disable-cpu-boost.service
    systemctl disable disable-cpu-boost.service
    rm "$OLD_SERVICE"
    systemctl daemon-reload
else
    echo "Alter Service war nicht vorhanden."
fi

# 3. GRUB bereinigen
if grep -q "amd_pstate=passive" /etc/default/grub; then
    echo "Entferne 'amd_pstate=passive' aus GRUB..."
    # Entfernt den String 'amd_pstate=passive ' aus der Zeile
    sed -i 's/amd_pstate=passive //g' /etc/default/grub
    # Fallback, falls es am Ende der Zeile ohne Leerzeichen stand
    sed -i 's/amd_pstate=passive//g' /etc/default/grub
    
    echo "Generiere GRUB neu (das dauert kurz)..."
    grub-mkconfig -o /boot/grub/grub.cfg
else
    echo "GRUB war bereits sauber."
fi

# 4. Filesystem sperren
steamos-readonly enable

echo -e "${GREEN}=== Fertig! Dein System ist wieder im Originalzustand (Standard-Treiber). ===${NC}"
echo "Bitte neu starten."

#!/bin/bash

# Farben für Output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== ROG Ally CPU Boost Disabler für SteamOS 3.9 ===${NC}"

# 1. Root-Rechte prüfen
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Bitte als root ausführen (sudo).${NC}"
  exit
fi

# 2. Filesystem entsperren
echo "Entsperre Dateisystem..."
steamos-readonly disable

# 3. Kernel-Parameter prüfen (Wichtig für SteamOS 3.9/Kernel 6.x)
# Wir brauchen 'amd_pstate=passive', sonst existiert die Boost-Datei oft gar nicht oder wird ignoriert.
if grep -q "amd_pstate=passive" /etc/default/grub; then
    echo -e "${GREEN}Kernel-Parameter bereits gesetzt.${NC}"
else
    echo "Füge 'amd_pstate=passive' zu GRUB hinzu..."
    # Fügt den Parameter am Ende der GRUB_CMDLINE_LINUX_DEFAULT Zeile hinzu, vor dem schließenden Anführungszeichen
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="amd_pstate=passive /' /etc/default/grub
    
    echo "Update GRUB Konfiguration..."
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# 4. Service-Datei erstellen
SERVICE_FILE="/etc/systemd/system/disable-cpu-boost.service"

echo "Erstelle Service unter $SERVICE_FILE..."

cat <<EOF > $SERVICE_FILE
[Unit]
Description=Disable CPU Boost for ROG Ally (SteamOS 3.9)
After=multi-user.target systemd-modules-load.service

[Service]
Type=oneshot
# Sleep 5 ist wichtig bei SteamOS 3.9, um Race-Conditions beim Boot zu verhindern
ExecStart=/bin/sh -c 'sleep 5; echo 0 > /sys/devices/system/cpu/cpufreq/boost'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# 5. Service aktivieren
echo "Aktiviere Service..."
systemctl daemon-reload
systemctl enable disable-cpu-boost.service
systemctl start disable-cpu-boost.service

# 6. Check ob es geklappt hat (nur Soft-Check, da Neustart oft nötig für Kernel-Parameter)
CURRENT_STATUS=$(cat /sys/devices/system/cpu/cpufreq/boost 2>/dev/null)
if [ "$CURRENT_STATUS" == "0" ]; then
    echo -e "${GREEN}Erfolg! CPU Boost ist JETZT deaktiviert.${NC}"
else
    echo -e "${RED}Hinweis: Ein Neustart ist wahrscheinlich erforderlich, damit die Kernel-Änderungen greifen.${NC}"
fi

# 7. Filesystem wieder sperren
echo "Sperre Dateisystem wieder..."
steamos-readonly enable

echo -e "${GREEN}=== Fertig! Bitte starte dein ROG Ally neu. ===${NC}"

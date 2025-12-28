#!/bin/bash
# setup_epp_boost_disable.sh
# Nutzt den modernen amd-pstate-epp Treiber, zwingt ihn aber zum Stromsparen.

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

SERVICE_FILE="/etc/systemd/system/rog-ally-epp-power.service"

if [ "$EUID" -ne 0 ]; then echo -e "${RED}Bitte mit sudo ausführen.${NC}"; exit 1; fi

echo -e "${GREEN}=== Setup: EPP Power Mode (Modern Driver) ===${NC}"

# 1. Filesystem entsperren
steamos-readonly disable

# 2. Service erstellen
echo "Erstelle Service..."
cat <<EOF > $SERVICE_FILE
[Unit]
Description=Set AMD EPP to Power (Disable Boost behavior)
After=multi-user.target systemd-modules-load.service

[Service]
Type=oneshot
# Wir setzen EPP auf 'power'. Alternativen: 'balance_power', 'balance_performance' (Standard), 'performance'
# 'power' hält den Takt meist beim Basistakt.
ExecStart=/bin/sh -c 'sleep 5; echo power | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# 3. Aktivieren
echo "Aktiviere Service..."
systemctl daemon-reload
systemctl enable rog-ally-epp-power.service
systemctl start rog-ally-epp-power.service

# 4. Filesystem sperren
steamos-readonly enable

echo -e "${GREEN}=== Fertig! ===${NC}"
echo "Der EPP-Modus ist nun auf 'power' gesetzt."
echo "Du kannst das überprüfen mit: cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference"

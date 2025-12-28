#!/bin/bash
# setup_boost_disable.sh
# Deaktiviert den CPU-Boost (setzt boost auf 0).

GREEN='\033[0;32m'
NC='\033[0m'

SERVICE_FILE="/etc/systemd/system/rog-ally-no-boost.service"

# 1. Root Check
if [ "$EUID" -ne 0 ]; then
  echo "Bitte mit sudo ausführen."
  exit 1
fi

echo -e "${GREEN}=== Setup: Disable CPU Boost ONLY ===${NC}"

# 2. Filesystem entsperren
echo "Entsperre Dateisystem..."
steamos-readonly disable

# 3. Service erstellen
# Wir nutzen direkt /bin/sh im Service, damit keine extra .sh Datei nötig ist (sauberer)
echo "Erstelle Service unter $SERVICE_FILE..."
cat <<EOF > $SERVICE_FILE
[Unit]
Description=Disable CPU Boost (Keep EPP untouched)
After=multi-user.target systemd-modules-load.service

[Service]
Type=oneshot
# Wartet 5s und schreibt dann '0' in die Boost-Datei
ExecStart=/bin/sh -c 'sleep 5; echo 0 | tee /sys/devices/system/cpu/cpufreq/boost'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# 4. Service aktivieren und sofort starten
echo "Aktiviere Service..."
systemctl daemon-reload
systemctl enable rog-ally-no-boost.service
systemctl restart rog-ally-no-boost.service

# 5. Filesystem sperren
echo "Sperre Dateisystem..."
steamos-readonly enable

# 6. Verifikation
echo -e "\n${GREEN}=== Überprüfung ===${NC}"
echo "Boost-Status (Soll: 0):"
cat /sys/devices/system/cpu/cpufreq/boost
echo ""
echo -e "${GREEN}=== Fertig! Boost ist deaktiviert. ===${NC}"

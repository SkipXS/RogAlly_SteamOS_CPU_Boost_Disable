#!/bin/bash
# setup_boost_disable_v2.sh
# Deaktiviert Boost global UND pro Kern.
# Lässt 'balance_performance' unberührt.

GREEN='\033[0;32m'
NC='\033[0m'

SERVICE_FILE="/etc/systemd/system/rog-ally-no-boost.service"

# 1. Root Check
if [ "$EUID" -ne 0 ]; then
  echo "Bitte mit sudo ausführen."
  exit 1
fi

echo -e "${GREEN}=== Setup: Disable CPU Boost (Global & Per-Core) ===${NC}"

# 2. Filesystem entsperren
steamos-readonly disable

# 3. Service erstellen
echo "Erstelle Service unter $SERVICE_FILE..."
cat <<EOF > $SERVICE_FILE
[Unit]
Description=Disable CPU Boost (Global + Per Core)
After=multi-user.target systemd-modules-load.service

[Service]
Type=oneshot
# Wartet 5s
# Befehl 1: Versucht den globalen Boost zu deaktivieren (Fehler werden ignoriert falls nicht existent)
# Befehl 2: Deaktiviert Boost für JEDEN Kern (cpu0, cpu1, etc.)
ExecStart=/bin/sh -c 'sleep 5; echo 0 | tee /sys/devices/system/cpu/cpufreq/boost 2>/dev/null; echo 0 | tee /sys/devices/system/cpu/cpu*/cpufreq/boost'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# 4. Service aktivieren und neustarten
echo "Aktiviere Service..."
systemctl daemon-reload
systemctl enable rog-ally-no-boost.service
systemctl restart rog-ally-no-boost.service

# 5. Filesystem sperren
steamos-readonly enable

# 6. Verifikation
echo -e "\n${GREEN}=== Überprüfung ===${NC}"
echo "Prüfe cpu0:"
cat /sys/devices/system/cpu/cpu*/cpufreq/boost
echo "(Sollte 0 sein)"

echo -e "${GREEN}=== Fertig! ===${NC}"

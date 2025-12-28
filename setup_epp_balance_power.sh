#!/bin/bash
# setup_epp_balance_power.sh
# Setzt 'balance_power' (Efficient Gaming) und zeigt am Ende alle Cores an.

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

SERVICE_FILE="/etc/systemd/system/rog-ally-epp-balance.service"

# 1. Root Check
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Bitte mit sudo ausführen.${NC}"
  exit 1
fi

echo -e "${GREEN}=== Setup: EPP Balance Power ===${NC}"

# 2. Filesystem entsperren
echo "Entsperre Dateisystem..."
steamos-readonly disable

# 3. Service erstellen
echo "Erstelle Service unter $SERVICE_FILE..."
cat <<EOF > $SERVICE_FILE
[Unit]
Description=Set AMD EPP to Balance Power (Efficient Gaming)
After=multi-user.target systemd-modules-load.service

[Service]
Type=oneshot
# Setzt EPP auf 'balance_power' für alle Kerne (Wildcard cpu*)
# Sleep 5 verhindert Race-Conditions beim Boot
ExecStart=/bin/sh -c 'sleep 5; echo balance_power | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# 4. Service aktivieren und sofort starten
echo "Aktiviere Service..."
systemctl daemon-reload
systemctl enable rog-ally-epp-balance.service
systemctl restart rog-ally-epp-balance.service

# 5. Filesystem sperren
echo "Sperre Dateisystem..."
steamos-readonly enable

# 6. Verifikation aller Cores (Korrigierte Version)
echo -e "\n${GREEN}=== Überprüfung aller CPU-Kerne ===${NC}"
echo "Soll: balance_power"
echo "Ist:"

# Wir warten kurz, um sicherzugehen, dass der Service durchgelaufen ist
sleep 2

# Robuste Schleife statt komplexem awk
for file in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
    # Extrahiere den CPU-Namen (z.B. cpu0) aus dem Pfad
    cpu_name=$(echo "$file" | grep -o 'cpu[0-9]\+')
    # Lese den tatsächlichen Wert aus der Datei
    val=$(cat "$file")
    echo "$cpu_name: $val"
done | sort -V  # sort -V sortiert "natürlich" (cpu2 kommt vor cpu10)

echo -e "${GREEN}=== Fertig! ===${NC}"

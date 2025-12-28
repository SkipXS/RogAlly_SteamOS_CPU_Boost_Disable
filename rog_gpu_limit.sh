#!/bin/bash
# SETUP: GPU Max Frequency Limit (1800 MHz Sweet Spot)

GREEN='\033[0;32m'
NC='\033[0m'

# Ziel: 1800 MHz
MAX_GPU_FREQ=1800

# 1. Root Check
if [ "$EUID" -ne 0 ]; then
  echo "Bitte mit sudo ausführen."
  exit 1
fi

echo -e "${GREEN}=== Setup: GPU Limit auf ${MAX_GPU_FREQ} MHz ===${NC}"

steamos-readonly disable

SERVICE_FILE="/etc/systemd/system/rog-gpu-limit.service"
SCRIPT_PATH="/usr/local/bin/rog_gpu_limit.sh"

# 2. Manager-Skript erstellen
echo "Erstelle Skript unter $SCRIPT_PATH..."
cat <<EOF > $SCRIPT_PATH
#!/bin/bash
sleep 8 
# Wir warten etwas länger (8s), damit der GPU-Treiber sicher geladen ist

GPU_PATH="/sys/class/drm/card0/device/pp_od_clk_voltage"

if [ -f "\$GPU_PATH" ]; then
    echo "Setze GPU Limit..."
    # 's 1 1800' bedeutet: Setze (s) Level 1 (Maximaltakt) auf 1800 MHz
    echo "s 1 $MAX_GPU_FREQ" > \$GPU_PATH
    # 'c' bedeutet: Commit (Änderungen anwenden)
    echo "c" > \$GPU_PATH
    echo "GPU Limit gesetzt auf $MAX_GPU_FREQ MHz."
else
    echo "FEHLER: GPU-Pfad nicht gefunden. Treiber geladen?"
fi
EOF

chmod +x $SCRIPT_PATH

# 3. Service erstellen
echo "Erstelle Service $SERVICE_FILE..."
cat <<EOF > $SERVICE_FILE
[Unit]
Description=Set ROG Ally GPU Max Frequency (Sweet Spot)
After=multi-user.target systemd-modules-load.service graphical.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# 4. Aktivieren
systemctl daemon-reload
systemctl enable rog-gpu-limit.service
systemctl restart rog-gpu-limit.service

steamos-readonly enable

# 5. Check
echo -e "\n${GREEN}=== Check (Kann leer sein, wenn keine Last anliegt) ===${NC}"
# Wir lesen die aktuellen Grenzen aus
if [ -f /sys/class/drm/card0/device/pp_od_clk_voltage ]; then
    cat /sys/class/drm/card0/device/pp_od_clk_voltage
else
    echo "Konnte Datei nicht lesen (Permission oder Pfad)."
fi

echo -e "${GREEN}=== Fertig! GPU geht nun nicht mehr über 1800 MHz. ===${NC}"

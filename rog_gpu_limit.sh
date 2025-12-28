#!/bin/bash
# FINAL SETUP: GPU Limit 1800 MHz (Persistent)

GREEN='\033[0;32m'
NC='\033[0m'

# 1. Root Check
if [ "$EUID" -ne 0 ]; then
  echo "Bitte mit sudo ausführen."
  exit 1
fi

echo -e "${GREEN}=== Setup: GPU Limit 1800 MHz (Auto-Start) ===${NC}"

steamos-readonly disable

SERVICE_FILE="/etc/systemd/system/rog-gpu-limit.service"
SCRIPT_PATH="/usr/local/bin/rog_gpu_limit.sh"
GPU_PATH="/sys/class/drm/card0/device"

# 2. Das Skript (Jetzt inkl. 'manual' Modus)
echo "Erstelle Skript unter $SCRIPT_PATH..."
cat <<EOF > $SCRIPT_PATH
#!/bin/bash
# Wir warten etwas, bis der Treiber bereit ist
sleep 10

# 1. In den manuellen Modus wechseln (WICHTIG! Sonst kommt "Invalid Argument")
if [ -f "$GPU_PATH/power_dpm_force_performance_level" ]; then
    echo "manual" > $GPU_PATH/power_dpm_force_performance_level
fi

# 2. Limit setzen
if [ -f "$GPU_PATH/pp_od_clk_voltage" ]; then
    # Setze Limit auf 1800 MHz
    echo "s 1 1800" > $GPU_PATH/pp_od_clk_voltage
    # Bestätigen
    echo "c" > $GPU_PATH/pp_od_clk_voltage
    echo "GPU Limit erfolgreich auf 1800 MHz gesetzt."
else
    echo "Fehler: Pfad nicht gefunden."
fi
EOF

chmod +x $SCRIPT_PATH

# 3. Service Update
echo "Aktualisiere Service..."
cat <<EOF > $SERVICE_FILE
[Unit]
Description=Set ROG Ally GPU Limit to 1800 MHz
After=multi-user.target graphical.target

[Service]
Type=oneshot
ExecStart=$SCRIPT_PATH
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# 4. Neustart des Services
systemctl daemon-reload
systemctl enable rog-gpu-limit.service
systemctl restart rog-gpu-limit.service

steamos-readonly enable

echo -e "${GREEN}=== Fertig! Das GPU-Limit überlebt jetzt auch Neustarts. ===${NC}"

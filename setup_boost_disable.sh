#!/bin/bash

# Farben für Output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SERVICE_FILE="/etc/systemd/system/disable-cpu-boost.service"

echo -e "${YELLOW}=== ROG Ally CPU Boost Disabler (Smart Check) ===${NC}"

# 1. Root-Rechte prüfen
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Bitte als root ausführen (sudo).${NC}"
  exit 1
fi

# ==========================================
# PHASE 1: STATUS PRÜFEN
# ==========================================
echo "Prüfe aktuellen Systemstatus..."

ALL_GOOD=true

# Check A: GRUB Parameter
if grep -q "amd_pstate=passive" /etc/default/grub; then
    echo -e "${GREEN}[OK] Kernel-Parameter 'amd_pstate=passive' gefunden.${NC}"
else
    echo -e "${RED}[FEHLT] Kernel-Parameter fehlt.${NC}"
    ALL_GOOD=false
fi

# Check B: Service Datei Existenz
if [ -f "$SERVICE_FILE" ]; then
    echo -e "${GREEN}[OK] Service-Datei existiert.${NC}"
else
    echo -e "${RED}[FEHLT] Service-Datei nicht gefunden.${NC}"
    ALL_GOOD=false
fi

# Check C: Service Status (Enabled?)
if systemctl is-enabled --quiet disable-cpu-boost.service 2>/dev/null; then
    echo -e "${GREEN}[OK] Service ist aktiviert (enabled).${NC}"
else
    # Nur Fehler, wenn Datei existiert, aber nicht enabled ist
    if [ -f "$SERVICE_FILE" ]; then
        echo -e "${RED}[FEHLT] Service ist nicht aktiviert.${NC}"
        ALL_GOOD=false
    fi
fi

# --- EARLY EXIT ---
if [ "$ALL_GOOD" = true ]; then
    echo -e "\n${GREEN}Alles ist bereits perfekt eingestellt! Keine Änderungen nötig.${NC}"
    
    # Optional: Kurzer Check ob Boost *aktuell* aus ist
    CURRENT_BOOST=$(cat /sys/devices/system/cpu/cpufreq/boost 2>/dev/null)
    if [ "$CURRENT_BOOST" == "0" ]; then
        echo -e "Status-Check: Boost ist aktuell ${GREEN}DEAKTIVIERT${NC}."
    else
        echo -e "Status-Check: Boost ist aktuell ${RED}AKTIV${NC} (Neustart steht wohl noch aus)."
    fi
    exit 0
fi

# ==========================================
# PHASE 2: INSTALLATION / REPARATUR
# ==========================================
echo -e "\n${YELLOW}Konfiguration unvollständig. Starte Reparatur/Installation...${NC}"

# 1. Filesystem entsperren
echo "Entsperre Dateisystem (steamos-readonly disable)..."
steamos-readonly disable

# 2. GRUB fixen (falls nötig)
if ! grep -q "amd_pstate=passive" /etc/default/grub; then
    echo "Füge 'amd_pstate=passive' zu GRUB hinzu..."
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="amd_pstate=passive /' /etc/default/grub
    
    echo "Generiere GRUB Config neu..."
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# 3. Service erstellen (wird überschrieben falls fehlerhaft/alt)
echo "Erstelle/Update Service Datei..."
cat <<EOF > $SERVICE_FILE
[Unit]
Description=Disable CPU Boost for ROG Ally (SteamOS 3.9)
After=multi-user.target systemd-modules-load.service

[Service]
Type=oneshot
# Sleep 5 ist wichtig bei SteamOS 3.9 um Race-Conditions zu verhindern
ExecStart=/bin/sh -c 'sleep 5; echo 0 > /sys/devices/system/cpu/cpufreq/boost'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# 4. Service aktivieren
echo "Aktiviere Service..."
systemctl daemon-reload
systemctl enable disable-cpu-boost.service
systemctl start disable-cpu-boost.service

# 5. Filesystem wieder sperren
echo "Sperre Dateisystem wieder..."
steamos-readonly enable

echo -e "\n${GREEN}=== Installation abgeschlossen! ===${NC}"
echo "Bitte starte dein ROG Ally neu, damit alle Änderungen (besonders GRUB) greifen."

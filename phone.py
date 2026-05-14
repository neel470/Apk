#!/usr/bin/env python3
# osint_fixed_api.py

import requests
import time
import sys
import json
import threading
from colorama import init, Fore, Style

init(autoreset=True)

# ========== API ==========
API_URL = "https://ayaanmods.site/number.php?key=annonymous&number="
# =========================

_fetch_container = {"done": False, "results": None, "error": None}

def banner():
    ascii_art = """
░█▀▀░█▀█░█░█░█▀▄░█▀█░█░█░░░█▀█░█▀▀░▀█▀░█▀█░▀█▀
░▀▀█░█▀▀░░█░░█░█░█░█░▄▀▄░░░█░█░▀▀█░░█░░█░█░░█░
░▀▀▀░▀░░░░▀░░▀▀░░▀▀▀░▀░▀░░░▀▀▀░▀▀▀░▀▀▀░▀░▀░░▀░
"""
    print(Fore.RED + Style.BRIGHT + ascii_art)
    print(Fore.RED + Style.DIM + "         Powered By Xspydox\n")

# ================= API CALL =================
def call_api(number):
    try:
        resp = requests.get(API_URL + str(number), timeout=10)
    except Exception as e:
        return {"error": f"Request error: {e}", "results": []}

    if resp.status_code != 200:
        return {"error": f"Status Code {resp.status_code}", "results": []}

    try:
        data = resp.json()
    except json.JSONDecodeError:
        return {"error": "Invalid JSON response", "results": []}

    if "result" in data and isinstance(data["result"], list):
        return {"error": None, "results": data["result"]}
    else:
        return {"error": "No result field found", "results": []}

# ============================================

def fetch_thread(number):
    try:
        res = call_api(number)
        _fetch_container["results"] = res["results"]
        _fetch_container["error"] = res["error"]
    finally:
        _fetch_container["done"] = True

def get_number():
    number = input(Fore.GREEN + "Enter target mobile: " + Style.BRIGHT).strip()

    if not number.isdigit() or len(number) != 10:
        print(Fore.RED + "[!] Invalid mobile number!")
        return None
    return number

def progress_arrow():
    width = 30
    idx = 0
    spinner = "|/-\\"
    i = 0

    while not _fetch_container["done"]:
        bar = [" "] * width
        bar[idx % width] = "▶"
        sys.stdout.write(
            f"\r[{''.join(bar).replace(' ', '.')}] {spinner[i % 4]}"
        )
        sys.stdout.flush()
        time.sleep(0.05)
        idx += 1
        i += 1

    print("\r[" + "▶" * width + "] ✓")

def main():
    banner()

    number = get_number()
    if not number:
        return

    _fetch_container["done"] = False

    t = threading.Thread(target=fetch_thread, args=(number,), daemon=True)
    t.start()

    print()
    progress_arrow()

    if _fetch_container["error"]:
        print(Fore.RED + Style.BRIGHT + "\nACCESS DENIED\n")
        print(Fore.RED + f"[!] Error: {_fetch_container['error']}")
        return

    results = _fetch_container["results"]
    if not results:
        print(Fore.RED + "[!] No data found.")
        return

    print(Fore.GREEN + f"[+] Result Found! ({len(results)} match)\n")

    # ================= TXT EXPORT =================
    with open("deteli.txt", "w", encoding="utf-8") as f:
        for idx, entry in enumerate(results, start=1):
            result_text = (
                f"--- Result {idx} ---\n"
                f"Name: {entry.get('name', 'N/A')}\n"
                f"Father: {entry.get('father_name', 'N/A')}\n"
                f"Mobile: {entry.get('mobile', 'N/A')}\n"
                f"Alt Mobile: {entry.get('alternate', 'N/A')}\n"
                f"Email: {entry.get('email', 'N/A')}\n"
                f"ID Number: {entry.get('id', 'N/A')}\n"
                f"Circle: {entry.get('circle', 'N/A')}\n"
                f"Address: {entry.get('address', 'N/A')}\n\n"
            )

            print(Fore.GREEN + Style.BRIGHT + f"--- Result {idx} ---")
            print(Fore.GREEN + f"Name: {entry.get('name', 'N/A')}")
            print(Fore.GREEN + f"Father: {entry.get('father_name', 'N/A')}")
            print(Fore.GREEN + f"Mobile: {entry.get('mobile', 'N/A')}")
            print(Fore.GREEN + f"Alt Mobile: {entry.get('alternate', 'N/A')}")
            print(Fore.GREEN + f"Email: {entry.get('email', 'N/A')}")
            print(Fore.GREEN + f"ID Number: {entry.get('id', 'N/A')}")
            print(Fore.GREEN + f"Circle: {entry.get('circle', 'N/A')}")
            print(Fore.GREEN + f"Address: {entry.get('address', 'N/A')}")
            print()

            f.write(result_text)

    # ================= JSON EXPORT =================
    json_data = {
        "searched_number": number,
        "total_results": len(results),
        "data": results
    }

    with open("deteli.json", "w", encoding="utf-8") as jf:
        json.dump(json_data, jf, indent=4, ensure_ascii=False)

    print(Fore.CYAN + "[+] Saved to deteli.txt and deteli.json")

if __name__ == "__main__":
    main()
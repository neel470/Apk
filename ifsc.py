#!/usr/bin/env python3

import requests
import os

# ====== COLORS ======
RED = "\033[91m"
GREEN = "\033[92m"
CYAN = "\033[96m"
YELLOW = "\033[93m"
RESET = "\033[0m"

IFSC_API_URL = "https://ifsc.razorpay.com/{ifsc_code}"

# ====== CLEAR SCREEN ======
def clear():
    os.system("clear" if os.name == "posix" else "cls")

# ====== BANNER ======
def banner():
    print(CYAN + "_" * 32)
    print("        IFSC INFO TOOL")
    print("_" * 32 + RESET)

# ====== FETCH DATA ======
def get_ifsc_info(ifsc_code):
    try:
        response = requests.get(
            IFSC_API_URL.format(ifsc_code=ifsc_code),
            timeout=5
        )

        if response.status_code == 200:
            return response.json()
        else:
            return None

    except Exception as e:
        print(RED + f"Error: {e}" + RESET)
        return None

# ====== DISPLAY RESULT ======
def display(data):
    print(GREEN + "\n========== RESULT ==========\n" + RESET)
    for key, value in data.items():
        print(YELLOW + f"{key}:" + RESET, value)
    print(GREEN + "\n============================\n" + RESET)

# ====== MAIN LOOP ======
def main():
    while True:
        clear()
        banner()

        print(CYAN + "Enter IFSC Code" + RESET)
        print("_" * 32)

        ifsc_code = input(GREEN + ">> " + RESET).strip().upper()

        if not ifsc_code:
            print(RED + "Invalid input!" + RESET)
            input("Press Enter to continue...")
            continue

        print(YELLOW + "\n[+] Fetching details...\n" + RESET)

        data = get_ifsc_info(ifsc_code)

        if data:
            display(data)
        else:
            print(RED + "Invalid IFSC or API error!" + RESET)

        choice = input(CYAN + "Check another? (y/n): " + RESET).lower()
        if choice != 'y':
            print(GREEN + "\nExiting tool. Bye bro!" + RESET)
            break

# ====== ENTRY POINT ======
if __name__ == "__main__":
    main()
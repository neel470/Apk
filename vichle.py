#!/usr/bin/env python3

import requests
from bs4 import BeautifulSoup
from collections import OrderedDict

DESIRED_ORDER = [
    "Owner Name", "Father's Name", "Owner Serial No", "Model Name", "Maker Model",
    "Vehicle Class", "Fuel Type", "Fuel Norms", "Registration Date", "Insurance Company",
    "Insurance No", "Insurance Expiry", "Insurance Upto", "Fitness Upto", "Tax Upto",
    "PUC No", "PUC Upto", "Financier Name", "Registered RTO", "Address", "City Name", "Phone"
]

def banner():
    print("""
____________________________
      VEHICLE INFO TOOL
____________________________
""")

def get_vehicle_details(rc_number: str) -> dict:
    rc = rc_number.strip().upper()
    url = f"https://vahanx.in/rc-search/{rc}"

    headers = {
        "User-Agent": "Mozilla/5.0",
        "Accept-Language": "en-US,en;q=0.9"
    }

    try:
        response = requests.get(url, headers=headers, timeout=10)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'html.parser')
    except Exception as e:
        return {"error": f"Request failed: {e}"}

    def get_value(label):
        span = soup.find("span", string=lambda x: x and label.lower() in x.lower())
        if span:
            div = span.find_parent("div")
            if div:
                p = div.find("p")
                if p:
                    return p.get_text(strip=True)
        return None

    return {key: get_value(key) for key in DESIRED_ORDER}

def format_output(data):
    ordered = OrderedDict()
    for key in DESIRED_ORDER:
        if data.get(key):
            ordered[key] = data[key]
    return ordered

def main():
    while True:
        banner()

        rc_number = input("Enter Vehicle number 🚘: ").strip()

        if not rc_number:
            print("\n[!] Please enter a valid number.\n")
            continue

        print(f"\n[+] Fetching data for: {rc_number}\n")

        data = get_vehicle_details(rc_number)

        if "error" in data:
            print(f"[!] Error: {data['error']}\n")
            continue

        result = format_output(data)

        if not result:
            print("[!] No data found.\n")
            continue

        print("========== RESULT ==========\n")
        for key, value in result.items():
            print(f"{key}: {value}")
        print("\n============================\n")

        again = input("Search again? (y/n): ").lower()
        if again != "y":
            print("\nGoodbye!\n")
            break

if __name__ == "__main__":
    main()
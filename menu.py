import os
import subprocess

# RED color
RED = "\033[91m"
RESET = "\033[0m"

def show_menu():
    os.system("clear")

    print(RED + """
╔══════════════════════════════════════════════════════════════╗
║                    UNIFIED TOOL MENU v1.0                   ║
╠══════════════════════════════════════════════════════════════╣
║  [1] IG POC Tool             [2] Insta Ban Tool            ║
║  [3] Vehicle Info Search     [4] IFSC Code Info            ║
║  [5] IG Private Viewer       [6] Phone Number OSINT        ║
║  [7] Exit                                                 ║
╚══════════════════════════════════════════════════════════════╝
""" + RESET)

def install_requirements(tool_file):
    folder = os.path.dirname(tool_file)
    req_path = os.path.join(folder, "requirements.txt")

    # Only install if exists (NO message if missing)
    if os.path.exists(req_path):
        print(RED + f"[+] Installing dependencies..." + RESET)
        subprocess.call(f"pip install -r {req_path}", shell=True)

def run_tool(choice):
    tools = {
        "1": "ig_poc.py",
        "2": "insta_ban.py",
        "3": "vichle.py",
        "4": "ifsc.py",
        "5": "igprivate.py",
        "6": "phone.py"
    }

    if choice in tools:
        tool = tools[choice]
        install_requirements(tool)
        subprocess.call(f"python3 {tool}", shell=True)

    elif choice == "7":
        print(RED + "[+] System shutting down... Stay anonymous." + RESET)
        exit()
    else:
        print(RED + "[!] Invalid option!" + RESET)

while True:
    show_menu()
    choice = input(RED + "Select an option: " + RESET)
    run_tool(choice)
    input(RED + "\nPress Enter to continue..." + RESET)


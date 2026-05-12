#!/bin/bash
set -e

echo "========================================"
echo "  APK Builder - Setup"
echo "========================================"
echo ""

# Install system dependencies
echo "[*] Installing system packages..."
if command -v apt-get &> /dev/null; then
    sudo apt-get update -qq
    sudo apt-get install -y -qq python3 python3-pip default-jdk wget unzip 2>/dev/null
elif command -v brew &> /dev/null; then
    brew install python3 openjdk wget
fi

# Install Python deps
echo "[*] Installing Python packages..."
pip3 install flask werkzeug 2>/dev/null

# Optional: Download Android command-line tools
if ! command -v aapt &> /dev/null; then
    echo ""
    echo "[!] Android SDK not detected."
    echo "    To install (Linux):"
    echo "      sudo apt install android-sdk android-sdk-build-tools"
    echo "      export ANDROID_HOME=/usr/lib/android-sdk"
    echo ""
    echo "    Or use the cmdline-tools:"
    echo '      wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip'
    echo '      unzip commandlinetools-*.zip -d ~/Android/cmdline-tools'
    echo '      export ANDROID_HOME=~/Android'
    echo ""
fi

echo ""
echo "========================================"
echo "  Setup complete! Run:"
echo "    python3 app.py"
echo "    -> http://localhost:5000"
echo "========================================"

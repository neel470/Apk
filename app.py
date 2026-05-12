#!/usr/bin/env python3
"""
APK Builder - Web-based Android APK Compiler
Converts source code into installable APK files via a web interface.
"""

import os
import sys
import re
import json
import uuid
import time
import shutil
import zipfile
import subprocess
import tempfile
import traceback
import threading
from pathlib import Path
from flask import Flask, render_template, request, jsonify, send_file
from werkzeug.utils import secure_filename

app = Flask(__name__)
app.secret_key = os.urandom(24).hex()
app.config['MAX_CONTENT_LENGTH'] = 200 * 1024 * 1024  # 200MB max upload

# --- Paths ---
BASE_DIR = Path(__file__).parent.absolute()
BUILDS_DIR = BASE_DIR / 'builds'
TEMPLATES_DIR = BASE_DIR / 'templates'
UPLOADS_DIR = BASE_DIR / 'uploads'

for d in [BUILDS_DIR, TEMPLATES_DIR, UPLOADS_DIR]:
    d.mkdir(parents=True, exist_ok=True)

build_status = {}  # build_id -> {status, progress, message}


# ============================================================
#  ROUTES
# ============================================================

@app.route('/')
def index():
    return render_template('index.html')


@app.route('/build', methods=['POST'])
def start_build():
    build_id = uuid.uuid4().hex[:12]
    build_status[build_id] = {'status': 'queued', 'progress': 0, 'message': 'Build queued'}

    app_name = request.form.get('app_name', 'MyApp').strip()
    package_name = request.form.get('package_name', 'com.example.myapp').strip().lower()
    version = request.form.get('version', '1.0').strip()

    # Validate package name
    if not re.match(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$', package_name):
        return jsonify({'error': 'Invalid package name. Use e.g. com.example.myapp'}), 400

    build_dir = BUILDS_DIR / build_id
    build_dir.mkdir(parents=True, exist_ok=True)

    source_file = request.files.get('source_file')
    source_code = request.form.get('source_code', '').strip()
    
    source_dir = build_dir / 'source'
    source_dir.mkdir(exist_ok=True)

    if source_file and source_file.filename:
        filename = secure_filename(source_file.filename)
        filepath = build_dir / filename
        source_file.save(filepath)

        if zipfile.is_zipfile(filepath):
            with zipfile.ZipFile(filepath, 'r') as zf:
                zf.extractall(source_dir)
        else:
            shutil.copy(filepath, source_dir / filename)
    elif source_code:
        # Parse multi-source from text: separate files separated by comment headers
        write_pasted_code(source_dir, source_code)
    else:
        # Generate default sample
        generate_sample_app(source_dir, app_name, package_name, version)

    # Run build in background
    thread = threading.Thread(
        target=build_apk, args=(build_id, build_dir, source_dir,
                                app_name, package_name, version),
        daemon=True
    )
    thread.start()

    return jsonify({'build_id': build_id, 'status': 'queued'})


@app.route('/status/<build_id>')
def get_status(build_id):
    data = build_status.get(build_id)
    if not data:
        return jsonify({'error': 'Build not found'}), 404
    return jsonify(data)


@app.route('/download/<build_id>')
def download_apk(build_id):
    apk = BUILDS_DIR / build_id / 'output' / 'app-release.apk'
    if not apk.exists():
        return jsonify({'error': 'APK not found or build still in progress'}), 404
    return send_file(str(apk), as_attachment=True,
                     download_name=f'{build_id[:8]}.apk')


@app.route('/logs/<build_id>')
def get_logs(build_id):
    log_file = BUILDS_DIR / build_id / 'build.log'
    if log_file.exists():
        return log_file.read_text(errors='replace'), 200, {'Content-Type': 'text/plain'}
    return '', 200


# ============================================================
#  CODE PARSING
# ============================================================

def write_pasted_code(source_dir, text):
    """Parse multi-file code pasted into the textarea."""
    # Detect files separated by comments like // filename.ext or # filename.ext
    # Also handle block separators like --- filename ---
    lines = text.split('\n')
    current_file = None
    current_content = []
    file_map = {}

    patterns = [
        re.compile(r'^//\s*(.+\.\w+)\s*$'),           # // MainActivity.java
        re.compile(r'^#\s*(.+\.\w+)\s*$'),              # # MainActivity.java
        re.compile(r'^---+\s*(.+\.\w+)\s*---+\s*$'),    # --- MainActivity.java ---
        re.compile(r'^;\s*(.+\.\w+)\s*$'),              # ; MainActivity.java
    ]

    for line in lines:
        matched = False
        for pat in patterns:
            m = pat.match(line)
            if m:
                if current_file and current_content:
                    file_map[current_file] = '\n'.join(current_content)
                current_file = m.group(1).strip()
                current_content = []
                matched = True
                break
        if not matched:
            current_content.append(line)

    if current_file and current_content:
        file_map[current_file] = '\n'.join(current_content)

    if not file_map:
        # No file headers detected — treat entire paste as MainActivity.java
        file_map['MainActivity.java'] = text

    for filename, content in file_map.items():
        # Determine subdirectory based on file type
        fname = filename.strip()
        if fname.endswith('.xml') and 'layout' in fname.lower():
            out = source_dir / 'app' / 'src' / 'main' / 'res' / 'layout' / fname
        elif fname == 'AndroidManifest.xml':
            out = source_dir / 'app' / 'src' / 'main' / 'AndroidManifest.xml'
        elif fname in ('build.gradle', 'build.gradle.kts'):
            out = source_dir / 'app' / fname
        elif fname in ('settings.gradle', 'gradle.properties'):
            out = source_dir / fname
        elif fname.endswith('.html'):
            out = source_dir / 'app' / 'src' / 'main' / 'assets' / fname
        else:
            out = source_dir / 'app' / 'src' / 'main' / 'java' / fname
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(content)


# ============================================================
#  SAMPLE APP GENERATOR
# ============================================================

def generate_sample_app(source_dir, app_name, package_name, version):
    """Generate a minimal WebView-based Android project."""
    pkg_path = package_name.replace('.', '/')
    java_dir = source_dir / 'app' / 'src' / 'main' / 'java' / pkg_path
    res_dir = source_dir / 'app' / 'src' / 'main' / 'res'
    layout_dir = res_dir / 'layout'
    values_dir = res_dir / 'values'
    assets_dir = source_dir / 'app' / 'src' / 'main' / 'assets'

    for d in [java_dir, layout_dir, values_dir, assets_dir]:
        d.mkdir(parents=True, exist_ok=True)

    # MainActivity.java
    (java_dir / 'MainActivity.java').write_text(f'''package {package_name};

import android.os.Bundle;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.webkit.WebSettings;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {{
    private WebView webView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {{
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        webView = findViewById(R.id.webview);
        WebSettings ws = webView.getSettings();
        ws.setJavaScriptEnabled(true);
        ws.setDomStorageEnabled(true);
        ws.setLoadWithOverviewMode(true);
        ws.setUseWideViewPort(true);
        webView.setWebViewClient(new WebViewClient() {{
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {{
                view.loadUrl(url);
                return true;
            }}
        }});
        webView.loadUrl("file:///android_asset/index.html");
    }}

    @Override
    public void onBackPressed() {{
        if (webView.canGoBack()) webView.goBack();
        else super.onBackPressed();
    }}
}}
''')

    # activity_main.xml
    (layout_dir / 'activity_main.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">
    <WebView
        android:id="@+id/webview"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
</RelativeLayout>
''')

    # styles.xml
    (values_dir / 'styles.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="AppTheme" parent="Theme.AppCompat.Light.NoActionBar">
        <item name="colorPrimary">#6200EE</item>
        <item name="colorPrimaryDark">#3700B3</item>
        <item name="colorAccent">#03DAC5</item>
    </style>
</resources>
''')

    # colors.xml
    (values_dir / 'colors.xml').write_text('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="colorPrimary">#6200EE</color>
    <color name="colorPrimaryDark">#3700B3</color>
    <color name="colorAccent">#03DAC5</color>
</resources>
''')

    # AndroidManifest.xml
    (source_dir / 'app' / 'src' / 'main' / 'AndroidManifest.xml').write_text(f'''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="{package_name}">
    <uses-permission android:name="android.permission.INTERNET" />
    <application
        android:allowBackup="true"
        android:label="{app_name}"
        android:theme="@style/AppTheme"
        android:usesCleartextTraffic="true">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
''')

    # index.html
    (assets_dir / 'index.html').write_text(f'''<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{app_name}</title>
<style>
* {{ margin:0; padding:0; box-sizing:border-box; }}
body {{ font-family:-apple-system,sans-serif; padding:20px; background:#f5f5f5; }}
.container {{ max-width:800px; margin:0 auto; }}
h1 {{ color:#6200EE; margin-bottom:20px; }}
.card {{ background:white; padding:20px; border-radius:8px; box-shadow:0 2px 4px rgba(0,0,0,0.1); }}
</style>
</head>
<body>
<div class="container">
<div class="card">
<h1>{app_name}</h1>
<p>Your app is ready! Replace this HTML with your own content.</p>
<p>Built with APK Builder</p>
</div>
</div>
</body>
</html>
''')

    # build.gradle (app-level)
    (source_dir / 'app' / 'build.gradle').write_text(f'''apply plugin: 'com.android.application'

android {{
    compileSdkVersion 33
    buildToolsVersion "33.0.2"
    defaultConfig {{
        applicationId "{package_name}"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "{version}"
    }}
    buildTypes {{
        release {{
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }}
    }}
}}

dependencies {{
    implementation 'androidx.appcompat:appcompat:1.6.1'
}}
''')

    # settings.gradle
    (source_dir / 'settings.gradle').write_text("rootProject.name = 'app'\ninclude ':app'\n")

    # gradle.properties
    (source_dir / 'gradle.properties').write_text("org.gradle.jvmargs=-Xmx2048m\nandroid.useAndroidX=true\n")


# ============================================================
#  BUILD ENGINE
# ============================================================

def build_apk(build_id, build_dir, source_dir, app_name, package_name, version):
    """Main build orchestrator."""
    log_file = build_dir / 'build.log'
    output_dir = build_dir / 'output'
    output_dir.mkdir(exist_ok=True)

    def log(msg):
        ts = time.strftime('%H:%M:%S')
        with open(log_file, 'a') as f:
            f.write(f'[{ts}] {msg}\n')

    def update(status, progress, msg):
        build_status[build_id] = {'status': status, 'progress': progress, 'message': msg}
        log(msg)

    try:
        update('building', 5, 'Analyzing project structure...')

        # Detect project type
        gradle_files = list(source_dir.rglob('build.gradle'))
        gradle_files += list(source_dir.rglob('build.gradle.kts'))
        has_manifest = list(source_dir.rglob('AndroidManifest.xml'))
        has_smali = list(source_dir.rglob('*.smali'))
        has_java = list(source_dir.rglob('*.java'))

        if gradle_files:
            update('building', 10, 'Gradle project detected')
            build_with_gradle(build_id, source_dir, output_dir, log_file, update, log)
        elif has_smali:
            update('building', 10, 'Smali project detected, using APKTool')
            build_with_apktool(build_id, source_dir, output_dir, log_file, update, log)
        elif has_java or has_manifest:
            update('building', 10, 'Source files detected, building with AAPT')
            build_with_aapt(build_id, source_dir, output_dir, log_file, update, log,
                           package_name, app_name, version)
        else:
            update('building', 10, 'No recognized project found, generating sample app')
            generate_sample_app(source_dir, app_name, package_name, version)
            build_with_gradle(build_id, source_dir, output_dir, log_file, update, log)

        # Verify output
        apk = output_dir / 'app-release.apk'
        if apk.exists() and apk.stat().st_size > 1000:
            update('complete', 100, f'APK built successfully! ({apk.stat().st_size / 1024:.0f} KB)')
        else:
            raise Exception('APK file too small or missing — build may have failed silently')

    except Exception as e:
        tb = traceback.format_exc()
        log(f'BUILD FAILED: {e}')
        log(tb)
        update('failed', 0, f'Build failed: {e}')


def build_with_gradle(build_id, source_dir, output_dir, log_file, update, log):
    """Build using Gradle."""
    update('building', 20, 'Setting up Gradle wrapper...')

    # Find or create gradlew
    gradlew = source_dir / 'gradlew'
    if not gradlew.exists():
        log('Gradle wrapper not found, attempting to generate...')
        try:
            subprocess.run(['gradle', 'wrapper', '--gradle-version', '7.6'],
                          cwd=str(source_dir), capture_output=True, timeout=60)
        except Exception:
            # Provide a basic gradlew script
            log('Generating gradlew script manually...')
            (source_dir / 'gradlew').write_text('''#!/bin/sh
PRG="$0"
PRGDIR=$(dirname "$PRG")
"$PRGDIR/gradlew" "$@"
''')
            # Download gradle wrapper jar
            gradle_jar_url = 'https://raw.githubusercontent.com/gradle/gradle/v7.6.0/gradlew'
            try:
                import urllib.request
                urllib.request.urlretrieve(
                    'https://services.gradle.org/distributions/gradle-7.6-bin.zip',
                    str(source_dir / 'gradle' / 'wrapper' / 'gradle-wrapper.jar')
                )
            except Exception:
                pass

        gradlew = source_dir / 'gradlew'

    if not gradlew.exists():
        raise Exception('Could not create Gradle wrapper. Install Gradle with: sudo apt install gradle')

    gradlew.chmod(0o755)

    # Try release build first, fall back to debug
    for build_type in ['assembleRelease', 'assembleDebug']:
        update('building', 40, f'Running: ./gradlew {build_type}...')
        log(f'Starting Gradle {build_type}...')

        env = os.environ.copy()
        env['JAVA_HOME'] = env.get('JAVA_HOME', shutil.which('java') and str(Path(shutil.which('java')).parent.parent) or '')

        proc = subprocess.run(
            [str(gradlew), build_type, '--no-daemon', '--stacktrace'],
            cwd=str(source_dir),
            capture_output=True,
            text=True,
            timeout=900,  # 15 min timeout for Gradle
            env=env
        )

        log(proc.stdout[-3000:] if len(proc.stdout) > 3000 else proc.stdout)
        if proc.stderr:
            log(proc.stderr[-2000:] if len(proc.stderr) > 2000 else proc.stderr)

        if proc.returncode == 0:
            break
        elif build_type == 'assembleDebug':
            raise Exception(f'Gradle build failed. Check logs for details.')

    # Find the generated APK
    apks = sorted(source_dir.rglob('*.apk'), key=lambda p: p.stat().st_mtime, reverse=True)
    if apks:
        update('building', 85, f'Found APK: {apks[0].name}')
        shutil.copy(str(apks[0]), str(output_dir / 'app-release.apk'))
    else:
        raise Exception('Gradle completed but no APK found in output.')

    update('building', 90, 'Signing APK...')
    sign_apk(output_dir / 'app-release.apk', log)


def build_with_aapt(build_id, source_dir, output_dir, log_file, update, log,
                    package_name, app_name, version):
    """Build using Android SDK command-line tools (aapt + dx + apksigner)."""
    update('building', 20, 'Looking for Android SDK...')

    android_home = None
    for var in ['ANDROID_HOME', 'ANDROID_SDK_ROOT']:
        if os.environ.get(var):
            android_home = Path(os.environ[var])
            break

    if not android_home:
        for p in ['/usr/lib/android-sdk', '/opt/android-sdk',
                  str(Path.home() / 'Android/Sdk')]:
            if Path(p).exists():
                android_home = Path(p)
                break

    if not android_home or not (android_home / 'build-tools').exists():
        log('Android SDK not found. Trying Gradle build instead...')
        build_with_gradle(build_id, source_dir, output_dir, log_file, update, log)
        return

    update('building', 25, f'Using SDK: {android_home}')

    build_tools = sorted((android_home / 'build-tools').glob('*'))
    platforms = sorted((android_home / 'platforms').glob('android-*'))

    if not build_tools or not platforms:
        raise Exception('Android SDK incomplete — need build-tools and platforms')

    bt = str(build_tools[-1])
    aapt = f'{bt}/aapt'
    aapt2 = f'{bt}/aapt2'
    dx = f'{bt}/dx'
    d8 = f'{bt}/d8'
    zipalign = f'{bt}/zipalign'
    apksigner = f'{bt}/apksigner'
    android_jar = str(platforms[-1] / 'android.jar')

    work_dir = source_dir / 'aapt_work'
    work_dir.mkdir(parents=True, exist_ok=True)

    # Find AndroidManifest.xml
    manifest = (source_dir / 'app' / 'src' / 'main' / 'AndroidManifest.xml')
    if not manifest.exists():
        manifest = (source_dir / 'AndroidManifest.xml')
    if not manifest.exists():
        # Generate one
        manifest = work_dir / 'AndroidManifest.xml'
        manifest.write_text(f'''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="{package_name}">
    <uses-permission android:name="android.permission.INTERNET" />
    <application android:label="{app_name}" android:usesCleartextTraffic="true">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>''')

    # Find resources
    res_dir = source_dir / 'app' / 'src' / 'main' / 'res'
    if not res_dir.exists():
        res_dir = source_dir / 'res'
    if not res_dir.exists():
        res_dir = work_dir / 'res'
        res_dir.mkdir()
        (res_dir / 'values').mkdir()
        (res_dir / 'values' / 'strings.xml').write_text(
            f'<resources><string name="app_name">{app_name}</string></resources>')

    # Step 1: Compile resources with aapt2 (or aapt)
    update('building', 35, 'Compiling resources...')
    if os.path.exists(aapt2):
        # aapt2 compile
        compiled_res = work_dir / 'compiled_res'
        compiled_res.mkdir(exist_ok=True)
        for rfile in res_dir.rglob('*'):
            if rfile.is_file() and not rfile.name.startswith('.'):
                rel = rfile.relative_to(res_dir)
                out = compiled_res / f'{rel}.flat'
                out.parent.mkdir(parents=True, exist_ok=True)
                subprocess.run([aapt2, 'compile', '-o', str(out), str(rfile)],
                              capture_output=True, timeout=30)

        # aapt2 link
        compiled_list = list(compiled_res.rglob('*.flat'))
        link_cmd = [aapt2, 'link',
                    '--manifest', str(manifest),
                    '-I', android_jar,
                    '-o', str(work_dir / 'unaligned.apk')]
        for c in compiled_list:
            link_cmd.extend(['-R', str(c)])

        result = subprocess.run(link_cmd, capture_output=True, text=True, timeout=60)
        log(result.stdout)
        if result.stderr:
            log(result.stderr)
    else:
        # Legacy aapt
        result = subprocess.run([
            aapt, 'package', '-f',
            '-M', str(manifest),
            '-S', str(res_dir),
            '-I', android_jar,
            '-F', str(work_dir / 'unaligned.apk')
        ], capture_output=True, text=True, timeout=60)
        log(result.stdout or result.stderr)

    if not (work_dir / 'unaligned.apk').exists():
        raise Exception('Resource compilation failed')

    # Step 2: Compile Java sources to DEX
    update('building', 50, 'Compiling Java sources...')
    java_files = list(source_dir.rglob('*.java'))

    if java_files:
        # Compile .java -> .class
        classes_dir = work_dir / 'classes'
        classes_dir.mkdir(exist_ok=True)

        javac_cmd = ['javac', '-d', str(classes_dir), '-cp', android_jar]

        # Add support libraries
        for lib_dir in [source_dir / 'app' / 'libs', source_dir / 'libs']:
            if lib_dir.exists():
                for jar in lib_dir.glob('*.jar'):
                    javac_cmd[3] += os.pathsep + str(jar)

        javac_cmd.extend(str(f) for f in java_files)

        result = subprocess.run(javac_cmd, capture_output=True, text=True, timeout=120)
        log(result.stdout)
        if result.stderr:
            log(result.stderr)

        if result.returncode == 0:
            update('building', 65, 'Converting to DEX...')
            # Use d8 if available, fallback to dx
            if os.path.exists(d8):
                result = subprocess.run([
                    d8, '--lib', android_jar,
                    '--output', str(work_dir),
                    str(classes_dir)
                ], capture_output=True, text=True, timeout=120)
            else:
                result = subprocess.run([
                    dx, '--dex', f'--output={work_dir}/classes.dex',
                    str(classes_dir)
                ], capture_output=True, text=True, timeout=120)

            log(result.stdout or result.stderr)

            # Add classes.dex to APK
            dex_file = work_dir / 'classes.dex'
            if not dex_file.exists():
                # d8 outputs .dex directly in the output dir
                dex_files = list(work_dir.glob('*.dex'))
                if dex_files:
                    dex_file = dex_files[0]

            if dex_file.exists():
                update('building', 75, 'Adding DEX to APK...')
                subprocess.run([
                    aapt, 'add', str(work_dir / 'unaligned.apk'),
                    str(dex_file)
                ], capture_output=True, timeout=30)

    # Step 3: Align and sign
    update('building', 80, 'Aligning and signing...')
    aligned = work_dir / 'aligned.apk'

    if os.path.exists(zipalign):
        subprocess.run([zipalign, '-f', '-p', '4',
                       str(work_dir / 'unaligned.apk'), str(aligned)],
                      capture_output=True, timeout=30)
    else:
        shutil.copy(work_dir / 'unaligned.apk', aligned)

    # Sign
    signed = output_dir / 'app-release.apk'
    sign_result = sign_apk(aligned, log, output_path=signed)

    if not signed.exists():
        # Try to use the aligned APK directly
        shutil.copy(str(aligned), str(signed))

    update('building', 95, 'APK ready')


def build_with_apktool(build_id, source_dir, output_dir, log_file, update, log):
    """Build using APKTool from smali or decompiled sources."""
    update('building', 25, 'Looking for APKTool...')

    apktool = None
    for cmd in ['apktool', 'apktool.jar']:
        p = shutil.which(cmd)
        if p:
            apktool = p
            break

    if not apktool:
        for p in ['/usr/local/bin/apktool', '/opt/apktool/apktool.jar']:
            if Path(p).exists():
                apktool = p
                break

    if not apktool:
        log('APKTool not found. Attempting direct build...')
        raise Exception('APKTool not installed. Install with:\n'
                       '  wget https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool\n'
                       '  wget https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.9.3.jar\n'
                       '  chmod +x apktool && sudo mv apktool apktool_2.9.3.jar /usr/local/bin/')

    update('building', 40, 'Building with APKTool...')
    output_apk = output_dir / 'unsigned.apk'

    cmd = ['java', '-jar', apktool, 'b', str(source_dir), '-o', str(output_apk)]

    # Check for aapt2
    aapt2 = shutil.which('aapt2')
    if aapt2:
        cmd.append('--use-aapt2')

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    log(result.stdout[-2000:] if len(result.stdout) > 2000 else result.stdout)
    if result.stderr:
        log(result.stderr[-2000:] if len(result.stderr) > 2000 else result.stderr)

    if result.returncode != 0:
        raise Exception(f'APKTool build failed: {result.stderr[-500:]}')

    update('building', 80, 'Signing APK...')
    sign_apk(output_apk, log)


def sign_apk(apk_path, log, output_path=None):
    """Sign an APK with a debug keystore."""
    if output_path is None:
        output_path = apk_path.parent / 'app-release.apk'

    keystore_dir = apk_path.parent / 'keystore'
    keystore_dir.mkdir(exist_ok=True)
    keystore = keystore_dir / 'debug.keystore'

    # Generate keystore if needed
    if not keystore.exists():
        log('Generating debug keystore...')
        subprocess.run([
            'keytool', '-genkey', '-v', '-keystore', str(keystore),
            '-alias', 'debug', '-keyalg', 'RSA', '-keysize', '2048',
            '-validity', '10000', '-storepass', 'android', '-keypass', 'android',
            '-dname', 'CN=Android Debug, O=Android, C=US'
        ], capture_output=True, timeout=30)

    # Try apksigner first
    apksigner = shutil.which('apksigner')
    if apksigner:
        log('Signing with apksigner...')
        signed_apk = output_path
        result = subprocess.run([
            apksigner, 'sign',
            '--ks', str(keystore),
            '--ks-pass', 'pass:android',
            '--key-pass', 'pass:android',
            '--ks-key-alias', 'debug',
            '--out', str(signed_apk),
            str(apk_path)
        ], capture_output=True, text=True, timeout=60)
        if result.returncode == 0:
            log('APK signed successfully with apksigner')
            return
        log(f'apksigner failed: {result.stderr}')

    # Fallback to jarsigner
    log('Signing with jarsigner...')
    result = subprocess.run([
        'jarsigner', '-verbose', '-sigalg', 'SHA1withRSA',
        '-digestalg', 'SHA1',
        '-keystore', str(keystore),
        '-storepass', 'android', '-keypass', 'android',
        str(apk_path), 'debug'
    ], capture_output=True, text=True, timeout=60)
    log(result.stdout or result.stderr)

    # Copy to output
    if apk_path != output_path:
        shutil.copy(str(apk_path), str(output_path))

    if output_path.exists():
        log(f'Signed APK: {output_path} ({output_path.stat().st_size / 1024:.0f} KB)')


# ============================================================
#  ENTRY POINT
# ============================================================

if __name__ == '__main__':
    print('=' * 60)
    print('  APK Builder - Web Interface')
    print('=' * 60)
    print()
    print('  Checking available tools...')

    checks = [
        ('java',     'Java Runtime'),
        ('javac',    'Java Compiler'),
        ('keytool',  'Keytool'),
        ('jarsigner','Jarsigner'),
        ('gradle',   'Gradle'),
        ('apktool',  'APKTool'),
        ('aapt',     'AAPT'),
        ('aapt2',    'AAPT2'),
        ('apksigner','APKSigner'),
        ('zipalign', 'Zipalign'),
    ]

    found_tools = 0
    for cmd, name in checks:
        path = shutil.which(cmd)
        if path:
            print(f'    ✓ {name:15s} -> {path}')
            found_tools += 1
        else:
            print(f'    ✗ {name:15s} -> NOT FOUND')

    print()
    if found_tools < 3:
        print('  ⚠ Few build tools found. Install Android SDK for full functionality:')
        print('    sudo apt install android-sdk android-sdk-build-tools default-jdk')
    else:
        print(f'  ✓ {found_tools} tools available')
    print()
    print('  Server starting at http://0.0.0.0:5000')
    print('=' * 60)

    app.run(host='0.0.0.0', port=5000, debug=False, threaded=True)

#!/usr/bin/env python3
"""Configure Godot user settings and export a signed ARM64 debug APK."""
import os
import json
from pathlib import Path
import re
import subprocess
import sys
import zipfile
from verify_audio_assets import verify_audio_archive

ROOT = Path(__file__).resolve().parents[1]
sdk = Path(os.environ['ANDROID_HOME']).resolve()
java = Path(os.environ['JAVA_HOME']).resolve()
key = Path(os.environ['GODOT_ANDROID_KEYSTORE_DEBUG_PATH']).resolve()
for required in (sdk / 'platform-tools/adb', sdk / 'build-tools/36.0.0/apksigner', java / 'bin/java', key):
    if not required.is_file():
        raise SystemExit(f'Missing Android build prerequisite: {required}')
config = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'godot'
config.mkdir(parents=True, exist_ok=True)
# Dedicated build settings; no editor or user action required.
def gd_string(value):
    return '"' + str(value).replace('\\', '/').replace('"', '\\"') + '"'
(config / 'editor_settings-4.6.tres').write_text(
    '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
    f'export/android/android_sdk_path = {gd_string(sdk)}\n'
    f'export/android/java_sdk_path = {gd_string(java)}\n')
output = ROOT / 'build/AbyssOfTears-debug.apk'
output.parent.mkdir(exist_ok=True)
output.unlink(missing_ok=True)
env = dict(os.environ, GODOT_ANDROID_KEYSTORE_DEBUG_USER='androiddebugkey',
           GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD='android')
result = subprocess.run([os.environ.get('GODOT', 'godot'), '--headless', '--path', str(ROOT),
                         '--export-debug', 'Android', str(output)], env=env, text=True,
                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=600)
print(result.stdout, flush=True)
if result.returncode or re.search(r'SCRIPT ERROR:|(?:^|\n)ERROR:|Export failed', result.stdout):
    raise SystemExit('Android export failed; inspect the Godot output above.')
if not output.exists() or output.stat().st_size < 1_000_000:
    raise SystemExit('Export did not produce a valid-size APK')
with zipfile.ZipFile(output) as apk:
    if apk.testzip():
        raise SystemExit('Corrupt APK ZIP entries')
    print(f'Exported audio verified: {verify_audio_archive(apk, ROOT)} real imported resources')
    archaeology = json.loads((ROOT / 'data/archaeology.json').read_text())
    if json.loads(apk.read('assets/data/archaeology.json')) != archaeology:
        raise SystemExit('APK archaeology catalog differs from validated source')
    for artifact in archaeology['artifacts']:
        mapping = apk.read('assets/' + artifact['icon'][6:] + '.import').decode()
        match = re.search(r'^path="res://([^"\n]+)"', mapping, re.M)
        if not match or apk.getinfo('assets/' + match[1]).file_size < 1:
            raise SystemExit('APK missing an imported archaeology icon')
    print(f"Exported archaeology verified: {len(archaeology['artifacts'])} icons and matching runtime catalog")
    if 'assets/data/balance.json' not in apk.namelist():
        raise SystemExit('APK is missing its runtime balance configuration')
    if json.loads(apk.read('assets/data/balance.json')) != json.loads((ROOT / 'data/balance.json').read_text()):
        raise SystemExit('APK balance configuration differs from validated source')
    if 'assets/data/relics_expansion.json' not in apk.namelist() or json.loads(apk.read('assets/data/relics_expansion.json')) != json.loads((ROOT / 'data/relics_expansion.json').read_text()):
        raise SystemExit('APK is missing or changed its runtime relic expansion')
    if 'AndroidManifest.xml' not in apk.namelist() or 'lib/arm64-v8a/libgodot_android.so' not in apk.namelist():
        raise SystemExit('Missing Android manifest or ARM64 engine')
    if any(n.startswith(('lib/armeabi-v7a/', 'lib/x86/', 'lib/x86_64/')) for n in apk.namelist()):
        raise SystemExit('Unexpected non-ARM64 native libraries')
subprocess.run([str(sdk / 'build-tools/36.0.0/apksigner'), 'verify', '--verbose', str(output)], check=True)
badging = subprocess.check_output([str(sdk / 'build-tools/36.0.0/aapt'), 'dump', 'badging', str(output)], text=True)
print(badging)
if "name='org.abyssoftears.game'" not in badging or "native-code: 'arm64-v8a'" not in badging:
    raise SystemExit('Unexpected package identity or ABI')
if "android.permission.INTERNET" in badging:
    raise SystemExit('Offline game unexpectedly requests Internet permission')
match = re.search(r"sdkVersion:'(\d+)'", badging)
if not match or int(match[1]) > 33:
    raise SystemExit('Minimum Android version would exclude Android 13')
print(f'Android APK verified: {output} ({output.stat().st_size:,} bytes)')
# Record actual build size instead of padding the project toward a size target.
baseline_path = ROOT / 'docs/visual-baseline-0.4.2.json'
if baseline_path.is_file():
    baseline = json.loads(baseline_path.read_text())
    current_size = output.stat().st_size
    previous_size = int(baseline['apk_bytes'])
    delta = current_size - previous_size
    report = (f"### Comparación de tamaño del APK\n\n"
              f"Referencia {baseline['version']}: {previous_size:,} bytes.\n\n"
              f"Compilación actual: {current_size:,} bytes.\n\n"
              f"Cambio: {delta:+,} bytes ({delta / previous_size * 100:+.2f} %).\n\n"
              "Compilar no demuestra FPS ni instalación en el teléfono.\n")
    print(report)
    if os.environ.get('GITHUB_STEP_SUMMARY'):
        with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as summary:
            summary.write(report)

# This is a measured preview build, never a claim that the 100 MB final target passed.
size_bytes = output.stat().st_size
minimum_bytes = 100_000_000
meets_target = size_bytes >= minimum_bytes
size_report = {"apk_bytes": size_bytes, "minimum_bytes": minimum_bytes,
               "size_requirement_met": meets_target, "version": re.search(r'config/version="([^\"]+)"', (ROOT / "project.godot").read_text()).group(1)}
(output.parent / 'apk-size.json').write_text(json.dumps(size_report, indent=2) + '\n')
message = (f"### Objetivo de tamaño de la actualización de personajes\n\n"
           f"APK real: {size_bytes:,} bytes ({size_bytes / 1_000_000:.2f} MB).\n\n"
           f"Mínimo solicitado: 100 MB. Estado: {'CUMPLIDO' if meets_target else 'PENDIENTE; APK de prueba, actualización final incompleta'}.\n\n"
           "No se incluyen archivos de relleno.\n")
print(message)
if os.environ.get('GITHUB_STEP_SUMMARY'):
    with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as summary:
        summary.write(message)
if os.environ.get('REQUIRE_FINAL_CHARACTER_APK') == '1' and not meets_target:
    raise SystemExit('Final character APK does not meet the measured 100 MB minimum')

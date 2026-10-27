#!/usr/bin/env python3
"""Install the pinned official engine and matching Android templates in CI."""
import argparse
import hashlib
import os
from pathlib import Path
import urllib.request
import zipfile

VERSION = '4.6.3'
ASSETS = {
 'engine': ('Godot_v4.6.3-stable_linux.x86_64.zip', 'd0bc2113065e481c9c2c2b2c37daa4e8be3fe9e27f0ab9ab0b6096e9a37907f3'),
 'templates': ('Godot_v4.6.3-stable_export_templates.tpz', '3fbe2c0e2dec9d537ab9ec97bcf8da91dcf23357fc51f67092dd068d839290a8'),
}
parser = argparse.ArgumentParser()
parser.add_argument('--android', action='store_true')
args = parser.parse_args()
cache = Path(os.environ.get('RUNNER_TEMP', '/tmp')) / 'abyss-godot'
cache.mkdir(parents=True, exist_ok=True)

def download(kind):
    name, checksum = ASSETS[kind]
    archive = cache / name
    url = f'https://github.com/godotengine/godot/releases/download/{VERSION}-stable/{name}'
    if not archive.exists():
        print(f'Downloading {url}', flush=True)
        with urllib.request.urlopen(url, timeout=120) as response, archive.open('wb') as out:
            while chunk := response.read(1024 * 1024):
                out.write(chunk)
    with archive.open('rb') as source:
        actual = hashlib.file_digest(source, 'sha256').hexdigest()
    if actual != checksum:
        archive.unlink()
        raise SystemExit(f'Checksum mismatch for {name}')
    return zipfile.ZipFile(archive)

with download('engine') as archive:
    engine = cache / f'Godot_v{VERSION}-stable_linux.x86_64'
    engine.write_bytes(archive.read(engine.name))
    engine.chmod(0o755)
link = cache / 'godot'
link.unlink(missing_ok=True)
link.symlink_to(engine.name)
if args.android:
    data = Path(os.environ.get('XDG_DATA_HOME', str(Path.home() / '.local/share')))
    templates = data / f'godot/export_templates/{VERSION}.stable'
    templates.mkdir(parents=True, exist_ok=True)
    with download('templates') as archive:
        for name in ['android_debug.apk', 'android_release.apk', 'version.txt']:
            (templates / name).write_bytes(archive.read('templates/' + name))
if 'GITHUB_PATH' in os.environ:
    with open(os.environ['GITHUB_PATH'], 'a') as out:
        out.write(str(cache) + '\n')
print(f'Installed Godot {VERSION}: {link}')

#!/usr/bin/env python3
"""Publish an immutable public Android preview from a verified Actions artifact."""
import argparse
import hashlib
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile

if __package__:
    from .verify_audio_assets import verify_audio_archive
else:
    from verify_audio_assets import verify_audio_archive


def prepare(apk, report_path, root, tag, output):
    report = json.loads(report_path.read_text())
    version = report['version']
    if not isinstance(version, str) or not re.fullmatch(r'\d+\.\d+\.\d+', version):
        raise ValueError('Invalid public preview version')
    if tag != f'v{version}-public':
        raise ValueError('Public tag must match the exported APK version exactly')
    if not apk.is_file() or apk.stat().st_size != report['apk_bytes']:
        raise ValueError('APK size differs from its build report')
    with zipfile.ZipFile(apk) as archive:
        if archive.testzip():
            raise ValueError('Corrupted APK')
        verify_audio_archive(archive, root)
        for name in ['AndroidManifest.xml', 'lib/arm64-v8a/libgodot_android.so']:
            if name not in archive.namelist():
                raise ValueError(f'Missing APK resource: {name}')
        for name in ['balance.json', 'relics_expansion.json', 'archaeology.json']:
            if json.loads(archive.read(f'assets/data/{name}')) != json.loads((root / 'data' / name).read_text()):
                raise ValueError(f'Published APK does not match source: {name}')
    output.mkdir(parents=True, exist_ok=True)
    destination = output / 'AbyssOfTears-Android.apk'
    shutil.copyfile(apk, destination)
    digest = hashlib.sha256(destination.read_bytes()).hexdigest()
    checksum = output / 'AbyssOfTears-Android.apk.sha256'
    checksum.write_text(f'{digest}  {destination.name}\n')
    public_report = output / 'apk-size.json'
    shutil.copyfile(report_path, public_report)
    return version, digest, [destination, checksum, public_report]


def gh(*args, check=True):
    result = subprocess.run(['gh', *args], check=False, text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if check and result.returncode:
        raise RuntimeError(f'GitHub operation failed: {result.stderr.strip()}')
    return result


def publish(repo, tag, version, digest, assets, notes):
    # A published APK is never silently replaced: a new version needs a new tag.
    response = gh('release', 'view', tag, '--repo', repo,
                  '--json', 'isDraft,assets,url', check=False)
    if response.returncode == 0:
        release = json.loads(response.stdout)
        if not release['isDraft']:
            raise RuntimeError('This version is already public and immutable; use a new version/tag')
    else:
        # Creation verifies that this source tag exists; a permission/network
        # failure is reported by the actual operation, never treated as success.
        gh('release', 'create', tag, '--repo', repo, '--verify-tag', '--draft',
           '--prerelease', '--title', f'Abyss of Tears {version} · Prueba pública',
           '--notes-file', str(notes))
    gh('release', 'upload', tag, '--repo', repo, '--clobber', *map(str, assets))
    current = json.loads(gh('release', 'view', tag, '--repo', repo,
                            '--json', 'isDraft,assets,url').stdout)
    by_name = {asset['name']: asset for asset in current['assets']}
    for path in assets:
        if path.name not in by_name or by_name[path.name]['size'] != path.stat().st_size:
            raise RuntimeError(f'Uploaded asset missing or wrong size: {path.name}')
    # Compare downloaded bytes while the release is still a private draft.
    with tempfile.TemporaryDirectory(prefix='release-check-') as directory:
        gh('release', 'download', tag, '--repo', repo, '--pattern', assets[0].name,
           '--dir', directory)
        if hashlib.sha256((Path(directory) / assets[0].name).read_bytes()).hexdigest() != digest:
            raise RuntimeError('Uploaded APK checksum differs from the verified artifact')
    gh('release', 'edit', tag, '--repo', repo, '--draft=false', '--prerelease')
    final = json.loads(gh('release', 'view', tag, '--repo', repo,
                          '--json', 'isDraft,url').stdout)
    if final['isDraft']:
        raise RuntimeError('Release remains draft; publication was not confirmed')
    return final['url']


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--repo', required=True)
    parser.add_argument('--tag', required=True)
    parser.add_argument('--apk', type=Path, default=Path('build/AbyssOfTears-debug.apk'))
    parser.add_argument('--report', type=Path, default=Path('build/apk-size.json'))
    parser.add_argument('--notes', type=Path)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    version, digest, assets = prepare(args.apk, args.report, root, args.tag, root / 'build/public')
    notes = args.notes or root / 'docs' / 'releases' / f'{version}.md'
    if not notes.is_file():
        raise ValueError('Missing version-specific public release notes')
    url = publish(args.repo, args.tag, version, digest, assets, notes)
    print(f'Public release confirmed: {url}\nAPK SHA-256: {digest}')
    if os.environ.get('GITHUB_STEP_SUMMARY'):
        with open(os.environ['GITHUB_STEP_SUMMARY'], 'a') as stream:
            stream.write(f'### Descarga pública\n\n{url}\n\nAPK: {assets[0].stat().st_size:,} bytes.\n\nSHA-256: `{digest}`\n')

if __name__ == '__main__':
    main()

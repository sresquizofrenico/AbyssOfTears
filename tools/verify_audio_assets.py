"""Verify the exported runtime score and all imported sound resources in an APK."""
import json
import re

EFFECTS = ('shoot', 'hit', 'hurt', 'enemy', 'coin', 'relic', 'buy', 'chest', 'door', 'error', 'ui')


def verify_audio_archive(archive, root):
    expected = json.loads((root / 'data/soundtrack.json').read_text())
    if json.loads(archive.read('assets/data/soundtrack.json')) != expected:
        raise ValueError('APK soundtrack registry differs from validated source')
    paths = [entry['path'] for entry in expected['tracks']]
    paths += [f'res://assets/audio/sfx/{name}.wav' for name in EFFECTS]
    for path in paths:
        if not re.fullmatch(r'res://assets/audio/(music|sfx)/[a-z_]+\.(ogg|wav)', path):
            raise ValueError('Invalid soundtrack resource path')
        remap = archive.read('assets/' + path[6:] + '.import').decode()
        match = re.search(r'^path="res://([^"\n]+)"', remap, re.M)
        if not match or not match[1].startswith('.godot/imported/') or '..' in match[1].split('/'):
            raise ValueError('Invalid exported sound import mapping: ' + path)
        if archive.getinfo('assets/' + match[1]).file_size < 1:
            raise ValueError('Empty exported sound resource: ' + path)
    return len(paths)

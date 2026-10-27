#!/usr/bin/env python3
"""Import, resource integrity, runtime and behavior checks. Standard library only."""
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
GODOT = os.environ.get('GODOT', 'godot')
ERROR = re.compile(r'SCRIPT ERROR:|(?:^|\n)ERROR:|Parse Error:|TEST FAILED:|Failed to load', re.I)

def run(args, env):
    result = subprocess.run([GODOT, '--headless', '--path', str(ROOT), *args],
                            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                            env=env, timeout=180)
    print(result.stdout, flush=True)
    if result.returncode or ERROR.search(result.stdout):
        raise SystemExit(f'Godot validation failed: {args} (exit {result.returncode})')

with tempfile.TemporaryDirectory(prefix='abyss-tests-') as user_dir:
    env = dict(os.environ, XDG_DATA_HOME=user_dir, XDG_CONFIG_HOME=user_dir,
               XDG_CACHE_HOME=user_dir)
    project = (ROOT / 'project.godot').read_text()
    if 'run/main_scene="res://scenes/main.tscn"' not in project:
        raise SystemExit('Missing or incorrect main scene')
    for path in ROOT.rglob('*'):
        if '.godot' in path.parts or path.suffix not in ('.tscn', '.gd', '.godot', '.cfg'):
            continue
        for resource in re.findall(r'res://[^"\s)]+', path.read_text()):
            target = ROOT / resource[6:]
            if not (target.is_dir() if resource.endswith('/') else target.is_file()):
                raise SystemExit(f'Missing resource {resource} referenced by {path}')
    run(['--editor', '--import', '--quit'], env)
    run(['--quit-after', '120'], env)
    run(['--script', 'res://tests/run_tests.gd'], env)
    run(['--script', 'res://tests/enemy_tests.gd'], env)
    run(['--script', 'res://tests/floor_tests.gd'], env)
    run(['--script', 'res://tests/relic_tests.gd'], env)
    run(['--script', 'res://tests/menu_tests.gd'], env)
    run(['--script', 'res://tests/exploration_tests.gd'], env)
    run(['--script', 'res://tests/selection_tests.gd'], env)
    run(['--script', 'res://tests/pickup_interaction_tests.gd'], env)
    run(['--script', 'res://tests/illustrated_art_tests.gd'], env)
    run(['--script', 'res://tests/hud_tests.gd'], env)
    run(['--script', 'res://tests/room_structure_tests.gd'], env)
    run(['--script', 'res://tests/economy_tests.gd'], env)
    run(['--script', 'res://tests/character_progress_tests.gd'], env)
    run(['--script', 'res://tests/mythic_expansion_tests.gd'], env)
    run(['--script', 'res://tests/character_passive_tests.gd'], env)
    run(['--script', 'res://tests/control_accessibility_tests.gd'], env)
    run(['--script', 'res://tests/audio_tests.gd'], env)
    run(['--script', 'res://tests/audio_mixer_tests.gd'], env)
    run(['--script', 'res://tests/journal_tests.gd'], env)
    run(['--script', 'res://tests/archaeology_tests.gd'], env)
subprocess.run([sys.executable, '-m', 'unittest', 'discover', '-s', 'tests', '-p', 'test_public_release.py'], cwd=ROOT, check=True)
print('All project validations passed.')

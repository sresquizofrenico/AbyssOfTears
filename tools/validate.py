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
            if not (ROOT / resource[6:]).is_file():
                raise SystemExit(f'Missing resource {resource} referenced by {path}')
    run(['--editor', '--import', '--quit'], env)
    run(['--quit-after', '120'], env)
    run(['--script', 'res://tests/run_tests.gd'], env)
print('All project validations passed.')

#!/usr/bin/env python3
"""Render Abyss's original score. Optional art tool: Python/numpy + ffmpeg.

The game and CI use the committed Ogg files and do not need these dependencies.
All notes, synthesis and percussion are original; no sampled instruments.
"""
from pathlib import Path
import hashlib
import json
import subprocess
import tempfile
import wave

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100
MOTIFS = [
    [0, 7, 10, 9, 5, 2, 7, 3, 0, 5, 9, 7, 2, 3, 7, 0],
    [0, 3, 7, 12, 10, 7, 5, 3, 2, 7, 9, 5, 3, 2, 7, 0],
    [0, 2, 7, 10, 9, 5, 3, 7, 12, 10, 7, 9, 5, 3, 2, 0],
]
# id, Spanish title, root MIDI, tempo, arrangement, motif
SCORES = [
    ('menu', 'Una luz conserva tu nombre', 50, 76, 'calm', 0),
    ('salt_explore', 'Campanas bajo la sal', 50, 80, 'calm', 0),
    ('salt_combat', 'El pulso de la cripta', 50, 104, 'combat', 0),
    ('salt_boss', 'Juramento de la marea', 50, 116, 'boss', 0),
    ('garden_explore', 'Raíces que recuerdan', 53, 84, 'calm', 1),
    ('garden_combat', 'Esporas en la penumbra', 53, 108, 'combat', 1),
    ('garden_boss', 'La promesa enterrada', 53, 120, 'boss', 1),
    ('crystal_explore', 'La falla canta', 57, 88, 'calm', 2),
    ('crystal_combat', 'Fragmentos en marcha', 57, 112, 'combat', 2),
    ('crystal_boss', 'Corona de resonancias', 57, 124, 'boss', 2),
    ('special', 'Un trato con la luz', 55, 80, 'calm', 2),
    ('victory', 'El faro abre los ojos', 62, 92, 'ending', 1),
    ('defeat', 'Todavía queda una brasa', 45, 68, 'calm', 0),
]


def hz(midi):
    return 440 * 2 ** ((midi - 69) / 12)


def render(root, bpm, arrangement, motif):
    beat = 60 / bpm
    length = int(round(32 * beat * RATE))
    mix = np.zeros((length, 2), dtype=np.float64)

    def voice(at, note, duration, gain, kind='bell', pan=0.0):
        t = np.arange(int(duration * RATE)) / RATE
        freq = hz(note)
        if kind == 'pad':
            sound = (np.sin(2 * np.pi * freq * t) + .23 * np.sin(2 * np.pi * freq * 2.003 * t))
            env = np.minimum(1, t / .14) * np.minimum(1, (duration - t) / .25)
        elif kind == 'bass':
            sound = np.sin(2 * np.pi * freq * t) + .15 * np.sin(4 * np.pi * freq * t)
            env = np.minimum(1, t / .009) * np.exp(-t * 3 / duration)
        else:
            sound = np.sin(2 * np.pi * freq * t) + .3 * np.sin(2 * np.pi * freq * 2.01 * t) + .08 * np.sin(2 * np.pi * freq * 3 * t)
            env = np.minimum(1, t / .005) * np.exp(-t * 5 / duration)
        # Wrap releases into the start: no hard truncation at the looping seam.
        idx = (np.arange(len(t)) + int(round(at * beat * RATE))) % length
        audio = sound * env * np.minimum(1, (duration - t) / .02) * gain
        np.add.at(mix[:, 0], idx, audio * np.sqrt((1 - pan) / 2))
        np.add.at(mix[:, 1], idx, audio * np.sqrt((1 + pan) / 2))

    progression = [0, -5, 3, -2, 0, 5, 3, -2]
    for bar, chord in enumerate(progression):
        for interval in [0, 7, 10 if bar % 2 else 3]:
            voice(bar * 4, root + chord + interval, beat * 4.4, .055, 'pad', interval / 18 - .3)
        for pulse in range(2 if arrangement == 'calm' else 4):
            voice(bar * 4 + pulse * (2 if arrangement == 'calm' else 1), root + chord - 12, beat * .8, .14, 'bass')
        for j in range(4):
            step = MOTIFS[motif][(bar * 4 + j) % 16]
            voice(bar * 4 + j + (.5 if j % 2 else 0), root + 12 + step, beat * 1.8, .10, pan=(-.35 if j % 2 else .35))
            if arrangement in ('combat', 'boss'):
                voice(bar * 4 + j + .5, root + 7 + MOTIFS[motif][(bar + j) % 16], beat * .6, .045, pan=.5 if j % 2 else -.5)
        if arrangement == 'boss':
            voice(bar * 4, root + 24 + MOTIFS[motif][bar], beat * 2, .065)
    # Deterministic original filtered-noise percussion, restrained in calm tracks.
    rng = np.random.default_rng(6100 + root)
    step = 1 if arrangement in ('combat', 'boss') else 4
    for at in range(0, 32, step):
        t = np.arange(int(.23 * RATE)) / RATE
        kick = np.sin(2 * np.pi * (55 * t + 3 * (1 - np.exp(-t * 25)))) * np.exp(-t * 24)
        noise = rng.normal(0, 1, len(t))
        tick = (noise - np.roll(noise, 1)) * np.exp(-t * 80) * .12
        drum = (kick * (.14 if at % 2 == 0 else .05) + tick) * (.4 if arrangement == 'calm' else 1)
        drum *= np.minimum(1, t / .004) * np.minimum(1, (.23 - t) / .02)
        idx = (np.arange(len(t)) + int(round(at * beat * RATE))) % length
        for side in range(2):
            np.add.at(mix[:, side], idx, drum)
    # One circular stereo echo, bounded; no feedback chain or external reverb.
    mix += np.roll(mix[:, ::-1], int(beat * .75 * RATE), axis=0) * .19
    mix *= .63 / max(.63, float(np.abs(mix).max()))
    return np.round(mix * 32767).astype('<i2')


def encode(samples, destination):
    with tempfile.TemporaryDirectory() as folder:
        wav_path = Path(folder) / 'score.wav'
        with wave.open(str(wav_path), 'wb') as wav:
            wav.setnchannels(2)
            wav.setsampwidth(2)
            wav.setframerate(RATE)
            wav.writeframes(samples.tobytes())
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(wav_path), '-map_metadata', '-1',
                        '-c:a', 'libvorbis', '-q:a', '4', str(destination)], check=True)


def main():
    entries = []
    for ident, title, root, bpm, arrangement, motif in SCORES:
        samples = render(root, bpm, arrangement, motif)
        target = ROOT / 'assets/audio/music' / (ident + '.ogg')
        target.parent.mkdir(parents=True, exist_ok=True)
        encode(samples, target)
        entries.append(dict(id=ident, title=title, path='res://' + str(target.relative_to(ROOT)),
                            bpm=bpm, bars=8, seconds=len(samples) / RATE, root_midi=root,
                            arrangement=arrangement, motif=motif,
                            sha256=hashlib.sha256(target.read_bytes()).hexdigest()))
        print(ident, target.stat().st_size)
    (ROOT / 'data/soundtrack.json').write_text(json.dumps(dict(version=1, license='MIT', tracks=entries), ensure_ascii=False, indent=2) + '\n')
    # Short deterministic cues: no borrowed samples, bounded mono PCM memory.
    cues = {'shoot': (740, 410, .08), 'hit': (230, 90, .09), 'hurt': (190, 70, .23),
            'enemy': (150, 42, .19), 'coin': (980, 1400, .13), 'relic': (440, 880, .33),
            'buy': (660, 1320, .28), 'chest': (260, 780, .34), 'door': (180, 350, .25),
            'error': (150, 110, .18), 'ui': (540, 700, .06)}
    for name, (start, end, duration) in cues.items():
        t = np.arange(int(duration * 22050)) / 22050
        phase = 2 * np.pi * (start * t + (end - start) * t * t / (2 * duration))
        env = np.minimum(1, t / .004) * (1 - t / duration) ** 2
        sound = (np.sin(phase) + .16 * np.sin(phase * 2)) * env * .4
        target = ROOT / 'assets/audio/sfx' / (name + '.wav')
        target.parent.mkdir(parents=True, exist_ok=True)
        with wave.open(str(target), 'wb') as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(22050)
            wav.writeframes(np.round(sound * 32767).astype('<i2').tobytes())


if __name__ == '__main__':
    main()

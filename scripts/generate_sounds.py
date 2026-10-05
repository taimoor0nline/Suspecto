"""Synthesize the app's short sound effects as WAV files. No network needed.

Every sound is generated from simple tones, so the audio is original and
free of third-party licensing. Run: python scripts/generate_sounds.py
"""
import math
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / 'assets/sounds'


def tone(freq, seconds, volume=0.5, end_freq=None, harmonics=(1.0, 0.25),
         attack=0.005, release=0.06, tremolo=0.0):
    n = int(RATE * seconds)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = freq if end_freq is None else freq + (end_freq - freq) * i / n
        phase += 2 * math.pi * f / RATE
        sample = sum(a * math.sin(phase * (k + 1)) for k, a in enumerate(harmonics))
        sample /= sum(harmonics)
        env = min(1.0, t / attack) if attack else 1.0
        env *= min(1.0, (seconds - t) / release) if release else 1.0
        if tremolo:
            env *= 0.75 + 0.25 * math.sin(2 * math.pi * tremolo * t)
        out.append(sample * env * volume)
    return out


def silence(seconds):
    return [0.0] * int(RATE * seconds)


def pluck(freq, seconds, volume=0.5):
    # Exponential decay gives a soft woodblock/click character.
    n = int(RATE * seconds)
    return [volume * math.exp(-i / (RATE * seconds / 5)) *
            math.sin(2 * math.pi * freq * i / RATE) for i in range(n)]


def write(name, samples):
    OUT.mkdir(parents=True, exist_ok=True)
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = min(1.0, 0.9 / peak)
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(RATE)
        file.writeframes(b''.join(
            struct.pack('<h', int(s * scale * 32767)) for s in samples))


def main():
    write('tap', pluck(1200, 0.04, 0.35))
    write('reveal', tone(480, 0.18, 0.45, end_freq=1100, release=0.08))
    write('vote', tone(700, 0.09, 0.4, end_freq=950, release=0.04))
    write('tick', pluck(1500, 0.05, 0.45))
    beep = tone(880, 0.15, 0.55, harmonics=(1.0, 0.4, 0.2), release=0.03)
    write('timeup', beep + silence(0.08) + beep + silence(0.08) +
          tone(880, 0.4, 0.55, harmonics=(1.0, 0.4, 0.2), release=0.15))
    notes = [523.25, 659.25, 783.99]
    write('win', sum((tone(f, 0.11, 0.5, harmonics=(1.0, 0.3, 0.1)) for f in notes), []) +
          tone(1046.5, 0.5, 0.55, harmonics=(1.0, 0.3, 0.1), release=0.3))
    sneaky = [392.0, 311.13, 261.63]
    write('imposters', sum((tone(f, 0.16, 0.5, harmonics=(1.0, 0.5, 0.3)) for f in sneaky), []) +
          tone(246.94, 0.6, 0.5, harmonics=(1.0, 0.5, 0.3), release=0.35, tremolo=7))
    bounce = [659.25, 880.0, 659.25, 987.77]
    write('jester', sum((tone(f, 0.09, 0.45, harmonics=(1.0, 0.6)) for f in bounce), []) +
          tone(700, 0.35, 0.45, end_freq=1400, harmonics=(1.0, 0.6), release=0.2))
    print(f'Wrote {len(list(OUT.glob("*.wav")))} sounds to {OUT}')


if __name__ == '__main__':
    main()

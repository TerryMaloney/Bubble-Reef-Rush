#!/usr/bin/env python3
"""
Generate placeholder audio files for Bubble Reef Rush.

Produces:
  assets/audio/music/zone_1_sunlit_shallows.wav  — 100 BPM click track (24 s)
  assets/audio/sfx/timing_perfect.wav
  assets/audio/sfx/timing_good.wav
  assets/audio/sfx/timing_miss.wav
  assets/audio/sfx/collectible_pearl.wav
  assets/audio/sfx/player_hit.wav

Usage:
  python3 tools/gen_audio.py

After running, open the Godot editor once to trigger automatic WAV import.
To use OGG instead (smaller, better compression):
  ffmpeg -i assets/audio/music/zone_1_sunlit_shallows.wav \\
             assets/audio/music/zone_1_sunlit_shallows.ogg
  # then update z1-l1.brl "filename" field back to .ogg
"""
import math
import os
import random
import struct
import wave

SAMPLE_RATE = 44100
ROOT = os.path.join(os.path.dirname(__file__), "..")


def write_wav(path: str, samples: list) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "w") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(struct.pack(f"<{len(samples)}h", *samples))
    kb = os.path.getsize(path) // 1024
    print(f"  {os.path.relpath(path, ROOT)}  ({len(samples) / SAMPLE_RATE:.2f}s, {kb} KB)")


def sine_burst(freq: float, duration_s: float, decay_s: float, volume: float = 0.8) -> list:
    n = int(SAMPLE_RATE * duration_s)
    return [
        max(-32767, min(32767, int(
            32767 * volume
            * math.exp(-i / (SAMPLE_RATE * decay_s))
            * math.sin(2 * math.pi * freq * i / SAMPLE_RATE)
        )))
        for i in range(n)
    ]


def chord_burst(freqs: list, duration_s: float, decay_s: float, volume: float = 0.55) -> list:
    n = int(SAMPLE_RATE * duration_s)
    k = len(freqs)
    return [
        max(-32767, min(32767, int(
            32767 * volume
            * math.exp(-i / (SAMPLE_RATE * decay_s))
            * sum(math.sin(2 * math.pi * f * i / SAMPLE_RATE) for f in freqs) / k
        )))
        for i in range(n)
    ]


def noise_thump(duration_s: float, decay_s: float, volume: float = 0.5) -> list:
    n = int(SAMPLE_RATE * duration_s)
    rng = random.Random(7)
    raw = [rng.random() * 2 - 1 for _ in range(n + 1)]
    lp = [(raw[i] + raw[i + 1]) * 0.5 for i in range(n)]
    return [
        max(-32767, min(32767, int(
            32767 * volume * math.exp(-i / (SAMPLE_RATE * decay_s)) * lp[i]
        )))
        for i in range(n)
    ]


def gen_click_track(bpm: float, total_beats: int) -> list:
    beat_dur = 60.0 / bpm
    total_samples = int(SAMPLE_RATE * total_beats * beat_dur)
    click_len = int(SAMPLE_RATE * 0.07)
    decay = 55.0

    def click(freq, vol):
        return [
            max(-32767, min(32767, int(
                32767 * vol
                * math.exp(-i / SAMPLE_RATE * decay)
                * math.sin(2 * math.pi * freq * i / SAMPLE_RATE)
            )))
            for i in range(click_len)
        ]

    downbeat = click(1000, 0.80)
    beat_click = click(700, 0.55)

    audio = [0] * total_samples
    for b in range(total_beats):
        start = int(b * beat_dur * SAMPLE_RATE)
        src = downbeat if b % 4 == 0 else beat_click
        for i, s in enumerate(src):
            if start + i < total_samples:
                audio[start + i] = s
    return audio


def main() -> None:
    print("Generating placeholder audio files...")

    music_dir = os.path.join(ROOT, "assets", "audio", "music")
    sfx_dir   = os.path.join(ROOT, "assets", "audio", "sfx")

    write_wav(
        os.path.join(music_dir, "zone_1_sunlit_shallows.wav"),
        gen_click_track(bpm=100, total_beats=40),
    )

    sfx = {
        "timing_perfect.wav":    chord_burst([880, 1109, 1319], 0.25, 0.07),
        "timing_good.wav":       sine_burst(660, 0.18, 0.09),
        "timing_miss.wav":       sine_burst(180, 0.22, 0.18, 0.4),
        "collectible_pearl.wav": chord_burst([1047, 1319, 1568], 0.28, 0.10),
        "player_hit.wav":        noise_thump(0.22, 0.06),
    }
    for name, samples in sfx.items():
        write_wav(os.path.join(sfx_dir, name), samples)

    print("\nDone. Open Godot editor to import the WAV files.")
    print("Or convert to OGG: ffmpeg -i <file.wav> <file.ogg>")


if __name__ == "__main__":
    main()

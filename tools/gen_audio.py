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


def gen_variable_click_track(tempo_curve_path: str) -> list:
    """Generate a variable-BPM click track from a z5_tempo_curve.json file."""
    import json
    with open(tempo_curve_path) as f:
        curve = json.load(f)
    events = curve.get("bpm_changes", [])
    total_beats = int(curve.get("total_beats", 128))

    # Build per-beat BPM table from the curve.
    bpm_table = []
    current_bpm = float(curve.get("base_bpm", 110.0))
    event_idx = 0
    for beat in range(total_beats):
        while event_idx < len(events) and int(events[event_idx]["beat_index"]) <= beat:
            current_bpm = float(events[event_idx]["new_bpm"])
            event_idx += 1
        bpm_table.append(current_bpm)

    click_len = int(SAMPLE_RATE * 0.07)
    decay = 55.0

    def click(freq: float, vol: float) -> list:
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

    total_samples = sum(int(60.0 / bpm * SAMPLE_RATE) for bpm in bpm_table)
    audio = [0] * total_samples

    pos = 0
    for b, bpm in enumerate(bpm_table):
        src = downbeat if b % 4 == 0 else beat_click
        for i, s in enumerate(src):
            if pos + i < total_samples:
                audio[pos + i] = s
        pos += int(60.0 / bpm * SAMPLE_RATE)

    return audio


def main() -> None:
    print("Generating placeholder audio files...")

    music_dir = os.path.join(ROOT, "assets", "audio", "music")
    sfx_dir   = os.path.join(ROOT, "assets", "audio", "sfx")

    # Zone 1-6 click tracks.
    music_tracks = [
        ("zone_1_sunlit_shallows.wav",  100, 40),
        ("zone_2_kelp_forest.wav",      120, 60),
        ("zone_3_shipwreck_alley.wav",  135, 64),
        ("zone_4_volcanic_vent.wav",    155, 64),
        ("zone_6_crystal_caves.wav",    175, 64),
    ]
    for filename, bpm, beats in music_tracks:
        write_wav(os.path.join(music_dir, filename), gen_click_track(bpm=bpm, total_beats=beats))

    # Zone 5 variable-BPM click track from canonical tempo curve.
    z5_curve = os.path.join(ROOT, "assets", "levels", "z5_tempo_curve.json")
    if os.path.exists(z5_curve):
        write_wav(
            os.path.join(music_dir, "zone_5_twilight_trench.wav"),
            gen_variable_click_track(z5_curve),
        )
    else:
        print(f"  (skipping zone_5 — {z5_curve} not found)")

    # SFX — original set.
    sfx_original = {
        "timing_perfect.wav":    chord_burst([880, 1109, 1319], 0.25, 0.07),
        "timing_good.wav":       sine_burst(660, 0.18, 0.09),
        "timing_miss.wav":       sine_burst(180, 0.22, 0.18, 0.4),
        "collectible_pearl.wav": chord_burst([1047, 1319, 1568], 0.28, 0.10),
        "player_hit.wav":        noise_thump(0.22, 0.06),
    }
    # SFX — new (Phase 3+).
    sfx_new = {
        "fever_start.wav":        chord_burst([523, 659, 784, 1047], 0.40, 0.12, 0.6),
        "fever_end.wav":          chord_burst([440, 349], 0.30, 0.15, 0.5),
        "near_miss.wav":          sine_burst(1760, 0.15, 0.04, 0.6),
        "checkpoint_set.wav":     sine_burst(880, 0.20, 0.08, 0.5),
        "checkpoint_respawn.wav": chord_burst([523, 659, 784], 0.50, 0.20, 0.45),
        "coin_collect.wav":       chord_burst([1319, 1568, 2093], 0.22, 0.06, 0.65),
        "achievement.wav":        chord_burst([523, 659, 784, 1047], 0.55, 0.18, 0.55),
        "ui_select.wav":          sine_burst(1047, 0.05, 0.03, 0.45),
        "ui_back.wav":            sine_burst(784, 0.05, 0.03, 0.35),
        # Phase 15 — Resonance powers
        "power_charge.wav":       chord_burst([440, 659, 880], 0.38, 0.12, 0.60),
        "power_fire.wav":         chord_burst([600, 900, 1200], 0.28, 0.06, 0.65),
        "shield_break.wav":       chord_burst([800, 1000, 1400], 0.38, 0.08, 0.55),
    }
    for name, samples in {**sfx_original, **sfx_new}.items():
        write_wav(os.path.join(sfx_dir, name), samples)

    print("\nDone. Open Godot editor to import the WAV files.")
    print("Or convert to OGG: ffmpeg -i <file.wav> <file.ogg>")


if __name__ == "__main__":
    main()

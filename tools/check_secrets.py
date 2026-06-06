#!/usr/bin/env python3
"""Lightweight secret pattern scanner for all git-tracked files."""

import re
import subprocess
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Pattern definitions
# ---------------------------------------------------------------------------
# Each entry: (name, compiled_regex, is_hard_fail)
# Hard-fail patterns cause a non-zero exit. Warn-only patterns are reported
# but do not affect the exit code.

HARD_FAIL_PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    (
        "GitHub PAT",
        re.compile(r"ghp_[A-Za-z0-9]{36}"),
    ),
    (
        "Generic token assignment",
        re.compile(r"token\s*=\s*['\"][A-Za-z0-9_\-]{20,}['\"]", re.IGNORECASE),
    ),
    (
        "Private key header",
        re.compile(r"-----BEGIN (RSA|EC|DSA|OPENSSH) PRIVATE KEY-----"),
    ),
]

WARN_ONLY_PATTERNS: list[tuple[str, re.Pattern[str]]] = [
    (
        "Keystore password in config",
        re.compile(r"storePassword\s*=\s*\S+"),
    ),
]

# Heuristic: common binary file extensions to skip
BINARY_EXTENSIONS: frozenset[str] = frozenset({
    ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp", ".tga", ".svg",
    ".ico", ".icns",
    ".wav", ".ogg", ".mp3", ".flac", ".aac", ".opus",
    ".mp4", ".webm", ".ogv",
    ".ttf", ".otf", ".woff", ".woff2",
    ".zip", ".tar", ".gz", ".bz2", ".xz", ".7z",
    ".apk", ".aab", ".aar", ".jar",
    ".so", ".dll", ".dylib", ".exe", ".o", ".a",
    ".pck", ".wasm",
    ".blend", ".fbx", ".obj", ".glb", ".gltf",
    ".pdf",
    ".pyc", ".pyo",
})


def get_tracked_files() -> list[str]:
    """Return list of files tracked by git."""
    result = subprocess.run(
        ["git", "ls-files"],
        capture_output=True,
        text=True,
        check=True,
    )
    return [line for line in result.stdout.splitlines() if line.strip()]


def is_git_ignored(path: str) -> bool:
    """Return True if git considers the file ignored."""
    result = subprocess.run(
        ["git", "check-ignore", "-q", path],
        capture_output=True,
    )
    return result.returncode == 0


def looks_binary(path: Path) -> bool:
    """Return True if the file should be treated as binary."""
    if path.suffix.lower() in BINARY_EXTENSIONS:
        return True
    # Sniff first 8 KB for null bytes
    try:
        with open(path, "rb") as fh:
            chunk = fh.read(8192)
        return b"\x00" in chunk
    except OSError:
        return True


def scan_file(
    path: Path,
    hard_patterns: list[tuple[str, re.Pattern[str]]],
    warn_patterns: list[tuple[str, re.Pattern[str]]],
) -> tuple[list[str], list[str]]:
    """Scan one file. Returns (hard_findings, warn_findings) as formatted strings."""
    hard_findings: list[str] = []
    warn_findings: list[str] = []

    try:
        lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    except OSError as exc:
        warn_findings.append(f"  [READ ERROR] {path}: {exc}")
        return hard_findings, warn_findings

    for lineno, line in enumerate(lines, start=1):
        for name, pattern in hard_patterns:
            if pattern.search(line):
                hard_findings.append(f"  [FAIL] {path}:{lineno}  ({name})")

        for name, pattern in warn_patterns:
            if pattern.search(line):
                warn_findings.append(f"  [WARN] {path}:{lineno}  ({name})")

    return hard_findings, warn_findings


def main() -> int:
    repo_root = Path(
        subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
    )

    try:
        tracked = get_tracked_files()
    except subprocess.CalledProcessError as exc:
        print(f"ERROR: Could not list tracked files: {exc}", file=sys.stderr)
        return 1

    print(f"Scanning {len(tracked)} tracked file(s) for secret patterns...")
    print()

    all_hard: list[str] = []
    all_warn: list[str] = []
    skipped = 0

    for rel_path in tracked:
        abs_path = repo_root / rel_path

        if not abs_path.is_file():
            continue

        # Skip git-ignored files (belt-and-suspenders; ls-files rarely returns them)
        if is_git_ignored(rel_path):
            skipped += 1
            continue

        if looks_binary(abs_path):
            skipped += 1
            continue

        hard, warn = scan_file(abs_path, HARD_FAIL_PATTERNS, WARN_ONLY_PATTERNS)
        all_hard.extend(hard)
        all_warn.extend(warn)

    if all_warn:
        print("Warnings (informational — will NOT fail the build):")
        for msg in all_warn:
            print(msg)
        print()

    if all_hard:
        print("Failures (hard-fail — build WILL fail):")
        for msg in all_hard:
            print(msg)
        print()

    print(f"Skipped {skipped} binary/ignored file(s).")
    print()

    if all_hard:
        print(f"RESULT: FAIL — {len(all_hard)} hard-fail finding(s) detected.", file=sys.stderr)
        return 1

    print(f"RESULT: PASS — no hard-fail secret patterns found "
          f"({len(all_warn)} warning(s)).")
    return 0


if __name__ == "__main__":
    sys.exit(main())

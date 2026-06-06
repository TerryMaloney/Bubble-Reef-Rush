#!/usr/bin/env python3
"""Validate all .brl level files in assets/levels/ against the JSON schema."""

import json
import os
import sys

try:
    import jsonschema
    from jsonschema import validate, ValidationError
except ImportError:
    print("ERROR: jsonschema is not installed. Run: pip install jsonschema", file=sys.stderr)
    sys.exit(1)

LEVELS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                          "assets", "levels")
SCHEMA_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                           "docs", "design", "level_schema.json")

CURRENT_SCHEMA_VERSION = "1.1"
LEGACY_SCHEMA_VERSION = "1.0"


def load_schema() -> dict:
    if not os.path.isfile(SCHEMA_PATH):
        print(f"WARNING: Schema file not found at {SCHEMA_PATH}. Skipping schema validation.")
        return {}
    with open(SCHEMA_PATH, encoding="utf-8") as f:
        return json.load(f)


def find_brl_files(root: str) -> list[str]:
    matches: list[str] = []
    for dirpath, _dirnames, filenames in os.walk(root):
        for filename in filenames:
            if filename.endswith(".brl"):
                matches.append(os.path.join(dirpath, filename))
    return sorted(matches)


def validate_file(path: str, schema: dict) -> bool:
    """Validate a single .brl file. Returns True on pass, False on failure."""
    try:
        with open(path, encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError as exc:
        print(f"  FAIL  {path}")
        print(f"        JSON parse error: {exc}")
        return False
    except OSError as exc:
        print(f"  FAIL  {path}")
        print(f"        Cannot read file: {exc}")
        return False

    # schema_version check
    schema_version = None
    if isinstance(data, dict):
        schema_version = data.get("schema_version")

    if schema_version == LEGACY_SCHEMA_VERSION:
        print(f"  WARN  {path}")
        print(f"        schema_version is \"{LEGACY_SCHEMA_VERSION}\" "
              f"(legacy, backwards-compatible). Consider upgrading to \"{CURRENT_SCHEMA_VERSION}\".")
    elif schema_version != CURRENT_SCHEMA_VERSION:
        print(f"  WARN  {path}")
        print(f"        schema_version is {schema_version!r}; "
              f"expected \"{CURRENT_SCHEMA_VERSION}\".")

    # JSON Schema validation (only if schema was loaded)
    if schema:
        try:
            validate(instance=data, schema=schema)
        except ValidationError as exc:
            print(f"  FAIL  {path}")
            print(f"        Schema validation error: {exc.message}")
            return False

    print(f"  PASS  {path}")
    return True


def main() -> int:
    if not os.path.isdir(LEVELS_DIR):
        print(f"WARNING: Levels directory not found: {LEVELS_DIR}")
        print("No .brl files to validate. Exiting with success.")
        return 0

    schema = load_schema()
    files = find_brl_files(LEVELS_DIR)

    if not files:
        print(f"WARNING: No .brl files found under {LEVELS_DIR}")
        print("Nothing to validate. Exiting with success.")
        return 0

    print(f"Validating {len(files)} .brl file(s) in {LEVELS_DIR}")
    if schema:
        print(f"Schema: {SCHEMA_PATH}")
    else:
        print("Schema: (not found — JSON parse only)")
    print()

    passed = 0
    failed = 0
    for path in files:
        if validate_file(path, schema):
            passed += 1
        else:
            failed += 1

    print()
    print(f"Summary: {passed}/{len(files)} files passed.")

    if failed > 0:
        print(f"ERROR: {failed} file(s) failed validation.", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())

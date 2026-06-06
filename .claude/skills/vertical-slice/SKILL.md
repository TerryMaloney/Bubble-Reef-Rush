# Skill: Bootstrap Vertical Slice

Use this skill to verify the project is in a runnable state and identify what still
needs to be done before the vertical slice is playable end-to-end.

## Steps

### 1. Verify `project.godot` exists

```bash
test -f project.godot && echo "OK: project.godot found" || echo "MISSING"
```

If `project.godot` is not present, **halt immediately** and tell the user:

> `project.godot` is missing. This likely means the Godot project has not been
> scaffolded yet. Run `tools/scaffold.sh` from the repository root to create the
> initial project structure, then re-run this skill.

Do not proceed past this step if the file is absent.

### 2. Validate `.brl` level files

```bash
python tools/validate_brl.py
```

- If validation fails, **fix schema errors before continuing.** Common issues:
  - `schema_version` is `"1.0"` instead of `"1.1"` — update the field.
  - Missing required keys (`metadata`, `beat_map`) — check the level file against
    `docs/design/level_schema.json`.
  - Malformed JSON — use a JSON linter to find the syntax error.
- If `assets/levels/` does not exist yet, the script exits cleanly. Note this in your
  report as a gap (no levels to test).

### 3. Run smoke tests (headless)

If `./bin/godot` is present and executable:

```bash
./bin/godot --headless -s res://tests/smoke/run_smoke_tests.gd 2>&1 | tee smoke_output.txt
grep "SMOKE_OK" smoke_output.txt && echo "Smoke tests PASSED" || echo "Smoke tests FAILED"
```

If `./bin/godot` is not present:

```bash
./tools/install_godot_linux.sh
```

Then re-run the smoke tests.

Interpret failures:
- `assert ... autoload missing` — the named autoload is not registered in
  `project.godot`. Add it under `[autoload]`.
- `z1-l1.brl level file missing` — create a minimal valid level file at
  `assets/levels/z1-l1.brl` using the schema in `docs/design/level_schema.json`.
- `Cannot open z1-l1.brl` / `not valid JSON` — the file exists but is unreadable or
  malformed. Fix the JSON.
- `SaveSystem returned empty profile id` — `SaveSystem.get_active_profile_id()` is
  returning an empty string. Check the SaveSystem autoload initialization logic.

### 4. Check for unstaged changes

```bash
git status --short
```

Note any unstaged or untracked files that may indicate in-progress work that has not
been committed. Do not commit changes on the user's behalf; report what you find.

### 5. Report

Summarize findings in this format:

**Passing:**
- List each check that succeeded.

**Failing:**
- List each check that failed, with the specific error and the recommended fix.

**Next steps:**
- Ordered list of the most important remaining tasks to reach a playable vertical
  slice, based on what is currently failing and what is still missing.

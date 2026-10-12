# PLAN — Rename `co-awareness` → `co-awake`, and `brain-doctor` → `co-doctor`

> Grounded 2026-10-12 on macOS 27 (Darwin 27.0.0), Apple Silicon. This draft folds in the Codex spec review (P1–P3) and the owner's final calls on D1–D4.
> Code read: `CoAwareness.swift` (`AppInfo`, `Config.retiredEnvironment`, `IntentForwarder`, `StateStore.fileURL` / `intentDirectoryURL` / `spoolIntent` / `migrateLegacyDirectoryIfNeeded`, `applicationDidFinishLaunching`, `Restarter`, `Builder`, `UpdateChecker`); the `co-awareness` launcher; `install.sh`; `uninstall.sh`; `scripts/*-login-item.sh`; `tests/qa.sh`; `tests/install-smoke.sh`; and the R26 rename commit `c8196f1`.
> co-doctor side: `co-brain/skills/brain-doctor/` (`SKILL.md`, `scripts/doctor.py`), `env-config/macos/bin/brain-doctor`, `env-config/macos/Library/LaunchAgents/com.binle.brain-doctor.plist`, `env-config/macos/setup-scripts/{01-activate-environment,05-validate-setup}.sh`, `env-config/.agents/`.
> Machine state, 2026-10-11:
> - `ai.bera.coawareness` is loaded with argv `start --foreground --preset horse-white --load-source cpu --display trace --battery-threshold 15`.
> - `com.binle.brain-doctor` is loaded. Its last run completed a treat with 0 active alerts.
>
> Tracking: `docs/ROADMAP.md` R31. The row is added in its own commit, because `ROADMAP.md` currently holds an uncommitted R30 edit.

---

## 1. Objective & Scope

**Why rename.** A name should say what the program actually does on the machine.

- `co-awareness` suggests perception or consciousness. The code does two physical things:
  - It reads 10 unprivileged hardware counters and uses them to drive a menu-bar animation (load visualization).
  - It holds a sleep assertion through `caffeinate -di -w <pid>`, which lives and dies with the app's own process (Keep Awake).

  `awake` names the second job. It is also the action users type most in a terminal. The load visualization is how the app looks while it runs.
- `brain-doctor` sits in the cognitive `brain-*` family, but it does no cognition. It runs deterministic probes plus whitelisted self-repair, and it looks after the base layer of the whole co ecosystem:
  - L0/L1 router symlinks;
  - the FTS5 index;
  - brain-index;
  - the executable bit on skills.

  Renamed to the ecosystem-member name `co-doctor`, it leaves only the three cognitive skills (storm / research / reflection) under `brain-*`. Each namespace then covers one kind of job.

**In scope**

| Block | Content |
|---|---|
| A. co-awake (this repo) | Source, binary, launcher, env prefix, state directory and migration protocol, LaunchAgent label, install dir, PATH link, tests, docs, cover page, Pages project, GitHub repo name. Ships as v3.0.0 |
| B. co-doctor (co-brain + env-config) | Skill directory, `SKILL.md`, `doctor.py` self-description, CLI wrapper plus `doctor` link, LaunchAgent label, setup/validation scripts, L0 router text, co-brain doc cross-references |
| C. Switching this machine | Handover of both LaunchAgents with planned downtime, the `state.json` chain migration, continuity of `doctor.log` / `.doctor-alert`, moving the dev directory and Claude's project memory directory, L1 router entry (D4) |

**Behavior boundary.** Business behavior does not change, apart from three approved items:

1. the naming migration itself;
2. refusing the old spellings (D2);
3. the state-migration protocol hardening in § 4.1.3, which closes the race found in review.

These stay unchanged: CLI verbs and flags, the JSON schemas of `snapshot` / `status` / `presets`, telemetry, the Keep Awake rules, the 5% floor, and `doctor.py`'s checks and treatment whitelist. A rename commit that carries any other behavior diff is out of bounds.

**Out of scope** (each needs its own item if it comes up)

- **Compatibility aliases.** No `co-awareness`, `coa`, or `co-awake` command alias. No fallback reading of `CO_AWARENESS_*` (red line 9). D2 refuses the old prefix; it never translates it. `brain-doctor` gets no alias either (the `brain-refresh` precedent). `doctor` is a second entry point the owner asked for, see § 4.2.
- **`env-config/macos/bin/keep-awake.sh`.** It overlaps with `awake` in function but has a different name and does not conflict. Whether to absorb it is a separate decision.
- **A generic "no one-click update across MAJOR versions" gate** (D1 option b). That is a new capability, so it gets its own item.
- **Content of the three cognitive skills.** Only their cross-references to `brain-doctor` change.
- **History.** Existing `CHANGELOG.md` entries, git history, and `co-brain/docs/RESEARCH-*.md` (dated evidence) stay as they are.
- **co-library body text.** No full-library grep. Phase 3 uses the library's own search to list leftover references, and only reports them.

---

## 2. Decisions (all made)

**Owner decisions**

- Repo and ecosystem name `co-awake`; command `awake`; env prefix `CO_AWAKE_*`; version v3.0.0.
- State directory `Application Support/co-awake`. `coa` is retired.
- `co-doctor` (plus `doctor`) stays in `co-brain/skills/`. Its LaunchAgent label is `com.binle.co-doctor`.
- `doctor.log` and `.doctor-alert` continue in place.

| # | Decision | Resolution and remaining risk |
|---|---|---|
| **D1** | One-click update across the rename | **(a) Hard cut.** A v2.4.x install that clicks Update breaks: the icon does not come back (mechanism in § 4.1.7). The owner accepts this risk. Mitigations: the CHANGELOG upgrade notes give two procedures, *before updating* and *after a mistaken update* (§ 4.1.7). Phase 1.5 on this machine deliberately takes the mistaken-update path, so it reproduces the failure and proves the recovery for real (§ 5). Installs that are never upgraded by hand stay stuck on v2.4.x; external install count is unknown, so this risk cannot be removed |
| **D2** | Old env prefix | **(b) Refuse with an error.** A non-empty `CO_AWARENESS_*` variable means exit 1 with the replacement name, **before the first side effect at every entry point**. That covers the `awake` launcher, `install.sh`, `uninstall.sh`, both `scripts/*-login-item.sh`, and the binary (§ 4.1.2). This is a refusal, not a fallback, so it does not break red line 9 |
| **D3** | LaunchAgent label | **`com.binle.coawake`**, no hyphen. The gate is that four places agree (binary `Restarter.launchAgentLabel` + three scripts) and that the loaded job is correct. Spelling consistency with `com.binle.co-doctor` is not a goal |
| **D4** | L1 router | Add `co-awake/` to the active-project list in `~/workspace_genai/AGENTS.md`. That directory is not a git repo, so this is a direct edit. It happens after the dev directory is really renamed, and is checked on its own (M13) |

**Derived decisions** (they follow from the above and add no capability)

| # | Decision | Reason |
|---|---|---|
| S1 | Product name `co-awake`, command name `awake` (split listed below). The launcher file in the repo is `awake`; there is no `co-awake` executable | One thing, one entry point (red line 9). Same shape as `co-jue` → `jue` |
| S2 | Binary `CoAwake`, source `CoAwake.swift`, build temp `CoAwake.new`, app class `CoAwakeApp` | The binary name is what the singleton guard and `ProcessProbe` match on |
| S3 | Install dir `~/.local/share/co-awake`, PATH link `~/.local/bin/awake` | R26 precedent |
| S4 | Detached log `/tmp/co-awake.log`; LaunchAgent log `/tmp/com.binle.coawake.log` | Follows the product name / label |
| S5 | `doctor.py`'s `STATE_DIR` (`~/.local/state/co-brain`) and the `doctor.log`, `.doctor-alert`, `.doctor.lock` paths do not change | Continuity means not moving them. The log format `%(asctime)s [%(levelname)s] %(message)s` has no logger name in it, so renaming does not affect grep |

How S1 splits the two names:

- **Product name `co-awake`:** repo, install dir, state directory, env prefix, Pages, menu / alert / accessibility labels, the first line of `--help`.
- **Command name `awake`:** launcher file, PATH link, every `awake: …` error prefix, usage lines.

---

## 3. Topology (before and after the rename)

```
  BEFORE                                         AFTER
  ------                                         -----
  ~/.local/bin/co-awareness  --+                 ~/.local/bin/awake  --+
  env-config/macos/bin/coa   --+                                       |
                               v                                       v
  ~/.local/share/co-awareness/co-awareness       ~/.local/share/co-awake/awake      (zsh launcher)
           |  pgrep "/CoAwareness( |$)"                   |  refuse CO_AWARENESS_*  (before anything)
           v                                              |  pgrep "/CoAwake( |$)"
  .../CoAwareness  <- CoAwareness.swift                   v
           |                                      .../CoAwake  <- CoAwake.swift
           v                                              |
  App Support/co-awareness/state.json                     v
     ^ (dir move, GUI boot only)                  App Support/co-awake/state.json   + intents/
  App Support/menubar-load-runner/                   ^ (state.json rename, RENAME_EXCL, GUI boot only,
                                                     |  skipped when STATE_FILE is overridden)
                                                  App Support/co-awareness/  else  menubar-load-runner/

  LaunchAgent ai.bera.coawareness                LaunchAgent com.binle.coawake

  env-config/macos/bin/brain-doctor              env-config/macos/bin/co-doctor   (+ doctor -> co-doctor)
  co-brain/skills/brain-doctor/scripts/doctor.py co-brain/skills/co-doctor/scripts/doctor.py
  LaunchAgent com.binle.brain-doctor             LaunchAgent com.binle.co-doctor
  ~/.local/state/co-brain/{doctor.log,.doctor-alert,.doctor.lock}   = unchanged
```

---

## 4. Migration inventory & contract changes

### 4.1 co-awake (this repo)

#### 4.1.1 Source, binary, and singleton

| Surface | Now | New | Notes |
|---|---|---|---|
| Source | `CoAwareness.swift` | `CoAwake.swift` | `git mv`, keeps blame |
| Binary / temp | `CoAwareness` / `CoAwareness.new` | `CoAwake` / `CoAwake.new` | Change both `.gitignore` lines. Keep listing them one by one; a `CoAwake*` wildcard would swallow the source |
| Launcher | `co-awareness` (`APP_CMD_NAME`) | `awake` | `git mv`. `swift_src` / `swift_bin`, the guard regex, and comments change with it |
| Singleton guard | `pgrep -U "$(id -u)" -f "/CoAwareness( \|$)"` | `"/CoAwake( \|$)"` | Still strictly before `compile_if_stale`. The `pkill` in `uninstall.sh` changes the same way |
| `AppInfo.name` / `repositoryURL` | `co-awareness` / `…/binlecode/co-awareness` | `co-awake` / `…/binlecode/co-awake` | `REPO` in `install.sh` changes the same way |
| `Restarter.launchAgentLabel` | `ai.bera.coawareness` | `com.binle.coawake` | Must equal `LABEL` in `install-login-item.sh`, `uninstall-login-item.sh`, and `uninstall.sh`. The code comment declares this as a cross-file invariant |
| `StateStore.directoryName` | `co-awareness` | `co-awake` | See § 4.1.3 |
| App class | `CoAwarenessApp` | `CoAwakeApp` | Internal symbol, not API |
| User-visible strings | Error prefixes, first line of `--help`, startup error alert, update alert, `setAccessibilityLabel` | Split into `awake` / `co-awake` per S1 | Only the name changes; sentences stay |
| `tests/menu-dump.applescript` | Finds the target process **by PID** | Only name strings change | Locating the target does not depend on the process name |

**Process-matching boundary.** These are stated so nobody over-reads them; this rename fixes none of them.

- **What the guard does not match.**
  - `/CoAwake( |$)` does not match the launcher path `…/co-awake/awake`: that path is all lowercase, and `pgrep` is case-sensitive.
  - It does not match `CoAwake.swift` open in an editor either: `.swift` follows the name, so `( |$)` fails.
- **The guard does not see the old binary.** `/CoAwake( |$)` does not match `CoAwareness`. In a new-plus-old setup the guard cannot stop the two from stacking. Phase 1.5 handles this by confirming the old process is gone (`pgrep` returns empty) before going on. The migration protocol has its own check for an old writer that is still alive (§ 4.1.3).
- **The existing cold-start race stays.** Two cold starts can pass `pgrep` at the same moment. That race predates this plan and the rename does not change it. Compiling to a temp file and `rename(2)`-ing it into place still ensures that concurrent builds never corrupt the binary.

**Name-collision check for the test binary (R26 lesson).**

- During R26, the first run of `tests/qa.sh` § 2b failed. The check build was called `tmp/check`, and the `status` probe matches the binary's own executable name as a case-insensitive substring, so `check` hit `TelemetryDiskChecker`.
- This time the check build is `tmp/awake-check`. Before any code changes, `grep -ci 'awake-check' CoAwareness.swift` must return 0.

#### 4.1.2 Environment variables and refusing the old prefix (D2)

**Mechanical replacement.** Every `CO_AWARENESS_<X>` becomes `CO_AWAKE_<X>` with `<X>` unchanged:

`PRESET LOAD_SOURCE DISPLAY KEEP_AWAKE KEEP_AWAKE_PID BATTERY_THRESHOLD UPDATE_CHECK LOG_FILE BIN_NAME FORWARD_ONLY LAUNCHER LAUNCH_MODE SHOW_ALL EXIT_AFTER FORCE_UNAVAILABLE FORCE_BATTERY FORCE_THERMAL STATE_FILE LOG_SLOTS LOG_ASSERTIONS LOG_AWAKE LOG_ANIMATION LOG_BATTERY_DIAGNOSTICS LOG_THERMAL`, plus the installer's `HOME` and `REPO_URL`.

`CO_AWAKE_KEEP_AWAKE` and `CO_AWAKE_LOG_AWAKE` read as repetitive. They still stay as they are: `<X>` is the feature name, the prefix is the product name, and changing `<X>` would change the API.

**Refusal rule (one rule, no exceptions).**

- A process is refused when its environment contains a `CO_AWARENESS_*` variable with a **non-empty** value. Empty counts as absent, which matches how the binary already reads env.
- Refused means: exit 1, stderr names each variable found and its replacement, and nothing else happens.
- The rule covers every verb, including `--help`, `status`, `snapshot`, `presets`, and `build`.

Physical reasons:

- `status` and `snapshot` read `STATE_FILE`. If a stale `CO_AWARENESS_STATE_FILE` were silently ignored, a query would read the real `state.json` instead of the test file. The caller would get a wrong answer that looks right.
- `--help` is the first thing a confused user runs. Refusing there surfaces the problem at the earliest point.

**Replacement map (single source).**

- The map lives only in the binary (it extends `Config.retiredEnvironment`). Each name `<X>` the binary reads maps to `CO_AWAKE_<X>`.
- Two current special cases stay: `PATH` → `CO_AWAKE_PRESET`, `LABEL` → `CO_AWAKE_DISPLAY`.
- An unknown `<X>` is reported as "no replacement; unset it". The binary never recommends a new variable that does not exist.

The shell entry points do not copy the map. Each one uses one of two forms:

- it delegates to the binary, which is the existing pattern: the launcher already hands retired spellings to the binary;
- or it prints the generic rule: "the prefix is now `CO_AWAKE_`; this script reads `CO_AWAKE_HOME` / `CO_AWAKE_REPO_URL`".

**Entry-point matrix.** "First side effect" is the boundary. A refusal must come before it.

| Entry point | First side effect it guards | Placement and form |
|---|---|---|
| `awake` launcher (every verb) | Detaching (once the background child is spawned, the caller always gets exit 0 + `started`, and the refusal ends up only in the log); `compile_if_stale`; the `pgrep` guard; forwarding | First statement of `main()`, before `resolve_script_path` dispatches. If the binary exists → `exec_binary "$@"` and the binary prints the mapped refusal. If no binary exists → print the generic rule and exit 1 (do not compile just to report an error) |
| `install.sh` | `git clone` / `pull`, `mkdir`, build, `ln` | Top of the script, before the `Darwin` check. Generic rule; exit 1 |
| `uninstall.sh` | `bootout`, `pkill`, `rm` of the link and install dir | Top of the script, before argument parsing. Generic rule; exit 1. Physical reason: a stale `CO_AWARENESS_HOME` that is ignored sends the uninstaller to the **default** directory |
| `scripts/install-login-item.sh`, `uninstall-login-item.sh` | `bootout` / `bootstrap`, writing the plist | Top of the script. Generic rule; exit 1. These also have side effects and the cost is one line, so they follow the same rule |
| Binary `CoAwake` (called directly, or under launchd) | GUI boot, forwarding, every query | Entry of `Config.parse()`, **before** `--help` handling and verb dispatch |

**Shell detection** (works in both `/bin/bash` 3.2 and zsh):

```sh
stale=$(env | sed -n 's/^\(CO_AWARENESS_[A-Za-z0-9_]*\)=..*$/\1/p')
```

The `..*` after `=` requires a non-empty value. A multi-line env value could produce a false match; that cost is accepted, because a false match only means one extra refusal and never a silent side effect.

**When this refusal can retire** (same precondition as § 11.2 *Retiring a spelling*): the old prefix no longer appears in the environment of any known install, or in any argv or environment launchd has loaded.

#### 4.1.3 State directory and the chain migration protocol

**Three facts in the current code that make the old protocol unsafe** (grounded):

1. **It ignores the override.** `StateStore.fileURL` honors the `STATE_FILE` override, but `migrateLegacyDirectoryIfNeeded` never looks at it. A test binary that redirects the state file still moves the real directory.
2. **A forward creates the target directory first.** `IntentForwarder.send` → `spoolIntent` runs `createDirectory(withIntermediateDirectories:)`, which creates `<state dir>/intents/`. The first launch of the new version can race like this:
   ```
   GUI process A starts (has not reached applicationDidFinishLaunching yet)
     -> a second `awake start --display value` sees A, forwards, creates co-awake/intents/
     -> A runs the migration: "co-awake exists" -> skips
     -> the old settings are never moved; A boots on defaults
   ```
   `rename(2)` makes only the move itself atomic. It does not make the whole "check target is absent → pick a source → create the target" sequence atomic.
3. **Directory existence is the wrong test.** Whether the directory exists is not the same as whether migration has happened. Only the presence of `state.json` means the new version holds settings.

**New protocol** (`migrateLegacyDirectoryIfNeeded`; still called only on the GUI boot path, as the first line of `applicationDidFinishLaunching`):

```
0. If STATE_FILE override is non-empty: return.
     Tests never touch the host's real directory.
1. current = App Support/co-awake
   If current has any entry other than `intents/` (state.json first among them): return.
     That means already migrated, or the new version has written state.
     So "absent", "empty", and "only intents/" all fall through to migration.
2. For legacy in [co-awareness, menubar-load-runner]   (newest name first):
     If legacy/state.json is missing: try the next one.
     If the old writer of that generation is alive (process named CoAwareness): return.
       This boot does not migrate; the next GUI boot retries.
     mkdir -p current
     renamex_np(legacy/state.json, current/state.json, RENAME_EXCL)
       Atomic within one volume. If the target already exists: EEXIST, return silently.
     On success: delete legacy/intents/ (all stale: sentAt is earlier than the new process's start),
       then rmdir(legacy). That only succeeds when the directory is empty; unknown entries are left alone.
     return   (only the first match moves; legacy directories are never merged)
3. Every failure is silent (§ 8.2 fail-silent).
```

**Why this is race-free.** The serialization boundary is that `state.json` has a single kind of writer.

- **Forwarders never create `state.json`.** They only write `intents/<stamp>-<pid>.json`: first under a dot-name, then renamed into place. So a spool cannot change the "has it migrated?" answer. That answer depends only on whether `current` contains entries other than `intents/`.
- **Migration comes first in its own process.** It runs on the main thread, before that process does any `StateStore.load()` / `persistState()`. Nothing else in the same process can write `state.json` ahead of it.
- **Two GUI instances started together (`--extra`) cannot both win.** `RENAME_EXCL` is the kernel-level exclusive point: exactly one `renamex_np` succeeds and the other gets `EEXIST`. There is no window where one overwrites the other.
- **An intent that is already spooled is not lost.** The migration leaves `current/intents/` alone. The drain picks it up as usual after boot, and the `sentAt` vs process-start check (`StateStore.intent(_:isFor:)`) still applies.

**Policy and boundaries.**

- **The current directory wins; nothing is merged.** If the new version has already written state, no old directory is read again.
- **When two legacy directories both have `state.json`, only the newer name moves.** The other one stays where it is and is not deleted. Merging JSON would mean deciding conflicts on the user's behalf, and `state.json` is only convenience data. The plan makes no claim about why two legacy directories exist together; it only defines what happens when they do.
- **Old-writer check.** A `CoAwareness` process that is still alive holds settings in memory and writes them back with `persistState()` when it exits. Migrating while it runs would let it re-create the old directory, and any setting changed in the old instance after the migration would be lost. So migration is deferred until that writer is gone.
  - Only the `CoAwareness` generation is checked. The `menubar-load-runner` generation's binary has been retired since R26.
  - During implementation, verify that `ProcessProbe`'s matching rules (process name, case sensitivity, substring or not) do not mistake `CoAwake` or an editor process for the old writer.
- **Old names appear in one place only.** The two old directory names and the old binary name all live inside this one function.
- **`status` stays read-only** (§ 8.3), and `snapshot` never touches `state.json`.

**Compile check.** `renamex_np` / `RENAME_EXCL` come from Darwin. Before writing the code, confirm that a zero-warning `swiftc -strict-concurrency=complete` build can call them directly.

#### 4.1.4 LaunchAgent

| Item | Now | New |
|---|---|---|
| Label / plist | `ai.bera.coawareness` | `com.binle.coawake` (D3) |
| ProgramArguments[0] | `~/.local/share/co-awareness/co-awareness` | `~/.local/share/co-awake/awake` |
| Log | `/tmp/ai.bera.coawareness.log` | `/tmp/com.binle.coawake.log` |
| KeepAlive | Not set (on purpose: choosing Exit from the menu means it stays quit until the next login) | Same |

The new `install-login-item.sh` does not clean up the old label. If the old label appears in a new script, that is compatibility code. The old job is cleaned up by one of the two procedures in § 4.1.7.

#### 4.1.5 Test gates and QA isolation

**Isolation (P1.1).** In the current `tests/qa.sh`, several GUI launches do not set `STATE_FILE`, including:

- trace slots (§ 3c);
- animation freezing (§ 3g);
- battery diagnostics (§ 3h);
- thermal (§ 3i);
- live instance (§ 3j / § 3k);
- error paths (§ 4);
- the reader readouts (§ 5);
- the launcher's `--foreground` (§ 6).

After the prefix rename, a GUI run of the new binary on this machine would hit the real directory while the old instance is still running, and kick off the migration early. That would ruin the precondition for the Phase 1.5 switch.

Changes:

| # | Change |
|---|---|
| Q1 | Near the top of `qa.sh`, right after `BIN=`, add `export CO_AWAKE_STATE_FILE="$PWD/tmp/qa-default-state/state.json"` and clear that directory. Every launch inherits it by default, including the GUI tier and the launcher tier (`./awake` passes the environment to its child). Sections that already set their own `STATE_FILE` keep it; a local value overrides the exported one |
| Q2 | **Host-state sentinel.** Before the first section and after the last, record a fingerprint of the host's real `App Support/{co-awake,co-awareness,menubar-load-runner}`: whether each exists, plus `stat -f '%m %z'` of `state.json` and the `intents/` entry list. If they differ, FAIL ("qa touched the real state directory"). This asserts a real side effect; it is not a hook |
| Q3 | The rule also applies to manual runs in Phase 1. Any hand-run of `./awake` or `tmp/awake-check` during development must set `CO_AWAKE_STATE_FILE=tmp/…`, until Phase 1.5 has stopped the old writer |

**Changes to the test files themselves.**

| File | Change |
|---|---|
| `tests/qa.sh` | `BIN=./tmp/awake-check`. Every `CO_AWARENESS_*` → `CO_AWAKE_*`. The version line greps for `co-awake $VER`. `./co-awareness` → `./awake`, `./CoAwareness` → `./CoAwake`. The needle in § 3k `count()` becomes `awake-check`, and the process match in § 6 changes the same way |
| `tests/qa.sh` § 2 (refusal, core) | Replace the two `rt` lines with these D2 assertions, all core tier with no GUI needed: **(1)** `env CO_AWARENESS_DISPLAY=value $BIN` → rc=1, stderr has `CO_AWAKE_DISPLAY`; **(2)** `CO_AWARENESS_PATH` → stderr has `CO_AWAKE_PRESET`; **(3)** `CO_AWARENESS_BOGUS=1 $BIN status` → rc=1 and no made-up replacement name; **(4)** `CO_AWARENESS_X=1 $BIN --help` → rc=1; **(5)** launcher with no instance: `env CO_AWARENESS_DISPLAY=value ./awake` → rc=1, stdout has no `started`, and no new `CoAwake` process appears; **(6)** `env CO_AWARENESS_X=1 ./awake build` → rc=1 and the binary's mtime does not change; **(7)** `CO_AWARENESS_DISPLAY=` (empty) does not trigger a refusal |
| `tests/qa.sh` § 3k (with an instance) | Add: with a live instance, `env CO_AWARENESS_DISPLAY=value ./awake` → rc=1, no new file in `intents/`, and the instance's display stays as it was |
| `tests/install-smoke.sh` | Use `CO_AWAKE_HOME` / `CO_AWAKE_REPO_URL`, and assert the `bin/awake` link and the `share/co-awake/CoAwake` binary. Add: `CO_AWARENESS_HOME=… bash install.sh` → rc=1 and the target directory is not created; `CO_AWARENESS_HOME=… bash uninstall.sh --yes` → rc=1 and the planted fake install dir and link are still there |
| `tests/hold-assertion.swift`, `tests/menu-dump.applescript` | Name strings only |

**Migration matrix (P2).** These cases need a real App Support location that is **not** this user's.

- Under the new protocol, `STATE_FILE` disables migration, so `qa.sh` cannot test it with that knob.
- **No business-logic hook may be added for this.** Only these two environments count:
  - **(i) Temporary `HOME`.** Use this if the Phase 0 probe shows that, unsandboxed, `FileManager.url(for: .applicationSupportDirectory)` follows `HOME`. (*Untested.* The probe was not run while this plan was drafted.) In that case the matrix becomes a new GUI-tier section in `qa.sh`, and Q2's sentinel also proves the real directory was not touched.
  - **(ii) A throwaway standard macOS user account,** running the same script by hand. Use this if the probe shows `HOME` is not followed.

| # | Setup (under the isolated App Support) | Expected after one GUI boot (`CO_AWAKE_EXIT_AFTER=2`) |
|---|---|---|
| X1 | Only `co-awareness/state.json` | `co-awake/state.json` has the same content; `co-awareness/` is gone |
| X2 | Only `menubar-load-runner/state.json` | Same as above; the source is `menubar-load-runner` |
| X3 | Both legacy directories exist | Only `co-awareness` moves; `menubar-load-runner/` stays untouched |
| X4 | `co-awake/state.json` already exists, and a legacy directory also exists | Nothing moves; all three directories are byte-for-byte unchanged |
| X5 | `co-awake/` contains only `intents/<stale>.json`, plus `co-awareness/state.json` | Migration happens, and `intents/` is kept. **This is the race in fact 2 above, set up directly** |
| X6 | X5 plus a live race: start the GUI and fire a second `start --display value` 50 ms later | The settings were migrated, and the boot ends with display=value (the forward was not lost). Repeat 20 times; all must pass |
| X7 | X1 with a non-empty `CO_AWAKE_STATE_FILE` set | Nothing moves |
| X8 | X1, with an old v2.4.2 `CoAwareness` process alive (under its own `STATE_FILE`, so it does not write the isolated directory) | Nothing moves; after the old process exits, the next boot migrates |
| X9 | Make `co-awake/` unwritable (`chmod 500`) | Boot succeeds on defaults; the legacy directory is intact (fail-silent) |

#### 4.1.6 Other assets

| Asset | Change |
|---|---|
| `README.md` (~71 hits), `AGENTS.md` (~27), `docs/ARCHITECTURE.md` (~53) | Full rename. In ARCH § 8.2, rewrite the migration entry as the § 4.1.3 protocol: why `state.json` presence is the test, and the single-writer argument. In § 11.3, swap the env table prefix and add the refusal rule from § 4.1.2. Update the label in § 11.2 *Retiring a spelling*. README upgrade notes link to the CHANGELOG `[3.0.0]` section and do not repeat the procedure |
| `CHANGELOG.md` | Rename in the *Public API* section at the top. New `[3.0.0]` with Breaking (env prefix, command name, label, install path, refusal rule) and **Upgrade** containing the two procedures from § 4.1.7. These two procedures are the only place in the repo where the old paths and old label may appear as current text. Older entries stay unchanged |
| `docs/cover.html`, `docs/media/hero.svg` | Name, command examples, badge v3.0.0, upgrade link |
| `.agents/skills/publish-cover/` (`SKILL.md` + `build-cover-dist.sh`) | `--project-name=co-awake` and the live URL. How the old site is handled follows the Pages decision in § 4.3 |
| `.agents/skills/build-visuals/SKILL.md` | Name |
| `.github/ISSUE_TEMPLATE/*`, `LICENSE.md` | Name / repo URL |
| `gifs/presets.json` | No hits; untouched |
| `docs/RESEARCH-peer-survey.md` | Change the one self-reference; leave the other external facts |
| `docs/ROADMAP.md` | R31 comes out once this lands |

#### 4.1.7 Self-update across the rename (D1 = a): mechanism and two procedures

**How a mistaken update fails** (derived from the code; Phase 1.5 reproduces it for real). Clicking Update on v2.4.x does this, in order:

1. `git pull --ff-only` succeeds. **The checkout now holds v3 content**: `awake`, `CoAwake.swift`, and the v3 `uninstall.sh`, which knows only the new label, the new binary, and the new default path.
2. `Builder.precompile` runs `…/co-awareness build`. That file no longer exists, so it fails.
3. The success dialog still offers Restart:
   - in detached mode it re-runs the same missing path;
   - in LaunchAgent mode `kickstart` replays the **loaded old argv** launchd already holds, which also points at the missing file.

The process exits and does not come back. `state.json` is unharmed: the old process writes back to `co-awareness/` on exit, and the new install migrates it.

**Consequence:** after a mistaken update, `~/.local/share/co-awareness/uninstall.sh` has been replaced by the v3 version. It can no longer clean up the old identity. **Recovery must not rely on any script in that checkout.**

**Procedure A: before updating (proactive).** The old uninstaller is still the old version, so it can be used.

```bash
~/.local/share/co-awareness/uninstall.sh --yes     # Old script: bootout ai.bera.coawareness, kill the instance, remove the link and install dir; App Support untouched
until ! pgrep -U "$(id -u)" -f '/CoAwareness( |$)' >/dev/null; do sleep 0.5; done
curl -fsSL https://raw.githubusercontent.com/binlecode/co-awake/main/install.sh | bash
```

**Procedure B: after a mistaken update (hard cleanup that touches no local script).** It is idempotent and safe to run more than once.

```bash
u=$(id -u); old=ai.bera.coawareness; dir="$HOME/.local/share/co-awareness"; \
launchctl bootout "gui/$u/$old" 2>/dev/null; \
while launchctl print "gui/$u/$old" >/dev/null 2>&1; do sleep 0.5; done; \
rm -f "$HOME/Library/LaunchAgents/$old.plist" "/tmp/$old.log"; \
pkill -U "$u" -f '/CoAwareness( |$)'; \
while pgrep -U "$u" -f '/CoAwareness( |$)' >/dev/null; do sleep 0.5; done; \
l="$HOME/.local/bin/co-awareness"; [ -L "$l" ] && case "$(readlink "$l")" in "$dir"/*) rm -f "$l";; esac; \
git -C "$dir" remote get-url origin 2>/dev/null | grep -Eq 'binlecode/co-awa(re|ke)' && rm -rf "$dir"; \
echo "old identity cleared; now install co-awake"
```

Then run the last line of Procedure A to install. Each line:

- `bootout` is asynchronous, so the loop polls until `print` fails. Only then is the plist removed, which keeps launchd from re-registering it.
- `pkill` uses the old binary's path anchor. The new `CoAwake` cannot match it.
- The link is removed only if it points into the old install dir; anything else is left alone.
- The install dir is removed only after confirming it is our git checkout (origin is the old name or the redirected new name). It holds no user data; settings live in App Support.
- Users who customized `CO_AWARENESS_HOME` or `BIN_DIR` must swap in their paths. The CHANGELOG says so explicitly.

---

### 4.2 co-doctor (co-brain + env-config)

| Surface | Now | New | Repo |
|---|---|---|---|
| Skill directory | `skills/brain-doctor/` | `skills/co-doctor/` (`git mv`; delete `__pycache__` rather than carrying it) | co-brain |
| SKILL.md | `name: brain-doctor`, description, H1, trigger table, usage | `name: co-doctor`. Positioning: "infrastructure doctor for the whole co ecosystem: deterministic checks + whitelisted self-repair". Trigger-table label and CLI name. `Invoke as /co-doctor` | co-brain |
| `doctor.py` | docstring, `getLogger("brain-doctor")`, "Another brain-doctor instance…", "Run 'brain-doctor --treat'…", CRASH text | All `co-doctor`. Path constants such as `STATE_DIR` **do not change** (S5) | co-brain |
| CLI wrapper | `macos/bin/brain-doctor` | `macos/bin/co-doctor`: `DOCTOR_PY` and its fallback path point to `skills/co-doctor/…`; error prefix `co-doctor:` | env-config |
| Second entry point | — | `macos/bin/doctor -> co-doctor` (relative link; `~/bin` itself points at `env-config/macos/bin`) | env-config |
| Old wrapper | `macos/bin/brain-doctor` | `git rm`, no alias | env-config |
| plist | `com.binle.brain-doctor.plist` | `com.binle.co-doctor.plist`: `Label` changes; the last `ProgramArguments` item becomes `$HOME/bin/co-doctor -q --treat`; `StartInterval 7200`, `RunAtLoad`, `LowPriorityIO`, and the log paths stay as they are | env-config |
| Setup scripts | `link_file` in `01-activate-environment.sh`, `check_link` in `05-validate-setup.sh` | Point to the new plist | env-config |
| Skill mount | `.agents/skills/brain-doctor -> co-brain/skills/brain-doctor` | `.agents/skills/co-doctor -> …/co-doctor`; delete the old link. `~/.claude/skills` and `~/.agents/skills` both point at this directory, so every client picks it up at once | env-config |
| L0 router | `.agents/AGENTS.md` (that is `~/.claude/CLAUDE.md`), two lines; `.agents/skills/README.md` | `/co-doctor` | env-config |
| co-brain docs | `AGENTS.md`, `README.md`, `docs/ARCHITECTURE.md`, `docs/ARCH-user-space-indexing.md`, `skills/brain-storm/SKILL.md`, `docs/diagrams/tri-memory-topology.svg` | `co-doctor`; add a stage line to `CHANGELOG.md` | co-brain |
| `co-awareness` mentions in co-brain | Ecosystem member list in `AGENTS.md` / `README.md`, an example in `skills/brain-research/SKILL.md`, gold paths in `engine/eval_brain_index.py` | `co-awake` | co-brain |
| Unchanged | `docs/RESEARCH-*.md`, existing `CHANGELOG.md` lines, path examples inside code blocks that record history | — | co-brain |

**What "keeping `brain-*` cognitive-only" means in practice.** From now on the `brain-*` prefix means cognitive skills only. In `brain-storm`, "use `/brain-doctor` for health checks" becomes `/co-doctor`. The contents of the three cognitive skills are not rewritten.

**Incident-ledger continuity (P2, narrowed).**

- The `.doctor-alert` incident id has no program name in it, but it **does include the `target` path**. Renaming the skill directory can therefore change the identity of incidents whose target sits under the old path.
- Keeping the path unchanged guarantees only that **the ledger file continues**. It does not guarantee every unresolved incident keeps its identity.
- So "`.doctor-alert` is empty" is a hard precondition for this machine's switch (Phase 0), not a nice-to-have.

**Cross-repo commit discipline (P2).**

- co-brain has unrelated uncommitted changes in `brain-reflection` and `jue`; env-config has others too.
- **Commits contain only the paths this plan touches.** Use `git add <explicit paths>` / `git commit -- <paths>`. No `git add -A`, no blanket `reset`, no whole-repo `revert`.
- env-config's project rules require approval before committing, so every env-config commit waits for the owner's go-ahead.
- Rollback only `git revert <sha>`s the specific commits from this plan.

---

### 4.3 External state on this machine

| Object | Handling |
|---|---|
| Dev directory `~/workspace_genai/co-awareness` | Once the switch is done and no process runs from it, `mv` it to `co-awake` |
| Claude project memory `~/.claude/projects/-Users-binle-workspace-genai-co-awareness/` | Keyed by path, so after the rename the project would start with fresh, empty memory. `mv` it to `…-co-awake/` and update old paths in the memory text |
| `env-config/macos/bin/coa` | `git rm` (it points at the dev directory's old launcher and would dangle after the rename anyway). Separate commit |
| L1 router (D4) | Edit `~/workspace_genai/AGENTS.md` directly (not a git repo): add a `co-awake/` line to the active-project list, in the same format as `co-jue/` |
| GitHub repo | `binlecode/co-awareness` → `binlecode/co-awake`. Both git and the API redirect. On the old name, v2.4.x's `UpdateChecker` `ls-remote` and `git pull` depend on that redirect. **Never create a new repo named `co-awareness` again**: doing so breaks the redirect for good. Locally, `git remote set-url` |
| Cloudflare Pages | Create a `co-awake` project and deploy. First confirm `co-awake.pages.dev` is free; pages.dev is one global namespace. **[owner]** Choose how the old site goes: (a) **recommended**: keep the `co-awareness` project and deploy only a `_redirects` file containing `/* https://co-awake.pages.dev/:splat 301`, so old links keep working (this is a web redirect, a different boundary from a CLI alias); or (b) delete it and accept the broken links |

---

## 5. Execution steps & rollback

**Commit discipline.**

- One feature per commit. The version number rides alone in the release commit.
- Every outward-facing action waits for the owner's go-ahead, one at a time: `git push`, the GitHub rename, Pages create / redirect / delete, and env-config commits.

**This is a planned-downtime handover, not a seamless one.** Two windows exist in Phase 1.5:

- **The menu-bar icon is gone** between stopping the old instance and the first boot of the new one.
- **The Keep Awake assertion is released.** When the old process exits, the `caffeinate -w` child it is bound to exits too. A **timed** window comes back with `state.json` when the new instance starts. An **indefinite** window is not restored, by design (§ 7).

So do the switch while the owner is at the machine and on AC power, and not while depending on Keep Awake.

### Phase 0 — Preflight audit and gates

1. **Baseline.** On the current HEAD, `tests/qa.sh --core` and the full `tests/qa.sh` run in the foreground both pass. The GUI tier must run in the foreground.
2. **Name availability.**
   - `command -v awake doctor co-doctor` returns nothing.
   - `brew search awake` shows no same-named CLI that would install into `/opt/homebrew/bin`.
   - `co-awake.pages.dev` is free.
   - `binlecode/co-awake` does not exist.
3. **Collision needle.** `grep -ci 'awake-check' CoAwareness.swift` = 0.
4. **Isolation probe (decides how the migration matrix runs).**
   - Compile a three-line Swift program into `tmp/` that prints `FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, …)`.
   - Run it twice: once normally, once under `HOME=$PWD/tmp/fakehome`.
   - Different output → § 4.1.5 path (i), automated. Same output → path (ii), a throwaway user account.
   - Write the result into the PLAN as the measured value.
5. **Record the current state (basis for rollback).**
   - `launchctl print gui/$(id -u)/ai.bera.coawareness`: take the **loaded** argv, not the plist file.
   - Back up the state directory: `cp -Rp "$HOME/Library/Application Support/co-awareness" tmp/backup-appsupport-co-awareness`.
   - Record the `com.binle.brain-doctor` state and `wc -l ~/.local/state/co-brain/doctor.log`.
   - Confirm `~/.local/state/co-brain/.doctor-alert` is **empty** (hard precondition; § 4.2 ledger continuity).
6. **Snapshot the dirty trees.** Run `git status --short` in co-brain, env-config, and this repo, and save each to `tmp/`. Commits in Phase 2 / 3 must not touch any path listed there.

### Phase 1 — co-awake code and tests (dev directory still at the old path)

> In this phase the old v2.4.2 instance keeps running and keeps writing `App Support/co-awareness/`. **Every run of the new binary must have `CO_AWAKE_STATE_FILE` set** (Q1 / Q3), and nothing may touch the real directory.

1. `git mv` the source and launcher, and apply all replacements from § 4.1. Then `swiftc -O -strict-concurrency=complete CoAwake.swift -o tmp/awake-check` with zero warnings.
2. Implement the D2 entry-point refusals (§ 4.1.2), the new migration protocol (§ 4.1.3), and QA isolation Q1 / Q2 (§ 4.1.5).
3. Run `tests/qa.sh --core` → `tests/qa.sh` in the foreground → `tests/qa.sh --launcher`. All must pass, and the Q2 sentinel must report the host state unchanged.
4. Run the migration matrix X1–X9 by the path Phase 0 step 4 chose. All must pass.
5. Leftover scan: `git grep -n -i -E 'co-awareness|coawareness|CO_AWARENESS|CoAwareness|ai\.bera'`. Allowed hits only:
   - the old directory names and old binary name inside `migrateLegacyDirectoryIfNeeded`;
   - the D2 map and the refusal detection in the shell entry points;
   - the Upgrade section of `CHANGELOG.md` `[3.0.0]`, and older history entries;
   - the positions § 4.1.6 lists as unchanged.
6. Commit `feat: rename to co-awake (R31)`. Then run `tests/install-smoke.sh`: it clones the committed HEAD, so it must run after the commit. It must pass.
7. Doc distillation: update ARCH, `git rm` this PLAN, and remove R31 from ROADMAP. Do this in the same commit or the one right after.
8. Commit `release: v3.0.0`. All five version surfaces move together (`AppInfo.version`, CHANGELOG, README, cover badge, tag). Then re-run `tests/qa.sh --core`.

### Phase 1.5 — Release and switch this machine (owner approves each step)

1. **[owner]** Rename the repo on GitHub. Locally run `git remote set-url origin git@github.com-binlecode:binlecode/co-awake.git`.
2. **[owner]** `git push origin main v3.0.0`. Then use the `ls-remote` from § 13 step 6 to confirm the tag is live. Also check from the old name: `git ls-remote https://github.com/binlecode/co-awareness.git v3.0.0` reaches it through the redirect.
3. **Switch this machine, and reproduce D1 for real at the same time.** The order is a constraint.
   1. Click **Check for Updates → Update** in the menu of the running v2.4.2 instance. This is the D1 mistaken-update path, triggered on purpose.
   2. Click Restart. **Expected:** the icon does not come back; `launchctl print gui/$(id -u)/ai.bera.coawareness` is still loaded, with argv pointing at the missing file; `~/.local/share/co-awareness` now holds v3 files. Record what actually happens, as evidence for D1.
   3. Run Procedure B from § 4.1.7 (the hard cleanup that touches no local script). Then confirm: the old label is gone, no `/CoAwareness( |$)` process remains, `~/.local/bin/co-awareness` is gone, the old install dir is gone, and `App Support/co-awareness/state.json` is still there.
   4. Install:
      ```bash
      curl -fsSL https://raw.githubusercontent.com/binlecode/co-awake/main/install.sh | bash
      ~/.local/share/co-awake/scripts/install-login-item.sh --preset horse-white --load-source cpu --display trace --battery-threshold 15
      #  The arguments come from the loaded argv recorded in Phase 0.
      ```
      The first GUI boot runs the migration.
   - **If the owner does not want to take this path,** use Procedure A instead. Then D1 counts as "derived from code, not reproduced", and the acceptance section must say so.
4. The dev directory is `mv`'d to `co-awake`, and the Claude project memory directory is `mv`'d with it. In env-config, `git rm macos/bin/coa` (separate commit, waits for approval). Make the D4 edit to `~/workspace_genai/AGENTS.md`.
5. **[owner]** Pages: `wrangler pages project create co-awake …` → deploy with `publish-cover` → check the badge → handle the old site as decided in § 4.3.

**Rollback (within Phase 1.5)**

- **Before the tag is pushed:** in this repo, `git reset` back to v2.4.2. This machine has not been switched yet.
- **After the tag is pushed:** the tag is not re-cut (§ 13). Fix forward and release v3.0.1.
- **Must return to v2.4.2.** `install.sh` cannot pin a version: on a fresh install it clones the default branch, and on an existing checkout it pulls the current branch. Downloading an old script is not the same as installing old source. So every step is written out by hand:

  ```bash
  u=$(id -u); AS="$HOME/Library/Application Support"
  # 1. Stop and remove the v3 install (it was installed by v3 itself, so its own uninstaller still matches)
  ~/.local/share/co-awake/uninstall.sh --yes
  while launchctl print "gui/$u/com.binle.coawake" >/dev/null 2>&1; do sleep 0.5; done
  while pgrep -U "$u" -f '/CoAwake( |$)' >/dev/null; do sleep 0.5; done
  # 2. Confirm neither generation's writer is alive and the target does not exist, so mv cannot nest one directory inside another
  ! pgrep -U "$u" -f '/CoAwa(ke|reness)( |$)' && [ ! -e "$AS/co-awareness" ] && [ -d "$AS/co-awake" ] \
    && mv "$AS/co-awake" "$AS/co-awareness"
  # 3. Fetch a pinned v2.4.2 checkout; v2.4.2's migration only recognizes menubar-load-runner and never moves anything backwards
  git clone https://github.com/binlecode/co-awake.git "$HOME/.local/share/co-awareness"
  git -C "$HOME/.local/share/co-awareness" checkout --detach v2.4.2
  # 4. Build with the v2.4.2 launcher (temp + atomic rename -> CoAwareness), then link
  "$HOME/.local/share/co-awareness/co-awareness" build
  test -x "$HOME/.local/share/co-awareness/CoAwareness"
  mkdir -p "$HOME/.local/bin" && ln -sfn "$HOME/.local/share/co-awareness/co-awareness" "$HOME/.local/bin/co-awareness"
  # 5. Reinstall the login item with the argv recorded in Phase 0
  "$HOME/.local/share/co-awareness/scripts/install-login-item.sh" --preset horse-white --load-source cpu --display trace --battery-threshold 15
  ```

  Notes:
  - Leftover `intents/` from v3 move along with the directory. They are harmless: `sentAt` is earlier than the new process's start, so they are discarded.
  - The v3 rename did not change the `state.json` schema, so v2.4.2 reads it directly.
  - A detached-HEAD checkout makes `git pull` fail. **Do not click Update in the rolled-back v2.4.2.** It would find v3.0.0 again and go back down the D1 path.
  - **Rehearse once in Phase 1:** with `CO_AWARENESS_HOME` / `BIN_DIR` pointed into `tmp/` and an isolated `STATE_FILE`, run steps 3–4, and confirm `CoAwareness --help` prints `co-awareness 2.4.2`.
  - Last-resort fallback: the `tmp/backup-appsupport-co-awareness` copy from Phase 0.

### Phase 2 — co-doctor cross-repo handover

**Why this order.** The old job fires every 7200 s, and at login through `RunAtLoad`; its command is `$HOME/bin/brain-doctor`. If the files went first and the job was unloaded later, there would be a window where launchd tries to run a path that no longer exists. That only writes `launchd.err`; it never heals itself. So: **unload the job first, then move the files, then install the new job.**

**Handling an in-flight run (P2).** `bootout` sends SIGTERM to a job that is running; it does not wait for a Treat to finish. `doctor.py` has no SIGTERM exit protocol, and the shared `flock` only prevents concurrent writes. It cannot guarantee that a Treat that was killed partway through has finished. Hence a stop window and a confirmation step:

```bash
u=$(id -u)
# 0. Stop window: make sure no doctor run is in progress, then bootout immediately
while pgrep -U "$u" -f 'skills/brain-doctor/scripts/doctor.py' >/dev/null; do sleep 2; done
launchctl bootout "gui/$u/com.binle.brain-doctor"
while launchctl print "gui/$u/com.binle.brain-doctor" >/dev/null 2>&1; do sleep 0.5; done
# 1. Confirm after unloading: no process, and the lock is free
! pgrep -U "$u" -f 'doctor.py'
python3 -c 'import fcntl,os;f=open(os.path.expanduser("~/.local/state/co-brain/.doctor.lock"),"a");fcntl.flock(f,fcntl.LOCK_EX|fcntl.LOCK_NB);print("lock free")'
tail -2 ~/.local/state/co-brain/doctor.log     # The last entry must be a complete [SCAN] / [RESULT], not cut off in the middle
# 2. co-brain: git mv skills/brain-doctor skills/co-doctor; update SKILL.md / doctor.py / docs -> commit only these paths
# 3. env-config: new co-doctor wrapper + doctor link + new plist + setup scripts + skills link + L0 text;
#    git rm the old wrapper and old plist -> commit only these paths (after owner approval)
rm ~/Library/LaunchAgents/com.binle.brain-doctor.plist             # 4. Old symlink (its target is gone)
ln -s ~/env-config/macos/Library/LaunchAgents/com.binle.co-doctor.plist ~/Library/LaunchAgents/
launchctl bootstrap "gui/$u" ~/Library/LaunchAgents/com.binle.co-doctor.plist   # 5. RunAtLoad runs once immediately
```

- **If step 1's `tail` shows the last run was cut off** (a `[SCAN]` with no `[RESULT]` after it, or a `[TREAT]` that never finished): after the new job is installed, run `co-doctor` by hand once (scan only, no treat), read its `[SCAN]` / `[RESULT]`, and then decide whether to `--treat`.
- **Lock contention.** If old and new runs ever overlap, the one that arrives second prints "Another … instance is active" and exits. That exit **does not count as a successful check** (see A7).
- **Continuity.**
  - The new job keeps appending to `doctor.log`, which rotates at 1 MB × 3.
  - `.doctor-alert` was empty before the switch (Phase 0), so there are no unresolved incidents whose identity could break.
  - The `.zshrc` prompt hook reads a path that does not change, so it needs no edit.
- **Rollback.** `bootout` the new label → `git revert <sha>` of only this plan's commits in both repos → restore the old symlink → `bootstrap` the old plist. The state directory never moved, so no data needs restoring.

### Phase 3 — Cross-ecosystem self-repair and acceptance

1. **Leftover gates across repos** (this replaces using `cite-verify` as proof of path integrity; on 2026-10-11 the review measured that `cite-verify check co-brain/docs` returned **10 docs, 0 citations**, so it cannot prove anything here):
   - `git -C ~/co-brain grep -n -E 'brain-doctor'`: allowed hits are only `docs/RESEARCH-*.md`, existing `CHANGELOG.md` lines, and historical path examples inside code blocks.
   - `git -C ~/env-config grep -n -E 'brain-doctor|co-awareness|coawareness|\bcoa\b'`: zero hits.
   - `git -C ~/co-brain grep -n 'co-awareness'`: allowed hits are only RESEARCH and CHANGELOG history.
2. Run `co-doctor --treat`. The brain-index entries reported moved/missing because of the dev-directory rename are healed by `update_brain_index`.
3. `brain-index status` shows the same document count as before the rename (differences from docs added or removed by this plan are allowed). The gold set in `eval_brain_index.py` now points at `co-awake/…`, and the eval passes.
4. Run the co-library's own search for leftover `co-awareness` and `brain-doctor` references. List them for the owner; change nothing.

---

## 6. Parameter & name reference (merged into ARCH § 11 once landed)

| Name | Default / value | Purpose | Lives in |
|---|---|---|---|
| Command | `awake` | The only CLI entry point | Launcher in the repo + `~/.local/bin/awake` |
| Binary | `CoAwake` | What the singleton guard and process probe match on | Output of the launcher's `compile_if_stale` |
| Env prefix | `CO_AWAKE_` | All settings and QA / observability hooks | Binary, launcher, installers |
| Old prefix | `CO_AWARENESS_` (non-empty value) | Present → exit 1 with the replacement name, before the first side effect. Covers every verb, including `--help` / `build` | Binary (holds the map) + launcher / `install.sh` / `uninstall.sh` / `*-login-item.sh` (generic rule) |
| State directory | `~/Library/Application Support/co-awake/` | `state.json` + `intents/` | `StateStore` |
| Migration trigger | Target absent, or target holds only `intents/`; no `STATE_FILE` override; old writer not alive | Moves legacy `state.json` once (`RENAME_EXCL`) | `StateStore.migrateLegacyDirectoryIfNeeded` (GUI boot only) |
| Migration sources (in order) | `co-awareness/`, `menubar-load-runner/` | Only the first one holding `state.json` moves; no merging | Same as above |
| LaunchAgent | `com.binle.coawake` | Login start. `Restarter` uses it to tell whether it is the agent process | Binary + three scripts; all four must agree |
| Install dir | `~/.local/share/co-awake` (`CO_AWAKE_HOME`) | Source checkout | `install.sh` / `uninstall.sh` |
| Detached log | `/tmp/co-awake.log` (`CO_AWAKE_LOG_FILE`) | Background output | Launcher |
| QA default state file | `tmp/qa-default-state/state.json` | Exported by default in `qa.sh`, so tests never touch the real directory | `tests/qa.sh` |
| Version | `3.0.0` | MAJOR: env prefix, command name, label, install path, old-prefix refusal | Five version surfaces |
| co-doctor commands | `co-doctor`, `doctor` | Check / `--treat` repair | `env-config/macos/bin` |
| co-doctor job | `com.binle.co-doctor`, 7200 s + RunAtLoad, `-q --treat` | Quiet background self-repair | env-config plist |
| co-doctor state | `~/.local/state/co-brain/{doctor.log,.doctor-alert,.doctor.lock}` | Audit log / incident ledger / singleton lock | `doctor.py` `STATE_DIR`, **unchanged** |

---

## 7. Acceptance criteria (verification matrix)

**Automated (all must pass)**

| # | Command | Expected |
|---|---|---|
| A1 | `tests/qa.sh --core` | ALL PASS, including the `co-awake 3.0.0` version line and D2 refusal assertions (1)–(7) |
| A2 | `tests/qa.sh` in the foreground (GUI session) | ALL PASS; no NOTE covers a renamed surface; the Q2 host-state sentinel shows no change |
| A3 | `tests/qa.sh --launcher` | ALL PASS: the singleton and the atomic replace hold under the new name; the sentinel shows no change |
| A4 | `tests/install-smoke.sh` | `bin/awake` link and `share/co-awake/CoAwake` binary exist; the old-prefix refusals in the installer and uninstaller leave no side effect |
| A5 | Migration matrix X1–X9 (§ 4.1.5) | All pass; X6 passes 20 times out of 20 |
| A6 | `git grep` leftover scan (Phase 1 step 5) and the cross-repo scan (Phase 3 step 1) | Only allowlisted hits |
| A7 | `co-doctor -q --treat; echo $?` | **Not enough on its own.** Under `-q`, losing the lock race also gives no output and exit 0. Must also show: `doctor.log` line count went up, **this run's** new `[SCAN]` line plus a `[RESULT]` line, and no "Another … instance is active" in this run. `doctor --help` and `co-doctor --help` print identical output |
| A8 | `co-doctor` first RunAtLoad | After `bootstrap`, `doctor.log` gains a complete `[SCAN]` + `[RESULT]` pair written by the new job (judged by timestamp later than the `bootstrap` time) |

**Manual / this machine**

| # | Check | Expected |
|---|---|---|
| M1 | `awake status` | `{"running":true,…}`, and the pid belongs to `…/co-awake/CoAwake` |
| M2 | `launchctl print gui/$(id -u)/com.binle.coawake` | Loaded argv matches the Phase 0 record; `ai.bera.coawareness` is not found |
| M3 | `ls "$HOME/Library/Application Support"` | `co-awake/` exists, with `state.json`'s preset / display / loadSource / batteryThreshold the same as before the switch; `co-awareness/` is gone. This machine has no `menubar-load-runner/` (if it did, it stays, by the X3 contract) |
| M4 | Menu → Restart (through launchd) | Icon comes back with settings kept (proves `Restarter.launchAgentLabel` matches the plist) |
| M5 | Menu → Check for Updates | Shows "co-awake 3.0.0 is the latest release" |
| M6 | `command -v co-awareness coa brain-doctor` | All empty |
| M7 | `launchctl print gui/$(id -u)/com.binle.co-doctor` | Loaded, `last exit code = 0`; `com.binle.brain-doctor` is not found |
| M8 | `tail -3 ~/.local/state/co-brain/doctor.log` | New lines follow the old ones in the same file (with A8) |
| M9 | `[[ -s ~/.local/state/co-brain/.doctor-alert ]] && echo ALERT` | No output |
| M10 | Type `/co-doctor` in any agent client | Found. `/brain-doctor` is no longer listed. `grep '^name: co-doctor$' ~/co-brain/skills/co-doctor/SKILL.md` matches, and the directory name agrees (`doctor.py` Stage 4 does not check that name equals directory, so it is checked here directly) |
| M11 | `curl -s https://co-awake.pages.dev \| grep -o 'class="badge">v[0-9.]*'` | `v3.0.0`. If the old site went the redirect way, `curl -sI https://co-awareness.pages.dev/x` returns 301 to `co-awake.pages.dev/x`. The owner checks the page by eye |
| M12 | The `caffeinate -w` leak check from § 13 | No LEAK |
| M13 | `grep -n 'co-awake/' ~/workspace_genai/AGENTS.md` | One hit in the active-project list (D4). `co-doctor`'s Stage 1 only checks the router at the workspace root and does not check project entries, so it does not count as proof of this item |
| M14 | D1 reproduction record (Phase 1.5 step 3) | After the mistaken update the icon does not return, and the old label is loaded with argv pointing at a missing file. After Procedure B, all four old identity pieces (job, process, link, install dir) are gone and `state.json` is intact |

**What cannot be verified, stated plainly.**

- **External v2.4.x installs.** They stay stuck after a mistaken update; the install count is unknown. All that covers them is the two procedures in the CHANGELOG `[3.0.0]` Upgrade section, which README and the cover link to.
- **If Phase 1.5 used Procedure A instead of reproducing D1,** then M14 is missing and D1 is only derived from the code: the cause chain is `Builder.precompile` cannot find the launcher, and `kickstart` replays the loaded old argv. That chain must not be written up as accepted evidence.
- **The `HOME` isolation conclusion is untested when this plan was drafted.** It is decided by the Phase 0 step 4 probe.
- **`ProcessProbe`'s match semantics have not been rechecked against the old-writer liveness check** (§ 4.1.3). That is confirmed during implementation and covered by X8.

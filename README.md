# co-awake

<p align="center">
  <img src="docs/media/hero.svg?v=2" alt="co-awake — a running horse in the macOS menu bar whose animation speed tracks system load" width="880">
</p>

A small native macOS menu bar app with two audiences. **People** glance at an animated runner whose
speed tracks system load (or a trace chart, or a live number), and toggle Keep Awake with one click.
**Programs and agents** run `awake snapshot` and get one line of JSON with the machine's physical vitals
— DRAM bus bandwidth, memory pressure, die temperature, P/E-core split, GPU, Neural Engine power, fans,
battery — read without privileges and without touching the menu bar.

Version is single-sourced in [`VERSION`](VERSION); release history in [`CHANGELOG.md`](CHANGELOG.md).

**Cover page:** [co-awake.pages.dev](https://co-awake.pages.dev)

| You want to… | Read |
|---|---|
| Use it day to day, or have an agent use it (scenarios, menu map, reading the JSON, FAQ) | [`docs/RUNBOOK-user-manual.md`](docs/RUNBOOK-user-manual.md) |
| Understand how it is built, why, and what it deliberately does not do | [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) |
| See what changed | [`CHANGELOG.md`](CHANGELOG.md) |

## Two tracks: the menu bar is for people, `snapshot` is for programs

| | People | Programs / agents |
|---|---|---|
| **Read the machine** | Glance at the status bar (runner GIF, trace chart, or live value); click for every reading | `awake snapshot` — one JSON line, physical units, ~0.3 s, writes nothing |
| **Is the app up, is it holding sleep?** | The track line under the icon, the countdown beside it | `awake status` — one JSON line |
| **Keep the Mac awake** | ⌥-click the icon, or the menu's first row (`Start Keep Awake` / `Stop Keep Awake`), with durations under `Keep Awake For ▸` — with a battery release point and a hard 5% floor | `caffeinate -i -w <pid>` bound to the job itself; not this app |
| **Change the look** | `Settings ▸ Display Mode ▸` / `Runner Preset ▸`; click a readout row to make it the driver | `awake --preset … --display … --load-source …` (applied live) |

Both tracks share one set of unprivileged readers (`TelemetryCore`: Mach, IOKit, IOReport, SMC). No
root, no `pmset`, no per-process table, no network except the release-tag check.

## Feedback wanted

This project grows by community feedback. Want a new preset, another load source, or
different behavior? Say so in
[Discussions](https://github.com/binlecode/co-awake/discussions) — a one-liner
is enough. Found a bug? [Open an issue](https://github.com/binlecode/co-awake/issues/new/choose).

## Install

macOS only. Requires the **Xcode Command Line Tools** (`git` + `swiftc`); the installer tells you
to run `xcode-select --install` if they're missing. It compiles from source on your machine — no
Apple signing, notarization, or Homebrew involved.

Recommended — download, inspect, then run:

```bash
curl -fsSL https://raw.githubusercontent.com/binlecode/co-awake/main/install.sh -o install.sh
less install.sh          # inspect before running
bash install.sh
```

Or the one-line convenience form:

```bash
curl -fsSL https://raw.githubusercontent.com/binlecode/co-awake/main/install.sh | bash
```

The installer clones the repo to `~/.local/share/co-awake`, compiles the binary, and
symlinks the launcher to `~/.local/bin/awake`. Run interactively, it also asks
whether to enable start-at-login (pass `--login` to enable it without prompting; a piped
`curl | bash` skips the prompt).

- **Overrides:** `CO_AWAKE_HOME` (install dir), `BIN_DIR` (launcher symlink dir).
- **Update:** re-run the installer (it runs `git pull` in place), or use the in-app updater below.
- **Uninstall:** `~/.local/share/co-awake/uninstall.sh` — tears down start-at-login, stops any
  running instance, removes the launcher symlink and the install dir (`--yes` skips the confirmation).

Already have the repo checked out? `./awake` from the repo directory works the same; to put it on your
`PATH`, `ln -s "$PWD/awake" ~/.local/bin/awake`.

## Quick start

```bash
awake                                      # start in the menu bar (detached; default preset horse-white)
awake --preset horse-black --display value # change the look — live, if it is already running
awake snapshot                             # one JSON line of hardware readings, then exit
awake status                               # is an instance up, is it holding the Mac awake
awake presets                              # the built-in preset keys
awake --help                               # the one full reference
```

The first argument is a command; leave it out and it means `start`:

| Command | Does |
|---|---|
| `awake [start] [flags]` | Start in the menu bar, or apply the flags to the instance already running. Replies `{"action":"started"\|"forwarded"\|"unchanged","pid":N}` |
| `awake snapshot` | Every hardware reading in physical units, without touching the menu bar |
| `awake status` | Is an instance up, and is it holding the Mac awake |
| `awake presets` | The built-in presets (key, title) and the default |
| `awake build` | Compile if the source is newer, then exit; safe while the app runs |

- **One instance, changed in place.** Settings — `--preset`, `--display`, `--load-source`,
  `--keep-awake`, `--keep-awake-pid`, `--battery-threshold` — sent to a running instance apply live.
  Launch-only flags (`--speed-multiplier`, `--show-all-sources`, `--no-update-check`, `--foreground`)
  are refused while it runs. `--extra` starts an additional instance that never writes the state file.
- **Logs.** A detached or login-item launch writes to `~/Library/Logs/co-awake.log` (override with `CO_AWAKE_LOG_FILE`);
  `--foreground` keeps output in your terminal.
- **Stop.** Menu → `Exit`, or `pkill -f CoAwake`.

## What it shows

**One representation at a time** (`--display`, or `Settings ▸ Display Mode ▸`): `gif` — the runner, faster under
load (default); `trace` — a 12-slot monochrome sparkline; `value` — a live reading like `CPU 15%` or
`NET ↓3.4 ↑0.1`. The item's width is fixed per mode, so changing digits never shift the menu bar.

**Ten load sources** (`--load-source`, or click its readout row in the menu) choose what drives the animation:
`cpu` (default, with a P/E-cluster split), `memory` (with swap), `bandwidth` (DRAM bus GB/s — usually
the ceiling for local model inference), `gpu` (with a Renderer/Tiler split), `network`, `disk`, `fan`,
`battery` (discharge current), `temperature` (hottest die sensor, on a fixed 30–100 °C scale), and
`ane` (Neural Engine watts — the load CPU and GPU can't see). A source this Mac can't read is hidden
and falls back to `cpu`. How each is measured: [ARCHITECTURE § 4](docs/ARCHITECTURE.md#4-hardware-telemetry--scaling-subsystems).

**The dropdown** is a live dashboard of every available reading, plus Keep Awake, appearance, start
at login and updates. Its full map and every Keep Awake state are in the
[user manual](docs/RUNBOOK-user-manual.md#菜单地图点击状态栏图标).

## Built-in presets

> The bundled art is **third-party sample content, not licensed with this project** — the Totoro and
> Chihiro presets are © Studio Ghibli, sourced from public internet pages and carried for **research
> and educational** demonstration in an open-source, non-commercial app. See
> [Assets & attribution](#assets--attribution) before forking, packaging, or redistributing;
> [any GIF of your own](#use-a-custom-gif) works just as well.

Horse (the default, `horse-white`), Chihiro and Totoro, most in white and black silhouettes for
light and dark menu bars. `gifs/presets.json` is the list — `awake presets`, the help and the menu all
read it, so adding a preset is a GIF plus one manifest entry, no Swift change.

### Use a custom GIF

```bash
awake --preset /absolute/path/to/your.gif      # or CO_AWAKE_PRESET=/absolute/path/to/your.gif
```

The item sizes itself to the GIF's aspect ratio at menu-bar height; width is not configurable.
`--speed-multiplier 1.2` fixes the speed instead of following load.

## Read the sensors from a script (`snapshot`)

```bash
$ awake snapshot
{"v":1,"power_source":"ac","memory_pressure":"normal","cpu_pct":12.3,"cpu_p_pct":3.4,"cpu_e_pct":39.5,"cpu_p_cores":12,"cpu_e_cores":4,"mem_pct":34.1,"swap_mibs":0.00,"bw_gbps":28.3,"gpu_pct":33.0,"gpu_rend_pct":33.0,"gpu_tiler_pct":15.0,"net_rx_mibs":0.00,"net_tx_mibs":0.00,"disk_read_mibs":0.00,"disk_write_mibs":0.00,"fan_rpm":[1332,1459],"battery_pct":80.0,"battery_health_pct":100.0,"battery_cycles":118,"temp_c":56.0,"thermal":"nominal","ane_w":0.00}
$ awake snapshot | jq '{bw_gbps, memory_pressure, thermal}'
```

- **Units are in the key name** — `_pct` %, `_mibs` MiB/s, `_gbps` GB/s, `_c` °C, `_w` W, `_a` A;
  `fan_rpm` is one entry per fan. `v` is the only key always present; read by key, ignore unknown ones.
- **An absent key means unknown.** A reading the machine can't give is left out — never `null`, never
  a `0` or a reassuring default. `memory_pressure`, `power_source`, `thermal` and `temp_c` appear only
  when macOS actually stated them; don't treat their absence as "fine".
- **No side effects.** No menu bar, no state file, no compile; safe beside a running instance and in
  parallel with itself. It must be the only argument. About 0.3 s, because rates are counter deltas
  over a sampling window. Exit `2` means the binary isn't built yet — run `awake build` once.

Full schema and the absent-when table: [ARCHITECTURE § 4.7](docs/ARCHITECTURE.md#47-telemetry-core--the-snapshot-command).
How an agent should read it, scenario by scenario: [the user manual](docs/RUNBOOK-user-manual.md).

## Ask whether one is already running (`status`)

```bash
$ awake status
{"running":true,"pid":1598,"keep_awake":{"active":true,"remaining_s":3540}}
```

`snapshot` answers for the machine; this answers for the app. Nothing running is `{"running":false}`
and still exit 0 (exit 1 only means the question wasn't understood). `keep_awake` reports whether Keep Awake
was armed (user intent; `remaining_s` for a timed window). Read-only. Details: [ARCHITECTURE § 8.3](docs/ARCHITECTURE.md#83-the-status-query).

## Keep Awake

For a person stepping away. ⌥-click the menu bar item (or click the menu's first row) to toggle it, or pick a window from
`Keep Awake For ▸` (30 min to 8 h, custom up to 24 h, until turned off, or until a process exits). From the
command line:

```bash
awake --keep-awake 4h                  # a window (a unit is required: 30m, 2h, 1h30m; max 24h)
awake --keep-awake on                  # until turned off
long-job.sh & awake --keep-awake-pid $!   # until that job exits, visible in the menu bar
awake --battery-threshold 10           # release at 10% on battery instead of 20% (6–100, or off)
```

It holds sleep with `caffeinate -di -w <app pid>`, so the hold dies with the app. It pauses on battery
below the release point (default 20%) or under serious thermal pressure, resumes when that clears, and
**always releases at 5% battery** — no flag, menu action or saved state gets past that floor. A timed
window survives a relaunch or reboot as its remaining time; an indefinite or process-bound hold does
not. Every state and rule: [user manual](docs/RUNBOOK-user-manual.md); mechanism: [ARCHITECTURE § 7](docs/ARCHITECTURE.md#7-integrated-sleep-prevention-sleeppreventer--assertion-monitor).

**Unattended agent jobs don't use Keep Awake** — they bind a hold to the job with
`caffeinate -i -w <pid>`, which needs no resident app and releases when the job exits (see the
manual's scenario 3 for the `-i` vs `-di` tradeoff).

## Start at login

A per-user LaunchAgent supervising the compiled `CoAwake` Mach-O binary directly (`adhoc`-signed as
`com.binle.coawake`) — no root, no `.app` bundle, no Apple Developer certificate required. Toggle
**Start at Login** in the menu, or from the shell:

```bash
./scripts/install-login-item.sh                                           # default preset
./scripts/install-login-item.sh --preset horse-black --load-source memory # bake in launcher args
./scripts/uninstall-login-item.sh                                         # remove; leaves no residue
```

It appears under **System Settings → General → Login Items → "Allow in the Background"**. `Exit` from
the menu quits it until the next login (no `KeepAlive`). A new release is picked up on the next start
(`launchctl kickstart -k "gui/$(id -u)/com.binle.coawake"`); re-run the install script only to change
the baked-in args.

## Updates

On launch the app compares your checkout's highest release tag (`git ls-remote --tags origin 'v*'`)
with its own version — **the only network access it makes**, once per launch, failing silently. A newer
tag turns the root `Settings` row into `Settings · Update available` and its update row into `Update to vX.Y.Z…`. Applying it is always a deliberate click and confirm:
`git pull --ff-only` (never `--force`), compile while the app keeps running, then **Restart**. Your
Keep Awake window, display mode, battery threshold and tint carry over. Disable the check with
`--no-update-check` or `CO_AWAKE_UPDATE_CHECK=0`.

## Resource cost

co-awake is built to stay out of the way of the load it visualizes. Measured on Apple
Silicon at 2× Retina — your numbers vary with Mac model, menu-bar height, display refresh rate, the
active preset, and the current load level:

- **CPU:** ~0.4–0.9% of one core while the icon is animating and visible; **0% when hidden** (the
  game loop stops when the item is occluded by the notch, a full-screen app, or an inactive Space).
  Capped at half speed under Low Power Mode / thermal / memory pressure. With **Reduce Motion** on,
  the animation stops and the status bar shows the live value instead.
- **Memory:** ~10 MB at launch, ~20–24 MB once the menu has been opened — essentially the AppKit
  floor for a menu-bar app.

Reproduce it:

```bash
PID=$(pgrep -U "$(id -u)" -f '/CoAwake( |$)')
top -pid "$PID" -l 6 -s 1 -stats pid,command,cpu,mem     # CPU + memory
footprint -p "$PID"                                      # phys_footprint (true memory)
```

## Testing & CI

There's no unit-test framework — the release gate is a single tiered QA harness, `tests/qa.sh`.
What it can't reach — the menu clicks and the eyes-only checks — stays manual; the release-cut walk
is [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) § 13. Run it from the repo root:

```bash
tests/qa.sh            # core + gui (local default)
tests/qa.sh --core     # core only — the headless / CI-safe subset
tests/qa.sh --gui      # build + the GUI sections only
tests/qa.sh --launcher # also run the disruptive §6 launcher/singleton check
tests/qa.sh --help
```

| Tier | Sections | Needs a GUI session? | Role |
|---|---|---|---|
| `core` | §1 build (warning-clean) · §2 CLI/version · §2a `snapshot` · §2b `status` · §2c `presets` | No | Primary gate — must pass before a release; headless-safe |
| `gui` | §3 launch lifecycle · §3a–§3i Keep Awake / persistence / status item geometry / sleep assertions / animation driver / battery diagnostics / kernel thermal · §3j `status` and §3k idempotent `start` against a live instance · §5 reader readouts · §4 error paths | Yes (WindowServer) | Best-effort — needs a logged-in Mac; skipped on a headless host |
| `launcher` | §6 launcher + singleton (disruptive `pkill`) | — | Manual — run locally before a release |
| manual | the menu walk + the eyes-only checks — never scripted | — | Hands and eyes; a NOTE in the tiers above is an unanswered case, not a pass |

Every check launches the real binary and asserts a real side effect (a `caffeinate` child, a state
file, the live status item's geometry and readout) — never a re-ported copy of the app's logic, which
passes while the app is broken. `snapshot`, `status` and `presets` build no GUI, so running them in the
headless tier *is* the proof the readers answer with no WindowServer behind them.

A GitHub Actions workflow ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)) mirrors these tiers
on `macos-14`, but its automatic triggers are **disabled to conserve the free-tier Actions quota**
(macOS runners bill at a 10× minute multiplier); run it on demand from the Actions tab.

## How it compares

co-awake sits between two categories: animated load indicators (RunCat-style "the
creature runs faster when the machine works harder") and menu-bar system monitors (numeric
dashboards). It is the CLI-first, no-Xcode entry in the first category, with a lightweight slice of
the second built into its dropdown. Feature presence at a glance versus the closest open-source
neighbors — [menubar_runcat](https://github.com/Kyome22/menubar_runcat) (the open-source edition of
RunCat, by its original developer), [zoomies](https://github.com/KartikLabhshetwar/zoomies) (SwiftUI
pixel-pet indicator), and [stats](https://github.com/exelban/stats) (the full system-monitor
dashboard):

| | co-awake | menubar_runcat | zoomies | stats |
| :--- | :--- | :--- | :--- | :--- |
| **Category** | Animated load indicator | Animated load indicator | Animated load indicator | System monitor |
| **Packaging** | Single Swift file + shell launcher (no Xcode project) | Xcode `.app` | Xcode `.app` | Xcode `.app` |
| **Load sources** | CPU (with P/E split), memory+swap, DRAM bus bandwidth, GPU (with Renderer/Tiler split), network, disk, fan, battery, die temperature, Neural Engine power | CPU | CPU, GPU, RAM | Full hardware suite |
| **Unbounded rates (net/disk/swap) drive the animation** | Yes — adaptive auto-scaling | — | — | n/a (numeric display) |
| **In-menu readout** | Live numerics per source, with P/E and Renderer/Tiler splits | Minimal | Numeric dropdown | Full graphs, temps, per-process |
| **Battery health / cycle count** | Yes (menu-gated, unprivileged, never polled) | No | No | Yes |
| **Per-process breakdowns** | No (out of scope by design) | No | No | Yes |
| **Pauses when hidden; self-throttles under power/thermal pressure; honors Reduce Motion** | Yes | — | — | — |
| **Built-in sleep inhibitor (Keep Awake)** | Yes (`caffeinate`, timed release, auto-disengage, survives relaunch) | — | — | — |
| **CLI flags / headless install / login automation** | Yes (launcher, LaunchAgent scripts) | GUI app | GUI app | GUI app |
| **Settings window** | No (menu + CLI flags) | — | Yes (SwiftUI) | Yes |
| **Updates** | In-app git tag check + one-click `git pull` | Manual rebuild (archived repo) | GitHub releases | Built-in updater |

> Snapshot: July 2026, feature *presence* only — no performance comparisons are made or implied
> (no rigorous same-method measurements of other menu-bar apps exist; the only figures measured
> here are this app's own, above). Verify each project's current state upstream.

If you want per-sensor temperature lists or per-process breakdowns, use
**stats** — this app deliberately stays an unprivileged, aggregate-only indicator. If you want a graphical settings
window over CLI flags, **zoomies** offers one.

## License

Source code: **open source under the [MIT license](LICENSE.md)** © 2026 Bin Le — free to use, modify,
and redistribute. The bundled preset GIFs in `gifs/` are **not** ours and **not** covered by that
license; they are public-internet artwork carried for research and educational demonstration only —
see Assets & attribution below.

## Assets & attribution

> **This project is open source under the MIT license — and that license covers the code only, never
> the bundled preset GIFs.** The art is third-party, gathered **entirely from publicly accessible
> pages on the open internet** (e.g. Giphy, Pinterest — nothing paywalled, private, or extracted from
> a licensed release), and it is included **for research and educational purposes only**: sample
> frames that let a non-commercial, open-source demo have something to animate while its rendering,
> speed-mapping, and menu-bar behavior are studied. No ownership is claimed, no rights are granted to
> you over them, and **no permission to redistribute them is given or implied** — if you fork,
> package, or mirror this project, the artwork is yours to clear or to remove. Nothing is sold, no
> advertising runs against it, and the app takes any GIF you point it at (see
> [Use a custom GIF](#use-a-custom-gif)), so it works fully without a single bundled file.

All rights remain with their respective owners:

- `totoro.gif`, `totoro-white.gif`, `totoro-black.gif`, `totoro-group-white.gif`,
  `totoro-group-black.gif` — "Totoro" and related characters © Studio Ghibli.
- `chihiro-walk.gif`, `chihiro-walk-white.gif`, `chihiro-walk-black.gif` — "Chihiro" (Spirited Away)
  © Studio Ghibli.
- `running-horse-black.gif`, `running-horse-white.gif` — animal silhouettes from public sources (original authorship unverified).

**Third-party code.** `ThroughputScaler` — the adaptive ceiling that normalizes unbounded rate
sources (network, disk, swap, battery draw) — is a Swift port of the auto-scale logic in
[`btop`](https://github.com/aristocratos/btop)'s `Net::collect` (`src/osx/btop_collect.cpp`), which is
licensed under **Apache-2.0** © Jakob P. Liljenberg. No btop source is vendored; the algorithm is
reimplemented and credited here and at the call site.

This project is **not affiliated with, endorsed by, or sponsored by** any of these rights holders. It
is a free, non-commercial, open-source hobby utility, and the artwork is here to demonstrate and study
the software, not to trade on anyone's characters. If you are a rights holder and would like a file removed,
please open an issue and it will be taken down
promptly.

You don't need the bundled GIFs — point the app at any GIF you have the rights to use:
`awake --preset /absolute/path/to/your.gif` (or set `CO_AWAKE_PRESET`).

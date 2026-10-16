# co-awake 用户手册：人机协同硬件遥测与状态栏负载感知指南

**人看状态栏：小马跑多快、曲线多高、一键防休眠。Agent 读 `awake snapshot`：一行紧凑 JSON，只读地拿到整机物理体征。**
两条路径共用同一套无特权读数器，互不干扰：人不需要记命令，Agent 不需要看图标。

本手册讲「怎么用、什么时候用哪条路、读数怎么解读」。机制与设计取舍见 [`ARCHITECTURE.md`](ARCHITECTURE.md)，安装见根目录 [`README.md`](../README.md)，完整旗标以 `awake --help` 为准。

---

## 核心心智模型 (Mental Model)

```
             人类 (你)                                         AI Agent
                 |                                                 |
     +-----------+------------+                       +------------+-------------+
     |           |            |                       |                          |
     v           v            v                       v                          v
  glance       click      Option-click          awake snapshot          caffeinate -i -w <pid>
  status bar   dropdown   Keep Awake on/off     one JSON line           bound to the job's PID,
  gif/trace/   live rows  (no menu)             ~0.3 s, read-only       released when it exits;
  value        Keep Awake                                               never touches co-awake
     |           |            |                       |                          |
     +-----------+------------+                       |                          v
                 |                                    |                    macOS powerd
                 v                                    v
     +--------------------------+       +--------------------------+
     | GUI instance (resident)  |       | snapshot (one-shot)      |
     | animation, menu,         |       | sample, wait, sample,    |
     | Keep Awake (-di,         |       | print one line, exit     |
     | 5% battery floor)        |       | no GUI, writes nothing   |
     +------------+-------------+       +------------+-------------+
                  |                                  |
                  +-----------------+----------------+
                                    v
                  +-----------------------------------+
                  | TelemetryCore                     |
                  | Mach / IOKit / IOReport / SMC     |
                  | unprivileged, read-only           |
                  +-----------------------------------+

  awake status 不经过 TelemetryCore：只看进程表与 state.json，回答「实例在不在、用户是否开启了防休眠意图」（若因低电量或过热暂时暂停，active 仍为 true；真防休眠生效状态须查 pmset -g assertions）。
```

- **给人的是图形，给程序的是 JSON**：状态栏是一眼可读的「体感」，`snapshot` 是带单位、可被程序判定的「读数」。同一个传感器，两种呈现，同一份底层实现。
- **防休眠也分两条**：人临时离开工位，用状态栏 Keep Awake（带电量保护、可看倒计时）；Agent 跑无人值守长任务，用系统自带 `caffeinate` 绑定任务自己的 PID，不经过本应用。
- **只读，不管闲事**：co-awake 只读整机读数，不杀进程、不列进程表、不改系统电源策略（不碰 `pmset`）、不要 root。

---

## 常用交互场景详述与实操示范（按 ROI 价值排序）

> **ROI 排序原则**：直接决定一次重任务成败的体检 > 出问题时的定因 > 防休眠分工 > 个性化与日常查询。

### 场景 1：本地重型推理 / 编译前的「总线与内存压力」体检 (ROI ★★★★★)

**为什么重要**：Apple Silicon 是统一内存（UMA），CPU、GPU、神经引擎共用一条内存总线。本地大模型（MLX / Ollama）解码时，瓶颈通常是**总线带宽**和**内存压力**，不是 CPU 百分比 —— 一台机器可以内存只用了 40%、CPU 很闲，而总线已经跑满。只看 CPU 会得出「机器很空」的错误结论。

```
   你："准备跑本地 30B 模型，机器现在带得动吗？"
                      |
                      v
        Agent 执行 awake snapshot (约 0.3 s)
                      |
     +----------------+-----------------+-----------------+
     v                v                 v                 v
 bw_gbps          memory_pressure    swap_mibs          thermal / temp_c
 总线已被占多少    内核说内存紧不紧    是否正在换页        是否已经在热降频
     |                |                 |                 |
     +----------------+-----------------+-----------------+
                      v
          Agent 结合任务需求自行判断，并说明依据
          (缺键 = 未知，不当成"正常")
```

#### 实操对话示例：
> **你**：「*准备跑本地 30B 模型，帮我看看现在机器状态带得动吗？*」
>
> **Agent**（执行 `awake snapshot`，读到 `"memory_pressure":"normal","mem_pct":34.1,"swap_mibs":0.00,"bw_gbps":28.3,"thermal":"nominal","temp_c":56.0`）：
> 「*当前系统未见明显负载压力：内核内存压力为 `normal`、无换页活动（swap 0 MiB/s），总线带宽占用 28 GB/s，热状态 `nominal`。不过 30B 模型（Q4 量化通常需要约 18~20 GB 显存/内存），仍需结合物理内存总量核实空间；启动后请密切观察 `swap_mibs` 是否持续大于 0 或 `memory_pressure` 是否升为 `warn`。*」

#### 关键交互点：
- **四个字段各答一个问题**：`bw_gbps` 是「总线有多忙」，`memory_pressure` 是「内核认为内存紧不紧」，`swap_mibs` 是「是否已经开始拿磁盘当内存」，`thermal` 是「内核是否已经开始降频」。`mem_pct` 只是「装了多满」，单独看会误判（macOS 会把空闲内存拿去做缓存）。
- **带宽量级参考**（一台 M4 Max 的实测，换机型会变）：空闲约 16 GB/s，日常桌面 46–78 GB/s，重度流式负载 335 GB/s。看的是相对本机空闲基线涨了多少，而不是绝对阈值。
- **阈值归 Agent，不归 co-awake**：`snapshot` 只报读数，不给「能 / 不能」的结论，也没有 `--check`。判断标准取决于任务，由调用方决定。
- **跑的过程中可以复查**：`snapshot` 不写盘、不加锁，与常驻实例并存、并行调用都安全，可以在任务运行时随时再读一次。

---

### 场景 2：机器发热、风扇狂转、系统卡顿时的「真因定位」 (ROI ★★★★★)

**为什么重要**：「烫」「吵」「卡」是三个不同的物理事件。温度是**领先信号**（芯片毫秒级升温），风扇是**滞后信号**（几秒后才拉转速），卡顿可能来自 CPU、GPU、神经引擎、内存换页或磁盘。先用整机读数判断「是哪一类资源」，再用 `ps` 找「是哪个进程」。

```
   你："电脑怎么这么烫？风扇在转吗？哪个东西吃满了？"
                      |
                      v
   +-- 第 1 步：整机定性 (awake snapshot)
   |     temp_c       最热的芯片传感器 (°C)
   |     thermal      内核热压力等级
   |     fan_rpm      每个风扇一项 (RPM)
   |     cpu_p_pct / cpu_e_pct          性能核 / 能效核
   |     gpu_rend_pct / gpu_tiler_pct   GPU 两段管线
   |     ane_w                          神经引擎功耗 (W)
   |     swap_mibs / disk_*_mibs        换页与磁盘吞吐
   |
   +-- 第 2 步：进程归因 (POSIX 工具，不归 co-awake)
   |     ps -Ao pid,pcpu,pmem,comm -r | head    按 CPU 排序
   |     ps -Ao pid,pcpu,pmem,comm -m | head    按内存排序
   |
   v
   Agent 把「哪类资源」和「哪个进程」对上，给出真因与建议
```

#### 实操对话示例：
> **你**：「*电脑怎么这么烫？风扇在转吗？哪个东西吃满了？*」
>
> **Agent**（`snapshot` 读到 `"temp_c":92.0,"thermal":"serious","fan_rpm":[4800,5100],"cpu_p_pct":97.0,"cpu_e_pct":40.0,"gpu_pct":8.0,"ane_w":0.00`；再执行 `ps -Ao pid,pcpu,comm -r | head`）：
> 「*是 CPU 性能核被打满导致的：性能核 97%，芯片最热处 92 °C，内核热压力已到 `serious`（意味着系统已经在降频），两个风扇都在 4800–5100 RPM。GPU 和神经引擎都很闲。按进程看，`swift-frontend`（PID 41293）占了 780% CPU，是一次并发编译。等它编完会自己降下来；急用的话可以降低编译并发数。*」

#### 关键交互点：
- **`thermal` 比温度数字更有决策价值**：温度高不等于在降频；`serious` / `critical` 才说明内核已经动手。Apple Silicon 不公开频率上限，所以 co-awake 不编造「降频百分比」。
- **神经引擎是隐身负载**：Apple Intelligence、CoreML、Vision 等跑在 NPU 上时，CPU 和 GPU 都很闲，只有 `ane_w` 会显示几瓦功耗。
- **性能核 / 能效核要分开看**：总 CPU 35% 可能是 4 个能效核跑满，也可能是 4 个性能核跑满，是两种完全不同的机器状态。
- **为什么不内置进程排行**：遍历进程表本身就吃 CPU（观察者变成负载），且 `ps` / `top` / 活动监视器已经做得很好。整机读数归 co-awake，进程归因归 `ps`（见 ARCHITECTURE §4.10）。

---

### 场景 3：无人值守长任务防休眠分工 (ROI ★★★★☆)

两种「别让 Mac 睡着」的需求，生命周期完全不同，所以分两条路：

```
   命令行长任务                                  人临时离开工位
   (编译 / 调研 / 测试 / 训练)                   (开会 / 吃饭 / 过夜)
          |                                             |
          v                                             v
   caffeinate -i -w <pid>                        Option-click 状态栏图标
   (系统自带)                                    (或菜单 Keep Awake > 选时长)
          |                                             |
   - 绑定任务自己的 PID，任务退出即释放          - 30m / 1h / 2h / 4h / 8h /
   - 多个任务各持一把，互不影响                    自定义 (<= 24h) / 直到关闭
   - 无常驻进程，崩溃也不留锁                    - 状态栏倒计时 + 底部色条
   - 不经过 co-awake                             - 电量 <= 阈值 (默认 20%) 暂停
                                                 - 电量 <= 5% 无条件释放
                                                 - 热压力 serious 以上暂停
```

#### 实操对话示例：
> **你**：「*我去开会，这个测试套件大概要跑一个多小时，别让电脑睡着。*」
>
> **Agent**：「*已绑定到测试进程：`caffeinate -i -w 52817`。测试结束后锁自动释放，Mac 恢复正常睡眠，不需要你回来关。*」

> **你**：（准备离开工位，按住 Option 点一下状态栏图标）
> 状态栏图标底部出现色条，表示 Keep Awake 已开启；再 Option-click 一次关闭。

#### 关键交互点：
- **Agent 不用 Keep Awake**：Keep Awake 是给人的控件，会写入 `state.json` 持久化意图、受电量阈值约束；Agent 的任务需要的是「任务活多久就持有多久」，`caffeinate -w` 原生就是这个语义，而且不需要 co-awake 在运行。
- **`-i` 的已知局限**：`-i` 只阻止「空闲系统睡眠」，不阻止屏幕熄灭。本应用自己的 Keep Awake 用 `-di`，原因是在新版 macOS 上屏幕睡下去后系统可能跟着睡（见 ARCHITECTURE §7.1）；菜单也会把只有 `-i` 的持有显示为 `Idle sleep held, display is not — the Mac may still sleep`。如果任务必须跑完、且能接受屏幕常亮，用 `caffeinate -di -w <pid>`。
- **想在状态栏上看到任务绑定的持有**：`long-job.sh & awake --keep-awake-pid $!`，或菜单 `Keep Awake ▸ Until a process exits…` 输入 PID 或进程名（如 `claude`，取你名下最新的同名进程）。这条路受电量保护约束，且不会在重启后恢复（PID 会被复用）。
- **合盖睡眠挡不住**：电池供电下合盖，任何无特权方式都无法阻止睡眠；需要合盖运行请接电源 + 外接显示器（苹果标准合盖模式）。

---

### 场景 4：状态栏个性化与动图预设定制 (ROI ★★★☆☆)

状态栏同一时刻只显示**一种**形态，三选一：

| 形态 | 旗标 | 显示 | 适合 |
|---|---|---|---|
| 动图 | `--display gif`（默认） | 奔跑的动物 / 人物，负载越高跑越快 | 余光感知「机器在忙」 |
| 曲线 | `--display trace` | 12 格单色迷你曲线（随深浅色外观自适应） | 看最近趋势 |
| 数值 | `--display value` | 实时读数，如 `CPU 15%`、`NET ↓3.4 ↑0.1` | 要一个准数 |

**动图预设**：白 / 黑狗、黑 / 白骏马（默认白马 `horse-white`）、千寻散步（彩色 / 白 / 黑）、龙猫（单只 / 一群，彩色 / 白 / 黑）。`awake presets` 列出全部 key；也可以指定任意 GIF 的绝对路径。

**驱动源（谁决定跑速）**：`cpu`（默认）、`memory`、`bandwidth`、`gpu`、`network`、`disk`、`fan`、`battery`、`temperature`、`ane`。本机读不到的源自动隐藏，指定了也会回落到 `cpu`。

#### 实操对话示例：
> **你**：「*状态栏换成黑色龙猫，跟着内存总线带宽跑。*」
>
> **Agent**：「*已切换：`awake --preset totoro-black --load-source bandwidth`。实例在运行，设置已直接生效。*」

> **你**：「*不要动图了，直接显示 GPU 数值。*」
>
> **Agent**：「*`awake --display value --load-source gpu`，状态栏现在显示 `GPU 30%` 这样的读数。*」

#### 关键交互点：
- **同一条命令，运行中即热切换**：`--preset`、`--display`、`--load-source`、`--keep-awake`、`--keep-awake-pid`、`--battery-threshold` 对已运行的实例直接生效，返回 `{"action":"forwarded",...}`；设置没变则返回 `unchanged`。
- **只在启动时有效的旗标会被拒绝**：`--speed-multiplier`、`--show-all-sources`、`--no-update-check`、`--foreground` 在实例运行时报错退出（exit 1），不会被静默忽略。
- **菜单里也能点**：`Display Mode ▸`（形态）、`Runner Preset ▸`（动图）、`Selected Metric ▸`（驱动源）。
- **宽度不可配置**：状态栏宽度由 GIF 宽高比自动决定，读数变化时不会左右抖动。
- **加自己的预设**：放 GIF 到 `gifs/`，在 `gifs/presets.json` 加一项，无需改代码（流程见 `AGENTS.md`）。

---

### 场景 5：电池健康与硬件循环查询 (ROI ★★★☆☆)

#### 实操对话示例：
> **你**：「*电池还健康吗？循环多少次了？现在掉电快不快？*」
>
> **Agent**（`snapshot` 读到 `"power_source":"battery","battery_pct":80.0,"battery_a":1.20,"battery_health_pct":100.0,"battery_cycles":118`）：
> 「*电池健康度 100%，已循环 118 次，状态很好。现在用电池供电、剩余 80%，放电电流 1.2 A。*」

#### 关键交互点：
- **字段**：`battery_pct` 电量、`battery_health_pct` 健康度（当前最大容量 / 设计容量）、`battery_cycles` 循环次数、`battery_a` 放电电流（安培，正数为放电）。
- **`battery_a` 只在放电时出现**：接电源充电或电流读不到时该键缺失 —— 它是「掉电速度」，不报充电电流。
- **菜单里看得更细**：点开菜单，`Battery` 行显示健康度与循环次数，悬停可看状况（如 `Normal`）、当前与设计容量（mAh）。健康度低于 80% 或硬件报告永久故障时显示 `Service Recommended`，与 macOS 自身判定一致。
- **不轮询**：健康度和循环次数以月为单位变化，菜单只在打开时读一次，关闭即丢弃。台式机没有电池，相关键与菜单行全部缺失。

---

## 菜单地图（点击状态栏图标）

```
  CPU ... / Memory ... / GPU ... / ...     <- 每个可用读数源一行，实时刷新（只读）
  Slowing animation — <原因>               <- 仅在自限流时出现（热 / 低电量模式 / 内存压力）
  ----------------------------------------
  Keep Awake  >  Off
                 Until turned off / 30 minutes / 1 hour / 2 hours / 4 hours / 8 hours / Custom…
                 Until a process exits…
                 (倒计时或暂停原因, 仅在需要时出现)
                 Battery Safety Floor  >  10% / 15% / 20% / 30% / Never / Custom…
                 Indicator Bar Tint    >  Dusty Teal / Sand / Graphite / Mauve / Sage
                 (这台 Mac 此刻是否被持有、被谁持有)
                 Other Assertions: (其他进程持有的睡眠断言, 或 none)
  ----------------------------------------
  Display Mode   >  Runner GIF / Trace Chart / Live Value
  Runner Preset  >  (全部动图预设)
  Selected Metric > (全部可用驱动源)
  ----------------------------------------
  Start at Login
  Update available: vX.Y.Z  (有新版本时)  /  Check for Updates…
  About / Exit
```

**手势**：普通点击、右键、Control-click 打开菜单；**Option-click** 不开菜单、直接开关 Keep Awake；⌘-拖动调整图标位置。

**Keep Awake 的几种状态怎么看**：

| 你看到的 | 含义 |
|---|---|
| 图标底部实色条 | 本应用正在持有，Mac 不会因空闲睡眠 |
| 图标旁倒计时 `29:58` | 定时窗口剩余时间；「直到关闭」或绑定进程的持有没有倒计时 |
| 色条变淡 | 不是本应用，是别的进程（如你自己跑的 `caffeinate`）在持有 —— 本应用的 `Off` 关不掉它 |
| 色条更淡 + 菜单 `(paused)` | 已开启但暂时让出：电量低于阈值、电量 ≤ 5%、或机器过热；条件解除后自动恢复 |

**Keep Awake 的保护规则**：
- **电量阈值**（默认 20%，可设 6–100% 或 `Never`）：电池供电且低于阈值时自动暂停，接上电源自动恢复。
- **5% 硬底线**：电量 ≤ 5% 无条件释放，任何设置、菜单操作、命令行参数都绕不过去。
- **低电量下手动开启**：在菜单或 Option-click 开启，会覆盖阈值暂停（仅本次会话，不持久化），但仍止于 5%。命令行 `--keep-awake` 不享有这个覆盖，因为它可能写在开机自启里、没人在场判断。
- **过热暂停不可覆盖**。
- **重启后恢复**：未到期的定时窗口按剩余时间恢复；已到期的不恢复；「直到关闭」不恢复（没有终点的持有会在每次重启后悄悄让 Mac 不睡）；绑定进程的持有不恢复。

---

## 诚实遥测契约 (Honest Telemetry Contract) 与缺键解读

`snapshot` 的硬规矩只有一条：**系统没明确告诉它的，就不打印。** 读不到的键直接缺失 —— 不填 `null`，不填 `0`，也不填一个「看起来正常」的默认值。

> **给 Agent 的警告**：缺键 = 未知。**严禁**把缺键当作「正常」「0」或「接着电源」。要么如实告诉用户「这项读不到」，要么按保守方向处理（例如不知道内存压力时，不要断言「内存充足」）。注意：使用 `jq '{key1, key2}'` 时会将 JSON 中不存在的键显示为 `null`，这是 `jq` 自身的投影行为，不代表底层输出了 `null`。
>
> 此外，当前诚实缺键主要覆盖 `memory_pressure`、`power_source`、`temp_c`、`thermal` 等关键状态键；电池诊断（如 `battery_health_pct`）在部分机型缺少容量明细时仍可能回退到 100%。

**最容易被误读的四个键**（Agent 常拿它们做门控判断）：

| 键 | 正常取值 | 缺失意味着 | 不要臆测成 |
|---|---|---|---|
| `bw_gbps` | GB/s | 本机没有内存控制器（AMCC）带宽直方图，例如 Intel Mac | 总线空闲 |
| `temp_c` | °C，最热传感器 | 读不到芯片温度传感器（如虚拟机），或所有核心簇都已断电停车（此时动画下限不作为温度输出） | 温度正常 / 30 °C |
| `memory_pressure` | `normal` · `warn` · `critical` | `sysctl` 被拒（如沙箱返回 `EPERM`），或内核返回了未知等级 | 内存正常 |
| `power_source` | `ac` · `battery` | IOPS 没有给出明确的电池描述列表（如台式机），查询失败，或供电是 UPS | 接着电源 |
| `thermal` | `nominal` · `fair` · `serious` · `critical` | 系统报了一个本版本不认识的等级（表明系统热压力，`serious`/`critical` 提示可能正在热降频） | 无降频 |

**其他缺键规律**：
- **成对出现，要么都有要么都没有**：`cpu_p_pct`/`cpu_e_pct`、`cpu_p_cores`/`cpu_e_cores`、`gpu_rend_pct`/`gpu_tiler_pct`、`battery_health_pct`/`battery_cycles`。
- **硬件不存在**：台式机无 `battery_*`，无风扇机型（如 MacBook Air）无 `fan_rpm`。
- **`0` 是真实读数**：`ane_w: 0.00` 表示神经引擎断电空闲，`swap_mibs: 0.00` 表示没在换页 —— 这些都是测出来的 0，不是占位。
- **按键名读取**：`v` 是唯一必有字段（契约版本）；以后可能新增字段，消费方应忽略不认识的键。

**单位从键名后缀读**：`_pct` 百分比 · `_mibs` MiB/s · `_gbps` GB/s · `_c` 摄氏度 · `_w` 瓦 · `_a` 安培 · `fan_rpm` 每风扇一项的转速列表。完整字段表与每个键的读数来源见 [ARCHITECTURE §4.7](ARCHITECTURE.md#47-telemetry-core--the-snapshot-command)。

---

## CLI 命令速查

首参是动词，省略即 `start`。每条命令都只输出一行 JSON。完整参数说明以 `awake --help` 为准。

| 命令 | 做什么 | 输出 / 退出码 |
|---|---|---|
| `awake snapshot` | 整机读数，物理单位；不建 GUI、不写盘、不编译；必须是唯一参数 | 一行 JSON · `0` 已输出（即使部分缺键）· `1` 用法错误 · `2` 尚未编译（先跑 `awake build`） |
| `awake status` | 有没有常驻实例、是否正在持有 Keep Awake | `{"running":false}` 也是 exit 0；`keep_awake` 仅在实例运行时出现；`remaining_s` 仅定时窗口有 |
| `awake presets` | 内置预设 key、标题与默认值（读自 `gifs/presets.json`） | 一行 JSON |
| `awake [start] [旗标]` | 启动到状态栏；已有实例则把设置转发给它 | `{"action":"started"\|"forwarded"\|"unchanged","pid":N}` |
| `awake build` | 源码比二进制新时才编译（原子替换），不启动；实例运行中也安全 | — |

**常用组合**：

```bash
awake snapshot | jq '{bw_gbps, memory_pressure, swap_mibs, thermal}'   # 推理前体检
awake snapshot | jq '{temp_c, thermal, fan_rpm, cpu_p_pct, cpu_e_pct}' # 发热定因
awake status | jq -e .keep_awake.active                                # 用户是否开启了防休眠意图（暂停时仍为 true，真防睡须看 pmset）
awake --preset dog-black --display value                               # 换外观（运行中热切换）
awake --keep-awake 2h                                                  # 人用：定时 2 小时
long-job.sh & awake --keep-awake-pid $!                                # 人用：任务结束即释放（状态栏可见）
caffeinate -i -w "$PID"                                                # Agent 用：绑定任务 PID，不经过本应用
```

**设置旗标**（启动时或对运行中实例都有效）：`--preset`、`--display`、`--load-source`、`--keep-awake`（`off` / `on` / 带单位的时长如 `30m`、`1h30m`，最长 24h；初次启动时传入非法或裸数字会发出警告并以 Keep Awake 关闭状态启动，转发给运行中实例时则严格报错拒绝）、`--keep-awake-pid`、`--battery-threshold`（整数百分比 6–100 或 `off`）。每个旗标都有对应环境变量 `CO_AWAKE_<FLAG>`，旗标优先。

**仅启动时有效**：`--speed-multiplier`、`--show-all-sources`、`--no-update-check`、`--foreground`、`--extra`（再起一个实例，该实例不写 `state.json`）。

---

## 常见问题 (FAQ)

| 问题 | 答案 |
|---|---|
| `awake snapshot` 退出码 2，提示 `build` | 二进制还没编译过。运行 `awake build` 一次即可；`snapshot` 故意不替你编译，避免一次查询变成 30 秒的编译。 |
| `snapshot` 为什么要 0.3 秒？ | 网速、磁盘、换页、DRAM 总线带宽、神经引擎功耗都是「两次采样之差」，必须等待约 200ms 的物理采样窗口。放电电流等则是即时读数。 |
| 菜单里某个读数源不见了 | 本机读不到该硬件（如 Intel 无带宽 / 神经引擎、台式机无电池、Air 无风扇），自动隐藏。 |
| Keep Awake 显示 Off，但 Mac 就是不睡 | 看 `Keep Awake ▸` 最上方的整机状态行和底部 `Other Assertions`，会列出其他持有睡眠断言的进程。可用 `pmset -g assertions` 交叉核对。 |
| Keep Awake 自己暂停了 | 菜单 `Keep Awake` 行会显示 `(paused)`，子菜单写明原因：电量低、电量 ≤ 5%，或机器过热。条件解除后自动恢复。 |
| 合盖后还是睡了 | 电池供电合盖无法用无特权方式阻止。接电源 + 外接显示器才能合盖运行。本应用不会用 `pmset disablesleep` 改系统策略。 |
| 动图不动了 | 开启了系统「减弱动态效果」（此时状态栏自动改显示数值），或图标被刘海 / 全屏应用挡住（被挡时完全停止渲染，0% CPU）。 |
| 动图突然变慢了 | 热压力、低电量模式或内存压力下，应用会把自己的动画速度上限减半；菜单出现 `Slowing animation — <原因>`。 |
| 它会联网吗？ | 只有启动时和点 `Check for Updates…` 时用 `git ls-remote` 查一次版本标签。可用 `--no-update-check` 关闭。 |
| 怎么停止？ | 菜单 `Exit`，或 `pkill -f CoAwake`。后台运行的日志在 `/tmp/co-awake.log`。 |
| 读数和活动监视器对不上 | CPU 有短时间移动平均；网速 / 磁盘是采样窗口内的平均速率。口径不同，量级应一致。 |
| 能不能加进程排行 / 每传感器温度列表？ | 不在范围内。进程用 `ps` / `top`，详细传感器用 [stats](https://github.com/exelban/stats)。理由见 ARCHITECTURE §4.10。 |

---

## 附录：自然语言话术速查

| 场景 | 你可以说 | Agent 的动作 |
|---|---|---|
| 推理前体检 | 「准备跑本地大模型，机器带得动吗？」 | `awake snapshot`，读 `bw_gbps` / `memory_pressure` / `swap_mibs` / `thermal` |
| 发热定因 | 「怎么这么烫？风扇在转吗？谁吃满了？」 | `awake snapshot` 定资源类别 + `ps -Ao pid,pcpu,pmem,comm -r` 定进程 |
| 长任务防睡 | 「这个测试要跑一小时，别让电脑睡」 | `caffeinate -i -w <pid>`（或 `-di`，见场景 3） |
| 人离开工位 | （Option-click 状态栏图标） | — |
| 定时防睡 | 「让电脑保持 2 小时不睡」 | `awake --keep-awake 2h` |
| 有没有在防睡 | 「现在有东西挡着睡眠吗？」 | `awake status`；要看别的进程用 `pmset -g assertions` |
| 换外观 | 「换成黑色龙猫，显示内存数值」 | `awake --preset totoro-black --display value --load-source memory` |
| 电池 | 「电池健康吗？循环几次了？」 | `awake snapshot`，读 `battery_health_pct` / `battery_cycles` / `battery_a` |

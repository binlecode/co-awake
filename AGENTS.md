# CLAUDE.md / AGENTS.md

Shared guidance for Claude Code and coding agents working in this repository.
`AGENTS.md` 与 `CLAUDE.md` 互为符号链接，保持单一正本。
给模型读的规矩在这里；给人读的文档在 `README.md` 与 `docs/`。

> 业务概览与用户交互见 `README.md`；架构正本见 `docs/ARCHITECTURE.md`（§0 路由、§4 遥测源、§8 启动与生命周期）；排期认 `docs/ROADMAP.md`。

---

## ⚠️ 关键陷阱与不可逾越红线（开工必看）

违反以下硬底线会导致进程崩溃、构建并发冲突、或破坏核心安全模型：

1. 🔴 **单文件无包架构（Unbundled Swift）**：业务逻辑集中于 `CoAwake.swift`，零外部依赖，由 `swiftc -O -strict-concurrency=complete` 编译；绝不引入 Xcode 项目、SwiftPM (`Package.swift`) 或 CocoaPods。类均标注 `@MainActor`，构建保持零警告。
2. 🔴 **原子重命名编译（Atomic Rename）**：启动器 `build` 必须先编译至临时路径再通过 `mv`（`rename(2)`）原子替换目标二进制；严禁原地覆盖 Mach-O 文件，否则破坏运行中进程的内存分页导致当场崩溃。
3. 🔴 **单例分流与探测（Singleton Guard）**：`start` 路径的单例探测（`pgrep -U "$(id -u)"`）必须严格在 `compile_if_stale` 之前执行；`build` 与只读查询（`snapshot`/`status`/`presets`/`--help`）按 `docs/ARCHITECTURE.md` §2 直接分流，不参与单例互斥。
4. 🔴 **零 Mock 真实驱动测试（Zero Mocks / Real Binary Assertions）**：`tests/qa.sh` 是唯一测试套件，必须驱动真实二进制检验副作用；严禁在测试中复制业务代码类型；只允许使用无侵入环境变量（详见 `docs/ARCHITECTURE.md` §11.3）：
   - `FORCE_THERMAL` 仅供显示层，**严禁回流自限流与功耗判定**；
   - `LOG_*` 只允许读取并打印，**严禁回写被测状态**；
   - 手动 GUI 验证必须指定独立 `CO_AWAKE_STATE_FILE`，严禁污染真实用户配置。
5. 🔴 **无特权只读遥测与纯用户态（Unprivileged & Read-Only）**：遥测仅限公开或无特权的 Mach / IOKit / SMC 接口，严禁请求 root，严禁通过 `pmset` 篡改系统全局电源配置；Keep Awake 仅通过绑定自身 PID 的 `caffeinate -di -w <pid>` 实现，保证异常退出时内核自动回收。
6. 🔴 **5% 硬件电池底线不可逾越**：电量 ≤ 5% 时强制释放 Keep Awake，任何 CLI 参数、状态恢复或菜单操作均严禁绕过此硬底线。
7. 🔴 **状态持久化单写者模型**：`state.json` 只能由 `persistState()` 统一驱动，禁止在局部 observer 或高频采样循环中自行写盘。
8. 🔴 **动词 CLI 与单一输出契约**：首参只放动词（`start`·`status`·`snapshot`·`presets`·`build`）；输出只有一份 Schema，字段自带物理单位，缺读数一律缺键（不补 0 或 null）；严禁新增兼容别名或双前缀回退。
9. 🔴 **脚本兼容性**：启动器与周边脚本必须严格保证 `/bin/bash` 3.2 与 macOS 原生 `/bin/zsh` 兼容性。

---

## 🔴 第一条：不要自作聪明

**有疑问或做技术选型时，严格按两步执行，顺序不可颠倒：**

1. **先 grounding** —— 查真实代码（`CoAwake.swift`、`awake`）、核查真实运行输出与可观测性探针（`CO_AWAKE_EXIT_AFTER`, `LOG_*`），深入代码实现与真实终端输出，**严禁凭空假设向下推演**。
2. **再确认** —— 严禁静默新增/废弃 CLI 参数、修改 `state.json` 数据结构、私自放宽安全门控或重新解释既有设计。若实测推翻了前提，如实报送发现并提问，**不要自行改动设计范围或重排优先级**。
3. **测试纪律** —— 临时文件必须入 `tmp/`；环境无法测定时输出 NOTE，绝不谎称覆盖或造假 PASS。

---

## 常用命令速查

```bash
# 启动与运行（首参是动词，缺省即 start；start 幂等）
./awake                          # start：后台脱离终端运行
./awake --foreground             # 前台运行（查看 stderr / print 输出）；已有实例时报错
./awake snapshot                 # 单行 JSON 快照（物理单位），随即退出；无 GUI / 无 state.json / 无编译
./awake status                   # 单行 JSON：是否有常驻实例、Keep Awake 状态
./awake presets                  # 单行 JSON：内置预设
./awake --help                   # 唯一 help 由二进制生成，不列预设

# 编译与无启动检查
./awake build                    # 仅当源码较新时原子编译，不启动（保持运行实例不损坏）
swiftc -O -strict-concurrency=complete CoAwake.swift -o tmp/coaware-check  # 快速编译检查

# 自动化测试门禁
tests/qa.sh --core               # 核心门禁（CI 友好，不依赖 WindowServer，秒级）
tests/qa.sh                      # 全量回归测试（需要活跃 WindowServer / GUI 会话）
tests/qa.sh --launcher           # 破坏性测试（需所有者明确授权，会 pkill 正在运行的实例）

# 常用调试钩子（无侵入可观测性，参数全集见 docs/ARCHITECTURE.md §11.3）
CO_AWAKE_EXIT_AFTER=5 ./tmp/coaware-check --load-source memory           # 运行 5s 自行退出
CO_AWAKE_FORCE_BATTERY=15:battery ./tmp/coaware-check --keep-awake 30m   # 模拟低电量
CO_AWAKE_FORCE_THERMAL=serious ./tmp/coaware-check --load-source temperature # 模拟内核热等级（仅限显示）
CO_AWAKE_LOG_ASSERTIONS=1 ./tmp/coaware-check 2>&1 | grep ASSERTIONS     # 嗅探外部睡眠断言
```

---

## 文档分工与生命周期

- **路由正本**：全文档唯一正本路由在 `docs/ARCHITECTURE.md` §0。未决候选议题认 `docs/ROADMAP.md`。
- **现行态唯一性**：文档只记录现行态机制与 why，严禁保留已删除特性的历史墓碑；变更史留给 git 与 `CHANGELOG.md`。
- **ADLC 闭环**：单项特性草案使用 `docs/PLAN-<topic>.md`，主体完成并蒸馏入 `docs/ARCHITECTURE.md` 后当场 `git rm` 删除。

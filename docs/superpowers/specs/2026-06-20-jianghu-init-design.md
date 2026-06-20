# jianghu 项目初始化 — 设计文档（Spec）

| 字段 | 值 |
|------|-----|
| 主题 | jianghu 项目初始化（CCGS 框架 + Godot 4.6 工程骨架 + iOS） |
| 日期 | 2026-06-20 |
| 状态 | 已实现（2026-06-20，commit cd8b4d9 截止） |
| 作者 | Claude Code（与用户协作） |

---

## 1. 背景与目标

`/Users/zhouwei/PersonalProjects/jianghu` 当前是**空目录**（非 git 仓库）。用户要把它初始化为一个
**武侠题材的 Godot 移动端 iOS 游戏**项目，并以
[Claude-Code-Game-Studios（CCGS）](https://github.com/Donchitos/Claude-Code-Game-Studios)
为参考脚手架。

**本次目标（范围内）**：把空目录立成一个**基于 CCGS 的 Claude Code 游戏工作室仓库**，并针对
**2D / 横屏 / GDScript / iOS / Godot 4.6** 配置就绪，包含一个**真正能在 Godot 里打开、能运行、能
iOS 导出**的工程骨架，以及一份 jianghu 专属的 `CLAUDE.md`。

**非目标（本次不做，留待后续）**：游戏玩法设计本体（品类/核心循环/GDD）——脚手架就绪后用 `/start` 走；
真实美术音频资源；iOS 真实签名与 Apple Team ID；安装 Godot iOS export templates（会文档化，按需再装）。

> 说明：CCGS 本身不是游戏，而是"把单个 Claude Code 会话变成游戏工作室"的模板（agents/skills/hooks/
> rules/文档模板）。因此本次初始化 ≈ **替用户跑完 `/setup-engine godot 4.6` 的等价配置 + 额外建出真正的
> Godot 工程文件**（后者 CCGS 不含）。

## 2. 环境事实（已核对）

| 项 | 值 |
|----|-----|
| 本机 Godot | 4.6.3 stable（`/opt/homebrew/bin/godot` + `/Applications/Godot.app`），与 CCGS pin 的 4.6 一致 |
| Xcode | 26.5（iOS 导出/构建链可用） |
| 工具 | git 2.51、jq、python3 均可用 |
| CCGS 引擎参考 | `docs/engine-reference/godot/` 已是 4.6 快照 |
| CCGS `.gitignore` | 已含 Godot 段（`.godot/`、`*.translation`），但默认忽略 `export_presets.cfg`（本次将改为入库） |

## 3. 已确认决策

| # | 决策 | 取值 |
|---|------|------|
| 1 | 渲染维度 | **2D**（Mobile 渲染后端） |
| 2 | 屏幕方向 | **横屏 Landscape**（基准 1920×1080） |
| 3 | 脚本语言 | **GDScript** |
| 4 | 引擎版本 | Godot **4.6**（pinned，本机 4.6.3） |
| 5 | 目标平台 | iOS（移动端，触控） |
| 6 | bundle id | `com.microboat.jianghu`（占位，可改） |
| 7 | CCGS 模板元文件 | **全部保留**（不裁 Testing Framework / UPGRADING / CONTRIBUTING / SECURITY / .github / README） |
| 8 | `export_presets.cfg` | **入库**（仅占位，不含签名密钥） |

## 4. 组件设计

### 4.1 CCGS 框架导入（裁剪版）

从 CCGS 模板复制进 jianghu，仅裁剪**与 Godot 无关的引擎 agent**，其余全部保留：

- **保留**：`.claude/`（agents / skills / hooks / rules / docs / settings.json / statusline.sh）、
  `docs/`（含 `engine-reference/godot/` 4.6 快照、架构与流程文档）、`design/`、`production/`、`src/`；
  并补建 CCGS 目录约定里缺失的 `assets/`、`tests/`、`tools/`、`prototypes/`（各放 `.gitkeep`）。
- **保留**（按决策 7）：`CCGS Skill Testing Framework/`、`UPGRADING.md`、`CONTRIBUTING.md`、
  `SECURITY.md`、`LICENSE`、`.github/`、CCGS 版 `README.md`。
- **裁掉的引擎 agent（共 12 个）**：
  - Unity（5）：`unity-specialist`、`unity-dots-specialist`、`unity-shader-specialist`、
    `unity-addressables-specialist`、`unity-ui-specialist`
  - Unreal（5）：`unreal-specialist`、`ue-blueprint-specialist`、`ue-gas-specialist`、
    `ue-replication-specialist`、`ue-umg-specialist`
  - Godot 非选用语言（2）：`godot-csharp-specialist`、`godot-gdextension-specialist`
- **保留的 Godot agent（3 个）**：`godot-specialist`、`godot-gdscript-specialist`、`godot-shader-specialist`。
- agent 总数：49 → **37**。
- **裁剪后处理悬挂引用**：检查并清理 `README.md`、`.claude/docs/agent-roster.md`、
  `agent-coordination-map.md` 等对已删 agent 的引用（避免文档指向不存在的 agent）。

### 4.2 Godot 工程骨架（2D / 横屏 / GDScript / Mobile 渲染）

- **工程根 = 仓库根**：`project.godot` 放仓库根目录，贴合 CCGS 的 `src/ assets/` 布局。
- `project.godot` 关键配置：
  - 应用名 `江湖`，主场景 `res://src/main.tscn`；
  - **Mobile 渲染后端**（`rendering/renderer/rendering_method="mobile"`）；
  - 视口 **1920×1080**，拉伸 `canvas_items` / `expand`；
  - `display/window/handheld/orientation` = 横屏；触控触发鼠标仿真开。
- **最小可跑场景** `src/main.tscn`：根 `Node2D` + 居中 `Label`（显示「江湖 / Jianghu」），
  挂 `src/main.gd`（`_ready()` 打印引擎版本，验证可运行）。
- 占位图标 `icon.svg`（Godot 默认）。
- **验证手段**：建完后用 `godot --headless --quit` 实际打开一次，让引擎规范化 `project.godot`
  并生成 `.godot/` 导入缓存，确认无解析错误（不依赖手写 .ini 一次蒙对）。

### 4.3 iOS 导出配置

- `export_presets.cfg` 写一个 iOS 预设：bundle id `com.microboat.jianghu`、显示名「江湖」、横屏方向。
- **调整 `.gitignore`**：移除对 `export_presets.cfg` 的忽略，使工程配置入库（决策 8）。
- 文档化 iOS 构建流程（写入 `CLAUDE.md` + 一处 docs）：
  1. 安装 iOS export templates（编辑器 → Manage Export Templates，或 `godot --install-templates`）；
  2. 填入 Apple Team ID / bundle id；
  3. 导出 Xcode 工程或 `.ipa`：`godot --headless --export-debug "iOS" build/jianghu.ipa`；
  4. 用 Xcode / `xcodebuild` 签名打包。
- 真实签名、Team ID、provisioning **由用户填**，不在本次。

### 4.4 jianghu 版 `CLAUDE.md`（同时即 `/init` 产出物）

在 CCGS 的 `CLAUDE.md` 基础上填实：

- **Technology Stack**：引擎 Godot 4.6（pinned）、语言 GDScript、渲染 Mobile、2D、平台 iOS/移动端、
  输入触控、方向横屏；
- **构建/运行/导出/测试命令**段（见第 6 节"常用命令"）；
- 保留 CCGS 的协作协议（Question → Options → Decision → Draft → Approval）与各 `@`-include；
- **顶部加一条**：全程简体中文回复（见 4.6，确保全局生效，不依赖 rule 触发）。
- 同步把 `.claude/docs/technical-preferences.md` 按上述选择填好（等价于 `/setup-engine` 产出）：
  Minimum Coverage = 95%（整库行覆盖，含 UI）、Testing Framework = gdUnit4（默认，`/test-setup` 时可改）。

### 4.5 Git 初始化

- 当前非 git 仓库 → `git init`（默认分支 `main`）。
- 使用 CCGS 的 `.gitignore` + 决策 8 的 `export_presets.cfg` 调整。
- 提交顺序：**首个 commit = 本 spec 文档**；随后按实现计划分步提交脚手架。
- commit message 遵循 CCGS 的 Conventional Commits 约定（`feat:`/`chore:`/`docs:` 等）。

### 4.6 新增项目规则（写入 `.claude/rules/`）

按用户要求新增三条约束。`.claude/rules/` 为 `paths:` glob 路径触发的 markdown 规则。

**(a) `.claude/rules/language-zh.md`（新建，`paths: ["**"]`）**
- 交流：**全程简体中文回复**（同时在 `CLAUDE.md` 顶部冗余声明，确保不依赖 rule 触发即生效）。
- 注释：**必须用简体中文**；**言之有物、言简意赅**；说清"**是什么 + 为什么**"；
  禁止复述代码的废话注释。

**(b) `.claude/rules/test-standards.md`（编辑既有文件，追加）**
- **每次代码改动必须伴随测试**（新功能测试 + bug 修复回归测试）。
- **覆盖率门槛：整库 GDScript 行覆盖率必须 > 95%**（用户决定，**含 UI**），低于即视为未完成（BLOCKING）。
  - 含义：所有 `.gd` 脚本（玩法/AI/状态机/工具，以及 UI 控制器/HUD/菜单等的脚本逻辑）都须被测试覆盖；
    自动化测的是**代码行**，不是像素。视觉保真与手感仍按 CCGS 用截图 / playtest 另行验证（两者并存，不互斥）。
  - 已知代价：UI/集成层需要更多自动化测试，脆弱性更高、维护成本更高；具体测试框架与覆盖率工具在
    `/test-setup` 阶段落地（见第 8 节）。
- 同步在 `.claude/docs/coding-standards.md` 的 Testing Standards 与 `technical-preferences.md`
  反映"整库 95%"门槛。

## 5. 目标目录结构（初始化后）

```text
jianghu/
├── CLAUDE.md                  # jianghu 主配置（含中文回复声明、Godot/iOS 技术栈、命令）
├── project.godot              # Godot 4.6 工程（2D / 横屏 / Mobile 渲染）
├── export_presets.cfg         # iOS 导出预设（入库，占位 bundle id）
├── icon.svg                   # 占位图标
├── .gitignore                 # CCGS 版（已含 Godot；移除 export_presets.cfg 忽略）
├── .claude/                   # agents(37) / skills(73) / hooks(12) / rules(12) / docs / settings.json
├── src/                       # 游戏源码（main.tscn / main.gd 骨架 + core/gameplay/ai/ui/...）
├── assets/                    # 美术/音频/数据（.gitkeep）
├── design/                    # GDD / 叙事 / 关卡（待 /start 填）
├── docs/                      # 技术文档 + engine-reference/godot(4.6) + superpowers/specs/
├── tests/                     # 测试套件（.gitkeep，/test-setup 时落框架）
├── tools/                     # 构建/管线工具（.gitkeep）
├── prototypes/                # 原型隔离区（.gitkeep）
├── production/                # sprint/里程碑/会话状态
├── CCGS Skill Testing Framework/ # CCGS 模板自带（保留）
├── README.md / LICENSE / CONTRIBUTING.md / SECURITY.md / UPGRADING.md  # CCGS 元文件（保留）
└── .github/                   # CCGS 元文件（保留）
```

## 6. 常用命令（写入 CLAUDE.md）

```bash
# 运行（编辑器内）
godot --path . --editor

# 无头运行/冒烟
godot --headless --quit                       # 打开并规范化工程，验证可解析
godot --path . res://src/main.tscn            # 直接跑主场景

# 测试（框架在 /test-setup 落地后；默认 gdUnit4）
godot --headless --script tests/gdunit4_runner.gd

# iOS 导出（需先装 export templates、填 Team ID）
godot --headless --export-debug "iOS" build/jianghu.ipa
```

## 7. 验收标准

1. `godot --headless --quit` 在仓库根成功打开工程，**无解析/导入错误**。
2. 主场景 `src/main.tscn` 可运行，`main.gd` 正确打印引擎版本。
3. `.claude/agents/` 中**不存在** Unity/Unreal/`godot-csharp`/`godot-gdextension` agent；
   保留 3 个 Godot agent；无文档悬挂引用。
4. `.claude/rules/` 含 `language-zh.md`，`test-standards.md` 含 >95% 覆盖率门槛；
   `CLAUDE.md` 顶部含中文回复声明。
5. `export_presets.cfg` 已入库且**不被** `.gitignore` 忽略。
6. `git log` 显示首个 commit 为本 spec，后续为脚手架提交；工作区干净。
7. `CLAUDE.md` 技术栈、命令、协作协议齐全，`@`-include 路径均可解析。

## 8. 风险与开放问题

- **iOS export templates 未安装**：导出命令在装模板前会失败。本次仅写预设 + 文档；按需再装。
- **GDScript 覆盖率工具**：Godot 无原生行覆盖统计，gdUnit4 需配合覆盖率插件/方案；具体工具在
  `/test-setup` 阶段确定。门槛策略先立，工具后落。
- **覆盖率范围（已定）**：用户选定**整库 >95%**（含 UI）。需在 `/test-setup` 阶段为 UI/集成层引入
  自动化测试方案，并接受其维护成本与脆弱性；视觉/手感仍用截图 + playtest 并行验证。
- **bundle id / 应用名为占位**：上架前需替换为真实值。

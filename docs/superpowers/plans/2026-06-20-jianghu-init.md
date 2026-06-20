# jianghu 项目初始化 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: 用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 按任务逐步实现本计划。步骤用 `- [ ]` 复选框跟踪。

**Goal:** 把空目录初始化为基于 CCGS 的 Claude Code 游戏工作室仓库，配好 Godot 4.6 / 2D / 横屏 / GDScript / iOS，并含一个可运行、可 iOS 导出的工程骨架与 jianghu 专属 CLAUDE.md。

**Architecture:** 以 CCGS 模板为基底 rsync 导入 → 裁掉非 Godot 引擎 agent → 叠加真正的 Godot 工程文件 → 把"待配置"的模板字段填成 jianghu 的技术栈 → 追加中文/覆盖率规则 → iOS 导出预设。每个任务产出一个可独立验证、可独立提交的交付物。

**Tech Stack:** Godot 4.6.3 (本机)、GDScript、Mobile 渲染、git、Xcode 26.5（iOS）。

## Global Constraints

> 每个任务都隐含遵守本节（数值逐字摘自 spec `docs/superpowers/specs/2026-06-20-jianghu-init-design.md`）。

- 引擎 **Godot 4.6**（本机 4.6.3 stable），语言 **GDScript**，渲染 **Mobile**，**2D**，平台 **iOS（移动端/触控）**，**横屏** 基准 **1920×1080**。
- **全程简体中文回复**；**注释必须用简体中文**、言之有物、言简意赅、说清"是什么+为什么"，禁止复述代码的废话注释。
- **代码必须伴随测试**；**整库 GDScript 行覆盖率 > 95%（含 UI）**，低于即视为未完成（BLOCKING）。测试框架与覆盖率工具在后续 `/test-setup` 落地（本次仅立规则与门槛）。
- bundle id = `com.microboat.jianghu`（占位，可改）；应用名 `江湖`。
- **保留** CCGS 全部模板元文件（README/LICENSE/CONTRIBUTING/SECURITY/UPGRADING/.github/`CCGS Skill Testing Framework/`）。
- **裁掉** 12 个非 Godot 引擎 agent；**保留** 3 个 Godot agent（`godot-specialist`、`godot-gdscript-specialist`、`godot-shader-specialist`）。
- `export_presets.cfg` **入库**。
- 工程根 = 仓库根（`project.godot` 放仓库根）。
- commit 用 Conventional Commits（`feat:`/`chore:`/`docs:`/`test:` …），message 用中文正文。
- **bootstrap 例外（已记录）**：`src/main.gd` 是临时引导桩，用 headless 运行验证（非单元测试）；>95% 覆盖率门槛适用于 `/test-setup` 之后实现的游戏系统代码。

> ⚠️ **执行环境提示**：本计划会写入 `.claude/settings.json`（含 PreToolUse/SessionStart 钩子）。这些钩子通常在**会话启动时**加载，会话中途新建一般不立即生效；若在新会话/子代理中执行，提交时 `validate-commit.sh` 可能对 commit message/暂存内容做检查——把钩子输出当作反馈处理即可，不要绕过。

---

## 文件结构图（本计划将创建/修改）

**新建（Godot 工程 + 规则 + 文档）**
- `project.godot` — Godot 4.6 工程配置（2D/横屏/Mobile）
- `src/main.gd` — 引导桩脚本（打印引擎版本）
- `src/main.tscn` — 主场景（Node2D + 居中 Label）
- `icon.svg` — 占位图标（自绘，避免 Godot 商标）
- `icon.svg.import` / `src/main.gd.uid` — Godot 导入生成物（入库）
- `export_presets.cfg` — iOS 导出预设（入库）
- `.claude/rules/language-zh.md` — 中文回复 + 中文注释规则
- `docs/build/ios-export.md` — iOS 构建流程文档

**修改（来自 CCGS，导入后改写）**
- `CLAUDE.md` — 顶部加中文回复声明；填实 Technology Stack；加 Commands 段
- `.claude/docs/technical-preferences.md` — 填 jianghu 技术栈/命名/性能/测试
- `.claude/rules/test-standards.md` — 追加 >95% 整库覆盖率门槛 + 每改动必带测试
- `.claude/docs/coding-standards.md` — Testing Standards 反映 95% 门槛
- `.claude/docs/rules-reference.md` — 增加 `language-zh.md` 行
- `.claude/docs/agent-roster.md` / `agent-coordination-map.md` — 删除已裁 agent 的条目
- `.gitignore` — 移除对 `export_presets.cfg` 的忽略

**删除（裁剪 12 个引擎 agent）**
- `.claude/agents/{unity-specialist,unity-dots-specialist,unity-shader-specialist,unity-addressables-specialist,unity-ui-specialist}.md`
- `.claude/agents/{unreal-specialist,ue-blueprint-specialist,ue-gas-specialist,ue-replication-specialist,ue-umg-specialist}.md`
- `.claude/agents/{godot-csharp-specialist,godot-gdextension-specialist}.md`

---

## Task 1: 导入 CCGS 框架并补全目录骨架

**Files:**
- 复制：CCGS 模板全部内容（除 `.git`）→ 仓库根
- 创建：`assets/.gitkeep`、`tests/.gitkeep`、`tools/.gitkeep`、`prototypes/.gitkeep`

**Interfaces:**
- Produces：`.claude/`（agents/skills/hooks/rules/docs/settings.json）、`docs/`（含 `engine-reference/godot/`）、`design/`、`production/`、`src/`、CCGS 元文件、`.gitignore`、`CLAUDE.md`（CCGS 原版，待 Task 4 改写）。后续任务都在此基础上修改。

- [ ] **Step 1: 确保 CCGS 模板就绪**

```bash
test -d /tmp/jianghu-ref/.claude || git clone --depth 1 https://github.com/Donchitos/Claude-Code-Game-Studios.git /tmp/jianghu-ref
ls /tmp/jianghu-ref/.claude/agents | wc -l   # 期望 49
```
Expected: 输出 `49`

- [ ] **Step 2: rsync 导入（排除 .git，合并而非覆盖 docs/superpowers）**

```bash
rsync -a --exclude='.git' /tmp/jianghu-ref/ /Users/zhouwei/PersonalProjects/jianghu/
```
说明：无 `--delete`，会与既有 `docs/superpowers/`（spec/plan）合并，不会删除它们。

- [ ] **Step 3: 补建 CCGS 目录约定里缺失的目录**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu
for d in assets tests tools prototypes; do mkdir -p "$d" && touch "$d/.gitkeep"; done
```

- [ ] **Step 4: 验证导入结果**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu
ls .claude/agents | wc -l                       # 期望 49（尚未裁剪）
ls -d .claude docs design production src assets tests tools prototypes
test -f .gitignore && test -f CLAUDE.md && test -d ".claude/skills" && echo OK
test -f docs/superpowers/specs/2026-06-20-jianghu-init-design.md && echo "spec 仍在"
```
Expected: `49`；所有目录存在；`OK`；`spec 仍在`

- [ ] **Step 5: 提交**

```bash
git add -A
git commit -m "chore: 导入 CCGS 游戏工作室框架并补全目录骨架

rsync 导入 CCGS 模板（agents/skills/hooks/rules/docs/templates），
补建 assets/tests/tools/prototypes 目录占位。

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: 裁剪非 Godot 引擎 agent 并清理花名册

**Files:**
- Delete: 上述 12 个 agent `.md`
- Modify: `.claude/docs/agent-roster.md`、`.claude/docs/agent-coordination-map.md`

**Interfaces:**
- Consumes：Task 1 导入的 `.claude/agents/`（49 个）、两份运营花名册文档。
- Produces：`.claude/agents/` 仅余 37 个；花名册不再列出已删 agent。后续工作室协作据此委派。

- [ ] **Step 1: 删除 12 个引擎 agent 文件**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu/.claude/agents
rm unity-specialist.md unity-dots-specialist.md unity-shader-specialist.md \
   unity-addressables-specialist.md unity-ui-specialist.md \
   unreal-specialist.md ue-blueprint-specialist.md ue-gas-specialist.md \
   ue-replication-specialist.md ue-umg-specialist.md \
   godot-csharp-specialist.md godot-gdextension-specialist.md
cd /Users/zhouwei/PersonalProjects/jianghu
ls .claude/agents | wc -l    # 期望 37
```
Expected: `37`

- [ ] **Step 2: 清理 `agent-roster.md`** —— 删除以下整行/整段（按精确字符串匹配）

删除"Engine Leads"表里这两行：
```
| `unreal-specialist` | Unreal Engine 5 | Sonnet | Blueprint vs C++, GAS overview, UE subsystems, Unreal optimization |
| `unity-specialist` | Unity | Sonnet | MonoBehaviour vs DOTS, Addressables, URP/HDRP, Unity optimization |
```
删除整段"### Unreal Engine Sub-Specialists"（含标题、表头、4 行 `ue-*`，直到下一个 `###` 之前的空行）。
删除整段"### Unity Sub-Specialists"（含标题、表头、4 行 `unity-*`，直到下一个 `###` 之前）。
在"### Godot Sub-Specialists"表里删除这两行：
```
| `godot-csharp-specialist` | C# / .NET | Sonnet | .NET patterns, [Signal] delegates, async, nullable types, type-safe node access |
| `godot-gdextension-specialist` | GDExtension | Sonnet | C++/Rust bindings, native performance, custom nodes, build systems |
```

- [ ] **Step 3: 清理 `agent-coordination-map.md`** —— 删除以下整块（精确匹配）

删除 Unreal 块（5 行）：
```
    unreal-specialist  -- UE5 lead: Blueprint/C++, GAS overview, UE subsystems
      ue-gas-specialist         -- GAS: abilities, effects, attributes, tags, prediction
      ue-blueprint-specialist   -- Blueprint: BP/C++ boundary, graph standards, optimization
      ue-replication-specialist -- Networking: replication, RPCs, prediction, bandwidth
      ue-umg-specialist         -- UI: UMG, CommonUI, widget hierarchy, data binding
```
删除 Unity 块（5 行 + 其上空行）：
```
    unity-specialist   -- Unity lead: MonoBehaviour/DOTS, Addressables, URP/HDRP
      unity-dots-specialist         -- DOTS/ECS: Jobs, Burst, hybrid renderer
      unity-shader-specialist       -- Shaders: Shader Graph, VFX Graph, SRP customization
      unity-addressables-specialist -- Assets: async loading, bundles, memory, CDN
      unity-ui-specialist           -- UI: UI Toolkit, UGUI, UXML/USS, data binding
```
在 Godot 块里删除这两行：
```
      godot-csharp-specialist      -- C#: .NET patterns, [Signal] delegates, async, type-safe node access
      godot-gdextension-specialist -- Native: C++/Rust bindings, GDExtension, build systems
```

- [ ] **Step 4: 验证无悬挂引用（仅运营花名册）**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu
grep -nE "unity-|unreal-|ue-gas|ue-blueprint|ue-replication|ue-umg|godot-csharp|godot-gdextension" \
  .claude/docs/agent-roster.md .claude/docs/agent-coordination-map.md || echo "运营花名册已无悬挂引用 OK"
ls .claude/agents | grep -E "godot-(specialist|gdscript|shader)" | wc -l   # 期望 3
```
Expected: `运营花名册已无悬挂引用 OK`；`3`
说明：`setup-engine`/`brainstorm`/`test-setup` 等 skill 仍按多引擎通用逻辑提到引擎名，属设计内行为，**不清理**。

- [ ] **Step 5: 提交**

```bash
git add -A
git commit -m "chore: 裁剪 Unity/Unreal 及 godot-csharp/gdextension 引擎 agent

仅保留 Godot+GDScript 相关 3 个引擎 agent（specialist/gdscript/shader），
同步清理 agent-roster 与 agent-coordination-map 中的悬挂引用。agent 49→37。

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Godot 工程骨架（可运行）

**Files:**
- Create: `project.godot`、`src/main.gd`、`src/main.tscn`、`icon.svg`
- Generated（入库）：`icon.svg.import`、`src/main.gd.uid`

**Interfaces:**
- Produces：`res://src/main.tscn` 为主场景；`Main`(Node2D) 挂 `src/main.gd`，`_ready()` 打印引擎版本。后续 UI/玩法场景挂到此结构下。

- [ ] **Step 1: 写 `project.godot`**（键名已用本机 4.6.3 实证可解析）

```ini
config_version=5

[application]

config/name="江湖"
config/description="武侠题材 2D 横屏 iOS 手游"
run/main_scene="res://src/main.tscn"
config/icon="res://icon.svg"

[display]

window/size/viewport_width=1920
window/size/viewport_height=1080
window/handheld/orientation="landscape"
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[input_devices]

pointing/emulate_mouse_from_touch=true

[rendering]

renderer/rendering_method="mobile"
renderer/rendering_method.mobile="mobile"
```

- [ ] **Step 2: 写 `icon.svg`**（自绘极简占位图标，含"江"字）

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><rect width="128" height="128" rx="24" fill="#2b2b3a"/><text x="64" y="92" font-size="84" text-anchor="middle" fill="#e8c07d" font-family="serif">江</text></svg>
```

- [ ] **Step 3: 写 `src/main.gd`**（注释用中文，说清是什么+为什么；缩进用 Tab）

```gdscript
extends Node2D
## 游戏入口引导桩。
## 作用：作为主场景根脚本，启动时打印引擎版本，用于验证工程可正常加载运行。
## 注意：这是初始化期的临时桩，真正的游戏流程在 /start 设计后接入，届时替换本文件。

func _ready() -> void:
	# 打印引擎版本，证明工程已被引擎正确加载（headless 与真机一致）
	print("江湖 启动，Godot 引擎版本：", Engine.get_version_info().string)
```

- [ ] **Step 4: 写 `src/main.tscn`**（Node2D + 居中 Label，挂脚本）

```ini
[gd_scene load_steps=2 format=3 uid="uid://bjianghumain00"]

[ext_resource type="Script" path="res://src/main.gd" id="1"]

[node name="Main" type="Node2D"]
script = ExtResource("1")

[node name="Title" type="Label" parent="."]
offset_left = 760.0
offset_top = 480.0
offset_right = 1160.0
offset_bottom = 600.0
text = "江湖 / Jianghu"
horizontal_alignment = 1
vertical_alignment = 1
```

- [ ] **Step 5: 导入并验证可解析（生成 .import/.uid/.godot）**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu
/opt/homebrew/bin/godot --headless --path . --import 2>&1 | tail -5
test -f icon.svg.import && test -f src/main.gd.uid && echo "导入生成物 OK"
```
Expected: 导入日志无 ERROR；`导入生成物 OK`

- [ ] **Step 6: 运行主场景，验证打印**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu
/opt/homebrew/bin/godot --headless --path . --quit-after 5 2>&1 | grep "江湖 启动"
```
Expected: 输出 `江湖 启动，Godot 引擎版本：4.6.3-stable (official)`

- [ ] **Step 7: 确认 .godot/ 被忽略，提交工程文件**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu
git check-ignore .godot/ && echo ".godot 已忽略 OK"
git add project.godot icon.svg icon.svg.import src/main.gd src/main.gd.uid src/main.tscn
git status -s
git commit -m "feat: 添加 Godot 4.6 工程骨架（2D/横屏/Mobile）

project.godot 配置 Mobile 渲染、1920x1080 横屏、触控仿真；
main 场景打印引擎版本作为可运行性验证桩。

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```
Expected: `.godot 已忽略 OK`；暂存区不含 `.godot/`

---

## Task 4: 配置技术栈到 CLAUDE.md 与 technical-preferences.md

**Files:**
- Modify: `CLAUDE.md`、`.claude/docs/technical-preferences.md`

**Interfaces:**
- Consumes：Task 1 导入的 CCGS `CLAUDE.md`（含 `[CHOOSE]` 占位）与 `technical-preferences.md`（含 `[TO BE CONFIGURED]`）。
- Produces：填实后的技术栈与命令，供全体 agent/skill 读取。

- [ ] **Step 1: CLAUDE.md 顶部加中文回复声明**

把 `CLAUDE.md` 第 1 行 `# Claude Code Game Studios -- Game Studio Agent Architecture` 之后紧接插入：

```markdown

> **语言约定（最高优先级）**：本项目全程使用**简体中文**回复用户；代码注释一律用简体中文，且言之有物、言简意赅、说清"是什么 + 为什么"。详见 `.claude/rules/language-zh.md`。
```

- [ ] **Step 2: 替换 Technology Stack 段**

把 `CLAUDE.md` 中这段：
```markdown
## Technology Stack

- **Engine**: [CHOOSE: Godot 4 / Unity / Unreal Engine 5]
- **Language**: [CHOOSE: GDScript / C# / C++ / Blueprint]
- **Version Control**: Git with trunk-based development
- **Build System**: [SPECIFY after choosing engine]
- **Asset Pipeline**: [SPECIFY after choosing engine]
```
整体替换为：
```markdown
## Technology Stack

- **Engine**: Godot 4.6（本机 4.6.3 stable，已 pin，见 `docs/engine-reference/godot/VERSION.md`）
- **Language**: GDScript（静态类型）
- **Rendering**: Mobile 渲染后端（2D）
- **Platform**: iOS（移动端 / 触控 / 横屏 1920×1080）
- **Version Control**: Git，trunk-based development
- **Build System**: Godot 导出（iOS → Xcode 26.5 签名打包）
- **Asset Pipeline**: Godot 内置导入（`assets/` 存放美术/音频/数据）
- **Engine Specialists**: `godot-specialist`（主）/ `godot-gdscript-specialist` / `godot-shader-specialist`
```

- [ ] **Step 3: 在 Technology Stack 段后插入 Commands 段**

```markdown

## Commands

```bash
# 编辑器内打开
godot --path . --editor

# 无头冒烟：打开并规范化工程、验证可解析
godot --headless --path . --import
godot --headless --path . --quit-after 5      # 跑主场景若干帧后退出

# 测试（/test-setup 落地 gdUnit4 后）
godot --headless --script tests/gdunit4_runner.gd

# iOS 导出（需先装 export templates、在编辑器 Export 对话框填 Team ID/bundle id）
godot --headless --path . --export-debug "iOS" build/jianghu.ipa
```
```

- [ ] **Step 4: 填实 `technical-preferences.md`**

把 `.claude/docs/technical-preferences.md` 中所有 `[TO BE CONFIGURED]`/`[None ...]` 段替换为：
```markdown
## Engine & Language

- **Engine**: Godot 4.6（本机 4.6.3 stable）
- **Language**: GDScript（启用静态类型）
- **Rendering**: Mobile 渲染后端（2D）
- **Physics**: Godot 2D 物理（GodotPhysics2D）

## Input & Platform

- **Target Platforms**: iOS（移动端）
- **Input Methods**: Touch
- **Primary Input**: Touch（触控）
- **Gamepad Support**: None
- **Touch Support**: Full
- **Platform Notes**: 横屏 1920×1080；拉伸 canvas_items/expand 适配多机型

## Naming Conventions

- **Classes**: PascalCase（如 `CombatSystem`，`class_name`）
- **Variables**: snake_case；私有成员前缀 `_`
- **Signals/Events**: snake_case 过去式（如 `health_depleted`）
- **Files**: snake_case（`combat_system.gd` / `main_menu.tscn`）
- **Scenes/Prefabs**: 文件 snake_case；节点名 PascalCase
- **Constants**: CONSTANT_CASE；枚举类型 PascalCase、成员 CONSTANT_CASE

## Performance Budgets

- **Target Framerate**: 60 FPS
- **Frame Budget**: 16.6 ms
- **Draw Calls**: < 100（移动端 2D 初始目标）
- **Memory Ceiling**: < 512 MB（移动端保守目标）

## Testing

- **Framework**: gdUnit4（默认，`/test-setup` 时确认）
- **Minimum Coverage**: 95%（整库 GDScript 行覆盖，含 UI）
- **Required Tests**: 玩法公式、系统逻辑、状态机、UI 控制器逻辑；每次代码改动必带测试

## Forbidden Patterns

- 硬编码玩法数值（必须数据驱动 / 外置配置）
- 非中文注释、复述代码的废话注释
- 无测试即合入的代码

## Allowed Libraries / Addons

- gdUnit4（测试框架，待 /test-setup 确认引入）

## Architecture Decisions Log

- 暂无 ADR —— 用 /architecture-decision 创建
```

- [ ] **Step 5: 验证无残留占位 + @-include 可解析**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu
grep -nE "\[CHOOSE|\[TO BE CONFIGURED|\[SPECIFY" CLAUDE.md .claude/docs/technical-preferences.md || echo "无残留占位 OK"
for f in .claude/docs/directory-structure.md docs/engine-reference/godot/VERSION.md \
         .claude/docs/technical-preferences.md .claude/docs/coordination-rules.md \
         .claude/docs/coding-standards.md .claude/docs/context-management.md; do
  test -f "$f" && echo "include 存在: $f" || echo "缺失: $f"
done
```
Expected: `无残留占位 OK`；6 个 include 全部存在

- [ ] **Step 6: 提交**

```bash
git add CLAUDE.md .claude/docs/technical-preferences.md
git commit -m "feat: 配置 jianghu 技术栈（Godot4.6/GDScript/iOS/横屏）并加中文约定与命令

填实 CLAUDE.md 技术栈与 Commands，顶部加简体中文回复声明；
technical-preferences 写入命名/性能/测试（整库95%覆盖）标准。

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: 新增/编辑规则（中文 + 覆盖率门槛）

**Files:**
- Create: `.claude/rules/language-zh.md`
- Modify: `.claude/rules/test-standards.md`、`.claude/docs/coding-standards.md`、`.claude/docs/rules-reference.md`

**Interfaces:**
- Produces：路径触发的中文规则与 >95% 整库覆盖率门槛，编辑对应路径文件时自动生效。

- [ ] **Step 1: 新建 `.claude/rules/language-zh.md`**

```markdown
---
paths:
  - "**"
---

# 语言与注释规则（中文）

## 交流语言
- 全程使用**简体中文**回复用户（最高优先级，亦在 `CLAUDE.md` 顶部声明，确保不依赖规则触发即生效）。

## 注释规则
- 注释**一律使用简体中文**。
- **言之有物、言简意赅**：解释**为什么**这么做、它**是什么**，不复述代码字面含义。
- 禁止废话注释（如 `# 把 i 加一` 配 `i += 1`）。
- 公共 API、非平凡逻辑、关键决策点必须有注释说明意图与约束。

## 示例

**正确**（说清是什么 + 为什么）：

```gdscript
# 用平方距离比较，避免每帧开方的性能开销（移动端 60FPS 预算敏感）
if from.distance_squared_to(to) < attack_range_sq:
	_start_attack()
```

**错误**：

```gdscript
# 计算距离  ← 复述代码、未说为什么
var d := from.distance_to(to)
i += 1  # i 加一  ← 废话注释
```
```

- [ ] **Step 2: 在 `.claude/rules/test-standards.md` 正文末尾追加覆盖率门槛**

在文件末尾追加：
```markdown

## 覆盖率门槛（项目强制）

- **每次代码改动必须伴随测试**：新功能配新测试，bug 修复配回归测试。
- **整库 GDScript 行覆盖率必须 > 95%（含 UI）** —— 低于即视为未完成（BLOCKING）。
  - 覆盖的是**代码行**（含玩法/AI/状态机/工具，以及 UI 控制器/HUD/菜单等脚本逻辑），不是像素。
  - 视觉保真与手感另按 CCGS 用截图 / playtest 验证，与行覆盖率并存、不互斥。
- 覆盖率工具与统计方式在 `/test-setup` 阶段落地（默认 gdUnit4）。
```

- [ ] **Step 3: 在 `.claude/docs/coding-standards.md` 的 "# Testing Standards" 段补一条总览**

在 `# Testing Standards` 标题下方紧接插入：
```markdown

> **项目覆盖率门槛**：整库 GDScript 行覆盖率 **> 95%（含 UI）**，BLOCKING；每次代码改动必带测试。详见 `.claude/rules/test-standards.md`。
```

- [ ] **Step 4: 在 `.claude/docs/rules-reference.md` 表格追加一行**

在规则表格末尾（`prototype-code.md` 行之后）追加：
```markdown
| `language-zh.md` | `**` | 中文回复、中文注释、言之有物言简意赅 |
```

- [ ] **Step 5: 验证规则就位**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu
test -f .claude/rules/language-zh.md && head -4 .claude/rules/language-zh.md
grep -q "整库 GDScript 行覆盖率必须 > 95%" .claude/rules/test-standards.md && echo "覆盖率门槛 OK"
grep -q "language-zh.md" .claude/docs/rules-reference.md && echo "rules-reference 已登记 OK"
ls .claude/rules | wc -l   # 期望 12
```
Expected: frontmatter 含 `paths:` 与 `"**"`；`覆盖率门槛 OK`；`rules-reference 已登记 OK`；`12`

- [ ] **Step 6: 提交**

```bash
git add .claude/rules/language-zh.md .claude/rules/test-standards.md \
        .claude/docs/coding-standards.md .claude/docs/rules-reference.md
git commit -m "feat: 新增中文规则与整库>95%覆盖率门槛

language-zh.md 约束中文回复与中文注释；test-standards 追加
每改动必带测试 + 整库行覆盖率>95%（含UI）的 BLOCKING 门槛。

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: iOS 导出预设 + .gitignore 调整 + 构建文档

**Files:**
- Create: `export_presets.cfg`、`docs/build/ios-export.md`
- Modify: `.gitignore`

**Interfaces:**
- Produces：可入库的 iOS 导出起点预设 + iOS 构建流程文档。真实签名/Team ID 由用户在编辑器 Export 对话框补全（本次不验证完整导出，因 iOS export templates 未安装）。

- [ ] **Step 1: 写 `export_presets.cfg`**（iOS 起点预设；编辑器 Export 对话框会补全其余默认项）

```ini
[preset.0]

name="iOS"
platform="iOS"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path="build/jianghu.ipa"
patches=PackedStringArray()
encryption_include_filters=""
encryption_exclude_filters=""
seed=0
encrypt_pck=false
encrypt_directory=false
script_export_mode=2

[preset.0.options]

application/app_store_team_id=""
application/bundle_identifier="com.microboat.jianghu"
application/name="江湖"
application/short_version="1.0"
application/version="1.0"
application/min_ios_version="13.0"
application/targeted_device_family=2
application/signature=""
application/export_method_debug=1
application/export_method_release=0
orientation/portrait=false
orientation/landscape_left=true
orientation/landscape_right=true
orientation/portrait_upside_down=false
```

- [ ] **Step 2: 从 `.gitignore` 移除对 `export_presets.cfg` 的忽略**

删除 `.gitignore` 中"# === Engine: Godot ===" 段里的这一行：
```
export_presets.cfg
```
（保留同段的 `.godot/`、`*.translation`、`# *.import` 注释行不动。）

- [ ] **Step 3: 写 `docs/build/ios-export.md`**

```markdown
# iOS 构建与导出流程

> 前置：本机已装 Godot 4.6.3、Xcode 26.5。`export_presets.cfg` 已入库（含占位 bundle id）。

## 一次性准备
1. **安装 iOS export templates**：Godot 编辑器 → 顶部菜单 Editor → Manage Export Templates → Download（与引擎同版本 4.6.x）。
2. **填签名信息**：编辑器 → Project → Export → 选 "iOS" 预设，填入：
   - Bundle Identifier：`com.microboat.jianghu`（或你的真实 id）
   - App Store Team ID：你的 Apple 开发者 Team ID
   - Provisioning / Code Sign Identity：按 Xcode 配置

## 导出
```bash
# 导出为 Xcode 工程或 .ipa（需模板与签名就绪）
godot --headless --path . --export-debug "iOS" build/jianghu.ipa
```
- 导出产物在 `build/`（已被 .gitignore 忽略）。
- 如导出为 Xcode 工程，用 Xcode 26.5 打开后 `xcodebuild` 签名打包真机/上架。

## 说明
- 真实签名、Team ID、provisioning 不入库；`export_presets.cfg` 仅存非敏感占位配置。
- 屏幕方向：项目级为横屏；预设 `orientation/landscape_*` 与之一致。
```

- [ ] **Step 4: 验证 export_presets.cfg 已纳入版本管理**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu
git check-ignore export_presets.cfg && echo "仍被忽略(错误)" || echo "export_presets.cfg 不再被忽略 OK"
test -f docs/build/ios-export.md && echo "iOS 文档 OK"
```
Expected: `export_presets.cfg 不再被忽略 OK`；`iOS 文档 OK`

- [ ] **Step 5: 提交**

```bash
git add export_presets.cfg .gitignore docs/build/ios-export.md
git commit -m "feat: 添加 iOS 导出预设与构建文档，export_presets.cfg 入库

iOS 起点预设（bundle id=com.microboat.jianghu，横屏）；
从 .gitignore 移除 export_presets.cfg 以便复现；补 iOS 构建流程文档。

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: 最终整体验证

**Files:** 无新增（纯验证；如有遗漏再补提交）

- [ ] **Step 1: 工程可加载 + 主场景可运行**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu
/opt/homebrew/bin/godot --headless --path . --import 2>&1 | grep -i error && echo "有错误(需修)" || echo "导入无错误 OK"
/opt/homebrew/bin/godot --headless --path . --quit-after 5 2>&1 | grep "江湖 启动" && echo "运行 OK"
```
Expected: `导入无错误 OK`；`运行 OK`

- [ ] **Step 2: 裁剪与规则核对**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu
ls .claude/agents | wc -l                                   # 37
ls .claude/agents | grep -cE "unity|unreal|^ue-|csharp|gdextension"   # 0
test -f .claude/rules/language-zh.md && echo "中文规则 OK"
grep -q "> 95%" .claude/rules/test-standards.md && echo "覆盖率门槛 OK"
grep -q "简体中文" CLAUDE.md && echo "CLAUDE.md 中文声明 OK"
```
Expected: `37`；`0`；三条 OK

- [ ] **Step 3: 配置/占位/入库核对**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu
grep -rnE "\[CHOOSE|\[TO BE CONFIGURED" CLAUDE.md .claude/docs/technical-preferences.md || echo "无残留占位 OK"
git check-ignore export_presets.cfg || echo "export_presets 入库 OK"
git check-ignore .godot >/dev/null && echo ".godot 忽略 OK"
git status -s   # 期望干净
git log --oneline | head -10
```
Expected: `无残留占位 OK`；`export_presets 入库 OK`；`.godot 忽略 OK`；工作区干净；7~8 个 commit

- [ ] **Step 4: 标记 spec 为已实现并提交（如有改动）**

把 spec 状态行更新为"已实现"，提交：
```bash
cd /Users/zhouwei/PersonalProjects/jianghu
# 编辑 docs/superpowers/specs/2026-06-20-jianghu-init-design.md 状态行 → 已实现
git add docs/superpowers/specs/2026-06-20-jianghu-init-design.md
git commit -m "docs: 标记 jianghu 初始化 spec 为已实现" || echo "无改动可跳过"
```

---

## 自检（Self-Review）

- **Spec 覆盖**：① CCGS 导入→T1；② 裁剪 12 agent→T2；③ Godot 骨架→T3；④ 技术栈/CLAUDE.md/technical-preferences→T4；⑤ 中文+覆盖率规则→T5；⑥ iOS 预设+gitignore+文档→T6；⑦ git init（已在 spec 阶段完成）+ 最终验证→T7。全部 spec 章节均有对应任务。
- **占位扫描**：各步均给出真实命令/文件内容；无 TODO/TBD。
- **类型一致**：主场景节点 `Main`(Node2D) 挂 `res://src/main.gd`，`main.tscn` 的 `ext_resource` 指向一致；`run/main_scene` 指向 `res://src/main.tscn` 一致；bundle id 全程 `com.microboat.jianghu` 一致。
- **已知边界**：iOS 完整导出依赖未安装的 export templates（T6 仅做预设+文档，不验证导出）；`main.gd` 为 bootstrap 桩，覆盖率门槛对其后游戏代码生效。

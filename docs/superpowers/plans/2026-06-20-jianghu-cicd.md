# jianghu CI/CD + changelog/tag 子系统 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: 用 superpowers:subagent-driven-development（推荐）或 superpowers:executing-plans 按任务逐步实现。步骤用 `- [ ]` 复选框跟踪。

**Goal:** 为 jianghu 加 GitHub Actions：CI（GDScript lint/format + Godot 导入冒烟，全 blocking）+ release-please 全自动 changelog/tag/release。

**Architecture:** 两个 workflow——`ci.yml`（push/PR 触发，并行 job：lint、import-smoke、test-if-exists、pr-title-lint）与 `release-please.yml`（push main 触发，基于 Conventional Commits 自动开 release PR、合并即发版）。`version.txt` 为版本真相源。端到端验证靠推送后用 `gh` 观察 Actions 与 release PR。

**Tech Stack:** GitHub Actions、gdtoolkit 4.x（gdformat/gdlint，本机实证 4.5.0）、chickensoft-games/setup-godot、googleapis/release-please-action@v4、amannn/action-semantic-pull-request@v5。

## Global Constraints

> 数值逐字摘自 spec `docs/superpowers/specs/2026-06-20-jianghu-cicd-design.md`。

- release 机制 **release-please**（`googleapis/release-please-action@v4`，`release-type: simple`）。
- 起始版本 **0.1.0**；`feat`→minor、`fix`→patch（pre-1.0：`bump-minor-pre-major` + `bump-patch-for-minor-pre-major`）。
- CI **lint + format + 导入冒烟 全 blocking**。
- Godot-in-CI 用 **chickensoft-games/setup-godot**，pin **4.6.3**，`use-dotnet: false`。
- 版本真相源 **`version.txt`**；`export_presets.cfg` 版本一次性对齐 0.1.0，不持续同步。
- 加 **pr-title-lint**（Conventional Commits 校验 PR 标题）。
- commit 用 Conventional Commits；提交身份 codeweiz / 13955645241@163.com（仓库本地 config 已设）。
- 全程简体中文回复；注释中文、言之有物。
- **偏离记录**：spec §4.5/§5 的 `.gdlintrc` **不创建**——gdlint 默认规则已通过本项目代码（本机实证），加部分配置反有禁用规则之险；后续需调参时再加。

---

## 文件结构图

**新建**
- `.github/workflows/ci.yml` — CI：lint / import-smoke / test / pr-title-lint
- `.github/workflows/release-please.yml` — 自动 release
- `release-please-config.json` — release-please 配置（simple/changelog/bump 规则）
- `.release-please-manifest.json` — 版本清单，初始 `{".":"0.1.0"}`
- `version.txt` — 版本真相源，`0.1.0`
- `docs/ci-cd.md` — 流水线与发版流程文档（含 iOS CD 暂缓说明、分支保护开启步骤）

**修改**
- `src/main.gd` — 函数前补一个空行（满足 gdformat）
- `export_presets.cfg` — `application/version` 与 `application/short_version` → `0.1.0`
- `CLAUDE.md` — 加 "CI/CD" 段 + Commands 加本地 lint 命令

---

## Task 1: CI 流水线 + 本地 lint 规范化

**Files:**
- Modify: `src/main.gd`
- Create: `.github/workflows/ci.yml`

**Interfaces:**
- Produces：`ci.yml` 定义 4 个 job（`lint`/`import-smoke`/`test`/`pr-title-lint`）；`src/main.gd` 通过 `gdformat --check`。后续任务推送后这些 job 在 GitHub 上运行。

- [ ] **Step 1: 规范化 `src/main.gd`（函数前两空行）**

把 `src/main.gd` 改为（注意 `## 注意:` 行与 `func` 之间是**两个空行**，缩进用 Tab）：

```gdscript
extends Node2D
## 游戏入口引导桩。
## 作用：作为主场景根脚本，启动时打印引擎版本，用于验证工程可正常加载运行。
## 注意：这是初始化期的临时桩，真正的游戏流程在 /start 设计后接入，届时替换本文件。


func _ready() -> void:
	# 打印引擎版本，证明工程已被引擎正确加载（headless 与真机一致）
	print("江湖 启动，Godot 引擎版本：", Engine.get_version_info().string)
```

- [ ] **Step 2: 本地验证 format/lint 通过**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu
pip install -q "gdtoolkit==4.*"
gdformat --check src/    # 期望：1 file would be left unchanged，exit 0
gdlint src/              # 期望：Success: no problems found，exit 0
```
Expected: 两条均 exit 0

- [ ] **Step 3: 创建 `.github/workflows/ci.yml`**

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  lint:
    name: GDScript Lint & Format
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - name: 安装 gdtoolkit
        run: pip install "gdtoolkit==4.*"
      - name: 格式检查（gdformat）
        run: gdformat --check src/
      - name: 静态检查（gdlint）
        run: gdlint src/

  import-smoke:
    name: Godot 导入冒烟
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: chickensoft-games/setup-godot@v2
        with:
          version: 4.6.3
          use-dotnet: false
      - name: 导入工程（无 ERROR 即通过）
        run: |
          set -o pipefail
          godot --headless --path . --import 2>&1 | tee import.log
          if grep -qE "^ERROR|SCRIPT ERROR" import.log; then
            echo "::error::Godot 导入出现错误"; exit 1
          fi
      - name: 运行主场景（须打印「江湖 启动」）
        run: |
          godot --headless --path . --quit-after 5 2>&1 | tee run.log
          grep -q "江湖 启动" run.log

  test:
    name: 单元测试（存在才跑）
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: chickensoft-games/setup-godot@v2
        with:
          version: 4.6.3
          use-dotnet: false
      - name: 跑 gdUnit4（若已配置）
        run: |
          if [ -f tests/gdunit4_runner.gd ]; then
            godot --headless --path . --import
            godot --headless --path . --script tests/gdunit4_runner.gd
          else
            echo "暂无测试 runner（tests/gdunit4_runner.gd 不存在），跳过。/test-setup 后自动启用。"
          fi

  pr-title-lint:
    name: PR 标题规范（Conventional Commits）
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    permissions:
      pull-requests: read
    steps:
      - uses: amannn/action-semantic-pull-request@v5
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

- [ ] **Step 4: 本地校验 YAML 语法 + 工程冒烟**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu
python3 -c "import yaml,sys; yaml.safe_load(open('.github/workflows/ci.yml')); print('ci.yml YAML OK')"
godot --headless --path . --import >/dev/null 2>&1 && echo "import OK"
godot --headless --path . --quit-after 5 2>&1 | grep -q "江湖 启动" && echo "run OK"
```
Expected: `ci.yml YAML OK`；`import OK`；`run OK`

- [ ] **Step 5: 提交**

```bash
git add src/main.gd .github/workflows/ci.yml
git commit -m "ci: 添加 CI 流水线（gdformat/gdlint + Godot 导入冒烟，全 blocking）

新增 ci.yml：lint/import-smoke/test/pr-title-lint 四个 job；
规范化 main.gd 使其通过 gdformat。test job 在 /test-setup 后自动启用。"
```

---

## Task 2: release-please 自动发版

**Files:**
- Create: `.github/workflows/release-please.yml`、`release-please-config.json`、`.release-please-manifest.json`、`version.txt`
- Modify: `export_presets.cfg`

**Interfaces:**
- Consumes：Conventional Commits 历史。
- Produces：push main 后自动开 `chore: release X.Y.Z` PR；`version.txt` 为版本真相源。

- [ ] **Step 1: 创建 `version.txt`**

```text
0.1.0
```

- [ ] **Step 2: 创建 `.release-please-manifest.json`**

```json
{
  ".": "0.1.0"
}
```

- [ ] **Step 3: 创建 `release-please-config.json`**

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "packages": {
    ".": {
      "release-type": "simple",
      "changelog-path": "CHANGELOG.md",
      "bump-minor-pre-major": true,
      "bump-patch-for-minor-pre-major": true,
      "include-component-in-tag": false
    }
  }
}
```

- [ ] **Step 4: 创建 `.github/workflows/release-please.yml`**

```yaml
name: release-please

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write

concurrency:
  group: release-please-${{ github.ref }}
  cancel-in-progress: false

jobs:
  release-please:
    runs-on: ubuntu-latest
    steps:
      - uses: googleapis/release-please-action@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          config-file: release-please-config.json
          manifest-file: .release-please-manifest.json
```

- [ ] **Step 5: 对齐 `export_presets.cfg` 版本到 0.1.0**

把 `export_presets.cfg` 中：
```
application/short_version="1.0"
application/version="1.0"
```
改为：
```
application/short_version="0.1.0"
application/version="0.1.0"
```

- [ ] **Step 6: 本地校验 JSON/YAML 语法**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu
python3 -m json.tool release-please-config.json >/dev/null && echo "config JSON OK"
python3 -m json.tool .release-please-manifest.json >/dev/null && echo "manifest JSON OK"
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/release-please.yml')); print('release-please.yml YAML OK')"
grep -q '"0.1.0"' export_presets.cfg && echo "export 版本对齐 OK"
cat version.txt
```
Expected: 三个 OK + `export 版本对齐 OK` + `0.1.0`

- [ ] **Step 7: 提交**

```bash
git add .github/workflows/release-please.yml release-please-config.json \
        .release-please-manifest.json version.txt export_presets.cfg
git commit -m "ci: 接入 release-please 自动 changelog/tag/release

release-type=simple；version.txt 为版本真相源（0.1.0 起）；
export_presets 版本对齐 0.1.0。合并 release PR 即打 tag + 建 Release。"
```

---

## Task 3: 文档（ci-cd.md + CLAUDE.md）

**Files:**
- Create: `docs/ci-cd.md`
- Modify: `CLAUDE.md`

- [ ] **Step 1: 创建 `docs/ci-cd.md`**

````markdown
# CI/CD 流水线说明

## 概览
两个 GitHub Actions workflow：

| Workflow | 触发 | 作用 |
|----------|------|------|
| `ci.yml` | push/PR → main | GDScript lint+format、Godot 导入冒烟、测试（存在才跑）、PR 标题校验 |
| `release-please.yml` | push → main | 基于 Conventional Commits 自动发版 |

## CI 门禁（全 blocking）
- **lint**：`gdformat --check src/` + `gdlint src/`（gdtoolkit 4.x）。
- **import-smoke**：Godot 4.6.3 headless 导入无 ERROR + 主场景打印「江湖 启动」。
- **test**：存在 `tests/gdunit4_runner.gd` 时跑 gdUnit4，否则跳过；`/test-setup` 后自动启用。
- **pr-title-lint**：PR 标题须符合 Conventional Commits。

### 本地预检（提交前自查）
```bash
pip install "gdtoolkit==4.*"
gdformat src/        # 自动格式化（或 --check 只检查）
gdlint src/
godot --headless --path . --import
```

## 发版流程（release-please）
1. 正常用 Conventional Commits 提交到 `main`（`feat:`/`fix:`/...）。
2. release-please 自动开/更新一个 `chore: release X.Y.Z` PR，内含 `CHANGELOG.md` 与 `version.txt` 变更。
3. **合并该 PR** → 自动打 `vX.Y.Z` tag + 建 GitHub Release + 落库 `CHANGELOG.md`。
- 版本规则（pre-1.0）：`feat:`→minor、`fix:`→patch；MVP 成型后手动进 1.0.0。
- 版本真相源：`version.txt`。

## 把 CI 设为"必过门禁"（需在网页端操作一次）
GitHub 仓库 → Settings → Branches → Add branch ruleset（或 Branch protection rule）→ 目标 `main`：
- 勾选 **Require status checks to pass before merging**；
- 在列表里选中 `GDScript Lint & Format`、`Godot 导入冒烟`、`单元测试（存在才跑）`；
- （可选）勾 **Require a pull request before merging** 以强制走 PR。

## iOS CD（暂缓，未来接入点）
iOS 真机/上架部署需 Apple 开发者证书、provisioning profile（当前未配），故本期未建可运行的 iOS 构建 workflow。未来接入步骤：
1. 在 GitHub 仓库 Secrets 配置签名证书（base64）、provisioning、App Store Connect API key。
2. 新增 `ios-release.yml`（`macos-latest` runner）：装 Godot + iOS export templates → `godot --headless --export-release "iOS"` → Fastlane `pilot` 上传 TestFlight。
3. 导出时读 `version.txt` 注入应用版本，保持与 release tag 一致。
````

- [ ] **Step 2: 在 `CLAUDE.md` 末尾追加 CI/CD 段**

在 `CLAUDE.md` 文件末尾追加：
```markdown

## CI/CD

- **CI**（`.github/workflows/ci.yml`）：push/PR 触发，GDScript lint/format + Godot 导入冒烟全 blocking。
- **发版**（`.github/workflows/release-please.yml`）：Conventional Commits → 自动 release PR → 合并即打 tag + 建 Release + 更新 `CHANGELOG.md`。版本真相源 `version.txt`。
- 详见 `docs/ci-cd.md`（含本地预检与分支保护开启步骤）。
```

- [ ] **Step 3: 在 `CLAUDE.md` 的 Commands 段补本地 lint 命令**

在 `CLAUDE.md` 的 ```bash Commands 代码块里、`# 测试` 行之前插入：
```bash
# 本地代码检查（提交前自查，CI 同款）
pip install "gdtoolkit==4.*" && gdformat --check src/ && gdlint src/
```

- [ ] **Step 4: 校验 + 提交**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu
test -f docs/ci-cd.md && grep -q "release-please" docs/ci-cd.md && echo "ci-cd.md OK"
grep -q "## CI/CD" CLAUDE.md && echo "CLAUDE.md CI/CD 段 OK"
git add docs/ci-cd.md CLAUDE.md
git commit -m "docs: 补 CI/CD 流水线文档与 CLAUDE.md 说明

ci-cd.md 含门禁说明、发版流程、分支保护开启步骤、iOS CD 暂缓与未来接入点。"
```

---

## Task 4: 推送 + 端到端验证

**Files:** 无新增（推送并用 gh 观察 GitHub Actions 实际运行）

- [ ] **Step 1: 推送到 main**

```bash
cd /Users/zhouwei/PersonalProjects/jianghu
git push origin main 2>&1 | tail -3
```

- [ ] **Step 2: 观察 CI 运行直到结束**

```bash
sleep 15
gh run list --branch main --limit 5
# 取最新 CI run 并等待
gh run watch "$(gh run list --workflow ci.yml --branch main --limit 1 --json databaseId -q '.[0].databaseId')" --exit-status
```
Expected: CI run 结论 `success`（lint/import-smoke/test 均绿；push 事件不跑 pr-title-lint）

- [ ] **Step 3: 确认 release-please 开出 release PR**

```bash
sleep 10
gh pr list --state open --json number,title,headRefName -q '.[] | "\(.number) \(.title) [\(.headRefName)]"'
```
Expected: 出现一条 `chore: release 0.1.0`（或 `chore(main): release 0.1.0`）的 PR，分支名形如 `release-please--branches--main`

- [ ] **Step 4: 若版本不是 0.1.0，强制为 0.1.0（应急）**

仅当 Step 3 的 release PR 版本 ≠ 0.1.0 时执行：
```bash
cd /Users/zhouwei/PersonalProjects/jianghu
git commit --allow-empty -m "chore: 触发首个 release

Release-As: 0.1.0"
git push origin main
sleep 20
gh pr list --state open --json number,title -q '.[] | "\(.number) \(.title)"'
```
Expected: release PR 标题版本为 `0.1.0`

- [ ] **Step 5: 汇报状态**

向用户报告：CI 各 job 结论、release PR 链接/编号、并提示两件需人工的事：①合并 release PR 即发首个版本 `v0.1.0`；②在仓库 Settings 把 CI 勾为 required status checks（步骤见 `docs/ci-cd.md`）。
（合并 release PR 与改仓库设置都是外发/网页操作，**等用户确认后**再做或由用户自行操作。）

---

## 自检（Self-Review）

- **Spec 覆盖**：CI 四 job→T1；release-please+config+version.txt+export 对齐→T2；ci-cd.md+CLAUDE.md→T3；端到端验证（验收 §6 全部）→T4。spec §4 各节均有对应任务。
- **占位扫描**：所有文件给出完整内容；命令均含期望输出。`.gdlintrc` 明确不建（已在 Global Constraints 记偏离）。
- **类型/命名一致**：workflow 文件名 `ci.yml`/`release-please.yml` 全程一致；版本 `0.1.0` 在 version.txt/manifest/export_presets 一致；job 名与 docs/ci-cd.md 分支保护勾选项一致（`GDScript Lint & Format`/`Godot 导入冒烟`/`单元测试（存在才跑）`）。
- **已知边界**：release-please 首个 PR 版本需实跑确认（T4 Step4 应急）；chickensoft setup-godot 对 4.6.3 的支持若缺则回退最近 4.6.x（实现时若 import-smoke 失败据日志调整）；分支保护为网页端人工操作。

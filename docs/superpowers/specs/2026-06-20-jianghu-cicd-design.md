# jianghu CI/CD + changelog + tag 子系统 — 设计文档（Spec）

| 字段 | 值 |
|------|-----|
| 主题 | GitHub Actions CI/CD + release-please 自动化 changelog/tag/release |
| 日期 | 2026-06-20 |
| 状态 | 已实现（端到端验证通过；首发 v0.1.1） |

> **落地偏离记录**：① `.gdlintrc` 未创建——gdlint 默认规则已通过本项目代码，加部分配置反有禁用规则之险（YAGNI）。
> ② 首个 release 为 **v0.1.1** 而非 0.1.0——release-please 将 manifest 的 0.1.0 视为已发布基线并按 `feat:` 提交 bump，
> 且 release PR 在 `Release-As: 0.1.0` 应急前已被合并；经确认保留 0.1.1，后续正常递增。
| 依赖 | 已完成的项目初始化（`2026-06-20-jianghu-init-design.md`） |

---

## 1. 背景与目标

jianghu 已完成初始化（Godot 4.6 / GDScript / iOS / 强制 Conventional Commits），并推送到
`github.com/codeweiz/jianghu`。CCGS 自带 `.github/`（PR/issue 模板、CODEOWNERS）但**无 workflows**，
且 `/changelog`、`/release-checklist` 等均为**手动触发的 AI 技能**，非自动化流水线。

**本次目标**：搭建真正的 GitHub Actions 流水线：
- **CI**：push/PR 触发，GDScript lint + format + Godot 导入冒烟，全部作为 PR 必过门禁（blocking）。
- **自动 release**：基于 Conventional Commits 的 release-please，全自动维护版本号、`CHANGELOG.md`、
  git tag、GitHub Release。

**非目标（暂缓）**：iOS 真机构建 / 签名 / TestFlight 上架（缺 Apple 证书，仅文档化未来接入点）；
gdUnit4 测试本体（由 `/test-setup` 负责，CI 预留位）。

## 2. 现状事实（已核对）

| 项 | 值 |
|----|-----|
| `.github/workflows/` | 不存在（无任何 workflow） |
| `CHANGELOG.md` / `version.txt` | 均不存在 |
| 提交规范 | 已强制 Conventional Commits（见 `.claude/docs/coding-standards.md`） |
| 远程 | `origin = github.com/codeweiz/jianghu`，默认分支 `main` |
| Godot | 4.6.3 stable；CI 用 chickensoft setup-godot pin 4.6.3 |

## 3. 已确认决策

| # | 决策 | 取值 |
|---|------|------|
| 1 | release 机制 | **release-please**（`googleapis/release-please-action@v4`，全自动） |
| 2 | 起始版本 | **0.1.0** |
| 3 | CI 门禁严格度 | lint + format + 导入冒烟 **全 blocking** |
| 4 | Godot-in-CI | **chickensoft-games/setup-godot**（pin 4.6.3） |
| 5 | 版本同步 | **`version.txt` 为真相源**，未来 iOS 导出时注入；不持续改写 export_presets.cfg |
| 6 | PR 标题校验 | **加 pr-title-lint**（Conventional Commits） |

## 4. 组件设计

### 4.1 CI 流水线 —— `.github/workflows/ci.yml`

- **触发**：`push`（main）、`pull_request`（main）。
- **运行环境**：`ubuntu-latest`。各 job 并行；加 `concurrency` 取消同分支旧运行。
- **Job `lint`（blocking）**：
  - `actions/setup-python@v5`（3.12）+ pip 缓存 → `pip install "gdtoolkit==4.*"`。
  - `gdformat --check src/`（格式不符即失败）。
  - `gdlint src/`（静态检查；规则见 `.gdlintrc`）。
- **Job `import-smoke`（blocking）**：
  - `chickensoft-games/setup-godot@v2`，version `4.6.3`，`use-dotnet: false`。
  - `godot --headless --path . --import`，抓 `^ERROR|SCRIPT ERROR` 即失败。
  - `godot --headless --path . --quit-after 5` 输出须含 `江湖 启动`。
- **Job `test`（条件门禁）**：
  - `if [ -f tests/gdunit4_runner.gd ]` 则用 setup-godot 跑 gdUnit4 runner；否则打印"暂无测试，跳过"并通过。
  - `/test-setup` 落地 runner 后自动成为 blocking 门禁（无需改 workflow）。
- **Job `pr-title-lint`（仅 PR）**：
  - `amannn/action-semantic-pull-request@v5`，校验 PR 标题符合 Conventional Commits。
  - 仅 `pull_request` 事件运行（push 跳过）。

> **落地前置**：实现时先在本地 `pip install gdtoolkit` 跑 `gdformat src/` 与 `gdlint src/`，
> 规范化 `src/main.gd` 并修掉告警/配 `.gdlintrc`，确保 CI 首次即绿。

### 4.2 自动 release —— `.github/workflows/release-please.yml`

- **触发**：`push`（main）。
- **权限**：`contents: write` + `pull-requests: write`（用内置 `GITHUB_TOKEN`，无额外 secret）。
- **步骤**：`googleapis/release-please-action@v4`，引用 `release-please-config.json` 与
  `.release-please-manifest.json`。
- **行为**：累积自上个 release 以来的 Conventional Commits → 自动开/更新一个
  `chore: release X.Y.Z` PR（含 `CHANGELOG.md` diff + `version.txt` bump）→ **合并该 PR**
  即打 `vX.Y.Z` tag + 建 GitHub Release + 更新 `CHANGELOG.md`。
  - `feat:` → minor（0.1.0 → 0.2.0）；`fix:` → patch（0.1.0 → 0.1.1）；`feat!`/`BREAKING CHANGE` → major（pre-1.0 下仍按配置，0.x 视为 minor）。
- **并发**：加 `concurrency` 防止重复 release PR。

### 4.3 release-please 配置文件

- **`.release-please-manifest.json`**：`{ ".": "0.1.0" }`。
- **`release-please-config.json`**：
  - `release-type: "simple"`（语言无关；维护 `version.txt`）。
  - `packages["."]`：`changelog-path: "CHANGELOG.md"`、`include-component-in-tag: false`、
    `bump-minor-pre-major: true`、`bump-patch-for-minor-pre-major: true`（pre-1.0 稳健递增）。
  - changelog 分节：`feat`→Features、`fix`→Bug Fixes、`docs/chore/refactor/test/perf` 等按默认分类。

### 4.4 版本真相源

- **`version.txt`**（仓库根，初始 `0.1.0`）：release-please 维护，应用版本真相源。
- **`CHANGELOG.md`**：由 release-please 首个 release PR 生成并维护（**不预建**，避免冲突）。
- **`export_presets.cfg`**：版本字段一次性对齐为 `0.1.0`；不做持续自动同步。未来 iOS 导出 workflow
  读 `version.txt` 注入版本。

### 4.5 `.gdlintrc`

- 基于 gdtoolkit 默认规则，按本项目放宽/收紧少量项（如 `max-line-length`、允许中文注释）。
- 落地时以"能让现有 `src/` 通过且不削弱质量"为准校准。

### 4.6 文档与 CLAUDE.md

- 新增 **`docs/ci-cd.md`**：流水线总览、release 操作流程（合并 release PR = 发版）、版本/标签规则、
  **iOS CD 暂缓说明 + 未来 Fastlane→TestFlight 接入点**。
- `CLAUDE.md` 补一小段 "CI/CD" 说明，并在 Commands 段加本地 lint 命令。

## 5. 新增/修改文件清单

**新建**
- `.github/workflows/ci.yml`
- `.github/workflows/release-please.yml`
- `release-please-config.json`
- `.release-please-manifest.json`
- `.gdlintrc`
- `version.txt`（`0.1.0`）
- `docs/ci-cd.md`

**修改**
- `export_presets.cfg`（版本 → `0.1.0`）
- `CLAUDE.md`（加 CI/CD 段 + 本地 lint 命令）
- `src/main.gd`（按 gdformat/gdlint 规范化，若有差异）

## 6. 验收标准

1. 推送后 GitHub Actions 出现 **CI** 与 **release-please** 两个 workflow，CI 三个 job（lint/import-smoke/test）+ PR 时的 pr-title-lint 全部**绿色通过**。
2. lint job：`gdformat --check src/` 与 `gdlint src/` 通过（本地已先行规范化）。
3. import-smoke job：Godot 导入无 ERROR，主场景打印「江湖 启动」。
4. release-please 在 push 后**自动开出 `chore: release 0.1.0` PR**（含 CHANGELOG + version.txt）。
5. 合并该 release PR 后：出现 tag `v0.1.0`、GitHub Release、`CHANGELOG.md` 落库。
6. `version.txt` = 当前版本；`export_presets.cfg` 版本与之一致（首次为 0.1.0）。
7. `docs/ci-cd.md` 完整，含 iOS CD 暂缓与未来接入说明。

## 7. 风险与开放问题

- **gdformat/gdlint 与现有代码冲突**：gdtoolkit 的规范化可能与 `src/main.gd` 现状有差异 → 落地时本地
  先规范化并配 `.gdlintrc`，确保 CI 首绿（见 4.1 前置）。
- **chickensoft setup-godot 对 4.6.3 的支持**：若该 action 未提供 4.6.3 精确版本，回退到最近的 4.6.x
  或改用固定下载链接（`Godot_v4.6.3-stable_linux.x86_64.zip`）。落地时验证。
- **release-please 首个 PR 的版本**：manifest 设 0.1.0 后，首个 release PR 是否直接发 0.1.0 取决于已有
  commits；若行为不符预期，用 `Release-As: 0.1.0` 提交或 manifest 调整。落地时验证。
- **iOS CD 真空**：真机部署需 Apple 证书/provisioning，本次仅文档化，未建可运行的 iOS 构建 workflow。
- **分支保护**：要让 CI 真正成为"必过门禁"，需在 GitHub 仓库设置里把 CI 勾为 required status checks
  —— 这是仓库 Web 设置，非代码，本 spec 在 `docs/ci-cd.md` 给出操作说明，由用户在网页端开启。

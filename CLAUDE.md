# Claude Code Game Studios -- Game Studio Agent Architecture

> **语言约定（最高优先级）**：本项目全程使用**简体中文**回复用户；代码注释一律用简体中文，且言之有物、言简意赅、说清"是什么 + 为什么"。详见 `.claude/rules/language-zh.md`。

Indie game development managed through 37 coordinated Claude Code subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: Godot 4.6（本机 4.6.3 stable，已 pin，见 `docs/engine-reference/godot/VERSION.md`）
- **Language**: GDScript（静态类型）
- **Rendering**: Mobile 渲染后端（2D）
- **Platform**: iOS（移动端 / 触控 / 横屏 1920×1080）
- **Version Control**: Git，trunk-based development
- **Build System**: Godot 导出（iOS → Xcode 26.5 签名打包）
- **Asset Pipeline**: Godot 内置导入（`assets/` 存放美术/音频/数据）
- **Engine Specialists**: `godot-specialist`（主）/ `godot-gdscript-specialist` / `godot-shader-specialist`

## Commands

```bash
# 编辑器内打开
godot --path . --editor

# 无头冒烟：打开并规范化工程、验证可解析
godot --headless --path . --import
godot --headless --path . --quit-after 5      # 跑主场景若干帧后退出

# 本地代码检查（提交前自查，CI 同款）
pip install "gdtoolkit==4.*" && gdformat --check src/ && gdlint src/

# 测试（/test-setup 落地 gdUnit4 后）
godot --headless --script tests/gdunit4_runner.gd

# iOS 导出（需先装 export templates、在编辑器 Export 对话框填 Team ID/bundle id）
godot --headless --path . --export-debug "iOS" build/jianghu.ipa
```

## Project Structure

@.claude/docs/directory-structure.md

## Engine Version Reference

@docs/engine-reference/godot/VERSION.md

## Technical Preferences

@.claude/docs/technical-preferences.md

## Coordination Rules

@.claude/docs/coordination-rules.md

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.

## Coding Standards

@.claude/docs/coding-standards.md

## Context Management

@.claude/docs/context-management.md

## CI/CD

- **CI**（`.github/workflows/ci.yml`）：push/PR 触发，GDScript lint/format + Godot 导入冒烟全 blocking。
- **发版**（`.github/workflows/release-please.yml`）：Conventional Commits → 自动 release PR → 合并即打 tag + 建 Release + 更新 `CHANGELOG.md`。版本真相源 `version.txt`。
- 详见 `docs/ci-cd.md`（含本地预检与分支保护开启步骤）。

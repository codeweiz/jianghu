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

## 把 CI 设为“必过门禁”（需在网页端操作一次）
GitHub 仓库 → Settings → Branches → Add branch ruleset（或 Branch protection rule）→ 目标 `main`：
- 勾选 **Require status checks to pass before merging**；
- 在列表里选中 `GDScript Lint & Format`、`Godot 导入冒烟`、`单元测试（存在才跑）`；
- （可选）勾 **Require a pull request before merging** 以强制走 PR。

## iOS CD（暂缓，未来接入点）
iOS 真机/上架部署需 Apple 开发者证书、provisioning profile（当前未配），故本期未建可运行的 iOS 构建 workflow。未来接入步骤：
1. 在 GitHub 仓库 Secrets 配置签名证书（base64）、provisioning、App Store Connect API key。
2. 新增 `ios-release.yml`（`macos-latest` runner）：装 Godot + iOS export templates → `godot --headless --export-release "iOS"` → Fastlane `pilot` 上传 TestFlight。
3. 导出时读 `version.txt` 注入应用版本，保持与 release tag 一致。

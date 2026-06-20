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

# Technical Preferences

<!-- jianghu 项目技术偏好。由初始化（等价 /setup-engine godot 4.6）填写，后续随决策更新。 -->
<!-- 所有 agent 都读取本文件获取项目级标准与约定。 -->

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

## Engine Specialists

<!-- 引擎专家路由。由 /code-review、/architecture-decision、/architecture-review 及 team 技能读取， -->
<!-- 据此决定为引擎相关校验派哪个专家。 -->

- **Primary**: `godot-specialist`
- **Language/Code Specialist**: `godot-gdscript-specialist`
- **Shader Specialist**: `godot-shader-specialist`
- **UI Specialist**: 无独立 UI 专家；Godot 的 UI 用 GDScript 实现，交由 `godot-gdscript-specialist`
- **Additional Specialists**: 无
- **Routing Notes**: 本项目纯 GDScript；C# / GDExtension / Native 不使用，相关文件一律回退 Primary（`godot-specialist`）

### File Extension Routing

<!-- 技能据此表为各类文件选择专家；标"回退 Primary"的，由 godot-specialist 处理。 -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code（`.gd`） | `godot-gdscript-specialist` |
| Shader / material（`.gdshader` / 材质） | `godot-shader-specialist` |
| UI / screen files（`.tscn` 中的 Control 界面 + 脚本） | `godot-gdscript-specialist` |
| Scene / prefab / level files（`.tscn` / `.tres`） | `godot-specialist` |
| Native extension / plugin files | 回退 Primary（`godot-specialist`） |
| General architecture review | Primary（`godot-specialist`） |

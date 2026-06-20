---
paths:
  - "tests/**"
---

# Test Standards

- Test naming: `test_[system]_[scenario]_[expected_result]` pattern
- Every test must have a clear arrange/act/assert structure
- Unit tests must not depend on external state (filesystem, network, database)
- Integration tests must clean up after themselves
- Performance tests must specify acceptable thresholds and fail if exceeded
- Test data must be defined in the test or in dedicated fixtures, never shared mutable state
- Mock external dependencies — tests should be fast and deterministic
- Every bug fix must have a regression test that would have caught the original bug

## Examples

**Correct** (proper naming + Arrange/Act/Assert):

```gdscript
func test_health_system_take_damage_reduces_health() -> void:
    # Arrange
    var health := HealthComponent.new()
    health.max_health = 100
    health.current_health = 100

    # Act
    health.take_damage(25)

    # Assert
    assert_eq(health.current_health, 75)
```

**Incorrect**:

```gdscript
func test1() -> void:  # VIOLATION: no descriptive name
    var h := HealthComponent.new()
    h.take_damage(25)  # VIOLATION: no arrange step, no clear assert
    assert_true(h.current_health < 100)  # VIOLATION: imprecise assertion
```

## 覆盖率门槛（项目强制）

- **每次代码改动必须伴随测试**：新功能配新测试，bug 修复配回归测试。
- **整库 GDScript 行覆盖率必须 > 95%（含 UI）** —— 低于即视为未完成（BLOCKING）。
  - 覆盖的是**代码行**（含玩法/AI/状态机/工具，以及 UI 控制器/HUD/菜单等脚本逻辑），不是像素。
  - 视觉保真与手感另按 CCGS 用截图 / playtest 验证，与行覆盖率并存、不互斥。
- 覆盖率工具与统计方式在 `/test-setup` 阶段落地（默认 gdUnit4）。

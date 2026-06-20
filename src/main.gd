extends Node2D
## 游戏入口引导桩。
## 作用：作为主场景根脚本，启动时打印引擎版本，用于验证工程可正常加载运行。
## 注意：这是初始化期的临时桩，真正的游戏流程在 /start 设计后接入，届时替换本文件。

func _ready() -> void:
	# 打印引擎版本，证明工程已被引擎正确加载（headless 与真机一致）
	print("江湖 启动，Godot 引擎版本：", Engine.get_version_info().string)

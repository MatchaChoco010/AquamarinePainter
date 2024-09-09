## リストのDnDの先を示すカーソルのクラス。
class_name ListDropCursor
extends BoxContainer


@onready var _spacing: ColorRect = $Control/ColorRect


## インデントを指定する。
func set_depth(depth: int) -> void:
	_spacing.position.x = 50 + depth * 32

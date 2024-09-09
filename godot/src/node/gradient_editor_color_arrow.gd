class_name GradientEditorColorArrow
extends Panel


@onready var _color_rect: ColorRect = %ColorRect;
@onready var _sprite: Sprite2D = %Sprite2D;


## 色。
var color: Color = Color(0, 0, 0, 1):
	set(value):
		color = value
		_color_rect.color = value
	get:
		return color

## 色のオフセット。
var offset: float = 0.0

## ホバー状態。
var hover: bool = false


func _ready() -> void:
	_sprite.material = _sprite.material.duplicate()


## 選択する。
func select() -> void:
	(_sprite.material as ShaderMaterial).set_shader_parameter("fill_color", Color(0.5, 0.5, 0.8, 1))


## 選択を解除する。
func deselect() -> void:
	(_sprite.material as ShaderMaterial).set_shader_parameter("fill_color", Color(0.1, 0.1, 0.1, 1))


## マウスがエリアに入ったときに呼ばれるコールバック。
func _on_mouse_entered() -> void:
	hover = true


## マウスがエリアから出たときに呼ばれるコールバック。
func _on_mouse_exited() -> void:
	hover = false

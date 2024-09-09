## マテリアル選択ポップアップのアイテムのノード。
class_name MaterialSelectPopupItem
extends PanelContainer


@onready var _node: PanelContainer = $"."
@onready var _color_panel: Panel = %Color
@onready var _name_label: Label = %Label

## この要素がクリックされたときに発火するシグナル。
signal on_clicked()

## マウスオーバーしているかどうか。
var mouse_over: bool = false
## このマテリアルのマテリアルid。
var material_id: String = ""

## マテリアルの単一色の表示マテリアル。
@export var _color_material: ShaderMaterial
## マテリアルの線形グラデーションの表示マテリアル。
@export var _linear_gradient_material: ShaderMaterial
## マテリアルの放射グラデーションの表示マテリアル。
@export var _radial_gradient_material: ShaderMaterial


func _ready() -> void:
	_node.add_theme_stylebox_override("panel", _node.get_theme_stylebox("panel").duplicate() as StyleBox)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		var node_mouse_position := _node.get_local_mouse_position()
		var rect := Rect2(Vector2.ZERO, _node.size)
		if rect.has_point(node_mouse_position) and mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			on_clicked.emit()


## マテリアルの色を設定する。
func set_color(color: Color) -> void:
	var mat := _color_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("fill_color", color)
	_color_panel.material = mat


## マテリアルの線形グラデーションを設定する。
func set_linear_gradient(gradient_texture: GradientTexture1D) -> void:
	var mat := _linear_gradient_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("gradient_texture", gradient_texture)
	_color_panel.material = mat


## マテリアルの放射グラデーションを設定する。
func set_radial_gradient(gradient_texture: GradientTexture1D) -> void:
	var mat := _radial_gradient_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("gradient_texture", gradient_texture)
	_color_panel.material = mat


## マテリアルの名前を設定する。
func set_material_name(new_name: String) -> void:
	_name_label.text = new_name


## マウスオーバーしたときに呼び出されるコールバック。
func _on_mouse_entered() -> void:
	mouse_over = true
	var style_box := _node.get_theme_stylebox("panel") as StyleBoxFlat
	style_box.bg_color = Color(0.5, 0.8, 0.9, 0.25)


## マウスが外れたときに呼び出されるコールバック。
func _on_mouse_exited() -> void:
	mouse_over = false
	var style_box := _node.get_theme_stylebox("panel") as StyleBoxFlat
	style_box.bg_color = Color.TRANSPARENT

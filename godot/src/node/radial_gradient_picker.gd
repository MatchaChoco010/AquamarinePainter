class_name RadialGradientPicker
extends Popup


@onready var _center_x: SpinBox = %CenterX
@onready var _center_y: SpinBox = %CenterY
@onready var _handle_1_x: SpinBox = %Handle1X
@onready var _handle_1_y: SpinBox = %Handle1Y
@onready var _handle_2_x: SpinBox = %Handle2X
@onready var _handle_2_y: SpinBox = %Handle2Y
@onready var _gradient_editor: GradientEditor = %GradientEditor

## グラデーションが変更したときのシグナル。
signal on_gradient_changed(gradient_material: RadialGradientPaintMaterial)

## 現在編集中のマテリアル。
var _gradient_material: RadialGradientPaintMaterial


func _ready() -> void:
	_gradient_editor.on_gradient_changed.connect(_on_gradient_editor_on_gradient_changed)


## ピッカーを表示する。
func show_picker(gradient_material: RadialGradientPaintMaterial) -> void:
	_gradient_editor.set_gradient(gradient_material.gradient)
	_center_x.set_value_no_signal(gradient_material.center_point.x)
	_center_y.set_value_no_signal(gradient_material.center_point.y)
	_handle_1_x.set_value_no_signal(gradient_material.handle_1_point.x)
	_handle_1_y.set_value_no_signal(gradient_material.handle_1_point.y)
	_handle_2_x.set_value_no_signal(gradient_material.handle_2_point.x)
	_handle_2_y.set_value_no_signal(gradient_material.handle_2_point.y)
	_gradient_material = gradient_material
	show()


## グラデーションが変化したときのコールバック。
func _on_gradient_editor_on_gradient_changed(gradient: Gradient) -> void:
	_gradient_material.gradient = gradient
	_gradient_material.gradient_texture.gradient = gradient
	on_gradient_changed.emit(_gradient_material)
	Main.on_change_material_parameters_changed.emit()


## ピッカーが非表示になったときに呼び出されるコールバック。
func _on_popup_hide() -> void:
	_gradient_editor.remove_color_arrow()
	_gradient_material = null


## 中心点のXの値が変わったときのコールバック。
func _on_center_x_value_changed(value: float) -> void:
	var delta_x := value - _gradient_material.center_point.x
	_gradient_material.center_point.x = value
	_gradient_material.handle_1_point.x += delta_x
	_gradient_material.handle_2_point.x += delta_x
	_handle_1_x.set_value_no_signal(_gradient_material.handle_1_point.x)
	_handle_2_x.set_value_no_signal(_gradient_material.handle_2_point.x)
	Main.on_change_material_parameters_changed.emit()


## 中心点のYの値が変わったときのコールバック。
func _on_center_y_value_changed(value: float) -> void:
	var delta_y := value - _gradient_material.center_point.y
	_gradient_material.center_point.y = value
	_gradient_material.handle_1_point.y += delta_y
	_gradient_material.handle_2_point.y += delta_y
	_handle_1_y.set_value_no_signal(_gradient_material.handle_1_point.y)
	_handle_2_y.set_value_no_signal(_gradient_material.handle_2_point.y)
	Main.on_change_material_parameters_changed.emit()


## ハンドル1のXの値が変わったときのコールバック。
func _on_handle_1x_value_changed(value: float) -> void:
	_gradient_material.handle_1_point.x = value
	var handle_2_length := (_gradient_material.handle_2_point - _gradient_material.center_point).length()
	var handle_2_dir := (_gradient_material.handle_1_point - _gradient_material.center_point).normalized().rotated(-PI / 2)
	_gradient_material.handle_2_point = _gradient_material.center_point + handle_2_dir * handle_2_length
	_handle_2_x.set_value_no_signal(_gradient_material.handle_2_point.x)
	_handle_2_y.set_value_no_signal(_gradient_material.handle_2_point.y)
	Main.on_change_material_parameters_changed.emit()


## ハンドル1のYの値が変わったときのコールバック。
func _on_handle_1y_value_changed(value: float) -> void:
	_gradient_material.handle_1_point.y = value
	var handle_2_length := (_gradient_material.handle_2_point - _gradient_material.center_point).length()
	var handle_2_dir := (_gradient_material.handle_1_point - _gradient_material.center_point).normalized().rotated(-PI / 2)
	_gradient_material.handle_2_point = _gradient_material.center_point + handle_2_dir * handle_2_length
	_handle_2_x.set_value_no_signal(_gradient_material.handle_2_point.x)
	_handle_2_y.set_value_no_signal(_gradient_material.handle_2_point.y)
	Main.on_change_material_parameters_changed.emit()


## ハンドル2のXの値が変わったときのコールバック。
func _on_handle_2x_value_changed(value: float) -> void:
	_gradient_material.handle_2_point.x = value
	var handle_1_length := (_gradient_material.handle_1_point - _gradient_material.center_point).length()
	var handle_1_dir := (_gradient_material.handle_2_point - _gradient_material.center_point).normalized().rotated(PI / 2)
	_gradient_material.handle_1_point = _gradient_material.center_point + handle_1_dir * handle_1_length
	_handle_1_x.set_value_no_signal(_gradient_material.handle_1_point.x)
	_handle_1_y.set_value_no_signal(_gradient_material.handle_1_point.y)
	Main.on_change_material_parameters_changed.emit()


## ハンドル2のYの値が変わったときのコールバック。
func _on_handle_2y_value_changed(value: float) -> void:
	_gradient_material.handle_2_point.y = value
	var handle_1_length := (_gradient_material.handle_1_point - _gradient_material.center_point).length()
	var handle_1_dir := (_gradient_material.handle_2_point - _gradient_material.center_point).normalized().rotated(PI / 2)
	_gradient_material.handle_1_point = _gradient_material.center_point + handle_1_dir * handle_1_length
	_handle_1_x.set_value_no_signal(_gradient_material.handle_1_point.x)
	_handle_1_y.set_value_no_signal(_gradient_material.handle_1_point.y)
	Main.on_change_material_parameters_changed.emit()


## 編集ボタンが押されたときのコールバック。
func _on_edit_button_pressed() -> void:
	Main.emit_start_edit_radial_gradient(_gradient_material)

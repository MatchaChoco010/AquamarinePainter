class_name LinearGradientPicker
extends Popup


@onready var _start_x: SpinBox = %StartX
@onready var _start_y: SpinBox = %StartY
@onready var _end_x: SpinBox = %EndX
@onready var _end_y: SpinBox = %EndY
@onready var _gradient_editor: GradientEditor = %GradientEditor

## グラデーションが変更したときのシグナル。
signal on_gradient_changed(gradient_material: LinearGradientPaintMaterial)

## 現在編集中のマテリアル。
var _gradient_material: LinearGradientPaintMaterial


func _ready() -> void:
	_gradient_editor.on_gradient_changed.connect(_on_gradient_editor_on_gradient_changed)


## ピッカーを表示する。
func show_picker(gradient_material: LinearGradientPaintMaterial) -> void:
	_gradient_editor.set_gradient(gradient_material.gradient)
	_start_x.set_value_no_signal(gradient_material.start_point.x)
	_start_y.set_value_no_signal(gradient_material.start_point.y)
	_end_x.set_value_no_signal(gradient_material.end_point.x)
	_end_y.set_value_no_signal(gradient_material.end_point.y)
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


## 開始点のXの値が変わったときのコールバック。
func _on_start_x_value_changed(value: float) -> void:
	_gradient_material.start_point.x = value
	Main.on_change_material_parameters_changed.emit()


## 開始点のYの値が変わったときのコールバック。
func _on_start_y_value_changed(value: float) -> void:
	_gradient_material.start_point.y = value
	Main.on_change_material_parameters_changed.emit()


## 終了点のXの値が変わったときのコールバック。
func _on_end_x_value_changed(value: float) -> void:
	_gradient_material.end_point.x = value
	Main.on_change_material_parameters_changed.emit()


## 終了点のYの値が変わったときのコールバック。
func _on_end_y_value_changed(value: float) -> void:
	_gradient_material.end_point.y = value
	Main.on_change_material_parameters_changed.emit()


## 編集ボタンが押されたときのコールバック。
func _on_edit_button_pressed() -> void:
	Main.emit_start_edit_linear_gradient(_gradient_material)

## レイヤー設定タブを扱うクラス。
class_name LayerSettingTab
extends Node


@onready var _fill_material: HBoxContainer = %FillMaterial
@onready var _fill_empty_panel: Panel = %FillMaterial/EmptyButton/Panel
@onready var _fill_fill_panel: Panel = %FillMaterial/FillButton/Panel
@onready var _fill_button: Button = %FillMaterial/ColorButton
@onready var _fill_color: Panel = %FillMaterial/ColorButton/HBoxContainer/Color
@onready var _fill_label: Label = %FillMaterial/ColorButton/HBoxContainer/Label
@onready var _fill_popup: MaterialSelectPopup = %FillMaterial/ColorButton/MaterialSelectPopup

@onready var _line_material: HBoxContainer = %LineMaterial
@onready var _line_empty_panel: Panel = %LineMaterial/EmptyButton/Panel
@onready var _line_fill_panel: Panel = %LineMaterial/FillButton/Panel
@onready var _line_button: Button = %LineMaterial/ColorButton
@onready var _line_color: Panel = %LineMaterial/ColorButton/HBoxContainer/Color
@onready var _line_label: Label = %LineMaterial/ColorButton/HBoxContainer/Label
@onready var _line_popup: MaterialSelectPopup = %LineMaterial/ColorButton/MaterialSelectPopup

@onready var _line_width: HBoxContainer = %LineWidth
@onready var _line_width_slider: HSlider = %LineWidth/HSlider
@onready var _line_width_spin_box: SpinBox = %LineWidth/SpinBox

@onready var _fill_layer_material: HBoxContainer = %FillLayerMaterial
@onready var _fill_layer_button: Button = %FillLayerMaterial/ColorButton
@onready var _fill_layer_color: Panel = %FillLayerMaterial/ColorButton/HBoxContainer/Color
@onready var _fill_layer_label: Label = %FillLayerMaterial/ColorButton/HBoxContainer/Label
@onready var _fill_layer_popup: MaterialSelectPopup = %FillLayerMaterial/ColorButton/MaterialSelectPopup

## マテリアルmissing時の表示用マテリアル。
@export var _missing_material: ShaderMaterial
## マテリアルの単一色の表示マテリアル。
@export var _color_material: ShaderMaterial
## マテリアルの線形グラデーションの表示マテリアル。
@export var _linear_gradient_material: ShaderMaterial
## マテリアルの放射グラデーションの表示マテリアル。
@export var _radial_gradient_material: ShaderMaterial

## 最後に線幅を変更した時刻。
var _last_line_width_changed_time: int = -1
## 線幅変更があってからcommitしたかどうか。
var _last_line_width_changed_commit: bool = true


func _process(_delta: float) -> void:
	if not Main.document_opened:
		_fill_material.visible = false
		_line_material.visible = false
		_line_width.visible = false
		_fill_layer_material.visible = false
		_last_line_width_changed_commit = true
		return

	# 現在選択中のレイヤーが存在しない場合は、表示を消す。
	if Main.layers.selected_layers.size() == 0:
		_fill_material.visible = false
		_line_material.visible = false
		_line_width.visible = false
		_fill_layer_material.visible = false
		_last_line_width_changed_commit = true
		return

	# 最後に選択されたレイヤーの情報を表示する
	var last_selected_layer := Main.layers.last_selected_layer
	if last_selected_layer is PathPaintLayer:
		var path_layer := last_selected_layer as PathPaintLayer

		_fill_material.visible = true
		_line_material.visible = true
		_line_width.visible = true
		_fill_layer_material.visible = false

		# fillの設定
		if path_layer.filled:
			_fill_empty_panel.visible = true
			_fill_fill_panel.visible = false
		else:
			_fill_empty_panel.visible = false
			_fill_fill_panel.visible = true
		var fill_material := Main.materials.get_material(path_layer.fill_material_id)
		if fill_material is ColorPaintMaterial:
			var color_material := fill_material as ColorPaintMaterial
			var material := _color_material.duplicate() as ShaderMaterial
			material.set_shader_parameter("fill_color", color_material.color)
			_fill_color.material = material
		elif fill_material is LinearGradientPaintMaterial:
			var gradient_material := fill_material as LinearGradientPaintMaterial
			var material := _linear_gradient_material.duplicate() as ShaderMaterial
			material.set_shader_parameter("gradient_texture", gradient_material.gradient_texture)
			_fill_color.material = material
		elif fill_material is RadialGradientPaintMaterial:
			var gradient_material := fill_material as RadialGradientPaintMaterial
			var material := _radial_gradient_material.duplicate() as ShaderMaterial
			material.set_shader_parameter("gradient_texture", gradient_material.gradient_texture)
			_fill_color.material = material
		elif fill_material == null:
			_fill_color.material = _missing_material
		_fill_label.text = Main.materials.get_material_name(path_layer.fill_material_id)

		# lineの設定
		if path_layer.outlined:
			_line_empty_panel.visible = true
			_line_fill_panel.visible = false
		else:
			_line_empty_panel.visible = false
			_line_fill_panel.visible = true
		var line_material := Main.materials.get_material(path_layer.outline_material_id)
		if line_material is ColorPaintMaterial:
			var color_material := line_material as ColorPaintMaterial
			var material := _color_material.duplicate() as ShaderMaterial
			material.set_shader_parameter("fill_color", color_material.color)
			_line_color.material = material
		elif line_material is LinearGradientPaintMaterial:
			var gradient_material := line_material as LinearGradientPaintMaterial
			var material := _linear_gradient_material.duplicate() as ShaderMaterial
			material.set_shader_parameter("gradient_texture", gradient_material.gradient_texture)
			_line_color.material = material
		elif line_material is RadialGradientPaintMaterial:
			var gradient_material := line_material as RadialGradientPaintMaterial
			var material := _radial_gradient_material.duplicate() as ShaderMaterial
			material.set_shader_parameter("gradient_texture", gradient_material.gradient_texture)
			_line_color.material = material
		elif line_material == null:
			_line_color.material = _missing_material
		_line_label.text = Main.materials.get_material_name(path_layer.outline_material_id)

		# line widthの設定
		_line_width_slider.set_value_no_signal(path_layer.outline_width)
		_line_width_spin_box.set_value_no_signal(path_layer.outline_width)
		if path_layer.outlined:
			_line_width_slider.editable = true
			_line_width_spin_box.editable = true
		else:
			_line_width_slider.editable = false
			_line_width_spin_box.editable = false

	elif last_selected_layer is FillPaintLayer:
		var fill_layer := last_selected_layer as FillPaintLayer

		_fill_material.visible = false
		_line_material.visible = false
		_line_width.visible = false
		_fill_layer_material.visible = true

		var fill_material := Main.materials.get_material(fill_layer.fill_material_id)
		if fill_material is ColorPaintMaterial:
			var color_material := fill_material as ColorPaintMaterial
			var material := _color_material.duplicate() as ShaderMaterial
			material.set_shader_parameter("fill_color", color_material.color)
			_fill_layer_color.material = material
		elif fill_material is LinearGradientPaintMaterial:
			var gradient_material := fill_material as LinearGradientPaintMaterial
			var material := _linear_gradient_material.duplicate() as ShaderMaterial
			material.set_shader_parameter("gradient_texture", gradient_material.gradient_texture)
			_fill_layer_color.material = material
		elif fill_material is RadialGradientPaintMaterial:
			var gradient_material := fill_material as RadialGradientPaintMaterial
			var material := _radial_gradient_material.duplicate() as ShaderMaterial
			material.set_shader_parameter("gradient_texture", gradient_material.gradient_texture)
			_fill_layer_color.material = material
		else:
			_fill_layer_color.material = _missing_material
		_fill_layer_label.text = Main.materials.get_material_name(fill_layer.fill_material_id)

	elif last_selected_layer is GroupPaintLayer:
		_fill_material.visible = false
		_line_material.visible = false
		_line_width.visible = false
		_fill_layer_material.visible = false

	# 線幅が最後に変更されてから500ms経っていて、かつ、コミットされていなければコミットする。
	if not _last_line_width_changed_commit and Time.get_ticks_msec() - _last_line_width_changed_time > 500:
		_last_line_width_changed_commit = true
		Main.commit_history()


## 線幅を調整中かどうか。
func is_manipulating_line_width() -> bool:
	return not _last_line_width_changed_commit


## 塗りをemptyにするボタンを押したときのコールバック。
func _on_empty_button_button_down() -> void:
	Main.layers.set_fill_of_selected_layers(false)
	Main.commit_history()


## 塗りをfillにするボタンを押したときのコールバック。
func _on_fill_button_button_down() -> void:
	Main.layers.set_fill_of_selected_layers(true)
	Main.commit_history()


## 塗りの色のボタンを押したときのコールバック。
func _on_color_button_button_down() -> void:
	_fill_popup.show()

	var pos := _fill_button.get_screen_position() + Vector2(0, 44)
	var popup_size := _fill_popup.get_visible_rect().size

	# get safe area
	var safe_area := DisplayServer.get_display_safe_area()

	# clamp pos
	if pos.x + popup_size.x > safe_area.position.x + safe_area.size.x:
		pos.x = safe_area.position.x + safe_area.size.x - popup_size.x
	if pos.y + popup_size.y > safe_area.position.y + safe_area.size.y:
		pos.y = safe_area.position.y + safe_area.size.y - popup_size.y

	_fill_popup.position = pos


## 塗りのマテリアルを選択したときのコールバック。
func _on_material_list_popup_on_material_selected(material_id: String) -> void:
	Main.layers.set_fill_material_of_selected_path_layers(material_id)
	Main.commit_history()


## 線をemptyにするボタンを押したときのコールバック。
func _on_line_empty_button_button_down() -> void:
	Main.layers.set_line_of_selected_layers(false)
	Main.commit_history()


## 線をfillにするボタンを押したときのコールバック。
func _on_line_fill_button_button_down() -> void:
	Main.layers.set_line_of_selected_layers(true)
	Main.commit_history()


## 線の色のボタンを押したときのコールバック。
func _on_line_color_button_button_down() -> void:
	_line_popup.show()

	var pos := _line_button.get_screen_position() + Vector2(0, 44)
	var popup_size := _line_popup.get_visible_rect().size

	# get safe area
	var safe_area := DisplayServer.get_display_safe_area()

	# clamp pos
	if pos.x + popup_size.x > safe_area.position.x + safe_area.size.x:
		pos.x = safe_area.position.x + safe_area.size.x - popup_size.x
	if pos.y + popup_size.y > safe_area.position.y + safe_area.size.y:
		pos.y = safe_area.position.y + safe_area.size.y - popup_size.y

	_line_popup.position = pos


## 線のマテリアルを選択したときのコールバック。
func _on_line_material_list_popup_on_material_selected(material_id: String) -> void:
	Main.layers.set_line_material_of_selected_path_layers(material_id)
	Main.commit_history()


## 線幅スライダーの値の変更で呼び出されるコールバック。
func _on_h_slider_value_changed(value: float) -> void:
	_line_width_spin_box.set_value_no_signal(value)
	Main.layers.set_line_width_of_selected_path_layers(value)
	_last_line_width_changed_time = Time.get_ticks_msec()
	_last_line_width_changed_commit = false


## 線幅スピンボックスの値の変更で呼び出されるコールバック。
func _on_spin_box_value_changed(value: float) -> void:
	_line_width_slider.set_value_no_signal(value)
	Main.layers.set_line_width_of_selected_path_layers(value)
	_last_line_width_changed_time = Time.get_ticks_msec()
	_last_line_width_changed_commit = false


## マテリアルの色のボタンを押したときのコールバック。
func _on_fill_layer_color_button_button_down() -> void:
	_fill_layer_popup.show()

	var pos := _fill_layer_button.get_screen_position() + Vector2(0, 44)
	var popup_size := _fill_layer_popup.get_visible_rect().size

	# get safe area
	var safe_area := DisplayServer.get_display_safe_area()

	# clamp pos
	if pos.x + popup_size.x > safe_area.position.x + safe_area.size.x:
		pos.x = safe_area.position.x + safe_area.size.x - popup_size.x
	if pos.y + popup_size.y > safe_area.position.y + safe_area.size.y:
		pos.y = safe_area.position.y + safe_area.size.y - popup_size.y

	_fill_layer_popup.position = pos


## 塗りつぶしの塗りマテリアルを設定したときのコールバック。
func _on_material_list_popup_on_fill_layer_material_selected(material_id: String) -> void:
	Main.layers.set_fill_material_of_selected_fill_layers(material_id)
	Main.commit_history()

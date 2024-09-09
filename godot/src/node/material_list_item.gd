## マテリアルリストの要素のノードのクラス。
class_name MaterialListItem
extends PanelContainer


@onready var _node: PanelContainer = $"."
@onready var _color_panel: Panel = %Color
@onready var _name_text: LineEdit = %NameText
@onready var _popup: PopupPanel = $PopupPanel
@onready var _dragging_panel: Panel = $DraggingtPanel
@onready var _color_picker: ColorPicker = $PopupPanel/ColorPicker
@onready var _linear_gradient_picker: LinearGradientPicker = $LinearGradientPicker
@onready var _radial_gradient_picker: RadialGradientPicker = $RadialGradientPicker

## この要素がクリックされたときに発火するシグナル。
signal on_selected()

## マウスオーバーしているかどうか。
var mouse_over: bool = false
## 上半分にマウスオーバーしているかどうか。
var mouse_over_top: bool = false
## 下半分にマウスオーバーしているかどうか。
var mouse_over_bottom: bool = false
## このマテリアルのマテリアルid。
var material_id: String = ""

## 編集中のテキスト。
var _editing_name: String = ""
## 名前を編集したかどうか。
var _edited_name: bool = false
## 選択中かどうか。
var _selected: bool = false

## 色の操作中かどうか。
var _is_manipulate_color: bool = false

## マテリアルの単一色の表示マテリアル。
@export var _color_material: ShaderMaterial
## マテリアルの線形グラデーションの表示マテリアル。
@export var _linear_gradient_material: ShaderMaterial
## マテリアルの放射グラデーションの表示マテリアル。
@export var _radial_gradient_material: ShaderMaterial


func _ready() -> void:
	_node.add_theme_stylebox_override("panel", _node.get_theme_stylebox("panel").duplicate() as StyleBox)
	_name_text.add_theme_stylebox_override("focus", _name_text.get_theme_stylebox("focus").duplicate() as StyleBox)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		var mouse_position := _node.get_local_mouse_position()

		# アイテムがクリックされたら選択して、アイテム外がクリックされたらtextを編集状態解除する
		var rect := Rect2(Vector2.ZERO, size)
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed and mouse_over:
			if rect.has_point(mouse_position):
				if not _selected:
					# 他のアイテムのrename確定処理が終わってからclickedを呼び出す
					(func x() -> void: on_selected.emit()).call_deferred()
			else:
				_exit_edit_name()

		# ダブルクリックで名前変更
		var text_mouse_position := _name_text.get_local_mouse_position()
		var text_rect := Rect2(Vector2.ZERO, _name_text.size)
		if text_rect.has_point(text_mouse_position) and mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.double_click:
			_enter_edit_name()


## テキスト編集状態に入る。
func _enter_edit_name() -> void:
	var style_box := _name_text.get_theme_stylebox("focus") as StyleBoxFlat
	_name_text.editable = true
	_name_text.selecting_enabled = true
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	_editing_name = _name_text.text


## テキストを編集状態解除する。
func _exit_edit_name() -> void:
	var style_box := _name_text.get_theme_stylebox("focus") as StyleBoxFlat
	_name_text.editable = false
	_name_text.selecting_enabled = false
	style_box.border_width_top = 0
	style_box.border_width_bottom = 0
	style_box.border_width_left = 0
	style_box.border_width_right = 0
	if _selected:
		Main.materials.rename_material(_editing_name)
	if _edited_name:
		_edited_name = false
		Main.commit_history()


## このマテリアルアイテムに色を設定する。
func set_color(color: Color) -> void:
	var mat := _color_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("fill_color", color)
	_color_panel.material = mat


## このマテリアルアイテムに線形グラデーションを設定する。
func set_linear_gradient(gradient_texture: GradientTexture1D) -> void:
	var mat := _linear_gradient_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("gradient_texture", gradient_texture)
	_color_panel.material = mat


## このマテリアルアイテムに放射グラデーションを設定する。
func set_radial_gradient(gradient_texture: GradientTexture1D) -> void:
	var mat := _radial_gradient_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("gradient_texture", gradient_texture)
	_color_panel.material = mat


## マテリアルの名前を設定する。
func set_material_name(new_name: String) -> void:
	_name_text.text = new_name
	_editing_name = _name_text.text


## 選択中の表示を設定する。
func set_selected(selected: bool) -> void:
	var style_box := _node.get_theme_stylebox("panel") as StyleBoxFlat
	if selected:
		style_box.bg_color = Color(0.5, 0.8, 0.9, 0.25)
	else:
		style_box.bg_color = Color.TRANSPARENT
	_selected = selected


## ドラッグ中の表示を設定する。
func set_dragging(dragging: bool) -> void:
	_dragging_panel.visible = dragging


## 色の操作中かどうか。
func is_manipulate_color() -> bool:
	return _is_manipulate_color


## 色のボタンを押したときのコールバック。
func _on_button_button_up() -> void:
	var paint_material := Main.materials.get_material(material_id)
	if paint_material is ColorPaintMaterial:
		var color_material := paint_material as ColorPaintMaterial
		_color_picker.color = color_material.color
		_popup.show()
		_is_manipulate_color = true

		var pos := _node.get_screen_position() + Vector2(0, 32)
		var popup_size := _popup.get_visible_rect().size

		# get safe area
		var safe_area := DisplayServer.get_display_safe_area()

		# clamp pos
		if pos.x + popup_size.x > safe_area.position.x + safe_area.size.x:
			pos.x = safe_area.position.x + safe_area.size.x - popup_size.x
		if pos.y + popup_size.y > safe_area.position.y + safe_area.size.y:
			pos.y = safe_area.position.y + safe_area.size.y - popup_size.y

		_popup.position = pos
	elif paint_material is LinearGradientPaintMaterial:
		var linear_gradient_material := paint_material as LinearGradientPaintMaterial
		_linear_gradient_picker.show_picker(linear_gradient_material)
		_is_manipulate_color = true

		var pos := _node.get_screen_position() + Vector2(0, 32)
		var popup_size := _linear_gradient_picker.get_visible_rect().size

		# get safe area
		var safe_area := DisplayServer.get_display_safe_area()

		# clamp pos
		if pos.x + popup_size.x > safe_area.position.x + safe_area.size.x:
			pos.x = safe_area.position.x + safe_area.size.x - popup_size.x
		if pos.y + popup_size.y > safe_area.position.y + safe_area.size.y:
			pos.y = safe_area.position.y + safe_area.size.y - popup_size.y

		_linear_gradient_picker.position = pos
	elif paint_material is RadialGradientPaintMaterial:
		var radial_gradient_material := paint_material as RadialGradientPaintMaterial
		_radial_gradient_picker.show_picker(radial_gradient_material)
		_is_manipulate_color = true

		var pos := _node.get_screen_position() + Vector2(0, 32)
		var popup_size := _radial_gradient_picker.get_visible_rect().size

		# get safe area
		var safe_area := DisplayServer.get_display_safe_area()

		# clamp pos
		if pos.x + popup_size.x > safe_area.position.x + safe_area.size.x:
			pos.x = safe_area.position.x + safe_area.size.x - popup_size.x
		if pos.y + popup_size.y > safe_area.position.y + safe_area.size.y:
			pos.y = safe_area.position.y + safe_area.size.y - popup_size.y

		_radial_gradient_picker.position = pos

## カラーピッカーの色が変わったときに呼び出されるコールバック。
func _on_color_picker_color_changed(color: Color) -> void:
	var mat := _color_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("fill_color", color)
	_color_panel.material = mat
	var paint_material := Main.materials.get_material(material_id)
	if paint_material is ColorPaintMaterial:
		var color_material := paint_material as ColorPaintMaterial
		color_material.color = color
	Main.on_change_material_parameters_changed.emit()


## 線形グラデーションピッカーのグラデーションが変わったときに呼び出されるコールバック。
func _on_linear_gradient_picker_on_gradient_changed(gradient_material: LinearGradientPaintMaterial) -> void:
	var mat := _linear_gradient_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("gradient_texture", gradient_material.gradient_texture)
	_color_panel.material = mat


## 放射グラデーションピッカーのグラデーションが変わったときに呼び出されるコールバック。
func _on_radial_gradient_picker_on_gradient_changed(gradient_material: RadialGradientPaintMaterial) -> void:
	var mat := _radial_gradient_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("gradient_texture", gradient_material.gradient_texture)
	_color_panel.material = mat


## 名前のテキストを確定したときに呼ばれるコールバック。
func _on_line_edit_text_submitted(new_text: String) -> void:
	Main.materials.rename_material(new_text)
	_exit_edit_name()


## 名前のテキストを変更したときに呼ばれるコールバック。
func _on_line_edit_text_changed(new_text: String) -> void:
	_editing_name = new_text
	_edited_name = true


## マウスオーバーしたときに呼び出されるコールバック。
func _on_padding_mouse_entered() -> void:
	mouse_over = true
	var mouse_pos := get_local_mouse_position()
	if mouse_pos.y > size.y / 2:
		mouse_over_bottom = true
		mouse_over_top = false
	else:
		mouse_over_bottom = false
		mouse_over_top = true


## マウスが外れたときに呼び出されるコールバック。
func _on_padding_mouse_exited() -> void:
	mouse_over = false
	mouse_over_bottom = false
	mouse_over_top = false


## ポップアップが閉じたときのコールバック。
func _on_popup_panel_popup_hide() -> void:
	_is_manipulate_color = false
	Main.commit_history()


## 線形グラデーションピッカーが閉じたときのコールバック。
func _on_linear_gradient_picker_popup_hide() -> void:
	_is_manipulate_color = false
	Main.commit_history()


## 放射グラデーションピッカーが閉じたときのコールバック。
func _on_radial_gradient_picker_popup_hide() -> void:
	_is_manipulate_color = false
	Main.commit_history()

class_name GradientEditor
extends VBoxContainer


const _color_allow_scene: PackedScene = preload("res://scenes/node/gradient_editor_color_arrow.tscn")

@onready var _color_rect: ColorRect = %ColorRect
@onready var _color_picker: ColorPicker = %ColorPicker

## グラデーションが変更したときのシグナル。
signal on_gradient_changed(gradient: Gradient)

## グラデーション。
var _gradient: Gradient = Gradient.new()
## グラデーションテクスチャ。
var _gradient_texture: GradientTexture1D = GradientTexture1D.new()

## カラーアローのリスト。
var _color_arrows: Array[GradientEditorColorArrow] = []

## 現在選択中のカラーアロー。
var _selected_color_arrow: GradientEditorColorArrow = null

## カラーアローを押下しているかどうか。
var _color_arrow_pressing: bool = false

## 更新が必要かどうか。
var _need_update: bool = false


func _ready() -> void:
	_color_rect.material = _color_rect.material.duplicate()


func _process(_delta: float) -> void:
	if _need_update:
		_gradient = Gradient.new()

		_color_arrows.sort_custom(func(a: GradientEditorColorArrow, b: GradientEditorColorArrow) -> bool:
			return a.offset < b.offset
		)

		var colors: Array[Color] = []
		var offsets: Array[float] = []

		for arrow in _color_arrows:
			colors.push_back(arrow.color)
			offsets.push_back(arrow.offset)
			arrow.position.x = arrow.offset * _color_rect.size.x - 12
			if arrow == _selected_color_arrow:
				arrow.select()
			else:
				arrow.deselect()

		_gradient.colors = colors
		_gradient.offsets = offsets
		_gradient_texture.gradient = _gradient

		(_color_rect.material as ShaderMaterial).set_shader_parameter("gradient_texture", _gradient_texture)

		on_gradient_changed.emit(_gradient)

		_need_update = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton

		# mouse down
		if not _color_arrow_pressing and mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			for arrow in _color_arrows:
				if arrow.hover:
					if _selected_color_arrow != null:
						_selected_color_arrow.deselect()

					_selected_color_arrow = arrow
					_selected_color_arrow.select()
					_color_picker.color = _selected_color_arrow.color

					_color_arrow_pressing = true
					break
		# mouse up
		elif _color_arrow_pressing and not mouse_event.pressed:
			_color_arrow_pressing = false
			_need_update = true

	if event is InputEventMouseMotion:
		# mouse drag
		if _color_arrow_pressing:
			var mouse_pos := _color_rect.get_local_mouse_position()
			var offset := mouse_pos.x / _color_rect.size.x
			offset = clamp(offset, 0.0, 1.0)
			_selected_color_arrow.offset = offset
			_need_update = true


## グラデーションを設定する。
func set_gradient(gradient: Gradient) -> void:
	_gradient = gradient.duplicate()
	_gradient_texture.gradient = _gradient

	for arrow in _color_arrows:
		arrow.queue_free()
	_color_arrows.clear()

	for index in _gradient.colors.size():
		var arrow := _color_allow_scene.instantiate() as GradientEditorColorArrow
		_color_rect.add_child(arrow)
		_color_arrows.push_back(arrow)
		arrow.color = _gradient.colors[index]
		arrow.offset = _gradient.offsets[index]

	if _color_arrows.size() > 0:
		_selected_color_arrow = _color_arrows[0]
		_color_picker.color = _selected_color_arrow.color

	_need_update = true


## カラーアローを削除する。
func remove_color_arrow() -> void:
	for arrow in _color_arrows:
		arrow.queue_free()
	_color_arrows.clear()


## カラーピッカーの色が変更されたときに呼ばれるコールバック。
func _on_color_picker_color_changed(color: Color) -> void:
	if _selected_color_arrow != null:
		_selected_color_arrow.color = color
		_need_update = true


## プラスボタンが押下されたときに呼ばれるコールバック。
func _on_plus_button_pressed() -> void:
	if _color_arrows.size() == 0:
		var arrow := _color_allow_scene.instantiate() as GradientEditorColorArrow
		_color_rect.add_child(arrow)
		_color_arrows.push_back(arrow)
	elif _color_arrows.size() == 1:
		var exists_arrow_offset := _color_arrows[0].offset
		var arrow := _color_allow_scene.instantiate() as GradientEditorColorArrow
		_color_rect.add_child(arrow)
		_color_arrows.push_back(arrow)
		arrow.color = Color(1, 1, 1, 1)
		arrow.offset = 0.0 if exists_arrow_offset > 0.5 else 1.0
	else:
		var offset := 1.0
		var next_select_arrow: GradientEditorColorArrow = null
		for index in _color_arrows.size() - 1:
			if _color_arrows[index] == _selected_color_arrow:
				next_select_arrow = _color_arrows[index + 1]
				break
		if next_select_arrow == null:
			var prev_select_arrow: GradientEditorColorArrow = null
			for index in range(1, _color_arrows.size()):
				if _color_arrows[index] == _selected_color_arrow:
					prev_select_arrow = _color_arrows[index - 1]
					break
			offset = (_selected_color_arrow.offset + prev_select_arrow.offset) / 2
		else:
			offset = (_selected_color_arrow.offset + next_select_arrow.offset) / 2
		var arrow := _color_allow_scene.instantiate() as GradientEditorColorArrow
		_color_rect.add_child(arrow)
		_color_arrows.push_back(arrow)
		arrow.color = Color(1, 1, 1, 1)
		arrow.offset = offset

	_need_update = true


## マイナスボタンが押下されたときに呼ばれるコールバック。
func _on_minus_button_pressed() -> void:
	if _color_arrows.size() > 1:
		_selected_color_arrow.queue_free()
		_color_arrows.erase(_selected_color_arrow)
		_selected_color_arrow = _color_arrows[0]

		_need_update = true

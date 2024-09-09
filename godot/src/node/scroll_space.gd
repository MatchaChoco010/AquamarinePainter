## キャンバスタブ内部のdocumentのプレビューの平行移動や拡大縮小の挙動を記述するクラス。
class_name ScrollSpace
extends Panel


@onready var _space: Panel = $"."
@onready var _document: Panel = $Document
@onready var _control_layer: Panel = $ControlLayer

## documentのビューポートでの拡大率。
var document_scale: float = 1.0

var _document_position_delta: Vector2 = Vector2()
var _middle_pressed: bool = false

const WHEEL_SCALE_SPEED: float = 0.1
const DOCUMENT_SCALE_MIN: float = 0.01
const DOCUMENT_SCALE_MAX: float = 100
const SPACE_SCALE: float = 2.8


func _process(_delta: float) -> void:
	_document.scale = Vector2(document_scale, document_scale)
	_control_layer.scale = Vector2(document_scale, document_scale)
	_document.position = _space.size / 2 - document_scale * _document.size / 2 \
		+ _document_position_delta
	_control_layer.position = _space.size / 2 - document_scale * _document.size / 2 \
		+ _document_position_delta


func _input(event: InputEvent) -> void:
	if not Main.document_opened:
		return

	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		var hover_space := Rect2(Vector2.ZERO, _space.size).has_point(_space.get_local_mouse_position())

		# Wheelでdocument scaleを変更
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and hover_space:
			document_scale *= 1 - WHEEL_SCALE_SPEED
			if document_scale < DOCUMENT_SCALE_MIN or document_scale > DOCUMENT_SCALE_MAX:
				document_scale = clampf(document_scale, DOCUMENT_SCALE_MIN, DOCUMENT_SCALE_MAX)
			else:
				var mouse_pos := _space.get_local_mouse_position() - _space.size / 2
				_document_position_delta = \
					(_document_position_delta - mouse_pos) * (1 - WHEEL_SCALE_SPEED) + mouse_pos
			Main.viewport_scale = document_scale
		if mouse_button_event.button_index == MOUSE_BUTTON_WHEEL_UP and hover_space:
			document_scale *= 1 + WHEEL_SCALE_SPEED
			if document_scale < DOCUMENT_SCALE_MIN or document_scale > DOCUMENT_SCALE_MAX:
				document_scale = clampf(document_scale, DOCUMENT_SCALE_MIN, DOCUMENT_SCALE_MAX)
			else:
				var mouse_pos := _space.get_local_mouse_position() - _space.size / 2
				_document_position_delta = \
					(_document_position_delta - mouse_pos) * (1 + WHEEL_SCALE_SPEED) + mouse_pos
			Main.viewport_scale = document_scale

		# Middle Buttonがpressedでドキュメントの平行移動状態
		if mouse_button_event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.is_pressed() and hover_space:
				_middle_pressed = true
			else:
				_middle_pressed = false

	if event is InputEventMouseMotion:
		var mouse_motion_event := event as InputEventMouseMotion
		if _middle_pressed:
			_document_position_delta += mouse_motion_event.relative


## 画面内中央にdocumentを納めます。
func expand_document() -> void:
	_document_position_delta = Vector2()
	var x_scale := _space.size.x / _document.size.x
	var y_scale := _space.size.y / _document.size.y
	document_scale = minf(minf(x_scale, y_scale), 1.0)
	Main.viewport_scale = document_scale


## documentのサイズを100%にします。
func reset_document_scale() -> void:
	document_scale = 1.0
	Main.viewport_scale = document_scale

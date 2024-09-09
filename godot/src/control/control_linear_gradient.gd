class_name ControlLinearGradient
extends Node2D


## 操作が確定したときに呼ばれるシグナル。
signal on_manipulate_finished()

@onready var _line2d: Line2D = %Line2D
@onready var _start_point: Node2D = %StartPoint
@onready var _start_sprite: Sprite2D = %StartSprite2D
@onready var _start_sprite2: Sprite2D = %StartSprite2D2
@onready var _end_point: Node2D = %EndPoint
@onready var _end_sprite: Sprite2D = %EndSprite2D
@onready var _end_sprite2: Sprite2D = %EndSprite2D2

## 開始点にマウスカーソルが乗っているかどうか。
var _mouse_over_start: bool = false
## 終了点にマウスカーソルが乗っているかどうか。
var _mouse_over_end: bool = false

## 非表示かどうか。
var _hide: bool = false

## マウスを押している状態かどうか。
var _mouse_pressing: bool = false
## マウスがmouse downしたあとに動いたかどうか。
var _mouse_moving: bool = false

## 開始点を操作中かどうか。
var _manipulating_start: bool = false
## 終了点を操作中かどうか。
var _manipulating_end: bool = false

## viewportの拡大率
var _viewport_scale: float = 1.0

## mouse upでヒストリを積む必要があるかどうか。
var _dirty_history: bool = false

## 現在編集中のマテリアル。
var _editing_material: LinearGradientPaintMaterial


func _ready() -> void:
	_start_sprite.material = _start_sprite.material.duplicate()
	_start_sprite2.material = _start_sprite2.material.duplicate()
	_end_sprite.material = _end_sprite.material.duplicate()
	_end_sprite2.material = _end_sprite2.material.duplicate()


func _process(_delta: float) -> void:
	if _hide:
		_line2d.default_color = Color.TRANSPARENT
	else:
		_line2d.default_color = Color(1, 1, 1, 0.75)

	var start_material1 := _start_sprite.material as ShaderMaterial
	var start_material2 := _start_sprite2.material as ShaderMaterial
	var end_material1 := _end_sprite.material as ShaderMaterial
	var end_material2 := _end_sprite2.material as ShaderMaterial
	if _hide:
		start_material1.set_shader_parameter("fill_color", Color.TRANSPARENT)
		start_material2.set_shader_parameter("fill_color", Color.TRANSPARENT)
		end_material1.set_shader_parameter("fill_color", Color.TRANSPARENT)
		end_material2.set_shader_parameter("fill_color", Color.TRANSPARENT)
	elif _mouse_over_start:
		start_material1.set_shader_parameter("fill_color", Color.AQUA)
		start_material2.set_shader_parameter("fill_color", Color.BLACK)
		end_material1.set_shader_parameter("fill_color", Color.WHITE)
		end_material2.set_shader_parameter("fill_color", Color.BLACK)
	elif _mouse_over_end:
		start_material1.set_shader_parameter("fill_color", Color.WHITE)
		start_material2.set_shader_parameter("fill_color", Color.BLACK)
		end_material1.set_shader_parameter("fill_color", Color.AQUA)
		end_material2.set_shader_parameter("fill_color", Color.BLACK)
	else:
		start_material1.set_shader_parameter("fill_color", Color.WHITE)
		start_material2.set_shader_parameter("fill_color", Color.BLACK)
		end_material1.set_shader_parameter("fill_color", Color.WHITE)
		end_material2.set_shader_parameter("fill_color", Color.BLACK)

	if _editing_material != null:
		_start_point.position = _editing_material.start_point
		_end_point.position = _editing_material.end_point
		if Main.mirror:
			_start_point.position.x = Main.document_size.x - _start_point.position.x
			_end_point.position.x = Main.document_size.x - _end_point.position.x
		_start_point.scale = Vector2(1.0 / _viewport_scale, 1.0 / _viewport_scale)
		_end_point.scale = Vector2(1.0 / _viewport_scale, 1.0 / _viewport_scale)
		_line2d.points = [_editing_material.start_point, _editing_material.end_point]


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_buttoun_event := event as InputEventMouseButton

		# mouse down
		if not _mouse_pressing and mouse_buttoun_event.pressed and mouse_buttoun_event.button_index == MOUSE_BUTTON_LEFT:
			if _mouse_over_start or _mouse_over_end:
				if _mouse_over_end:
					_manipulating_end = true
				elif _mouse_over_start:
					_manipulating_start = true
				_mouse_pressing = true
				_mouse_moving = false

		# mouse up
		if _mouse_pressing and not mouse_buttoun_event.pressed and mouse_buttoun_event.button_index == MOUSE_BUTTON_LEFT:
			_mouse_pressing = false
			_mouse_moving = false
			_manipulating_end = false
			_manipulating_start = false

			if _dirty_history:
				_dirty_history = false
				Main.commit_history()
				on_manipulate_finished.emit()

	if event is InputEventMouseMotion:
		var mouse_motion_event := event as InputEventMouseMotion

		# mouse drag
		if _mouse_pressing:
			_mouse_moving = true
			var delta := mouse_motion_event.relative / _viewport_scale
			if Main.mirror:
				delta.x = -delta.x
			if _manipulating_end:
				_editing_material.end_point += delta
			elif _manipulating_start:
				_editing_material.start_point += delta
			Main.on_change_material_parameters_changed.emit()
			_dirty_history = true


## グラデーションのマテリアルを設定する。
func set_gradeint_material(gradient_material: LinearGradientPaintMaterial) -> void:
	_editing_material = gradient_material


## ControlPointの表示上のスケールを設定する。
func set_control_scale(new_scale: float) -> void:
	_viewport_scale = new_scale


## このコントローラーを操作中かどうか。
func is_manipulating() -> bool:
	return _mouse_moving


## 非表示にする。
func control_hide() -> void:
	_hide = true


## 表示する。
func control_show() -> void:
	_hide = false


## マウスが開始点に乗ったときのコールバック。
func _on_start_area_2d_mouse_entered() -> void:
	_mouse_over_start = true


## マウスが開始点から離れたときのコールバック。
func _on_start_area_2d_mouse_exited() -> void:
	_mouse_over_start = false


## マウスが終了点に乗ったときのコールバック。
func _on_end_area_2d_mouse_entered() -> void:
	_mouse_over_end = true


## マウスが終了点から離れたときのコールバック。
func _on_end_area_2d_mouse_exited() -> void:
	_mouse_over_end = false

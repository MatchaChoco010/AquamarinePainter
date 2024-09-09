class_name ControlRadialGradient
extends Node2D


## 操作が確定したときに呼ばれるシグナル。
signal on_manipulate_finished()

@onready var _line2d1: Line2D = %Line2D1
@onready var _line2d2: Line2D = %Line2D2
@onready var _center_point: Node2D = %CenterPoint
@onready var _center_sprite: Sprite2D = %CenterSprite2D
@onready var _center_sprite2: Sprite2D = %CenterSprite2D2
@onready var _handle_1_point: Node2D = %Handle1Point
@onready var _handle_1_sprite: Sprite2D = %Handle1Sprite2D
@onready var _handle_1_sprite2: Sprite2D = %Handle1Sprite2D2
@onready var _handle_2_point: Node2D = %Handle2Point
@onready var _handle_2_sprite: Sprite2D = %Handle2Sprite2D
@onready var _handle_2_sprite2: Sprite2D = %Handle2Sprite2D2

## 中心点にマウスカーソルが乗っているかどうか。
var _mouse_over_center: bool = false
## ハンドル1にマウスカーソルが乗っているかどうか。
var _mouse_over_handle_1: bool = false
## ハンドル2にマウスカーソルが乗っているかどうか。
var _mouse_over_handle_2: bool = false

## 非表示かどうか。
var _hide: bool = false

## マウスを押している状態かどうか。
var _mouse_pressing: bool = false
## マウスがmouse downしたあとに動いたかどうか。
var _mouse_moving: bool = false

## 中心点を操作中かどうか。
var _manipulating_center: bool = false
## ハンドル1を操作中かどうか。
var _manipulating_handle_1: bool = false
## ハンドル2を操作中かどうか。
var _manipulating_handle_2: bool = false

## viewportの拡大率
var _viewport_scale: float = 1.0

## mouse upでヒストリを積む必要があるかどうか。
var _dirty_history: bool = false

## 現在編集中のマテリアル。
var _editing_material: RadialGradientPaintMaterial


func _ready() -> void:
	_center_sprite.material = _center_sprite.material.duplicate()
	_center_sprite2.material = _center_sprite2.material.duplicate()
	_handle_1_sprite.material = _handle_1_sprite.material.duplicate()
	_handle_1_sprite2.material = _handle_1_sprite2.material.duplicate()
	_handle_2_sprite.material = _handle_2_sprite.material.duplicate()
	_handle_2_sprite2.material = _handle_2_sprite2.material.duplicate()


func _process(_delta: float) -> void:
	if _hide:
		_line2d1.default_color = Color.TRANSPARENT
		_line2d2.default_color = Color.TRANSPARENT
	else:
		_line2d1.default_color = Color(1, 1, 1, 0.75)
		_line2d2.default_color = Color(1, 1, 1, 0.75)

	var center_material1 := _center_sprite.material as ShaderMaterial
	var center_material2 := _center_sprite2.material as ShaderMaterial
	var handle_1_material1 := _handle_1_sprite.material as ShaderMaterial
	var handle_1_material2 := _handle_1_sprite2.material as ShaderMaterial
	var handle_2_material1 := _handle_2_sprite.material as ShaderMaterial
	var handle_2_material2 := _handle_2_sprite2.material as ShaderMaterial
	if _hide:
		center_material1.set_shader_parameter("fill_color", Color.TRANSPARENT)
		center_material2.set_shader_parameter("fill_color", Color.TRANSPARENT)
		handle_1_material1.set_shader_parameter("fill_color", Color.TRANSPARENT)
		handle_1_material2.set_shader_parameter("fill_color", Color.TRANSPARENT)
		handle_2_material1.set_shader_parameter("fill_color", Color.TRANSPARENT)
		handle_2_material2.set_shader_parameter("fill_color", Color.TRANSPARENT)
	elif _mouse_over_center:
		center_material1.set_shader_parameter("fill_color", Color.AQUA)
		center_material2.set_shader_parameter("fill_color", Color.BLACK)
		handle_1_material1.set_shader_parameter("fill_color", Color.WHITE)
		handle_1_material2.set_shader_parameter("fill_color", Color.BLACK)
		handle_2_material1.set_shader_parameter("fill_color", Color.WHITE)
		handle_2_material2.set_shader_parameter("fill_color", Color.BLACK)
	elif _mouse_over_handle_1:
		center_material1.set_shader_parameter("fill_color", Color.WHITE)
		center_material2.set_shader_parameter("fill_color", Color.BLACK)
		handle_1_material1.set_shader_parameter("fill_color", Color.AQUA)
		handle_1_material2.set_shader_parameter("fill_color", Color.BLACK)
		handle_2_material1.set_shader_parameter("fill_color", Color.WHITE)
		handle_2_material2.set_shader_parameter("fill_color", Color.BLACK)
	elif _mouse_over_handle_2:
		center_material1.set_shader_parameter("fill_color", Color.WHITE)
		center_material2.set_shader_parameter("fill_color", Color.BLACK)
		handle_1_material1.set_shader_parameter("fill_color", Color.WHITE)
		handle_1_material2.set_shader_parameter("fill_color", Color.BLACK)
		handle_2_material1.set_shader_parameter("fill_color", Color.AQUA)
		handle_2_material2.set_shader_parameter("fill_color", Color.BLACK)
	else:
		center_material1.set_shader_parameter("fill_color", Color.WHITE)
		center_material2.set_shader_parameter("fill_color", Color.BLACK)
		handle_1_material1.set_shader_parameter("fill_color", Color.WHITE)
		handle_1_material2.set_shader_parameter("fill_color", Color.BLACK)
		handle_2_material1.set_shader_parameter("fill_color", Color.WHITE)
		handle_2_material2.set_shader_parameter("fill_color", Color.BLACK)

	if _editing_material != null:
		_center_point.position = _editing_material.center_point
		_handle_1_point.position = _editing_material.handle_1_point
		_handle_2_point.position = _editing_material.handle_2_point
		if Main.mirror:
			_center_point.position.x = Main.document_size.x - _center_point.position.x
			_handle_1_point.position.x = Main.document_size.x - _handle_1_point.position.x
			_handle_2_point.position.x = Main.document_size.x - _handle_2_point.position.x
		_center_point.scale = Vector2(1.0 / _viewport_scale, 1.0 / _viewport_scale)
		_handle_1_point.scale = Vector2(1.0 / _viewport_scale, 1.0 / _viewport_scale)
		_handle_2_point.scale = Vector2(1.0 / _viewport_scale, 1.0 / _viewport_scale)
		_line2d1.points = [_editing_material.center_point, _editing_material.handle_1_point]
		_line2d2.points = [_editing_material.center_point, _editing_material.handle_2_point]


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_buttoun_event := event as InputEventMouseButton

		# mouse down
		if not _mouse_pressing and mouse_buttoun_event.pressed and mouse_buttoun_event.button_index == MOUSE_BUTTON_LEFT:
			if _mouse_over_center or _mouse_over_handle_1 or _mouse_over_handle_2:
				if _mouse_over_handle_1:
					_manipulating_handle_1 = true
				elif _mouse_over_handle_2:
					_manipulating_handle_2 = true
				elif _mouse_over_center:
					_manipulating_center = true
				_mouse_pressing = true
				_mouse_moving = false

		# mouse up
		if _mouse_pressing and not mouse_buttoun_event.pressed and mouse_buttoun_event.button_index == MOUSE_BUTTON_LEFT:
			_mouse_pressing = false
			_mouse_moving = false
			_manipulating_handle_1 = false
			_manipulating_handle_2 = false
			_manipulating_center = false

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
			if _manipulating_handle_1:
				_editing_material.handle_1_point += delta
				var handle_2_length := _editing_material.handle_2_point.distance_to(_editing_material.center_point)
				var handle_2_dir := (_editing_material.handle_1_point - _editing_material.center_point).normalized().rotated(-PI / 2)
				_editing_material.handle_2_point = _editing_material.center_point + handle_2_dir * handle_2_length
			elif _manipulating_handle_2:
				_editing_material.handle_2_point += delta
				var handle_1_length := _editing_material.handle_1_point.distance_to(_editing_material.center_point)
				var handle_1_dir := (_editing_material.handle_2_point - _editing_material.center_point).normalized().rotated(PI / 2)
				_editing_material.handle_1_point = _editing_material.center_point + handle_1_dir * handle_1_length
			elif _manipulating_center:
				_editing_material.center_point += delta
				_editing_material.handle_1_point += delta
				_editing_material.handle_2_point += delta
			Main.on_change_material_parameters_changed.emit()
			_dirty_history = true


## グラデーションのマテリアルを設定する。
func set_gradeint_material(gradient_material: RadialGradientPaintMaterial) -> void:
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


## マウスが中心点に乗ったときのコールバック。
func _on_center_area_2d_mouse_entered() -> void:
	_mouse_over_center = true


## マウスが中心点から離れたときのコールバック。
func _on_center_area_2d_mouse_exited() -> void:
	_mouse_over_center = false


## マウスがハンドル1に乗ったときのコールバック。
func _on_handle_1_area_2d_mouse_entered() -> void:
	_mouse_over_handle_1 = true


## マウスがハンドル1から離れたときのコールバック。
func _on_handle_1_area_2d_mouse_exited() -> void:
	_mouse_over_handle_1 = false


## マウスがハンドル2に乗ったときのコールバック。
func _on_handle_2_area_2d_mouse_entered() -> void:
	_mouse_over_handle_2 = true


## マウスがハンドル2から離れたときのコールバック。
func _on_handle_2_area_2d_mouse_exited() -> void:
	_mouse_over_handle_2 = false

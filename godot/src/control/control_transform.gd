class_name ControlTransform
extends Panel


## 操作が完了したタイミングで発火するシグナル。
signal on_manipulate_finished()

## コントローラーのホバー状態。
var _hover: bool = false
## 左上の角のホバー状態。
var _top_left_hover: bool = false
## 上の辺のホバー状態。
var _top_hover: bool = false
## 右上の角のホバー状態。
var _top_right_hover: bool = false
## 右の辺のホバー状態。
var _right_hover: bool = false
## 右下の角のホバー状態。
var _bottom_right_hover: bool = false
## 下の辺のホバー状態。
var _bottom_hover: bool = false
## 左下の角のホバー状態。
var _bottom_left_hover: bool = false
## 左の変のホバー状態。
var _left_hover: bool = false
## 回転のコントローラーのホバー状態。
var _rotation_hover: bool = false

## マウスを押している状態かどうか。
var _mouse_pressing: bool = false
## マウスがmouse downしたあとに動いたかどうか。
var _mouse_moving: bool = false

## 通常ドラッグ開始しているかどうかのフラグ。
var _is_start_drag: bool = false
## 通常ドラッグの開始点の座標。
var _drag_start_position: Vector2

## スケール開始時の位置。
var _scale_start_position: Vector2
## スケール開始時の大きさ。
var _scale_start_size: Vector2
## スケール開始時の中心位置。
var _scale_start_center: Vector2
## 右下角でスケール開始しているかのフラグ。
var _is_start_scale_bottom_right: bool = false
## 下辺でスケール開始しているかのフラグ。
var _is_start_scale_bottom: bool = false
## 右辺でスケール開始しているかのフラグ。
var _is_start_scale_right: bool = false
## 左下角でスケール開始しているかのフラグ。
var _is_start_scale_bottom_left: bool = false
## 右上角でスケール開始しているかのフラグ。
var _is_start_scale_top_right: bool = false
## 左辺でスケール開始しているかのフラグ。
var _is_start_scale_left: bool = false
## 上辺でスケール開始しているかのフラグ。
var _is_start_scale_top: bool = false
## 左上角でスケール開始しているかのフラグ。
var _is_start_scale_top_left: bool = false

## 回転が開始しているかどうかのフラグ。
var _is_start_rotation: bool = false
## 回転の中心座標。
var _rotation_center: Vector2

## 非表示状態かどうかのフラグ。
var _hide: bool = false

## コントローラーのコントロールするControlPointの配列。
var _control_points: Array[ControlPoint] = []

## ドラッグ開始時のControlPointのいち情報の配列。
var _position_cache: Array[Vector2] = []


func _process(_delta: float) -> void:
	if _mouse_moving and _is_start_drag:
		_drag()
	elif _mouse_moving and _is_start_scale_bottom_right:
		_scale_bottom_right()
	elif _mouse_moving and _is_start_scale_bottom:
		_scale_bottom()
	elif _mouse_moving and _is_start_scale_right:
		_scale_right()
	elif _mouse_moving and _is_start_scale_bottom_left:
		_scale_bottom_left()
	elif _mouse_moving and _is_start_scale_top_right:
		_scale_top_right()
	elif _mouse_moving and _is_start_scale_left:
		_scale_left()
	elif _mouse_moving and _is_start_scale_top:
		_scale_top()
	elif _mouse_moving and _is_start_scale_top_left:
		_scale_top_left()
	elif _mouse_moving and _is_start_rotation:
		_rotate()

	if _hide:
		modulate = Color(1, 1, 1, 0)
	else:
		modulate = Color(1, 1, 1, 1)


func _input(event: InputEvent) -> void:
	var mouse_position: Vector2 = (get_parent() as Control).get_local_mouse_position()
	if event is InputEventMouseButton:
		var mouse_buttoun_event := event as InputEventMouseButton

		# mouse down
		if not _mouse_pressing and mouse_buttoun_event.pressed and mouse_buttoun_event.button_index == MOUSE_BUTTON_LEFT:
			if is_hover():
				_mouse_pressing = true
				_mouse_moving = false
				_capture_control_points_position()

			if _rotation_hover:
				# 回転
				_is_start_rotation = true
				_rotation_center = position + pivot_offset
				_drag_start_position = mouse_position
			elif _top_left_hover or \
				_top_hover or \
				_left_hover or \
				_top_right_hover or \
				_bottom_left_hover or \
				_right_hover or \
				_bottom_hover or \
				_bottom_right_hover:
				# スケーリング
				_scale_start_position = position
				_scale_start_size = size
				_scale_start_center = position + size / 2
				if _bottom_right_hover:
					_is_start_scale_bottom_right = true
				elif _bottom_hover:
					_is_start_scale_bottom = true
				elif _right_hover:
					_is_start_scale_right = true
				elif _bottom_left_hover:
					_is_start_scale_bottom_left = true
				elif _top_right_hover:
					_is_start_scale_top_right = true
				elif _left_hover:
					_is_start_scale_left = true
				elif _top_hover:
					_is_start_scale_top = true
				elif _top_left_hover:
					_is_start_scale_top_left = true
			elif _hover:
				# 平行移動
				_is_start_drag = true
				_drag_start_position = mouse_position

		# mouse up
		if _mouse_pressing and not mouse_buttoun_event.pressed and mouse_buttoun_event.button_index == MOUSE_BUTTON_LEFT:
			var manipulated := false
			if _mouse_pressing and _mouse_moving:
				manipulated = true

			_mouse_pressing = false
			_mouse_moving = false

			_is_start_rotation = false
			_is_start_scale_bottom_right = false
			_is_start_scale_bottom = false
			_is_start_scale_right = false
			_is_start_scale_bottom_left = false
			_is_start_scale_top_right = false
			_is_start_scale_left = false
			_is_start_scale_top = false
			_is_start_scale_top_left = false
			_is_start_drag = false

			_reset_control()

			if manipulated:
				Main.commit_history()
				on_manipulate_finished.emit()

	if event is InputEventMouseMotion:
		# mouse drag
		if _mouse_pressing:
			_mouse_moving = true


## ドラッグしたときの挙動。
func _drag() -> void:
	var mouse_position: Vector2 = (get_parent() as Control).get_local_mouse_position()
	var delta := mouse_position - _drag_start_position
	for index in _control_points.size():
		var start_pos := _position_cache[index]
		var cp := _control_points[index]
		cp.set_control_position(start_pos + delta)
	_reset_control()


## 右下でスケールしたときの挙動。
func _scale_bottom_right() -> void:
	var mouse_position: Vector2 = (get_parent() as Control).get_local_mouse_position()
	var ctrl_pressed := Input.is_key_pressed(KEY_CTRL)
	var shift_pressed := Input.is_key_pressed(KEY_SHIFT)
	if ctrl_pressed:
		var new_size := (mouse_position - _scale_start_center) * 2
		var scale_x := 0.0
		if _scale_start_size.x != 0.0:
			scale_x = new_size.x / _scale_start_size.x
		var scale_y := 0.0
		if _scale_start_size.y != 0.0:
			scale_y = new_size.y / _scale_start_size.y
		var scale_shift := signf(scale_x) * minf(absf(scale_x), absf(scale_y))
		for index in _control_points.size():
			var start_pos := _position_cache[index]
			var cp := _control_points[index]
			if shift_pressed:
				var new_pos := (start_pos - _scale_start_center) * scale_shift + _scale_start_center
				cp.set_control_position(new_pos)
			else:
				var new_pos := (start_pos - _scale_start_center) * Vector2(scale_x, scale_y) + _scale_start_center
				cp.set_control_position(new_pos)
	else:
		var new_size := mouse_position - _scale_start_position
		var scale_anchor := _scale_start_position
		var scale_x := 0.0
		if _scale_start_size.x != 0.0:
			scale_x = new_size.x / _scale_start_size.x
		var scale_y := 0.0
		if _scale_start_size.y != 0.0:
			scale_y = new_size.y / _scale_start_size.y
		var scale_shift := signf(scale_x) * minf(absf(scale_x), absf(scale_y))
		for index in _control_points.size():
			var start_pos := _position_cache[index]
			var cp := _control_points[index]
			if shift_pressed:
				var new_pos := (start_pos - scale_anchor) * scale_shift + scale_anchor
				cp.set_control_position(new_pos)
			else:
				var new_pos := (start_pos - scale_anchor) * Vector2(scale_x, scale_y) + scale_anchor
				cp.set_control_position(new_pos)
	_reset_control()


## 下でスケールしたときの挙動。
func _scale_bottom() -> void:
	var mouse_position: Vector2 = (get_parent() as Control).get_local_mouse_position()
	var ctrl_pressed := Input.is_key_pressed(KEY_CTRL)
	var shift_pressed := Input.is_key_pressed(KEY_SHIFT)
	if ctrl_pressed:
		var new_size_y := (mouse_position.y - _scale_start_center.y) * 2
		var scale_y := 0.0
		if _scale_start_size.y != 0.0:
			scale_y = new_size_y / _scale_start_size.y
		for index in _control_points.size():
			var start_pos := _position_cache[index]
			var cp := _control_points[index]
			if shift_pressed:
				var new_pos := (start_pos - _scale_start_center) * Vector2(scale_y * signf(scale_y), scale_y) + _scale_start_center
				cp.set_control_position(new_pos)
			else:
				var new_pos := (start_pos - _scale_start_center) * Vector2(1, scale_y) + _scale_start_center
				cp.set_control_position(new_pos)
	else:
		var new_size_y := mouse_position.y - _scale_start_position.y
		var scale_y := 0.0
		if _scale_start_size.y != 0.0:
			scale_y = new_size_y / _scale_start_size.y
		var scale_anchor := Vector2(_scale_start_center.x, _scale_start_position.y)
		for index in _control_points.size():
			var start_pos := _position_cache[index]
			var cp := _control_points[index]
			if shift_pressed:
				var new_pos := (start_pos - scale_anchor) * Vector2(scale_y * signf(scale_y), scale_y) + scale_anchor
				cp.set_control_position(new_pos)
			else:
				var new_pos := (start_pos - scale_anchor) * Vector2(1, scale_y) + scale_anchor
				cp.set_control_position(new_pos)
	_reset_control()


## 右でスケールしたときの挙動。
func _scale_right() -> void:
	var mouse_position: Vector2 = (get_parent() as Control).get_local_mouse_position()
	var ctrl_pressed := Input.is_key_pressed(KEY_CTRL)
	var shift_pressed := Input.is_key_pressed(KEY_SHIFT)
	if ctrl_pressed:
		var new_size_x := (mouse_position.x - _scale_start_center.x) * 2
		var scale_x := 0.0
		if _scale_start_size.x != 0.0:
			scale_x = new_size_x / _scale_start_size.x
		for index in _control_points.size():
			var start_pos := _position_cache[index]
			var cp := _control_points[index]
			if shift_pressed:
				var new_pos := (start_pos - _scale_start_center) * Vector2(scale_x, scale_x * signf(scale_x)) + _scale_start_center
				cp.set_control_position(new_pos)
			else:
				var new_pos := (start_pos - _scale_start_center) * Vector2(scale_x, 1) + _scale_start_center
				cp.set_control_position(new_pos)
	else:
		var new_size_x := mouse_position.x - _scale_start_position.x
		var scale_x := 0.0
		if _scale_start_size.x != 0.0:
			scale_x = new_size_x / _scale_start_size.x
		var scale_anchor := Vector2(_scale_start_position.x, _scale_start_center.y)
		for index in _control_points.size():
			var start_pos := _position_cache[index]
			var cp := _control_points[index]
			if shift_pressed:
				var new_pos := (start_pos - scale_anchor) * Vector2(scale_x, scale_x * signf(scale_x)) + scale_anchor
				cp.set_control_position(new_pos)
			else:
				var new_pos := (start_pos - scale_anchor) * Vector2(scale_x, 1) + scale_anchor
				cp.set_control_position(new_pos)
	_reset_control()


## 左下でスケールしたときの挙動。
func _scale_bottom_left() -> void:
	var mouse_position: Vector2 = (get_parent() as Control).get_local_mouse_position()
	var ctrl_pressed := Input.is_key_pressed(KEY_CTRL)
	var shift_pressed := Input.is_key_pressed(KEY_SHIFT)
	if ctrl_pressed:
		var new_size := Vector2((_scale_start_center.x - mouse_position.x) * 2, (mouse_position.y - _scale_start_center.y) * 2)
		var scale_x := 0.0
		if _scale_start_size.x != 0.0:
			scale_x = new_size.x / _scale_start_size.x
		var scale_y := 0.0
		if _scale_start_size.y != 0.0:
			scale_y = new_size.y / _scale_start_size.y
		var scale_shift := signf(scale_x) * minf(absf(scale_x), absf(scale_y))
		for index in _control_points.size():
			var start_pos := _position_cache[index]
			var cp := _control_points[index]
			if shift_pressed:
				var new_pos := (start_pos - _scale_start_center) * scale_shift + _scale_start_center
				cp.set_control_position(new_pos)
			else:
				var new_pos := (start_pos - _scale_start_center) * Vector2(scale_x, scale_y) + _scale_start_center
				cp.set_control_position(new_pos)
	else:
		var inner_start_position := _scale_start_position + Vector2(12, 12)
		var inner_start_size := _scale_start_size - Vector2(24, 24)
		var new_size := Vector2(_scale_start_position.x + _scale_start_size.x - mouse_position.x, mouse_position.y - _scale_start_position.y)
		var inner_size := new_size
		if new_size.x > 24:
			inner_size.x -= 24
		elif new_size.x > 0:
			inner_size.x = 0
		if new_size.y > 24:
			inner_size.y -= 24
		elif new_size.y > 0:
			inner_size.y = 0
		var scale_anchor := Vector2(inner_start_position.x + inner_start_size.x, inner_start_position.y)
		var scale_x := inner_size.x / inner_start_size.x
		var scale_y := inner_size.y / inner_start_size.y
		var scale_shift := signf(scale_x) * minf(absf(scale_x), absf(scale_y))
		for index in _control_points.size():
			var start_pos := _position_cache[index]
			var cp := _control_points[index]
			if shift_pressed:
				var new_pos := (start_pos - scale_anchor) * scale_shift + scale_anchor
				cp.set_control_position(new_pos)
			else:
				var new_pos := (start_pos - scale_anchor) * Vector2(scale_x, scale_y) + scale_anchor
				cp.set_control_position(new_pos)
	_reset_control()


## 右上でスケールしたときの挙動。
func _scale_top_right() -> void:
	var mouse_position: Vector2 = (get_parent() as Control).get_local_mouse_position()
	var ctrl_pressed := Input.is_key_pressed(KEY_CTRL)
	var shift_pressed := Input.is_key_pressed(KEY_SHIFT)
	if ctrl_pressed:
		var new_size := Vector2((mouse_position.x - _scale_start_center.x) * 2, (_scale_start_center.y - mouse_position.y) * 2)
		var scale_x := 0.0
		if _scale_start_size.x != 0.0:
			scale_x = new_size.x / _scale_start_size.x
		var scale_y := 0.0
		if _scale_start_size.y != 0.0:
			scale_y = new_size.y / _scale_start_size.y
		var scale_shift := signf(scale_x) * minf(absf(scale_x), absf(scale_y))
		for index in _control_points.size():
			var start_pos := _position_cache[index]
			var cp := _control_points[index]
			if shift_pressed:
				var new_pos := (start_pos - _scale_start_center) * scale_shift + _scale_start_center
				cp.set_control_position(new_pos)
			else:
				var new_pos := (start_pos - _scale_start_center) * Vector2(scale_x, scale_y) + _scale_start_center
				cp.set_control_position(new_pos)
	else:
		var new_size := Vector2(mouse_position.x - _scale_start_position.x, _scale_start_position.y + _scale_start_size.y - mouse_position.y)
		var scale_x := 0.0
		if _scale_start_size.x != 0.0:
			scale_x = new_size.x / _scale_start_size.x
		var scale_y := 0.0
		if _scale_start_size.y != 0.0:
			scale_y = new_size.y / _scale_start_size.y
		var scale_anchor := Vector2(_scale_start_position.x, _scale_start_position.y + _scale_start_size.y)
		var scale_shift := signf(scale_x) * minf(absf(scale_x), absf(scale_y))
		for index in _control_points.size():
			var start_pos := _position_cache[index]
			var cp := _control_points[index]
			if shift_pressed:
				var new_pos := (start_pos - scale_anchor) * scale_shift + scale_anchor
				cp.set_control_position(new_pos)
			else:
				var new_pos := (start_pos - scale_anchor) * Vector2(scale_x, scale_y) + scale_anchor
				cp.set_control_position(new_pos)
	_reset_control()


## 左でスケールしたときの挙動。
func _scale_left() -> void:
	var mouse_position: Vector2 = (get_parent() as Control).get_local_mouse_position()
	var ctrl_pressed := Input.is_key_pressed(KEY_CTRL)
	var shift_pressed := Input.is_key_pressed(KEY_SHIFT)
	if ctrl_pressed:
		var new_size_x := (_scale_start_center.x - mouse_position.x) * 2
		var scale_x := 0.0
		if _scale_start_size.x != 0.0:
			scale_x = new_size_x / _scale_start_size.x
		for index in _control_points.size():
			var start_pos := _position_cache[index]
			var cp := _control_points[index]
			if shift_pressed:
				var new_pos := (start_pos - _scale_start_center) * Vector2(scale_x, scale_x * signf(scale_x)) + _scale_start_center
				cp.set_control_position(new_pos)
			else:
				var new_pos := (start_pos - _scale_start_center) * Vector2(scale_x, 1) + _scale_start_center
				cp.set_control_position(new_pos)
	else:
		var new_size_x := _scale_start_position.x + _scale_start_size.x - mouse_position.x
		var scale_x := 0.0
		if _scale_start_size.x != 0.0:
			scale_x = new_size_x / _scale_start_size.x
		var scale_anchor := Vector2(_scale_start_position.x + _scale_start_size.x, _scale_start_center.y)
		for index in _control_points.size():
			var start_pos := _position_cache[index]
			var cp := _control_points[index]
			if shift_pressed:
				var new_pos := (start_pos - scale_anchor) * Vector2(scale_x, scale_x * signf(scale_x)) + scale_anchor
				cp.set_control_position(new_pos)
			else:
				var new_pos := (start_pos - scale_anchor) * Vector2(scale_x, 1) + scale_anchor
				cp.set_control_position(new_pos)
	_reset_control()


## 上でスケールしたときの挙動。
func _scale_top() -> void:
	var mouse_position: Vector2 = (get_parent() as Control).get_local_mouse_position()
	var ctrl_pressed := Input.is_key_pressed(KEY_CTRL)
	var shift_pressed := Input.is_key_pressed(KEY_SHIFT)
	if ctrl_pressed:
		var new_size_y := (_scale_start_center.y - mouse_position.y) * 2
		var scale_y := 0.0
		if _scale_start_size.y != 0.0:
			scale_y = new_size_y / _scale_start_size.y
		for index in _control_points.size():
			var start_pos := _position_cache[index]
			var cp := _control_points[index]
			if shift_pressed:
				var new_pos := (start_pos - _scale_start_center) * Vector2(scale_y * signf(scale_y), scale_y) + _scale_start_center
				cp.set_control_position(new_pos)
			else:
				var new_pos := (start_pos - _scale_start_center) * Vector2(1, scale_y) + _scale_start_center
				cp.set_control_position(new_pos)
	else:
		var new_size_y := _scale_start_position.y + _scale_start_size.y - mouse_position.y
		var scale_y := 0.0
		if _scale_start_size.y != 0.0:
			scale_y = new_size_y / _scale_start_size.y
		var scale_anchor := Vector2(_scale_start_center.x, _scale_start_position.y + _scale_start_size.y)
		for index in _control_points.size():
			var start_pos := _position_cache[index]
			var cp := _control_points[index]
			if shift_pressed:
				var new_pos := (start_pos - scale_anchor) * Vector2(scale_y * signf(scale_y), scale_y) + scale_anchor
				cp.set_control_position(new_pos)
			else:
				var new_pos := (start_pos - scale_anchor) * Vector2(1, scale_y) + scale_anchor
				cp.set_control_position(new_pos)
	_reset_control()


## 左上でスケールしたときの挙動。
func _scale_top_left() -> void:
	var mouse_position: Vector2 = (get_parent() as Control).get_local_mouse_position()
	var ctrl_pressed := Input.is_key_pressed(KEY_CTRL)
	var shift_pressed := Input.is_key_pressed(KEY_SHIFT)
	if ctrl_pressed:
		var new_size := Vector2((_scale_start_center.x - mouse_position.x) * 2, (_scale_start_center.y - mouse_position.y) * 2)
		var scale_x := 0.0
		if _scale_start_size.x != 0.0:
			scale_x = new_size.x / _scale_start_size.x
		var scale_y := 0.0
		if _scale_start_size.y != 0.0:
			scale_y = new_size.y / _scale_start_size.y
		var scale_shift := signf(scale_x) * minf(absf(scale_x), absf(scale_y))
		for index in _control_points.size():
			var start_pos := _position_cache[index]
			var cp := _control_points[index]
			if shift_pressed:
				var new_pos := (start_pos - _scale_start_center) * scale_shift + _scale_start_center
				cp.set_control_position(new_pos)
			else:
				var new_pos := (start_pos - _scale_start_center) * Vector2(scale_x, scale_y) + _scale_start_center
				cp.set_control_position(new_pos)
	else:
		var new_size := Vector2(_scale_start_position.x + _scale_start_size.x - mouse_position.x, _scale_start_position.y + _scale_start_size.y - mouse_position.y)
		var scale_x := 0.0
		if _scale_start_size.x != 0.0:
			scale_x = new_size.x / _scale_start_size.x
		var scale_y := 0.0
		if _scale_start_size.y != 0.0:
			scale_y = new_size.y / _scale_start_size.y
		var scale_anchor := Vector2(_scale_start_position.x + _scale_start_size.x, _scale_start_position.y + _scale_start_size.y)
		var scale_shift := signf(scale_x) * minf(absf(scale_x), absf(scale_y))
		for index in _control_points.size():
			var start_pos := _position_cache[index]
			var cp := _control_points[index]
			if shift_pressed:
				var new_pos := (start_pos - scale_anchor) * scale_shift + scale_anchor
				cp.set_control_position(new_pos)
			else:
				var new_pos := (start_pos - scale_anchor) * Vector2(scale_x, scale_y) + scale_anchor
				cp.set_control_position(new_pos)
	_reset_control()


## 回転したときの挙動。
func _rotate() -> void:
	var mouse_position: Vector2 = (get_parent() as Control).get_local_mouse_position()
	var angle := (mouse_position.x - _drag_start_position.x) / 200
	for index in _control_points.size():
		var start_pos := _position_cache[index]
		var cp := _control_points[index]
		var rotate_pos := (start_pos - _rotation_center).rotated(angle) + _rotation_center
		cp.set_control_position(rotate_pos)
	rotation = angle


## _control_pointsの位置をキャプチャする。
func _capture_control_points_position() -> void:
	_position_cache.clear()
	for cp in _control_points:
		_position_cache.append(cp.get_control_position())


## 現在の_control_pointsに合わせてコントローラーを設置し直す。
func _reset_control() -> void:
	if _control_points.size() <= 1:
		visible = false
		return

	visible = true

	# _control_pointsのバウンディングボックスを求める
	var min_x := _control_points[0].get_control_position().x
	var min_y := _control_points[0].get_control_position().y
	var max_x := _control_points[0].get_control_position().x
	var max_y := _control_points[0].get_control_position().y
	for i in range(1, _control_points.size()):
		var x := _control_points[i].get_control_position().x
		var y := _control_points[i].get_control_position().y
		if min_x > x:
			min_x = x
		elif max_x < x:
			max_x = x
		if min_y > y:
			min_y = y
		elif max_y < y:
			max_y = y

	# _control_pointsのバウンディングボックスを外に12px拡張したサイズを設定する
	var top_left := Vector2(min_x, min_y)
	var bottom_right := Vector2(max_x, max_y)

	position = top_left
	size = bottom_right - top_left
	pivot_offset = size / 2
	rotation = 0


## CPを与えてコントローラーを表示する。
func set_control_points(control_points: Array[ControlPoint]) -> void:
	var dirty := false
	if _control_points.size() != control_points.size():
		dirty = true
	else:
		for index in control_points.size():
			if _control_points[index] != control_points[index]:
				dirty = true
				break

	if dirty:
		_control_points.clear()
		_control_points.append_array(control_points)
		_reset_control()


## このコントローラーがホバー中かどうか。
func is_hover() -> bool:
	return _hover or \
		_top_left_hover or \
		_top_hover or \
		_left_hover or \
		_top_right_hover or \
		_bottom_left_hover or \
		_right_hover or \
		_bottom_hover or \
		_bottom_right_hover or \
		_rotation_hover


## このコントローラーを操作中かどうか。
func is_manipulating() -> bool:
	return _mouse_moving


## 非表示にする。
func control_hide() -> void:
	_hide = true


## 表示する。
func control_show() -> void:
	_hide = false


## マウスカーソルがメイン領域に入った際に呼ばれる。
func _on_mouse_entered() -> void:
	_hover = true


## マウスカーソルがメイン領域から出た際に呼ばれる。
func _on_mouse_exited() -> void:
	_hover = false


## マウスカーソルが左上角領域に入った際に呼ばれる。
func _on_top_left_control_mouse_entered() -> void:
	_top_left_hover = true


## マウスカーソルが左上角領域から出た際に呼ばれる。
func _on_top_left_control_mouse_exited() -> void:
	_top_left_hover = false


## マウスカーソルが上辺領域に入った際に呼ばれる。
func _on_top_control_mouse_entered() -> void:
	_top_hover = true


## マウスカーソルが上辺領域から出た際に呼ばれる。
func _on_top_control_mouse_exited() -> void:
	_top_hover = false


## マウスカーソルが左辺領域に入った際に呼ばれる。
func _on_left_control_mouse_entered() -> void:
	_left_hover = true


## マウスカーソルが左辺領域から出た際に呼ばれる。
func _on_left_control_mouse_exited() -> void:
	_left_hover = false


## マウスカーソルが右上角領域に入った際に呼ばれる。
func _on_top_right_control_mouse_entered() -> void:
	_top_right_hover = true


## マウスカーソルが右上角領域から出た際に呼ばれる。
func _on_top_right_control_mouse_exited() -> void:
	_top_right_hover = false


## マウスカーソルが左下角領域に入った際に呼ばれる。
func _on_bottom_left_control_mouse_entered() -> void:
	_bottom_left_hover = true


## マウスカーソルが左下角領域から出た際に呼ばれる。
func _on_bottom_left_control_mouse_exited() -> void:
	_bottom_left_hover = false


## マウスカーソルが右辺領域に入った際に呼ばれる。
func _on_right_control_mouse_entered() -> void:
	_right_hover = true


## マウスカーソルが右辺領域から出た際に呼ばれる。
func _on_right_control_mouse_exited() -> void:
	_right_hover = false


## マウスカーソルが下辺領域に入った際に呼ばれる。
func _on_bottom_control_mouse_entered() -> void:
	_bottom_hover = true


## マウスカーソルが下辺領域から出た際に呼ばれる。
func _on_bottom_control_mouse_exited() -> void:
	_bottom_hover = false


## マウスカーソルが右下角領域に入った際に呼ばれる。
func _on_bottom_right_control_mouse_entered() -> void:
	_bottom_right_hover = true


## マウスカーソルが右下角領域から出た際に呼ばれる。
func _on_bottom_right_control_mouse_exited() -> void:
	_bottom_right_hover = false


## マウスカーソルが回転コントローラーの領域に入った際に呼ばれる。
func _on_rotation_control_mouse_entered() -> void:
	_rotation_hover = true


## マウスカーソルが回転コントローラーの領域から出た際に呼ばれる。
func _on_rotation_control_mouse_exited() -> void:
	_rotation_hover = false

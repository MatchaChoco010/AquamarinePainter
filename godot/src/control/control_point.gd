## ユーザー制御点の挙動を記述するクラス。
class_name ControlPoint
extends Node2D


## 操作が確定したときに呼ばれるシグナル。
signal on_manipulate_finished()

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _sprite2: Sprite2D = $Sprite2D2

## ControlPointが属するパスの参照。
var path: Path
## ControlPointのパスの中でのインデックス。
var control_point_index: int = 0

## ControlPointのコントロールモードの列挙子。
enum ControlMode {
	NOOP,
	MOVE_POSITION,
	CHANGE_WEIGHT,
}
## 現在のControlPointのモード。
var mode: ControlMode = ControlMode.NOOP

## 現在のweightの値。
var weight: float = 1.0

## マウスカーソルが乗っているかどうか。
var mouse_over: bool = false

## このCPが選択中かどうか。
var selected: bool = false

const WEIGHT_MIN: float = 0.001
const WEIGHT_MAX: float = 100.0

## ホバーしているかどうか。
## ホバーは全コントロールポイントで排他制御される。
var _hover: bool = false

## control_transformがホバー状態かどうか。
var _control_transform_hover: bool = false

## マウスを押している状態かどうか。
var _mouse_pressing: bool = false
## マウスがmouse downしたあとに動いたかどうか。
var _mouse_moving: bool = false

## viewportの拡大率
var _viewport_scale: float = 1.0

## mouse upでヒストリを積む必要があるかどうか。
var _dirty_history: bool = false

## ControlPointのscene。
static var _control_point_scene: PackedScene

## 非表示かどうか。
var _hide: bool = false


func _ready() -> void:
	_sprite.material = _sprite.material.duplicate()
	_sprite2.material = _sprite2.material.duplicate()


func _process(_delta: float) -> void:
	var material1 := _sprite.material as ShaderMaterial
	var material2 := _sprite2.material as ShaderMaterial
	if _hide:
		material1.set_shader_parameter("fill_color", Color.TRANSPARENT)
		material2.set_shader_parameter("fill_color", Color.TRANSPARENT)
	elif selected:
		material1.set_shader_parameter("fill_color", Color.AQUA)
		material2.set_shader_parameter("fill_color", Color.BLACK)
	elif _hover:
		material1.set_shader_parameter("fill_color", Color(1, 0.7, 1, 1))
		material2.set_shader_parameter("fill_color", Color.BLACK)
	else:
		material1.set_shader_parameter("fill_color", Color.WHITE)
		material2.set_shader_parameter("fill_color", Color.BLACK)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_buttoun_event := event as InputEventMouseButton

		# mouse down
		if not _mouse_pressing and mouse_buttoun_event.pressed and mouse_buttoun_event.button_index == MOUSE_BUTTON_LEFT:
			if _hover and not _control_transform_hover:
				_mouse_pressing = true
				_mouse_moving = false

		# mouse up
		if _mouse_pressing and not mouse_buttoun_event.pressed and mouse_buttoun_event.button_index == MOUSE_BUTTON_LEFT:
			_mouse_pressing = false
			_mouse_moving = false

			if _dirty_history:
				_dirty_history = false
				Main.commit_history()
				emit_manipulate_finish_next_frame()

	if event is InputEventMouseMotion:
		var mouse_motion_event := event as InputEventMouseMotion

		# mouse drag
		if _mouse_pressing:
			_mouse_moving = true

			if mode == ControlMode.NOOP:
				pass
			elif mode == ControlMode.MOVE_POSITION:
				selected = true
				var node := $"." as Node2D
				var delta := mouse_motion_event.relative / _viewport_scale
				node.position += delta
				var pos := node.position
				if Main.mirror:
					pos.x = Main.document_size.x - pos.x
				path.move_control_point(pos, control_point_index)
				_dirty_history = true
			elif mode == ControlMode.CHANGE_WEIGHT:
				var log_weight := log(weight)
				log_weight += mouse_motion_event.relative.x / 100.0
				weight = exp(log_weight)
				weight = clampf(weight, WEIGHT_MIN, WEIGHT_MAX)
				path.change_weight(weight, control_point_index)
				_dirty_history = true


## 操作完了の通知を次のフレームに出す。
func emit_manipulate_finish_next_frame() -> void:
	await (Engine.get_main_loop() as SceneTree).process_frame
	on_manipulate_finished.emit()


## ControlPointの位置を設定する。
func set_control_position(pos: Vector2) -> void:
	var node := $"." as Node2D
	node.position = pos
	if Main.mirror:
		pos.x = Main.document_size.x - pos.x
	path.move_control_point(pos, control_point_index)


## ControlPointの位置を取得する。
func get_control_position() -> Vector2:
	var node := $"." as Node2D
	return node.position


## ControlPointの表示上のスケールを設定する。
func set_control_scale(new_scale: float) -> void:
	_viewport_scale = new_scale
	var node := $"." as Node2D
	node.scale = Vector2(1.0 / _viewport_scale, 1.0 / _viewport_scale)


## ControlPointのコントロールモードを設定する。
func set_mode(new_mode: ControlMode) -> void:
	mode = new_mode


## ホバーしているかどうかをセットする。
## ホバーは全コントロールポイントで排他制御される。
func set_hover(hover: bool) -> void:
	_hover = hover


## ホバー状態を取得する。
func get_hover() -> bool:
	return _hover


## このCPを削除する。
func delete_cp() -> void:
	path.delete_control_point(control_point_index)


## control_transformがホバー状態かをセットする。
func set_control_transform_hover(hover: bool) -> void:
	_control_transform_hover = hover


## 現在このコントローラーの値を変更中かどうか。
func is_changing_parameter() -> bool:
	return _mouse_pressing


## このコントローラーを操作中かどうか。
func is_manipulating() -> bool:
	return _mouse_moving


## 非表示にする。
func control_hide() -> void:
	_hide = true


## 表示する。
func control_show() -> void:
	_hide = false


## マウスオーバーしたときに呼ばれるコールバック。
func _on_area_2d_mouse_entered() -> void:
	mouse_over = true


## マウスが外れたときに呼ばれるコールバック。
func _on_area_2d_mouse_exited() -> void:
	mouse_over = false


## ControlPointを作成する関数。
static func new_control_point(new_path: Path, index: int) -> ControlPoint:
	if not _control_point_scene:
		_control_point_scene = load("res://scenes/control/control_point.tscn")
	var cp_data := new_path.control_points[index]
	if Main.mirror:
		cp_data.x = Main.document_size.x - cp_data.x
	var cp := _control_point_scene.instantiate() as ControlPoint
	cp.path = new_path
	cp.control_point_index = index
	cp.set_control_position(cp_data)
	cp.weight = new_path.weights[index]
	return cp

## 制御用セグメントの挙動を記述するクラス。
class_name ControlSegment
extends Node2D


## 操作が確定したときに呼ばれるシグナル。
signal on_manipulate_finished()

@onready var _line2d: Line2D = $Line2D

## ControlSegmentが属するパスの参照。
var path: Path
## ControlSegmentのパスの中でのインデックス。
var segment_index: int = 0

## ControlSegmentのコントロールモードの列挙子。
enum ControlMode {
	NOOP,
	CHANGE_PARAMETER,
}
## 現在のControlSegmentのモード。
var mode: ControlMode = ControlMode.NOOP

## 現在のphiのパラメータの値。
var phi: float = 1.0
## 現在のpsiのパラメータの値。
var psi: float = 0.0

const PHI_MIN: float = 0.01
const PHI_MAX: float = 6.0

const PSI_MIN: float = -2.0
const PSI_MAX: float = 2.0

## マウスカーソルが乗っているかどうか。
var mouse_over: bool = false

## 変更するパラメータの種類。
enum ChangeMode {
	NO_CHANGE,
	CHANGE_PHI,
	CHANGE_PSI,
}
## 現在の変更するパラメータの種類。
var _change_mode: ChangeMode = ChangeMode.NO_CHANGE
## 変更するパラメータを決定するしきい値。
const CHANGE_MODE_THREASHOLD: float = 5.0

## ホバーしているかどうか。
## ホバーは全コントロールポイントで排他制御される。
var _hover: bool = false

## マウスを押している状態かどうか。
var _mouse_pressing: bool = false
## マウスがmouse downしたあとに動いたかどうか。
var _mouse_moving: bool = false
## マウスダウンした座標。
var _mouse_down_point: Vector2

const COLLISION_WIDTH: float = 16.0
const DISPLAY_WIDTH: float = 5.0

## mouse upでヒストリを積む必要があるかどうか。
var _dirty_history: bool = false

## _set_segmentするためのsegment。
var _segment: PackedVector2Array

## documentの表示スケール。
var _viewport_scale: float = 1.0

## 非表示かどうか。
var _hide: bool = false

## ControlSegmentのscene。
static var _control_segment_scene: PackedScene


func _ready() -> void:
	_line2d.material = _line2d.material.duplicate()


func _process(_delta: float) -> void:
	_update_material()
	_check_mouseover()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_buttoun_event := event as InputEventMouseButton

		# mouse down
		if not _mouse_pressing and mouse_buttoun_event.pressed and mouse_buttoun_event.button_index == MOUSE_BUTTON_LEFT:
			if _hover:
				_mouse_pressing = true
				_mouse_moving = false
				_mouse_down_point = mouse_buttoun_event.position

		# mouse up
		if _mouse_pressing and not mouse_buttoun_event.pressed and mouse_buttoun_event.button_index == MOUSE_BUTTON_LEFT:
			_mouse_pressing = false
			_mouse_moving = false
			_change_mode = ChangeMode.NO_CHANGE

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
			elif mode == ControlMode.CHANGE_PARAMETER:
				if _change_mode == ChangeMode.NO_CHANGE:
					var delta := mouse_motion_event.position - _mouse_down_point
					if absf(delta.x) < absf(delta.y):
						if absf(delta.y) > CHANGE_MODE_THREASHOLD:
							_change_mode = ChangeMode.CHANGE_PHI
					else:
						if absf(delta.x) > CHANGE_MODE_THREASHOLD:
							_change_mode = ChangeMode.CHANGE_PSI
					_dirty_history = true
				elif _change_mode == ChangeMode.CHANGE_PHI:
					var log_phi := log(phi)
					log_phi -= mouse_motion_event.relative.y / 100.0
					phi = exp(log_phi)
					phi = clampf(phi, PHI_MIN, PHI_MAX)
					path.change_phi(phi, segment_index)
					_dirty_history = true
				elif _change_mode == ChangeMode.CHANGE_PSI:
					psi += mouse_motion_event.relative.x / 100.0
					psi = clampf(psi, PSI_MIN, PSI_MAX)
					path.change_psi(psi, segment_index)
					_dirty_history = true


## 操作完了の通知を次のフレームに出す。
func emit_manipulate_finish_next_frame() -> void:
	await (Engine.get_main_loop() as SceneTree).process_frame
	on_manipulate_finished.emit()


## セグメントの形状を設定する。
func set_segment(segment: PackedVector2Array) -> void:
	if Main.mirror:
		segment = segment.duplicate()
		for i in range(segment.size()):
			segment[i] = Vector2(Main.document_size.x - segment[i].x, segment[i].y)

	_segment = segment

	# 描画形状を設定する
	_line2d.points = _segment
	_line2d.width = COLLISION_WIDTH / 2 / _viewport_scale


## ControlSegmentのコントロールモードを設定する。
func set_mode(new_mode: ControlMode) -> void:
	mode = new_mode


## ホバーしているかどうかをセットする。
## ホバーは全コントロールポイントで排他制御される。
func set_hover(hover: bool) -> void:
	_hover = hover


## ホバー状態を取得する。
func get_hover() -> bool:
	return _hover


## ControlPointの表示上のスケールを設定する。
func set_control_scale(new_scale: float) -> void:
	_viewport_scale = new_scale
	_line2d.width = COLLISION_WIDTH / 2 / _viewport_scale


## control pointを挿入する。
func insert_cp(new_position: Vector2) -> void:
	path.insert_control_point(new_position, segment_index + 1)


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


## 見た目を更新する。
func _update_material() -> void:
	if _line2d.material is ShaderMaterial:
		var mat := _line2d.material as ShaderMaterial
		if _hide:
			mat.set_shader_parameter("fill_color", Color.TRANSPARENT)
		elif _hover:
			mat.set_shader_parameter("fill_color", Color(0.0, 1.0, 1.0, 0.7))
		else:
			mat.set_shader_parameter("fill_color", Color.TRANSPARENT)


## マウスオーバーを確認する。
func _check_mouseover() -> void:
	if Main.is_manipulating or _hide:
		mouse_over = false
		return
	var mouse_position: Vector2 = (get_parent() as Control).get_local_mouse_position()
	var distance := ShapeUtil.distance_segment_and_point(_segment, mouse_position)
	mouse_over = distance < COLLISION_WIDTH / 2 / _viewport_scale


## ControlSegmentを作成する関数。
static func new_control_segment(new_path: Path, index: int) -> ControlSegment:
	if not _control_segment_scene:
		_control_segment_scene = load("res://scenes/control/control_segment.tscn")
	var cs := _control_segment_scene.instantiate() as ControlSegment
	cs.path = new_path
	cs.segment_index = index
	cs.phi = new_path.phis[index]
	cs.psi = new_path.psis[index]
	return cs

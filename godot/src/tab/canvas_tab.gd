## キャンバスタブの挙動を記述するクラス。
extends PanelContainer
class_name CanvasTab


@onready var _space: ScrollSpace = %ScrollSpace
@onready var _document: Panel = %ScrollSpace/Document
@onready var _control_layer: Panel = %ScrollSpace/ControlLayer
@onready var _control_transform: ControlTransform = %ControlTransform
@onready var _control_linear_gradinet: ControlLinearGradient = %ControlLinearGradient
@onready var _control_radial_gradinet: ControlRadialGradient = %ControlRadialGradient
@onready var _drag_area_panel: Panel = %ScrollSpace/DragAreaPanel
@onready var _drawing_tool_highlight: Sprite2D = %DrawingButton/ToolHighlight
@onready var _manipulate_tool_highlight: Sprite2D = %ManipulateButton/ToolHighlight
@onready var _parameter_tuning_tool_highlight: Sprite2D = %ParameterTuningButton/ToolHighlight
@onready var _mirror_sprite: Sprite2D = %MirrorSprite
@onready var _mirror_flip_sprite: Sprite2D = %MirrorFlipSprite
@onready var _parameter_panel: Panel = %ParameterPanel
@onready var _parameter_label1: Label = %ParameterLabel1
@onready var _parameter_label2: Label = %ParameterLabel2

## ツールの種類の列挙子。
enum Tool {
	DRAWING,
	MANIPULATE,
	PARAMETER_TUNING,
	LINEAR_GRADIENT_EDITING,
	RADIAL_GRADIENT_EDITING,
}
## 現在のツール。
var _current_tool: Tool = Tool.DRAWING

## 現在表示しているControlPointの配列。
var _control_points: Array[ControlPoint] = []
## 現在表示しているControlSegmentの配列。
var _control_segments: Array[ControlSegment] = []

## 現在描画中のPathの参照。
## canvas_tabのモードがDRAWINGでCP追加中にそのパスを保持する。
## CP追加中ではない場合、nullとなる。
var _current_adding_cp_path: Path = null

## ドキュメントのマテリアル
var _document_material: ShaderMaterial

## マウスを押している状態かどうか。
var _mouse_pressing: bool = false
## マウスがmouse downしたあとに動いたかどうか。
var _mouse_moving: bool = false
## ドラッグエリアが開始したかどうか。
var _drag_area_start: bool = false
## ドラッグ開始時の位置。
var _drag_start_position: Vector2
## ドラッグ開始時にshiftやctrlを押していたか。
var _drag_start_modifier: bool = false

## 前フレームにcompositeが成功していたかどうか。
var _prev_composite_succeeded: bool = false


func _ready() -> void:
	Main.on_document_open.connect(_on_document_open)
	Main.on_document_close.connect(_on_document_close)
	Main.on_document_reload.connect(_on_document_reload)
	Main.on_mirror_changed.connect(_update_mirror)
	Main.on_start_edit_linear_gradient.connect(_start_edit_linear_gradient)
	Main.on_start_edit_radial_gradient.connect(_start_edit_radial_gradient)
	Main.on_end_edit_gradient.connect(_end_edit_gradient)
	Main.on_selected_paths_changed.connect(_on_selected_paths_changed)
	Main.on_update_control_segments.connect(_update_control_segments)
	Main.on_path_shape_changed.connect(_on_paths_shape_changed)
	_document_material = _document.material as ShaderMaterial


func _process(_delta: float) -> void:
	if Main.document_opened:
		_update_hover_controller()
		_update_parameter_panel()
		_update_control_point_scale()
		_update_control_segment_scale()
		_update_control_linear_gradient_scale()
		_update_control_radial_gradient_scale()
		_update_control_transform()
		_update_visibility_control()
		_set_document_size()
		_update_layer_texture()

		var composite_succecceeded := Main.compositor.composite(Main.layers.root)
		if not _prev_composite_succeeded and composite_succecceeded:
			Main.emit_update_layer_list_tab()
		_prev_composite_succeeded = composite_succecceeded


func _input(event: InputEvent) -> void:
	if not Main.document_opened:
		return

	if _current_tool == Tool.DRAWING:
		_drawing_tool_input(event)
	elif _current_tool == Tool.MANIPULATE:
		_manipulate_tool_input(event)
	else:
		pass

	# ESCでレイヤー/パス/マテリアルの選択状態を解除
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_ESCAPE:
			if _current_tool == Tool.LINEAR_GRADIENT_EDITING or _current_tool == Tool.RADIAL_GRADIENT_EDITING:
				_end_edit_gradient()
			Main.layers.clear_selected_items()
			Main.materials.clear_selected_index()
			Main.commit_history()


## Drawingツールのときのイベントハンドリング。
func _drawing_tool_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton
		var mouse_position := _control_layer.get_local_mouse_position()

		# Spaceの外をクリックした場合にはCPの追加などはしない
		var space_rect := Rect2(Vector2.ZERO, _space.size)
		if not space_rect.has_point(_space.get_local_mouse_position()):
			return

		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and \
			mouse_button_event.pressed and \
			_space.get_viewport_rect().has_point(_space.get_local_mouse_position()):
			if _current_adding_cp_path:
				# ControlPointが3つ以上で最初のControlPointへのクリックだったら
				# 現在CPを追加しているパスをclosedにしてCPの追加状態を終了する。
				if _control_points.size() > 2 and _control_points[0].get_hover():
					_current_adding_cp_path.change_closed(true)
					_current_adding_cp_path = null
					Main.commit_history()
				else:
					_current_adding_cp_path.add_control_point(mouse_position)
					Main.commit_history()

			else:
				# 新しくパスを追加してCPの追加モードを始める
				_current_adding_cp_path = Main.layers.add_path()
				if _current_adding_cp_path:
					_current_adding_cp_path.add_control_point(mouse_position)
					Main.commit_history()
			_reset_control_points()

	# EnterキーでDrawing状態の解除
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_ENTER:
			if _current_adding_cp_path and _current_adding_cp_path.control_points.size() > 2:
				_current_adding_cp_path = null


func _drag_area_update(start_pos: Vector2, end_pos: Vector2) -> void:
	var min_x := start_pos.x if start_pos.x < end_pos.x else end_pos.x
	var min_y := start_pos.y if start_pos.y < end_pos.y else end_pos.y
	var max_x := start_pos.x if start_pos.x > end_pos.x else end_pos.x
	var max_y := start_pos.y if start_pos.y > end_pos.y else end_pos.y

	var area_posision := Vector2(min_x, min_y)
	var area_size := Vector2(max_x - min_x, max_y - min_y)

	_drag_area_panel.position = area_posision
	_drag_area_panel.size = area_size


## Manipulateツールのときのイベントハンドリング。
func _manipulate_tool_input(event: InputEvent) -> void:
	var mouse_position := _space.get_local_mouse_position()
	if event is InputEventMouseButton:
		var mouse_button_event := event as InputEventMouseButton

		# mouse down
		if not _mouse_pressing and mouse_button_event.pressed and mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			_mouse_pressing = true
			_mouse_moving = false

			if _current_tool == Tool.MANIPULATE:
				# mouse down時にCP/CSをホバー中かどうか
				var hover_cp := false
				for cp in _control_points:
					if cp.get_hover():
						hover_cp = true
						break
				var hover_cs := false
				if not hover_cp:
					for cs in _control_segments:
						if cs.get_hover():
							hover_cs = true
							break

				if hover_cp:
					# CPをクリックしていたら
					if mouse_button_event.ctrl_pressed or mouse_button_event.shift_pressed:
						# モディファイアが押されていればhoverしているもののselectedを反転
						for cp in _control_points:
							if cp.get_hover():
								cp.selected = not cp.selected
					elif not _control_transform.is_hover():
						# モディファイアが押されていない場合、control_transformにホバー中ではない状態ならば、
						# hoverしているもの以外はselectedをクリアしてhoverしているものはselectedを反転
						for cp in _control_points:
							if cp.get_hover():
								cp.selected = not cp.selected
							else:
								cp.selected = false
				elif not hover_cs and not _control_transform.is_hover():
					# control_segmentやcontrol_transformにホバー中ではない状態で
					# CP以外のところをクリックしたらドラッグエリア開始
					_drag_area_start = true
					_drag_start_position = mouse_position
					_drag_area_panel.size = Vector2.ZERO
					_drag_area_panel.position = mouse_position
					_drag_area_update(_drag_start_position, mouse_position)

					if mouse_button_event.ctrl_pressed or mouse_button_event.shift_pressed:
						_drag_start_modifier = true
					else:
						_drag_start_modifier = false

		# mouse up
		if _mouse_pressing and not mouse_button_event.pressed:
			if _drag_area_start and _mouse_moving:
				# ドラッグエリアが開始していて実際にドラッグされていた場合

				# shiftやctrlを押していない場合はCPを一旦クリアする
				if not _drag_start_modifier:
					for cp in _control_points:
						cp.selected = false

				# 矩形の範囲内のCPを選択する
				var rect := Rect2((_drag_area_panel.position - _control_layer.position) / Main.viewport_scale, _drag_area_panel.size / Main.viewport_scale)
				for cp in _control_points:
					var pos := cp.get_control_position()
					if rect.has_point(pos):
						cp.selected = true

				_drag_area_panel.visible = false
			elif _drag_area_start and not _mouse_moving:
				# ドラッグエリアが開始しているがドラッグされていない場合
				# shiftやctrlを押していない場合はCPをクリアする
				if not _drag_start_modifier:
					for cp in _control_points:
						cp.selected = false

			_drag_area_start = false
			_mouse_pressing = false
			_mouse_moving = false

		# ダブルクリック時
		if mouse_button_event.double_click and mouse_button_event.button_index == MOUSE_BUTTON_LEFT:
			var space_rect := Rect2(Vector2.ZERO, _space.size)
			if space_rect.has_point(_space.get_local_mouse_position()):
				var click_position := _control_layer.get_local_mouse_position()

				# ホバー中のCPを削除
				var hover_cp := false
				for cp in _control_points:
					if cp.get_hover():
						cp.delete_cp()
						Main.commit_history()
						hover_cp = true
						break

				# ホバー中のCSに点を挿入
				var hover_cs := false
				for cs in _control_segments:
					if cs.get_hover():
						cs.insert_cp(click_position)
						Main.commit_history()
						hover_cs = true
						break

				# 何もホバー中でない場合、最後に選択したパスに新たにCPを追加
				if not hover_cp and not hover_cs:
					if Main.layers.last_selected_path:
						Main.layers.last_selected_path.add_control_point(click_position)
						Main.commit_history()

	if event is InputEventMouseMotion:
		# mouse drag
		if _mouse_pressing:
			_mouse_moving = true

		if _drag_area_start and _mouse_moving:
			_drag_area_panel.visible = true
			_drag_area_update(_drag_start_position, mouse_position)


## 選択中のパスが変更したときのコールバック。
func _on_selected_paths_changed() -> void:
	var selected := false
	for path in Main.layers.selected_paths:
		if not path.is_locked() and path == _current_adding_cp_path:
			selected = true
			break
	if not selected:
		_current_adding_cp_path = null
	_reset_control_points()
	_reset_control_segments()
	_update_control_segments()


## 選択中のパスの形状が変更したときのコールバック。
func _on_paths_shape_changed() -> void:
	_reset_control_points()
	_reset_control_segments()
	_update_control_segments()


## PathのControlPointを追加する。
func _add_path_control_points(path: Path) -> void:
	for j in path.control_points.size():
		var cp := ControlPoint.new_control_point(path, j)
		_control_points.append(cp)
		_control_layer.add_child(cp)
		cp.on_manipulate_finished.connect(_update_control_segments)


## PathのControlSegmentを追加する。
func _add_path_control_segments(path: Path) -> void:
	for j in path.segments.size():
		var cs := ControlSegment.new_control_segment(path, j)
		_control_segments.append(cs)
		_control_layer.add_child(cs)
		cs.on_manipulate_finished.connect(_update_control_segments)
		cs.set_segment(path.segments[j])


## コントローラーのhover状態を更新する。
func _update_hover_controller() -> void:
	# hoverフラグをリセットする
	for cp in _control_points:
		cp.set_hover(false)
	for cs in _control_segments:
		cs.set_hover(false)

	# mouse overしている最初の一つをhover状態にする
	for cp in _control_points:
		if cp.mouse_over:
			cp.set_hover(true)
			return
	for cs in _control_segments:
		if cs.mouse_over:
			cs.set_hover(true)
			return


## パラメータ調整中のパラメータ表示を更新する。
func _update_parameter_panel() -> void:
	if _current_tool == Tool.PARAMETER_TUNING:
		_parameter_panel.visible = true
		_parameter_label1.text = ""
		_parameter_label2.text = ""
		for cp in _control_points:
			if cp.get_hover() or cp.is_changing_parameter():
				_parameter_label1.text = "weight: " + str(cp.weight)
		for cs in _control_segments:
			if cs.get_hover() or cs.is_changing_parameter():
				_parameter_label1.text = "Psi: " + str(cs.psi)
				_parameter_label2.text = "Phi: " + str(cs.phi)
	else:
		_parameter_panel.visible = false
		_parameter_label1.text = ""
		_parameter_label2.text = ""


## ドキュメントの表示倍率をControlPointに反映させる関数。
func _update_control_point_scale() -> void:
	for cp in _control_points:
		cp.set_control_scale(Main.viewport_scale)


## ドキュメントの表示倍率をControlSegmentに反映させる関数。
func _update_control_segment_scale() -> void:
	for cs in _control_segments:
		cs.set_control_scale(Main.viewport_scale)


## ドキュメントの表示倍率をControlLinearGradientに反映させる関数。
func _update_control_linear_gradient_scale() -> void:
	_control_linear_gradinet.set_control_scale(Main.viewport_scale)


## ドキュメントの表示倍率をControlRadialGradientに反映させる関数。
func _update_control_radial_gradient_scale() -> void:
	_control_radial_gradinet.set_control_scale(Main.viewport_scale)


## 描画のレイヤーテクスチャを更新する関数。
func _update_layer_texture() -> void:
	var tex := Main.compositor.root_composite_texture.texture
	_document_material.set_shader_parameter("main_texture", tex)


## 現在選択中のレイヤーと現在のツールを確認してControlPointを作り直す。
func _reset_control_points(recreate: bool = true) -> void:
	if _current_tool == Tool.DRAWING:
		# 現在のコントローラーを削除する
		for cp in _control_points:
			cp.queue_free()
		_control_points.clear()

		# 現在描画中のPathについてコントローラーを作り直す。
		if _current_adding_cp_path:
			_add_path_control_points(_current_adding_cp_path)

		# コントローラの設定のアップデート
		for cp in _control_points:
			cp.mode = ControlPoint.ControlMode.NOOP
	elif _current_tool == Tool.MANIPULATE or _current_tool == Tool.PARAMETER_TUNING:
		if recreate:
			# 現在のコントローラーを削除する
			for cp in _control_points:
				cp.queue_free()
			_control_points.clear()

			# 現在選択中のPathについてコントローラーを作り直す。
			for path in Main.layers.selected_paths:
				if not path.is_locked():
					_add_path_control_points(path)

		# コントローラの設定のアップデート
		if _current_tool == Tool.MANIPULATE:
			for cp in _control_points:
				cp.mode = ControlPoint.ControlMode.MOVE_POSITION
		elif _current_tool == Tool.PARAMETER_TUNING:
			for cp in _control_points:
				cp.mode = ControlPoint.ControlMode.CHANGE_WEIGHT


## 現在選択中のレイヤーと現在のツールを確認してControlSegmentを作り直す。
func _reset_control_segments(recreate: bool = true) -> void:
	if _current_tool == Tool.DRAWING:
		# 現在のコントローラーを削除する
		for cs in _control_segments:
			cs.queue_free()
		_control_segments.clear()
	elif _current_tool == Tool.MANIPULATE or _current_tool == Tool.PARAMETER_TUNING:
		if recreate:
			# 現在のコントローラーを削除する
			for cs in _control_segments:
				cs.queue_free()
			_control_segments.clear()

			# 現在選択中のPathについてコントローラーを作り直す。
			for path in Main.layers.selected_paths:
				if not path.is_locked():
					_add_path_control_segments(path)

		# コントローラーの設定のアップデート
		if _current_tool == Tool.MANIPULATE:
			for cs in _control_segments:
				cs.mode = ControlSegment.ControlMode.NOOP
		elif _current_tool == Tool.PARAMETER_TUNING:
			for cs in _control_segments:
				cs.mode = ControlSegment.ControlMode.CHANGE_PARAMETER


## ControlSegmentの形状をupdateする。
func _update_control_segments() -> void:
	if _current_tool == Tool.MANIPULATE or _current_tool == Tool.PARAMETER_TUNING:
		var index := 0
		for path in Main.layers.selected_paths:
			for s in path.segments:
				if Main.is_manipulating:
					_control_segments[index].control_hide()
				else:
					_control_points[index].control_show()
					_control_segments[index].set_segment(s)
				index += 1


## ControlPointとControlSegmentをスペースバーを押している間は非表示にする。
func _update_visibility_control() -> void:
	if Input.is_key_pressed(KEY_SPACE):
		for cp in _control_points:
			cp.control_hide()
		for cs in _control_segments:
			cs.control_hide()
		_control_transform.control_hide()
		_control_linear_gradinet.control_hide()
		_control_radial_gradinet.control_hide()
	else:
		for cp in _control_points:
			cp.control_show()
		for cs in _control_segments:
			cs.control_show()
		_control_transform.control_show()
		_control_linear_gradinet.control_show()
		_control_radial_gradinet.control_show()


## マニピュレート中かどうかを取得する。
func get_manipulating() -> bool:
	var is_manipulating := false
	if _control_transform.is_manipulating():
		is_manipulating = true
	if _control_linear_gradinet.is_manipulating():
		is_manipulating = true
	if _control_radial_gradinet.is_manipulating():
		is_manipulating = true
	if not is_manipulating:
		for cp in _control_points:
			if cp.is_manipulating():
				is_manipulating = true
				break
	if not is_manipulating:
		for cs in _control_segments:
			if cs.is_manipulating():
				is_manipulating = true
				break
	return is_manipulating


## control transformのCPを更新する。
func _update_control_transform() -> void:
	var selected_control_points: Array[ControlPoint] = []
	for cp in _control_points:
		if cp.selected:
			selected_control_points.append(cp)
		cp.set_control_transform_hover(_control_transform.is_hover())
	_control_transform.set_control_points(selected_control_points)


## ドキュメントを閉じた状態にする。
func _remove_controls() -> void:
	# 現在のコントローラーを削除する
	for cp in _control_points:
		cp.queue_free()
	_control_points.clear()
	for cs in _control_segments:
		cs.queue_free()
	_control_segments.clear()


## ミラー状態を更新する。
func _update_mirror() -> void:
	if not Main.mirror:
		_mirror_sprite.visible = true
		_mirror_flip_sprite.visible = false
	else:
		_mirror_sprite.visible = false
		_mirror_flip_sprite.visible = true
	_reset_control_points()
	_reset_control_segments()


## 線形グラデーションの編集を開始する。
func _start_edit_linear_gradient(gradient_material: LinearGradientPaintMaterial) -> void:
	_current_tool = Tool.LINEAR_GRADIENT_EDITING
	_control_linear_gradinet.set_gradeint_material(gradient_material)
	_control_linear_gradinet.visible = true

	_control_transform.control_hide()
	for cp in _control_points:
		cp.control_hide()
	for cs in _control_segments:
		cs.control_hide()


## 放射グラデーションの編集を開始する。
func _start_edit_radial_gradient(gradient_material: RadialGradientPaintMaterial) -> void:
	_current_tool = Tool.RADIAL_GRADIENT_EDITING
	_control_radial_gradinet.set_gradeint_material(gradient_material)
	_control_radial_gradinet.visible = true

	_control_transform.control_hide()
	for cp in _control_points:
		cp.control_hide()
	for cs in _control_segments:
		cs.control_hide()


## グラデーションの編集を終了する。
func _end_edit_gradient() -> void:
	if _current_tool == Tool.LINEAR_GRADIENT_EDITING or _current_tool == Tool.RADIAL_GRADIENT_EDITING:
		_control_linear_gradinet.visible = false
		_control_radial_gradinet.visible = false
		_on_drawing_button_pressed()


## Documentのサイズを変更する。
func _set_document_size() -> void:
	_document.size = Main.document_size
	_control_layer.size = Main.document_size


## ドキュメントが開いたときに呼ばれるコールバック。
func _on_document_open() -> void:
	_document.visible = true
	_control_layer.visible = true
	_current_adding_cp_path = null
	if _current_tool == Tool.PARAMETER_TUNING:
		_parameter_panel.visible = true
	_reset_control_points()
	_reset_control_segments()
	_space.expand_document()
	_control_linear_gradinet.visible = false
	_control_radial_gradinet.visible = false


## ドキュメントが閉じたときに呼ばれるコールバック。
func _on_document_close() -> void:
	_document.visible = false
	_control_layer.visible = false
	_parameter_panel.visible = false
	_current_adding_cp_path = null
	_remove_controls()
	_control_linear_gradinet.visible = false
	_control_radial_gradinet.visible = false


## ドキュメントがリロードしたときに呼ばれるコールバック。
func _on_document_reload() -> void:
	_document.visible = true
	_control_layer.visible = true
	_current_adding_cp_path = null
	if _current_tool == Tool.PARAMETER_TUNING:
		_parameter_panel.visible = true
	_reset_control_points()
	_reset_control_segments()
	_control_linear_gradinet.visible = false
	_control_radial_gradinet.visible = false


## DRAWINGツールボタンを押したときのコールバック。
func _on_drawing_button_pressed() -> void:
	if not _current_tool == Tool.DRAWING:
		_current_tool = Tool.DRAWING
		_drawing_tool_highlight.visible = true
		_manipulate_tool_highlight.visible = false
		_parameter_tuning_tool_highlight.visible = false
		if not _drag_start_modifier:
			for cp in _control_points:
				cp.selected = false
		_reset_control_points()
		_reset_control_segments()
		_control_linear_gradinet.visible = false
		_control_radial_gradinet.visible = false


## MANIPULATEツールボタンを押したときのコールバック。
func _on_direct_selection_button_pressed() -> void:
	var prev_tool := _current_tool
	if not _current_tool == Tool.MANIPULATE:
		_current_tool = Tool.MANIPULATE
		_drawing_tool_highlight.visible = false
		_manipulate_tool_highlight.visible = true
		_parameter_tuning_tool_highlight.visible = false
		_current_adding_cp_path = null
		if prev_tool == Tool.PARAMETER_TUNING:
			_reset_control_points(false)
			_reset_control_segments(false)
		else:
			_reset_control_points()
			_reset_control_segments()
		_control_linear_gradinet.visible = false
		_control_radial_gradinet.visible = false


## PARAMETER_TUNINGツールボタンを押したときのコールバック。
func _on_parameter_tuning_button_pressed() -> void:
	var prev_tool := _current_tool
	if not _current_tool == Tool.PARAMETER_TUNING:
		_current_tool = Tool.PARAMETER_TUNING
		_drawing_tool_highlight.visible = false
		_manipulate_tool_highlight.visible = false
		_parameter_tuning_tool_highlight.visible = true
		_current_adding_cp_path = null
		if not _drag_start_modifier:
			for cp in _control_points:
				cp.selected = false
		if prev_tool == Tool.MANIPULATE:
			_reset_control_points(false)
			_reset_control_segments(false)
		else:
			_reset_control_points()
			_reset_control_segments()
		_control_linear_gradinet.visible = false
		_control_radial_gradinet.visible = false


## ズームリセットボタンが押された際のコールバック。
func _on_zoom_reset_button_pressed() -> void:
	_space.reset_document_scale()


## expandボタンが押された際のコールバック。
func _on_expand_button_pressed() -> void:
	_space.expand_document()


## ミラーボタンを押したときのコールバック。
func _on_mirror_button_pressed() -> void:
	Main.mirror = not Main.mirror


## ControlTransformの操作が完了するたびに呼ばれるコールバック。
func _on_control_transform_on_manipulate_finished() -> void:
	_reset_control_segments()
	_update_control_segments()

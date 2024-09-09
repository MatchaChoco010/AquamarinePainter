## レイヤーリストの要素のノードのクラス。
class_name LayerListItem
extends PanelContainer


@onready var _node: PanelContainer = $"."

@onready var _eye_open: Sprite2D = %EyeButton/EyeOpen
@onready var _eye_slash: Sprite2D = %EyeButton/EyeSlash

@onready var _pen_panel: Panel = %PenPanel
@onready var _pen_sprite: Sprite2D = %PenPanel/Sprite2D
@onready var _locked_panel: Panel = %LockedPanel
@onready var _locked_sprite: Sprite2D = %LockedPanel/Sprite2D

@onready var _spacer: ColorRect = %Spacer

@onready var _clipping_rect: ColorRect = %ClippingRect

@onready var _collapse_button: Button = %CollapseButton
@onready var _folder_open: Sprite2D = %CollapseButton/FolderOpen
@onready var _folder_close: Sprite2D = %CollapseButton/FolderClose
@onready var _caret_open: Sprite2D = %CollapseButton/CaretOpen
@onready var _caret_close: Sprite2D = %CollapseButton/CaretClose
@onready var _fill_mark: Sprite2D = %CollapseButton/FillMark

@onready var _thumbnail_panel: Panel = %Thumbnail
@onready var _thumbnail_rect: ColorRect = %Thumbnail/ThumbnailRect

@onready var _blend_mode_text: Label = %BlendModeText
@onready var _alpha_text: Label = %AlphaText

@onready var _boolean_panel: Panel = %BooleanPanel
@onready var _boolean_union: Sprite2D = %BooleanPanel/Union
@onready var _boolean_diff: Sprite2D = %BooleanPanel/Diff
@onready var _boolean_intersect: Sprite2D = %BooleanPanel/Intersect
@onready var _boolean_xor: Sprite2D = %BooleanPanel/Xor

@onready var _name_text: LineEdit = %NameText

@onready var _missint_panel: Panel = %MissingPanel

@onready var _dragging_panel: Panel = $DraggingtPanel

## マウスオーバーしているかどうか。
var mouse_over: bool = false
## 上半分にマウスオーバーしているかどうか。
var mouse_over_top: bool = false
## 下半分にマウスオーバーしているかどうか。
var mouse_over_bottom: bool = false
## インデントのデプス。
var depth: int = 0
## ドラッグ中かどうか。
var dragging: bool = false

## 編集中のテキスト。
var _editing_name: String = ""
## 選択中かどうか。
var _selected: bool = false
## 要素の上でマウスダウンしているかどうか。
var _mouse_down: bool = false

## eye openのSprite2Dのマテリアル
var _eye_open_material: ShaderMaterial
## eye closeのSprite2Dのマテリアル
var _eye_slash_material: ShaderMaterial
## lockedのSprite2Dのマテリアル
var _locked_material: ShaderMaterial
## thumbnail rectのColorRectのマテリアル
var _thumbnail_rect_material: ShaderMaterial

## このアイテムの対応するレイヤー。
var _layer: PaintLayer = null
## このアイテムの対応するパス。
var _path: Path = null

## パス再計算後にcommit hisotryする必要があるかどうか。
var _need_commit_history: bool = false

## リストアイテムのシーン。
static var _list_item: PackedScene


func _ready() -> void:
	_node.add_theme_stylebox_override("panel", _node.get_theme_stylebox("panel").duplicate() as StyleBox)
	_name_text.add_theme_stylebox_override("focus", _name_text.get_theme_stylebox("focus").duplicate() as StyleBox)
	_eye_open_material = _eye_open.material.duplicate() as ShaderMaterial
	_eye_open.material = _eye_open_material
	_eye_slash_material = _eye_slash.material.duplicate() as ShaderMaterial
	_eye_slash.material = _eye_slash_material
	_locked_material = _locked_sprite.material.duplicate() as ShaderMaterial
	_locked_sprite.material = _locked_material
	_thumbnail_rect_material = _thumbnail_rect.material.duplicate() as ShaderMaterial
	_thumbnail_rect.material = _thumbnail_rect_material


func _process(_delta: float) -> void:
	if _need_commit_history:
		Main.commit_history()
		_need_commit_history = false


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		var mouse_position := _node.get_local_mouse_position()

		# アイテムがクリックされたら選択して、アイテム外がクリックされたらtextを編集状態解除する
		var rect := Rect2(Vector2.ZERO, size)
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if rect.has_point(mouse_position) and mouse_over:
				if mouse_event.pressed and not _mouse_down:
					_mouse_down = true
				if not mouse_event.pressed and _mouse_down:
					_mouse_down = false
					# 他のアイテムのrename確定処理が終わってからclickedを呼び出す
					if mouse_event.ctrl_pressed and mouse_event.shift_pressed:
						if _layer:
							Main.layers.add_selected_layer_range(_layer)
							Main.commit_history()
						elif _path:
							Main.layers.add_selected_path_range(_path)
							Main.commit_history()
					elif mouse_event.ctrl_pressed:
						if _layer:
							Main.layers.add_or_remove_selected_layer(_layer)
							Main.commit_history()
						elif _path:
							Main.layers.add_or_remove_selected_path(_path)
							Main.commit_history()
					elif mouse_event.shift_pressed:
						if _layer:
							Main.layers.set_selected_layer_range(_layer)
							Main.commit_history()
						elif _path:
							Main.layers.set_selected_path_range(_path)
							Main.commit_history()
					else:
						if _layer:
							Main.layers.set_selected_layer(_layer)
							Main.commit_history()
						elif _path:
							Main.layers.set_selected_path(_path)
							Main.commit_history()
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
	if _name_text.editable:
		if _path:
			_path.path_name = _editing_name
		if _layer:
			_layer.layer_name = _editing_name
	var style_box := _name_text.get_theme_stylebox("focus") as StyleBoxFlat
	_name_text.editable = false
	_name_text.selecting_enabled = false
	style_box.border_width_top = 0
	style_box.border_width_bottom = 0
	style_box.border_width_left = 0
	style_box.border_width_right = 0


## このItemで表示するレイヤーを指定する。
func _set_layer(layer: PaintLayer) -> void:
	_layer = layer
	_path = null

	# eyeアイコン
	if layer.visible:
		_eye_open.visible = true
		_eye_slash.visible = false
	else:
		_eye_open.visible = false
		_eye_slash.visible = true
	if layer.parent_visible:
		_eye_open_material.set_shader_parameter("fill_color", Color("cccccc"))
		_eye_slash_material.set_shader_parameter("fill_color", Color("cccccc"))
	else:
		_eye_open_material.set_shader_parameter("fill_color", Color("666666"))
		_eye_slash_material.set_shader_parameter("fill_color", Color("666666"))

	# ロック状態
	if layer.is_locked():
		_locked_panel.visible = true
		_pen_panel.visible = false
	else:
		_locked_panel.visible = false
		_pen_panel.visible = true
	if layer.locked:
		_locked_material.set_shader_parameter("fill_color", Color("cccccc"))
	else:
		_locked_material.set_shader_parameter("fill_color", Color("666666"))


	# クリッピング
	if layer.clipped:
		_clipping_rect.visible = true
	else:
		_clipping_rect.visible = false

	# サムネイル
	if Main.document_size.x > Main.document_size.y:
		_thumbnail_rect.size.x = _thumbnail_panel.size.x
		_thumbnail_rect.size.y = _thumbnail_panel.size.y * Main.document_size.y / Main.document_size.x
		_thumbnail_rect.position = Vector2(0, (38 - _thumbnail_rect.size.y) / 2)
	else:
		_thumbnail_rect.size.x = _thumbnail_panel.size.x * Main.document_size.x / Main.document_size.y
		_thumbnail_rect.size.y = _thumbnail_panel.size.y
		_thumbnail_rect.position = Vector2((38 - _thumbnail_rect.size.x) / 2, 0)

	# blend mode
	if layer.blend_mode == PaintLayer.BlendMode.Normal:
		_blend_mode_text.text = tr("BLEND_MODE_NORMAL")
	elif layer.blend_mode == PaintLayer.BlendMode.Add:
		_blend_mode_text.text = tr("BLEND_MODE_ADD")
	elif layer.blend_mode == PaintLayer.BlendMode.Multiply:
		_blend_mode_text.text = tr("BLEND_MODE_MULTIPLY")
	elif layer.blend_mode == PaintLayer.BlendMode.Screen:
		_blend_mode_text.text = tr("BLEND_MODE_SCREEN")
	elif layer.blend_mode == PaintLayer.BlendMode.Overlay:
		_blend_mode_text.text = tr("BLEND_MODE_OVERLAY")

	# alpha
	_alpha_text.visible = true
	_alpha_text.text = str(layer.alpha) + "%"

	# boolean
	_boolean_panel.visible = false

	# レイヤーの名前
	_name_text.text = layer.layer_name

	# 選択中かどうか
	var style_box := _node.get_theme_stylebox("panel") as StyleBoxFlat
	var selected := false
	for l in Main.layers.selected_layers:
		if l == layer:
			selected = true
			break
	if selected:
		style_box.bg_color = Color(0.5, 0.8, 0.9, 0.25)
	else:
		style_box.bg_color = Color.TRANSPARENT

	if layer is PathPaintLayer:
		var path_layer := layer as PathPaintLayer

		# ペンアイコン
		if path_layer == Main.layers.drawing_path_layer:
			_pen_sprite.visible = true
		else:
			_pen_sprite.visible = false

		# デプス
		_spacer.custom_minimum_size.x = 24 * depth

		# サムネイル
		if Main.compositor.composite_textures[path_layer.id].valid:
			_thumbnail_rect_material.set_shader_parameter("main_texture", Main.compositor.composite_textures[path_layer.id].texture)
		else:
			_thumbnail_rect_material.set_shader_parameter("main_texture", null)

		# 折りたたみ
		_collapse_button.visible = true
		_folder_close.visible = false
		_folder_open.visible = false
		_fill_mark.visible = false
		if path_layer.collapsed:
			_caret_open.visible = false
			_caret_close.visible = true
		else:
			_caret_open.visible = true
			_caret_close.visible = false

		# マテリアルmissing
		if path_layer.is_material_missing():
			_missint_panel.visible = true
		else:
			_missint_panel.visible = false

	elif layer is FillPaintLayer:
		var fill_layer := layer as FillPaintLayer

		# ペンアイコン
		_pen_sprite.visible = false

		# デプス
		_spacer.custom_minimum_size.x = 24 * depth

		# サムネイル
		if Main.compositor.composite_textures[fill_layer.id].valid:
			_thumbnail_rect_material.set_shader_parameter("main_texture", Main.compositor.composite_textures[fill_layer.id].texture)
		else:
			_thumbnail_rect_material.set_shader_parameter("main_texture", null)

		# 折りたたみみ
		_collapse_button.visible = true
		_folder_close.visible = false
		_folder_open.visible = false
		_caret_open.visible = false
		_caret_close.visible = false
		_fill_mark.visible = true

		# マテリアルmissing
		if fill_layer.is_material_missing():
			_missint_panel.visible = true
		else:
			_missint_panel.visible = false

	elif layer is GroupPaintLayer:
		var group_layer := layer as GroupPaintLayer

		# ペンアイコン
		_pen_sprite.visible = false

		# デプス
		_spacer.custom_minimum_size.x = 24 * depth

		# サムネイル
		if Main.compositor.composite_textures[group_layer.id].valid:
			_thumbnail_rect_material.set_shader_parameter("main_texture", Main.compositor.composite_textures[group_layer.id].texture)
		else:
			_thumbnail_rect_material.set_shader_parameter("main_texture", null)

		# 折りたたみ
		_collapse_button.visible = true
		_caret_open.visible = false
		_caret_close.visible = false
		_fill_mark.visible = false
		if group_layer.collapsed:
			_folder_open.visible = false
			_folder_close.visible = true
		else:
			_folder_open.visible = true
			_folder_close.visible = false

		# マテリアルmissing
		_missint_panel.visible = false


## このItemで表示するパスを指定する。
func _set_path(path: Path) -> void:
	_layer = null
	_path = path

	# eyeアイコン
	if path.visible:
		_eye_open.visible = true
		_eye_slash.visible = false
	else:
		_eye_open.visible = false
		_eye_slash.visible = true
	if path.parent_visible:
		_eye_open_material.set_shader_parameter("fill_color", Color("cccccc"))
		_eye_slash_material.set_shader_parameter("fill_color", Color("cccccc"))
	else:
		_eye_open_material.set_shader_parameter("fill_color", Color("666666"))
		_eye_slash_material.set_shader_parameter("fill_color", Color("666666"))

	# ロック状態
	if path.is_locked():
		_locked_panel.visible = true
		_pen_panel.visible = false
	else:
		_locked_panel.visible = false
		_pen_panel.visible = true
	if path.locked:
		_locked_material.set_shader_parameter("fill_color", Color("cccccc"))
	else:
		_locked_material.set_shader_parameter("fill_color", Color("666666"))

	# ペンアイコン
	_pen_sprite.visible = false

	# クリッピング
	_clipping_rect.visible = false

	# デプス
	_spacer.custom_minimum_size.x = 24 + 24 * depth

	# 折りたたみ
	_collapse_button.visible = false

	# サムネイル
	if Main.document_size.x > Main.document_size.y:
		_thumbnail_rect.size.x = _thumbnail_panel.size.x
		_thumbnail_rect.size.y = _thumbnail_panel.size.y * Main.document_size.y / Main.document_size.x
		_thumbnail_rect.position = Vector2(0, (38 - _thumbnail_rect.size.y) / 2)
	else:
		_thumbnail_rect.size.x = _thumbnail_panel.size.x * Main.document_size.x / Main.document_size.y
		_thumbnail_rect.size.y = _thumbnail_panel.size.y
		_thumbnail_rect.position = Vector2((38 - _thumbnail_rect.size.x) / 2, 0)
	_thumbnail_rect_material.set_shader_parameter("main_texture", path.get_path_texture())

	# blend mode
	_blend_mode_text.text = ""

	# alpha
	_alpha_text.visible = false

	# boolean
	if path.get_is_line():
		_boolean_panel.visible = false
	else:
		_boolean_panel.visible = true
		if path.boolean == Path.Boolean.Union:
			_boolean_union.visible = true
			_boolean_diff.visible = false
			_boolean_intersect.visible = false
			_boolean_xor.visible = false
		elif path.boolean == Path.Boolean.Diff:
			_boolean_union.visible = false
			_boolean_diff.visible = true
			_boolean_intersect.visible = false
			_boolean_xor.visible = false
		elif path.boolean == Path.Boolean.Intersect:
			_boolean_union.visible = false
			_boolean_diff.visible = false
			_boolean_intersect.visible = true
			_boolean_xor.visible = false
		elif path.boolean == Path.Boolean.Xor:
			_boolean_union.visible = false
			_boolean_diff.visible = false
			_boolean_intersect.visible = false
			_boolean_xor.visible = true

	# パスの名前
	_name_text.text = path.path_name

	# 選択中かどうか
	var style_box := _node.get_theme_stylebox("panel") as StyleBoxFlat
	var selected := false
	for p in Main.layers.selected_paths:
		if p == path:
			selected = true
			break
	if selected:
		style_box.bg_color = Color(0.5, 0.8, 0.9, 0.25)
	else:
		style_box.bg_color = Color.TRANSPARENT

	# マテリアルmissing
	_missint_panel.visible = false


## 選択中の表示を設定する。
func set_selected(selected: bool) -> void:
	var style_box := _node.get_theme_stylebox("panel") as StyleBoxFlat
	if selected:
		style_box.bg_color = Color(0.5, 0.8, 0.9, 0.25)
	else:
		style_box.bg_color = Color.TRANSPARENT
	_selected = selected


## ドラッグ中の表示を設定する。
func set_dragging(new_dragging: bool) -> void:
	_dragging_panel.visible = new_dragging
	dragging = new_dragging


## 現在のアイテムがパスかどうかを返す。
func is_path() -> bool:
	if _path is Path:
		return true
	return false


## 現在のアイテムがPathPaintLayerかどうかを返す。
func is_path_layer() -> bool:
	if _layer is PathPaintLayer:
		return true
	return false


## 現在のアイテムがPathPaintLayerが空かどうかを返す。
func is_path_layer_empty() -> bool:
	if _layer is PathPaintLayer:
		var path_layer := _layer as PathPaintLayer
		return path_layer.paths.size() == 0
	return false


## 現在のアイテムがFillPaintLayerかどうかを返す。
func is_fill_layer() -> bool:
	if _layer is FillPaintLayer:
		return true
	return false


## 現在のアイテムがGroupPaintLayerかどうかを返す。
func is_group_layer() -> bool:
	if _layer is GroupPaintLayer:
		return true
	return false


## 現在のアイテムがGroupPaintLayerが空かどうかを返す。
func is_group_layer_empty() -> bool:
	if _layer is GroupPaintLayer:
		var group_layer := _layer as GroupPaintLayer
		return group_layer.child_layers.size() == 0
	return false


## 現在のアイテムがPathPaintLayerだったらそれを返す。
## そうでなければnullを返す。
func get_path_layer() -> PathPaintLayer:
	if _layer is PathPaintLayer:
		var gl := _layer as PathPaintLayer
		return gl
	return null


## 現在のアイテムがGroupPaintLayerだったらそれを返す。
## そうでなければnullを返す。
func get_group_layer() -> GroupPaintLayer:
	if _layer is GroupPaintLayer:
		var gl := _layer as GroupPaintLayer
		return gl
	return null


## 現在のアイテムがPathPaintLayerもしくはGroupPaintLayerでopen状態かどうか
func is_open() -> bool:
	if _layer is PathPaintLayer:
		var path_layer := _layer as PathPaintLayer
		return not path_layer.collapsed
	if _layer is GroupPaintLayer:
		var group_layer := _layer as GroupPaintLayer
		return not group_layer.collapsed
	return false


## 名前のテキストを確定したときに呼ばれるコールバック。
func _on_line_edit_text_submitted(_new_text: String) -> void:
	_exit_edit_name()


## 名前のテキストを変更したときに呼ばれるコールバック。
func _on_line_edit_text_changed(new_text: String) -> void:
	_editing_name = new_text


## マウスオーバーしたときに呼び出されるコールバック。
func _on_mouse_entered() -> void:
	mouse_over = true
	var mouse_pos := get_local_mouse_position()
	if mouse_pos.y > size.y / 2:
		mouse_over_bottom = true
		mouse_over_top = false
	else:
		mouse_over_bottom = false
		mouse_over_top = true


## マウスが外れたときに呼び出されるコールバック。
func _on_mouse_exited() -> void:
	mouse_over = false
	mouse_over_bottom = false
	mouse_over_top = false


## 折りたたみボタンを押したときに呼び出されるコールバック。
func _on_collapse_button_button_up() -> void:
	if _layer is PathPaintLayer:
		var path_layer := _layer as PathPaintLayer
		path_layer.collapsed = not path_layer.collapsed
		_collapse_button.visible = true
		_folder_close.visible = false
		_folder_open.visible = false
		_fill_mark.visible = false
		if path_layer.collapsed:
			_caret_open.visible = false
			_caret_close.visible = true
		else:
			_caret_open.visible = true
			_caret_close.visible = false
	elif _layer is GroupPaintLayer:
		var group_layer := _layer as GroupPaintLayer
		group_layer.collapsed = not group_layer.collapsed
		_collapse_button.visible = true
		_caret_open.visible = false
		_caret_close.visible = false
		_fill_mark.visible = false
		if group_layer.collapsed:
			_folder_open.visible = false
			_folder_close.visible = true
		else:
			_folder_open.visible = true
			_folder_close.visible = false
	Main.emit_update_layer_list_tab()


## 表示非表示の切り替えボタンを押したときに呼び出されるコールバック
func _on_eye_button_button_up() -> void:
	if _layer is PathPaintLayer:
		var path_layer := _layer as PathPaintLayer
		path_layer.update_visible(not path_layer.visible)
	if _layer is FillPaintLayer:
		var fill_layer := _layer as FillPaintLayer
		fill_layer.update_visible(not fill_layer.visible)
	if _layer is GroupPaintLayer:
		var group_layer := _layer as GroupPaintLayer
		group_layer.update_visible(not group_layer.visible)
	if _path:
		_path.visible = not _path.visible
		_path.recalculate_polygon()
	Main.emit_update_layer_list_tab()
	_need_commit_history = true


## レイヤーとして初期化する
func init_layer(layer: PaintLayer, new_depth: int) -> void:
	depth = new_depth
	_set_layer(layer)
	dragging = false
	for dragging_layer in Main.layers.dragging_layers:
		if layer == dragging_layer:
			dragging = true
	set_dragging(dragging)


## パスとして初期化する
func init_path(path: Path, new_depth: int) -> void:
	depth = new_depth
	_set_path(path)
	dragging = false
	for dragging_path in Main.layers.dragging_paths:
		if path == dragging_path:
			dragging = true
	set_dragging(dragging)


## ノードを生成する。
static func new_item() -> LayerListItem:
	if not _list_item:
		_list_item = load("res://scenes/node/layer_list_item.tscn")
	var list_item := _list_item.instantiate() as LayerListItem
	return list_item

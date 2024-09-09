## レイヤーのリストのタブのクラス。
## レイヤーのリストの並べ替えのDnDの処理を含む。
class_name LayerListTab
extends PanelContainer


@onready var _blend_mode_menu: MenuButton = %BlendModeMenu
@onready var _alpha_slider: Slider = %AlphaSlider
@onready var _alpha_spin_box: SpinBox = %AlphaSpinBox
@onready var _add_button: Button = %AddButton
@onready var _add_fill_button: Button = %AddFillButton
@onready var _add_group_button: Button = %AddGroupButton
@onready var _delete_button: Button = %DeleteButton
@onready var _clip_button: Button = %ClipButton
@onready var _clip_panel: Panel = %ClipButton/Panel
@onready var _locked_button: Button = %LockButton
@onready var _unlocked: Sprite2D = %LockButton/UnLocked
@onready var _locked: Sprite2D = %LockButton/Locked
@onready var _locked_panel: Panel = %LockButton/Panel
@onready var _open_close_button: Button = %OpenCloseButton
@onready var _open_path: Sprite2D = %OpenCloseButton/Open
@onready var _close_path: Sprite2D = %OpenCloseButton/Close
@onready var _boolean_menu: MenuButton = %BooleanMenu
@onready var _boolean_union: Sprite2D = %BooleanMenu/Union
@onready var _boolean_diff: Sprite2D = %BooleanMenu/Diff
@onready var _boolean_intersect: Sprite2D = %BooleanMenu/Intersect
@onready var _boolean_xor: Sprite2D = %BooleanMenu/Xor

@onready var _scroll_container: ScrollContainer = %ScrollContainer
@onready var _container: VBoxContainer = %ScrollContainer/ListContainer
@onready var _dnd_cursor: ListDropCursor = %ScrollContainer/ListContainer/ListDropCursor

## レイヤーリストの要素。
var _items: Array[LayerListItem] = []

## 最後にalphaを変更した時刻。
var _last_alpha_changed_time: int = -1
## alpha変更があってからcommitしたかどうか。
var _last_alpha_changed_commit: bool = true

## layer_listがdirtyかどうか。
var _is_layer_list_dirty: bool = false


func _ready() -> void:
	Main.on_update_layer_list_tab.connect(_set_dirty)
	Main.on_locale_changed.connect(_set_dirty)

	_boolean_menu.get_popup().id_pressed.connect(_change_boolean)
	_blend_mode_menu.get_popup().id_pressed.connect(_change_blend_mode)

	_update_layer_list_tab_buttons()


func _process(_delta: float) -> void:
	if not Main.document_opened:
		_update_layer_list()
		return

	# ドラッグ中ならマスカーソルの一でスクロールを動かす
	if Main.layers.dragging_root_layers.size() > 0 or Main.layers.dragging_paths.size() > 0:
		var mouse_position := _scroll_container.get_local_mouse_position()

		var top_rect := Rect2(Vector2.ZERO, Vector2(_scroll_container.size.x, 32))
		var bottom_rect := Rect2(Vector2(0, _scroll_container.size.y - 32), Vector2(_scroll_container.size.x, 32))

		if top_rect.has_point(mouse_position):
			_scroll_container.scroll_vertical -= 2
		if bottom_rect.has_point(mouse_position):
			_scroll_container.scroll_vertical += 2

	# アルファが最後に変更されてから500ms経っていて、かつ、コミットされていなければコミットする。
	if not _last_alpha_changed_commit and Time.get_ticks_msec() - _last_alpha_changed_time > 500:
		_last_alpha_changed_commit = true
		Main.commit_history()

	# dirtyだったら更新する
	if _is_layer_list_dirty:
		# レイヤーのサムネのミップマップ生成が遅いため、更新頻度の高いコントローラーの操作中は更新を止める
		if not Main.is_manipulating:
			_update_layer_list()
			_is_layer_list_dirty = false


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAG_END:
			_drag_end()


func _get_drag_data(_at_position: Vector2) -> Variant:
	# ドラッグ開始時に選択していたアイテムをクリックしてドラッグしているか確認する
	Main.layers.drag_start()
	_update_layer_list()

	var drag_item_mouse_on := false
	for item in _items:
		if item.dragging and item.mouse_over:
			drag_item_mouse_on = true
			break
	if not drag_item_mouse_on:
		Main.layers.drag_end()
		_set_dirty()
		return

	if Main.layers.dragging_root_layers.size() > 0:
		return Main.layers.dragging_root_layers[0]
	else:
		return Main.layers.dragging_paths[0]


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is PaintLayer:
		_dnd_cursor.visible = true

		var cursor_index := _container.get_child_count() - 1
		var depth := 0
		for index in _items.size():
			var item := _items[index]
			var next_item := _items[index + 1] if index != _items.size() - 1 else null
			if item.mouse_over_top:
				if item.dragging:
					cursor_index = -1
					break
				if item.is_path():
					cursor_index = -1
				else:
					cursor_index = index
					depth = item.depth
			elif item.mouse_over_bottom:
				if item.dragging:
					cursor_index = -1
					break
				if item.is_path():
					if next_item:
						if next_item.is_path():
							cursor_index = -1
						else:
							cursor_index = index + 1
							depth = next_item.depth
					else:
						cursor_index = index + 1
						depth = 0
				elif item.is_path_layer():
					if item.is_open():
						if item.is_path_layer_empty():
							cursor_index = index + 1
							depth = item.depth
						else:
							cursor_index = -1
					else:
						cursor_index = index + 1
						depth = item.depth
				elif item.is_fill_layer():
					cursor_index = index + 1
					depth = item.depth
				elif item.is_group_layer():
					if item.is_open():
						cursor_index = index + 1
						depth = item.depth + 1
					else:
						cursor_index = index + 1
						depth = item.depth
		_dnd_cursor.set_depth(depth)

		# ドラッグ先を示すカーソルを挿入する
		for child in _container.get_children():
			_container.remove_child(child)
		for index in _items.size():
			var item := _items[index]
			if index == cursor_index:
				_container.add_child(_dnd_cursor)
			_container.add_child(item)
		if cursor_index == _items.size():
			_container.add_child(_dnd_cursor)

		return true

	if data is Path:
		_dnd_cursor.visible = true

		var cursor_index := _container.get_child_count() - 1
		var depth := 0
		for index in _items.size():
			var prev_item := _items[index - 1] if index != 0 else null
			var item := _items[index]
			if item.mouse_over_top:
				if item.dragging:
					cursor_index = -1
					break
				if item.is_path():
					cursor_index = index
					depth = item.depth
				else:
					if prev_item:
						if prev_item.is_path():
							cursor_index = index
							depth = prev_item.depth
						else:
							cursor_index = -1
					else:
						cursor_index = -1
			elif item.mouse_over_bottom:
				if item.dragging:
					cursor_index = -1
					break
				if item.is_path():
					cursor_index = index + 1
					depth = item.depth
				elif item.is_path_layer():
					if item.is_open():
						cursor_index = index + 1
						depth = item.depth + 1
					else:
						cursor_index = -1
				else:
					cursor_index = -1
		_dnd_cursor.set_depth(depth)

		# ドラッグ先を示すカーソルを挿入する
		for child in _container.get_children():
			_container.remove_child(child)
		for index in _items.size():
			var item := _items[index]
			if index == cursor_index:
				_container.add_child(_dnd_cursor)
			_container.add_child(item)
		if cursor_index == _items.size():
			_container.add_child(_dnd_cursor)

		return true

	_dnd_cursor.visible = false
	return false


## ドラッグが終了したときに呼び出す関数。
func _drag_end() -> void:
	# レイヤーのドラッグ中
	if Main.layers.dragging_root_layers.size() > 0:
		var insert_at := func(item: LayerListItem, index: int, top: bool) -> void:
			var insert := 0
			var parent: GroupPaintLayer = null
			if item.is_path():
				# レベルが2つ上のGroupPaintLayerまで逆にたどって親を見つける
				for i in index:
					if _items[index - i - 1].depth == item.depth - 2:
						parent = _items[index - i - 1].get_group_layer()
						break
				# 一つ上のレベルで後ろにあるやつを数えてinsertの数を調べる
				for i in range(index + 1, _items.size()):
					if _items[i].depth == item.depth - 1:
						insert += 1
					elif _items[i].depth > item.depth - 1:
						pass
					else:
						break
			else:
				# レベルが一つ上のGroupPaintLayerまで逆にたどって親を見つける
				for i in index:
					if _items[index - i - 1].depth == item.depth - 1:
						parent = _items[index - i - 1].get_group_layer()
						break
				# 同じレベルで後ろにあるやつを数えてinsertの数を調べる
				for i in range(index + 1, _items.size()):
					if _items[i].depth == item.depth:
						insert += 1
					elif _items[i].depth > item.depth:
						pass
					else:
						break
			if top:
				insert += 1
			Main.layers.drag_move_layer(insert, parent)
			Main.commit_history()

		var inserted := false
		for index in _items.size():
			var item := _items[index]
			var next_item := _items[index + 1] if index != _items.size() - 1 else null
			if item.mouse_over_top:
				if item.dragging:
					break
				if item.is_path():
					break
				else:
					insert_at.call(item, index, true)
					inserted = true
					break
			elif item.mouse_over_bottom:
				if item.dragging:
					break
				if item.is_path():
					if next_item:
						if next_item.is_path():
							break
						else:
							insert_at.call(item, index, false)
							inserted = true
							break
					else:
						insert_at.call(item, index, false)
						inserted = true
						break
				elif item.is_path_layer():
					if item.is_open():
						if item.is_path_layer_empty():
							insert_at.call(item, index, false)
							inserted = true
							break
						else:
							pass
					else:
						insert_at.call(item, index, false)
						inserted = true
						break
				elif item.is_fill_layer():
					insert_at.call(item, index, false)
					inserted = true
					break
				elif item.is_group_layer():
					if item.is_open():
						var group_layer := item.get_group_layer()
						if item.is_group_layer_empty():
							Main.layers.drag_move_layer(0, group_layer)
							Main.commit_history()
						else:
							Main.layers.drag_move_layer(group_layer.child_layers.size(), group_layer)
							Main.commit_history()
						inserted = true
						break
					else:
						insert_at.call(item, index, false)
						inserted = true
						break
		if not inserted:
			Main.layers.drag_move_layer(0, null)

	# パスのドラッグ中
	elif Main.layers.dragging_paths.size() > 0:
		var insert_at := func(item: LayerListItem, index: int, top_of_path: bool) -> void:
			var insert := 0
			var parent: PathPaintLayer = null
			# レベルが一つ上PathpPaintLayerまで逆にたどって親を見つける
			for i in index:
				if _items[index - i - 1].depth == item.depth - 1:
					parent = _items[index - i - 1].get_path_layer()
					break
			# 同じレベルで後ろにあるやつを数えてinsertの数を調べる
			for i in range(index + 1, _items.size()):
				if _items[i].depth == item.depth:
					insert += 1
				elif _items[i].depth > item.depth:
					pass
				else:
					break
			if top_of_path:
				insert += 1
			Main.layers.drag_move_path(insert, parent)

		for index in _items.size():
			var prev_item := _items[index - 1] if index != 0 else null
			var item := _items[index]
			if item.mouse_over_top:
				if item.dragging:
					break
				if item.is_path():
					insert_at.call(item, index, true)
					break
				else:
					if prev_item:
						if prev_item.is_path():
							insert_at.call(prev_item, index - 1, false)
							break
						else:
							break
					else:
						break
			elif item.mouse_over_bottom:
				if item.dragging:
					break
				if item.is_path():
					insert_at.call(item, index, false)
					break
				elif item.is_path_layer():
					if item.is_open():
						var path_layer := item.get_path_layer()
						if item.is_path_layer_empty():
							Main.layers.drag_move_path(0, path_layer)
							Main.commit_history()
						else:
							Main.layers.drag_move_path(path_layer.paths.size(), path_layer)
							Main.commit_history()
						break
					else:
						break
				else:
					break

	_dnd_cursor.visible = false
	Main.layers.drag_end()
	_set_dirty()


## レイヤーリストタブの上部のボタンを更新する。
func _update_layer_list_tab_buttons() -> void:
	if not Main.document_opened:
		_blend_mode_menu.text = tr("BLEND_MODE_NORMAL")
		_add_button.disabled = true
		_add_fill_button.disabled = true
		_add_group_button.disabled = true
		_locked_button.disabled = true
		_locked_panel.visible = false
		_clip_panel.visible = false
		_blend_mode_menu.disabled = true
		_alpha_slider.editable = false
		_alpha_spin_box.editable = false
		_delete_button.disabled = true
		_clip_button.disabled = true
		_open_close_button.disabled = true
		_boolean_menu.disabled = true
		_alpha_slider.set_value_no_signal(100)
		_alpha_spin_box.set_value_no_signal(100)
		return

	if Main.layers.last_selected_layer == null:
		_blend_mode_menu.text = tr("BLEND_MODE_NORMAL")
		_locked_button.disabled = true
		_locked_panel.visible = false
		_clip_panel.visible = false
		_blend_mode_menu.disabled = true
		_alpha_slider.editable = false
		_alpha_spin_box.editable = false
		_delete_button.disabled = true
		_clip_button.disabled = true
		_open_close_button.disabled = true
		_boolean_menu.disabled = true
		_alpha_slider.set_value_no_signal(100)
		_alpha_spin_box.set_value_no_signal(100)
		return

	_add_button.disabled = false
	_add_fill_button.disabled = false
	_add_group_button.disabled = false
	_locked_button.disabled = false

	var layer := Main.layers.last_selected_layer
	var path := Main.layers.last_selected_path

	# blend mode
	match layer.blend_mode:
		0:
			_blend_mode_menu.text = tr("BLEND_MODE_NORMAL")
		1:
			_blend_mode_menu.text = tr("BLEND_MODE_ADD")
		2:
			_blend_mode_menu.text = tr("BLEND_MODE_MULTIPLY")
		3:
			_blend_mode_menu.text = tr("BLEND_MODE_SCREEN")
		4:
			_blend_mode_menu.text = tr("BLEND_MODE_OVERLAY")

	# alpha
	_alpha_slider.set_value_no_signal(layer.alpha)
	_alpha_spin_box.set_value_no_signal(layer.alpha)

	# clip
	if layer.clipped:
		_clip_panel.visible = true
	else:
		_clip_panel.visible = false

	# lock
	if Main.layers.all_locked_item_in_selected():
		_unlocked.visible = false
		_locked.visible = true
	else:
		_unlocked.visible = true
		_locked.visible = false
	if Main.layers.any_locked_item_in_selected():
		_locked_panel.visible = true
		_blend_mode_menu.disabled = true
		_alpha_slider.editable = false
		_alpha_spin_box.editable = false
		_delete_button.disabled = true
		_clip_button.disabled = true
		_open_close_button.disabled = true
		_boolean_menu.disabled = true
	else:
		_locked_panel.visible = false
		_blend_mode_menu.disabled = false
		_alpha_slider.editable = true
		_alpha_spin_box.editable = true
		_delete_button.disabled = false
		_clip_button.disabled = false
		_open_close_button.disabled = false
		_boolean_menu.disabled = false


	if path:
		# pathのopen/close
		if path.closed:
			_open_path.visible = false
			_close_path.visible = true
		else:
			_open_path.visible = true
			_close_path.visible = false

		# pathのboolean
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


## PathPaintLayerの中の表示されるitemの数を計算する。
func _count_visible_items_in_path_layer(path_layer: PathPaintLayer) -> int:
	if not path_layer.collapsed:
		return path_layer.paths.size()
	else:
		return 0


## GroupPaintLayerの中の表示されるitemの数を計算する。
func _count_visible_items_in_group_layer(group_layer: GroupPaintLayer) -> int:
	var count := 0
	if not group_layer.collapsed:
		for layer in group_layer.child_layers:
			count += 1
			if layer is PathPaintLayer:
				var path_layer := layer as PathPaintLayer
				count += _count_visible_items_in_path_layer(path_layer)
			if layer is GroupPaintLayer:
				var group := layer as GroupPaintLayer
				count += _count_visible_items_in_group_layer(group)
	return count


## 表示されるレイヤーの数を計算する。
func _count_visible_items() -> int:
	var count := 0
	for layer in Main.layers.root:
		count += 1
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			count += _count_visible_items_in_path_layer(path_layer)
		if layer is GroupPaintLayer:
			var group_layer := layer as GroupPaintLayer
			count += _count_visible_items_in_group_layer(group_layer)
	return count


## PathPaintLayerのパスを_itemに追加する。
func _add_path_layer_item(path_layer: PathPaintLayer, depth: int, items_index: int) -> int:
	if not path_layer.collapsed:
		for index in path_layer.paths.size():
			var path := path_layer.paths[path_layer.paths.size() - index - 1]
			var item := _items[items_index]
			item.init_path(path, depth)
			items_index += 1
	return items_index


## PathPaintLayerのレイヤーを_itemに追加する。
func _add_group_layer_item(group_layer: GroupPaintLayer, depth: int, items_index: int) -> int:
	if not group_layer.collapsed:
		for index in group_layer.child_layers.size():
			var layer := group_layer.child_layers[group_layer.child_layers.size() - index - 1]
			var item := _items[items_index]
			item.init_layer(layer, depth)
			items_index += 1

			if layer is PathPaintLayer:
				var path_layer := layer as PathPaintLayer
				items_index = _add_path_layer_item(path_layer, depth + 1, items_index)

			if layer is GroupPaintLayer:
				var group := layer as GroupPaintLayer
				items_index = _add_group_layer_item(group, depth + 1, items_index)
	return items_index


## layer_listをdirtyにマークする。
func _set_dirty() -> void:
	_is_layer_list_dirty = true


## レイヤーリストを再構築し更新する。
func _update_layer_list() -> void:
	if not Main.document_opened:
		# rレイヤーリストを空にする
		while _items.size() > 0:
			_items[_items.size() - 1].queue_free()
			_items.remove_at(_items.size() - 1)
		# 上部のボタンを更新する
		_update_layer_list_tab_buttons()
		return

	var count := _count_visible_items()
	while _items.size() > count:
		_items[_items.size() - 1].queue_free()
		_items.remove_at(_items.size() - 1)
	while _items.size() < count:
		var item := LayerListItem.new_item()
		_items.append(item)
		_container.add_child(item)

	var items_index := 0

	# レイヤーリストを再構築する
	for index in Main.layers.root.size():
		var layer := Main.layers.root[Main.layers.root.size() - index - 1]
		var item := _items[items_index]
		item.init_layer(layer, 0)
		items_index += 1

		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			items_index = _add_path_layer_item(path_layer, 1, items_index)

		if layer is GroupPaintLayer:
			var group_layer := layer as GroupPaintLayer
			items_index = _add_group_layer_item(group_layer, 1, items_index)

	# 上部のボタンを更新する
	_update_layer_list_tab_buttons()


## 現在選択中のパスのBooleanを切り替える。
func _change_boolean(id: int) -> void:
	var boolean := Path.Boolean.Union
	match id:
		1:
			boolean = Path.Boolean.Diff
		2:
			boolean = Path.Boolean.Intersect
		3:
			boolean = Path.Boolean.Xor
	for path in Main.layers.selected_paths:
		path.change_boolean(boolean)
	Main.emit_update_layer_list_tab()

	Main.commit_history()


func _change_blend_mode(id: int) -> void:
	var blend_mode := PaintLayer.BlendMode.Normal
	match id:
		1:
			blend_mode = PaintLayer.BlendMode.Add
		2:
			blend_mode = PaintLayer.BlendMode.Multiply
		3:
			blend_mode = PaintLayer.BlendMode.Screen
		4:
			blend_mode = PaintLayer.BlendMode.Overlay
	Main.layers.set_blend_mode_of_selected_layer(blend_mode)

	Main.commit_history()


## アルファを調整中かどうか。
func is_manipulating_alpha() -> bool:
	return not _last_alpha_changed_commit


## レイヤー追加ボタンを押したときのコールバック。
func _on_add_button_button_up() -> void:
	Main.layers.add_path_layer()

	Main.commit_history()


## 塗り頭レイヤー追加ボタンを押したときのコールバック。
func _on_add_fill_button_button_up() -> void:
	Main.layers.add_fill_layer()

	Main.commit_history()


## グループレイヤー追加ボタンを押したときのコールバック。
func _on_add_group_button_button_up() -> void:
	Main.layers.add_group_layer()

	Main.commit_history()


## レイヤー削除ボタンを押したときのコールバック。
func _on_delete_button_button_up() -> void:
	Main.layers.delete_selected_layer_path()

	Main.commit_history()


## レイヤークリッピングボタンを押したときのコールバック。
func _on_clip_button_button_up() -> void:
	Main.layers.change_clipping_of_selected_layer()

	Main.commit_history()


## レイヤーロックボタンを押したときのコールバック。
func _on_lock_button_button_up() -> void:
	Main.layers.change_locked_of_selected_item()

	Main.commit_history()


## パスのopen/close変更ボタンを押したときのコールバック。
func _on_open_close_button_button_up() -> void:
	Main.layers.change_closed_of_selected_path()

	Main.commit_history()


## アルファ値のスライダーの値が変わったときのコールバック。
func _on_alpha_slider_value_changed(value: float) -> void:
	Main.layers.set_alpha_of_selected_layer(int(value))
	_last_alpha_changed_time = Time.get_ticks_msec()
	_last_alpha_changed_commit = false


## アルファ値のSpinBoxの値が変わったときのコールバック。
func _on_alpha_spin_box_value_changed(value: float) -> void:
	Main.layers.set_alpha_of_selected_layer(int(value))
	_last_alpha_changed_time = Time.get_ticks_msec()
	_last_alpha_changed_commit = false

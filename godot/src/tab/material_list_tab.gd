## マテリアルのリストのタブのクラス。
## マテリアルのリストの並べ替えのDnDの処理を含む。
class_name MaterialListTab
extends PanelContainer


@onready var _add_button: MenuButton = %AddButton
@onready var _delete_button: Button = %DeleteButton
@onready var _delete_popup: Popup = %DeleteButton/Popup
@onready var _container: VBoxContainer = %ListContainer
@onready var _dnd_cursor: ListDropCursor = %ListContainer/ListDropCursor

## マテリアルのリストのノード。
var _list: Array[MaterialListItem] = []

## リストアイテムのシーン。
const _list_item: PackedScene = preload("res://scenes/node/material_list_item.tscn")

## ドラッグ中のアイテム。
var _drag_item: MaterialListItem = null


func _ready() -> void:
	Main.on_change_material_parameters_changed.connect(_update_material_list)
	Main.on_update_material_list_tab.connect(_update_material_list)
	Main.on_document_open.connect(_update_material_list)
	Main.on_document_close.connect(_update_material_list)
	Main.on_document_reload.connect(_update_material_list)

	_add_button.get_popup().id_pressed.connect(_on_add_ppressed)


func _input(_event: InputEvent) -> void:
	# can dropではないときドロップ先カーソルを非表示にする
	_dnd_cursor.visible = false


func _process(_delta: float) -> void:
	if Main.document_opened:
		_add_button.disabled = false
		_delete_button.disabled = false
	else:
		_add_button.disabled = true
		_delete_button.disabled = true


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAG_END:
			_drag_end()


func _get_drag_data(_at_position: Vector2) -> Variant:
	# ドラッグ開始時にマウスオーバーしていたアイテムをドラッグする
	var item: MaterialListItem = null
	for index in _list.size():
		var node := _list[index]
		var selected: bool = Main.materials.selected_index == index
		if selected:
			set_drag_preview(node.duplicate() as MaterialListItem)
			item = node
			item.set_dragging(true)
			break
	_drag_item = item
	return item


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is MaterialListItem:
		_dnd_cursor.visible = true

		# ドラッグ先を示すカーソルのindexを計算する
		var cursor_index := _container.get_child_count() - 1
		for index in _list.size():
			var item := _list[index]
			if item.mouse_over_top:
				cursor_index = index
			elif item.mouse_over_bottom:
				cursor_index = index + 1

		# ドラッグ先を示すカーソルを挿入する
		for child in _container.get_children():
			_container.remove_child(child)
		for index in _list.size():
			var item := _list[index]
			if index == cursor_index:
				_container.add_child(_dnd_cursor)
			_container.add_child(item)
		if cursor_index == _list.size():
			_container.add_child(_dnd_cursor)

		return true

	_dnd_cursor.visible = false
	return false


## ドラッグが終了したときに呼び出す関数。
func _drag_end() -> void:
	# アイテムをドラッグ中だったら、マテリアルの並び替えを発火する
	if _drag_item is MaterialListItem:
		var node := _drag_item as MaterialListItem
		node.set_dragging(false)
		var hover_container := Rect2(Vector2.ZERO, _container.size).has_point(_container.get_local_mouse_position())
		var cursor_index := _list.size()
		for index in _list.size():
			var item := _list[index]
			if item.mouse_over_top:
				cursor_index = index
			elif item.mouse_over_bottom:
				cursor_index = index + 1
			item.set_dragging(false)
		if hover_container:
			Main.materials.reorder_selected_material(cursor_index)
		Main.commit_history()

	_drag_item = null
	_dnd_cursor.visible = false


## マテリアルリストに変更があったときに呼び出されるコールバック。
func _update_material_list() -> void:
	if not Main.document_opened:
		while _list.size() > 0:
			_list[_list.size() - 1].queue_free()
			_list.remove_at(_list.size() - 1)
		return

	# Mainのmaterialsの個数と表示用nodeの個数を合わせる
	while _list.size() > Main.materials.list.size():
		_list[_list.size() - 1].queue_free()
		_list.remove_at(_list.size() - 1)
	while _list.size() < Main.materials.list.size():
		var list_item := _list_item.instantiate() as MaterialListItem
		list_item.on_selected.connect((func(index: int) -> void:
			Main.materials.set_selected_index(index)
			Main.layers.clear_selected_items()
		).bind(_list.size()))
		_container.add_child(list_item)
		_list.append(list_item)

	# パラメータを合わせる
	for index in Main.materials.list.size():
		var item := Main.materials.list[index]
		if item.material is ColorPaintMaterial:
			var color_material := item.material as ColorPaintMaterial
			var list_item := _list[index]
			list_item.material_id = item.id
			list_item.set_color(color_material.color)
			list_item.set_material_name(item.name)
			list_item.set_selected(Main.materials.selected_index == index)
		elif item.material is LinearGradientPaintMaterial:
			var linear_gradient_material := item.material as LinearGradientPaintMaterial
			var list_item := _list[index]
			list_item.material_id = item.id
			list_item.set_linear_gradient(linear_gradient_material.gradient_texture)
			list_item.set_material_name(item.name)
			list_item.set_selected(Main.materials.selected_index == index)
		elif item.material is RadialGradientPaintMaterial:
			var radial_gradient_material := item.material as RadialGradientPaintMaterial
			var list_item := _list[index]
			list_item.material_id = item.id
			list_item.set_radial_gradient(radial_gradient_material.gradient_texture)
			list_item.set_material_name(item.name)
			list_item.set_selected(Main.materials.selected_index == index)


## 色の操作中かどうか。
func is_manipulate_color() -> bool:
	for item in _list:
		if item.is_manipulate_color():
			return true
	return false


## Addのポップアップがクリックされたときに呼び出されるコールバック。
func _on_add_ppressed(id: int) -> void:
	if id == 0:
		Main.materials.add_color_material()
		Main.commit_history()
	elif id == 1:
		Main.materials.add_linear_gradient_material()
		Main.commit_history()
	elif id == 2:
		Main.materials.add_radial_gradient_material()
		Main.commit_history()


## Deleteボタンがクリックされたときに呼び出されるコールバック。
func _on_delete_button_button_up() -> void:
	if Main.materials.selected_index != -1:
		_delete_popup.show()


## DeleteダイアログでOKを押したときに呼び出されるコールバック。
func _on_ok_button_button_up() -> void:
	Main.materials.delete_material()
	_delete_popup.hide()
	Main.commit_history()


## Deleteモーダルダイアログでキャンセルを押したときに呼び出されるコールバック。
func _on_cancel_button_button_up() -> void:
	_delete_popup.hide()

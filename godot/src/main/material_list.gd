## マテリアルのリストを保持/操作を提供するクラス。
class_name MaterialList
extends RefCounted


const uuid_util = preload('res://addons/uuid/uuid.gd')

## マテリアルのリストの要素。
class PaintMaterialListItem:
	var id: String
	var name: String = ""
	var material: PaintMaterial = null

	func _init() -> void:
		id = uuid_util.v4()


## マテリアルのリスト。
var list: Array[PaintMaterialListItem] = []
## 現在選択中のマテリアル。-1で未選択。
var selected_index: int = -1

## 新規レイヤー作成時の塗りのマテリアルid。
var new_path_layer_fill_material_id: String
## 新規レイヤー作成時の線のマテリアルid。
var new_path_layer_line_material_id: String
## 新規レイヤー作成時の塗りのマテリアルid。
var new_fill_layer_material_id: String

## 新しいマテリアルの名前のregex。
var _new_material_regex: RegEx


func _init() -> void:
	_new_material_regex = RegEx.new()
	_new_material_regex.compile("^マテリアル (\\d+)$")


##新規ドキュメント用に マテリアルを作成する。
func create_materials_for_new_documet() -> void:
	var fill_material := ColorPaintMaterial.new()
	var fill_item := PaintMaterialListItem.new()
	fill_item.material = fill_material
	fill_item.name = "Default Path Fill"
	list.append(fill_item)
	new_path_layer_fill_material_id = fill_item.id

	var line_material := ColorPaintMaterial.new()
	line_material.color = Color.BLACK
	var line_item := PaintMaterialListItem.new()
	line_item.material = line_material
	line_item.name = "Default Path Line"
	list.append(line_item)
	new_path_layer_line_material_id = line_item.id

	var fill_layer_material := ColorPaintMaterial.new()
	fill_layer_material.color = Color.WHITE
	var fill_layer_item := PaintMaterialListItem.new()
	fill_layer_item.material = fill_layer_material
	fill_layer_item.name = "Default File Layer"
	list.append(fill_layer_item)
	new_fill_layer_material_id = fill_layer_item.id

	Main.emit_update_material_list_tab()
	Main.emit_update_layer_list_tab()
	Main.emit_end_edit_gradient()


## ドキュメントを閉じる際にマテリアルを削除する。
func clear() -> void:
	list.clear()
	selected_index = -1
	new_path_layer_fill_material_id = ""
	new_path_layer_line_material_id = ""
	new_fill_layer_material_id = ""


## 新しいマテリアルの名前を取得する。
func _get_new_material_name() -> String:
	var nums: Array[int] = []
	for item in list:
		var result := _new_material_regex.search(item.name)
		if result:
			nums.append(int(result.get_string(1)))
	nums.sort()

	var num := -1
	for i in nums:
		if num + 1 == i:
			num += 1
		elif num == i:
			continue
		else:
			break
	num += 1

	return tr("MATERIAL") + " " + str(num)


## 塗りつぶしマテリアルを追加する。
func add_color_material() -> void:
	var material := ColorPaintMaterial.new()
	var item := PaintMaterialListItem.new()
	item.material = material
	item.name = _get_new_material_name()
	if selected_index == -1:
		list.insert(0, item)
	else:
		list.insert(selected_index, item)
	Main.emit_update_material_list_tab()
	Main.emit_update_layer_list_tab()
	Main.emit_end_edit_gradient()


## 線形グラデーションマテリアルを追加する。
func add_linear_gradient_material() -> void:
	var material := LinearGradientPaintMaterial.new()
	var item := PaintMaterialListItem.new()
	item.material = material
	item.name = _get_new_material_name()
	if selected_index == -1:
		list.insert(0, item)
	else:
		list.insert(selected_index, item)
	Main.emit_update_material_list_tab()
	Main.emit_update_layer_list_tab()
	Main.emit_end_edit_gradient()


## 放射グラデーションマテリアルを追加する。
func add_radial_gradient_material() -> void:
	var material := RadialGradientPaintMaterial.new()
	var item := PaintMaterialListItem.new()
	item.material = material
	item.name = _get_new_material_name()
	if selected_index == -1:
		list.insert(0, item)
	else:
		list.insert(selected_index, item)
	Main.emit_update_material_list_tab()
	Main.emit_update_layer_list_tab()
	Main.emit_end_edit_gradient()


## マテリアルの削除。
func delete_material() -> void:
	if list.size() > 1:
		# 削除するidが新規作成用idだったら新規作成用idをリストの先頭のアイテムにする。
		if list[selected_index].id == new_path_layer_fill_material_id:
			new_path_layer_fill_material_id = list[0].id
		if list[selected_index].id == new_path_layer_line_material_id:
			new_path_layer_line_material_id = list[0].id
		if list[selected_index].id == new_fill_layer_material_id:
			new_fill_layer_material_id = list[0].id

		list.remove_at(selected_index)
		if selected_index > 0:
			selected_index -= 1

		Main.emit_update_layer_list_tab()
		Main.emit_update_material_list_tab()
		Main.emit_end_edit_gradient()
		Main.compositor.composite(Main.layers.root, true)


## マテリアルのリネーム。
func rename_material(name: String) -> void:
	if not list[selected_index].name == name:
		list[selected_index].name = name
		Main.emit_update_layer_list_tab()


## マテリアルの取得。
func get_material(id: String) -> PaintMaterial:
	for item in list:
		if item.id == id:
			return item.material
	return null


## マテリアルの名前取得。
func get_material_name(id: String) -> String:
	for item in list:
		if item.id == id:
			return item.name
	return "=== Not Found ==="


## 選択マテリアルを変更する。
func set_selected_index(index: int) -> void:
	selected_index = index
	Main.emit_update_material_list_tab()
	Main.emit_end_edit_gradient()


## マテリアルの並べ替え。
func reorder_selected_material(index: int) -> void:
	var m := list[selected_index]
	list.remove_at(selected_index)
	if selected_index < index:
		index -= 1
	list.insert(index, m)
	Main.emit_update_material_list_tab()
	Main.emit_end_edit_gradient()

	Main.commit_history()


## マテリアルの選択を解除する。
func clear_selected_index() -> void:
	selected_index = -1
	Main.emit_update_material_list_tab()
	Main.emit_end_edit_gradient()


## コピーしてあるマテリアルをペーストする。
func paste_copied_material() -> void:
	var copied_material := Main.copy_manager.get_copied_material()
	if copied_material != null:
		if selected_index == -1:
			list.insert(0, copied_material)
		else:
			list.insert(selected_index, copied_material)

		Main.emit_update_material_list_tab()
		Main.emit_end_edit_gradient()

		Main.commit_history()


## ドキュメントサイズの変更を適用する。
func change_document_size(new_document_size: Vector2, anchor: PaintLayer.ScaleAnchor) -> void:
	for item in list:
		if item.material is LinearGradientPaintMaterial:
			var material := item.material as LinearGradientPaintMaterial
			material.change_document_size(new_document_size, anchor)
		elif item.material is RadialGradientPaintMaterial:
			var material := item.material as RadialGradientPaintMaterial
			material.change_document_size(new_document_size, anchor)
	Main.emit_update_layer_list_tab()

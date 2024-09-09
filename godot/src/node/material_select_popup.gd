## マテリアル選択ポップアップのクラス。
class_name MaterialSelectPopup
extends Popup


@onready var _container: VBoxContainer = %ListContainer
@onready var _search: LineEdit = %LineEdit

## マテリアル選択時のシグナル。
## 引数はマテリアルのidの文字列。
signal on_material_selected(material_id: String)

## リストアイテムのシーン。
const _list_item: PackedScene = preload("res://scenes/node/material_select_popup_item.tscn")

## 検索文字列。
var _search_text: String = ""


## マテリアルリストポップアップの中身を更新する。
func _update_content() -> void:
	for child in _container.get_children():
		child.queue_free()

	for index in Main.materials.list.size():
		var item := Main.materials.list[index]

		if not item.name.substr(0, _search_text.length()) == _search_text:
			continue

		var node := _list_item.instantiate() as MaterialSelectPopupItem
		_container.add_child(node)

		node.set_material_name(item.name)

		if item.material is ColorPaintMaterial:
			var color_mat := item.material as ColorPaintMaterial
			node.set_color(color_mat.color)
		elif item.material is LinearGradientPaintMaterial:
			var linear_gradient_mat := item.material as LinearGradientPaintMaterial
			node.set_linear_gradient(linear_gradient_mat.gradient_texture)
		elif item.material is RadialGradientPaintMaterial:
			var radial_gradient_mat := item.material as RadialGradientPaintMaterial
			node.set_radial_gradient(radial_gradient_mat.gradient_texture)

		node.on_clicked.connect(_on_clicked_item.bind(index))


## 表示非表示が切り替わったときに呼び出されるコールバック。
func _on_visibility_changed() -> void:
	if visible:
		_search_text = ""
		_search.text = ""
		_update_content()


## アイテムがクリックされたときに呼び出されるコールバック。
func _on_clicked_item(index: int) -> void:
	var material_id := Main.materials.list[index].id
	on_material_selected.emit(material_id)
	hide()


## 検索も列が変更されたときに呼び出されるコールバック。
func _on_line_edit_text_changed(new_text: String) -> void:
	_search_text = new_text
	_update_content()

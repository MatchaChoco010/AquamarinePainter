## レイヤーグループのレイヤーを表現するクラス。
class_name GroupPaintLayer
extends PaintLayer


## 折りたたまれているか。
var collapsed: bool = false

## このグループレイヤーの子要素のレイヤー
var child_layers: Array[PaintLayer] = []


## 初期化する。
func _construct() -> void:
	(self as PaintLayer).need_composite = true


## ルートから親の表示状態を更新する。
func update_parent_visible(new_parent_visible: bool) -> void:
	parent_visible = new_parent_visible

	var child_visible := visible and parent_visible
	for child_layer in child_layers:
		if child_layer is PathPaintLayer:
			var path_layer := child_layer as PathPaintLayer
			path_layer.update_parent_visible(child_visible)
		elif child_layer is FillPaintLayer:
			var fill_layer := child_layer as FillPaintLayer
			fill_layer.update_parent_visible(child_visible)
		elif child_layer is GroupPaintLayer:
			var group_layer := child_layer as GroupPaintLayer
			group_layer.update_parent_visible(child_visible)


## ルートから親のロック状態を更新する。
func update_parent_locked(new_parent_locked: bool) -> void:
	parent_locked = new_parent_locked

	var child_locked := locked or parent_locked
	for child_layer in child_layers:
		if child_layer is PathPaintLayer:
			var path_layer := child_layer as PathPaintLayer
			path_layer.update_parent_locked(child_locked)
		elif child_layer is FillPaintLayer:
			var fill_layer := child_layer as FillPaintLayer
			fill_layer.update_parent_locked(child_locked)
		elif child_layer is GroupPaintLayer:
			var group_layer := child_layer as GroupPaintLayer
			group_layer.update_parent_locked(child_locked)


## ドキュメントサイズの変更を適用する。
func change_document_size(new_document_size: Vector2, _anchor: PaintLayer.ScaleAnchor) -> void:
	for layer in child_layers:
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			path_layer.change_document_size(new_document_size, _anchor)
		elif layer is GroupPaintLayer:
			var group_layer := layer as GroupPaintLayer
			group_layer.change_document_size(new_document_size, _anchor)


## レイヤーをクリアする。
func clear_layer() -> void:
	clipped = false
	visible = true
	parent_visible = true
	locked = false
	parent_locked = false
	blend_mode = BlendMode.Normal
	alpha = 100
	layer_name = ""

	collapsed = false
	child_layers = []


## レイヤーを作成する。
static func new_layer() -> GroupPaintLayer:
	var group_layer := GroupPaintLayer.new()
	group_layer._construct()
	group_layer.layer_name = Main.layers.get_new_layer_name()
	return group_layer

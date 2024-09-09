## 塗りつぶしレイヤーを表現するクラス。
class_name FillPaintLayer
extends PaintLayer


## マテリアルmissing時の表示用マテリアル。
@export var missing_material: ShaderMaterial

## fillの色。
var fill_material_id: String = ""


## 初期化する。
func _construct() -> void:
	Main.on_change_material_parameters_changed.connect(func() -> void: (self as PaintLayer).need_composite = true)
	(self as PaintLayer).need_composite = true


## ルートから親の表示状態を更新する。
func update_parent_visible(new_parent_visible: bool) -> void:
	parent_visible = new_parent_visible


## ルートから親のロック状態を更新する。
func update_parent_locked(new_parent_locked: bool) -> void:
	parent_locked = new_parent_locked


## マテリアルがmissingかどうか。
func is_material_missing() -> bool:
	var fill_material := Main.materials.get_material(fill_material_id)
	if fill_material == null:
		return true
	return false


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

	fill_material_id = ""


## レイヤーを作成する。
static func new_layer() -> FillPaintLayer:
	var fill_layer := FillPaintLayer.new()
	fill_layer._construct()
	fill_layer.layer_name = Main.layers.get_new_layer_name()
	fill_layer.fill_material_id = Main.materials.new_fill_layer_material_id
	return fill_layer

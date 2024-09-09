## パスをまとめたレイヤーを表現するクラス。
class_name PathPaintLayer
extends PaintLayer


## マテリアルmissing時の表示用マテリアル。
@export var missing_material: ShaderMaterial
## boolean描画用のマテリアル。
@export var boolean_draw_material: ShaderMaterial

## fillするかどうか。
var filled: bool = true:
	get: return filled
	set(value):
		filled = value
		set_need_composite()
## fillの色。
var fill_material_id: String = "":
	get: return fill_material_id
	set(value):
		fill_material_id = value
		set_need_composite()
## outlineのオンオフ。
var outlined: bool = true:
	get: return outlined
	set(value):
		outlined = value
		set_need_composite()
## outlineの色。
var outline_material_id: String = "":
	get: return outline_material_id
	set(value):
		outline_material_id = value
		set_need_composite()
## outlineの幅。
var outline_width: float = 2.0:
	get: return outline_width
	set(value):
		outline_width = value
		for path in paths:
			path.set_line_width(outline_width)
			path.update_line_polygon()
		set_need_composite()

## 折りたたまれているか。
var collapsed: bool = false

## レイヤーの保持するパスの配列。
var paths: Array[Path] = []

## 子要素のサムネをアップデートするかどうか。
var _need_update_children_thumbnaisl: bool = false


func _process(_delta: float) -> void:
	if _need_update_children_thumbnaisl:
		update_child_paths_thumbnail()


## 初期化する。
func _construct() -> void:
	Main.on_change_material_parameters_changed.connect(func() -> void: set_need_composite())
	set_need_composite()


## ルートから親の表示状態を更新する。
func update_parent_visible(new_parent_visible: bool) -> void:
	parent_visible = new_parent_visible

	var child_visible := visible and parent_visible
	for path in paths:
		path.parent_visible = child_visible


## ルートから親のロック状態を更新する。
func update_parent_locked(new_parent_locked: bool) -> void:
	parent_locked = new_parent_locked

	var child_locked := locked or parent_locked
	for path in paths:
		path.parent_locked = child_locked


## レイヤーの形状を計算する。
func set_need_composite() -> void:
	(self as PaintLayer).need_composite = true
	_need_update_children_thumbnaisl = true


## マテリアルがmissingかどうか。
func is_material_missing() -> bool:
	var fill_material := Main.materials.get_material(fill_material_id)
	if fill_material == null:
		return true
	var line_material := Main.materials.get_material(outline_material_id)
	if line_material == null:
		return true
	return false


## このレイヤーにパスを追加する。
func add_path(use_new_path_name: bool = true) -> Path:
	var path := Main.path_pool.get_path(use_new_path_name)
	path.set_line_width(outline_width)
	path.parent_path_layer = weakref(self)
	paths.append(path)
	set_need_composite()
	return path


## このレイヤーにパスを追加する。
## その際に特定のパスの後ろに追加する。
## after_pathがこのパスレイヤーに属するパスではない場合は末尾にパスを追加する。
func add_insert_path_after_path(after_path: Path) -> Path:
	var path := Main.path_pool.get_path()
	path.set_line_width(outline_width)
	path.parent_path_layer = weakref(self)
	var insert_index := 0
	for p in paths:
		insert_index += 1
		if p == after_path:
			break ;
	paths.insert(insert_index, path)
	set_need_composite()
	return path


## パスをこのレイヤーから除去する。
## このレイヤーに含まれていないPathを渡したときは何もしない。
func remove_path(path: Path) -> void:
	for index in paths.size():
		var p := paths[index]
		if p == path:
			paths.remove_at(index)
			(self as PaintLayer).need_composite = true
			_need_update_children_thumbnaisl = true
			break


## パスがこのレイヤーに含まれているか確認する。
func contain_path(path: Path) -> bool:
	for index in paths.size():
		var p := paths[index]
		if p == path:
			return true
	return false


## 子要素のパスのサムネイルを更新する。
func update_child_paths_thumbnail() -> void:
	# 子要素のパスのサムネのsub viewportを更新する
	if filled:
		var fill_material := Main.materials.get_material(fill_material_id)
		for path in paths:
			path.set_is_line(false)
			path.set_material(fill_material)
			path.update_thumbnail()
	elif outlined:
		var line_material := Main.materials.get_material(outline_material_id)
		for path in paths:
			path.set_is_line(true)
			path.set_material(line_material)
			path.update_thumbnail()
	else:
		var fill_material := Main.materials.get_material(fill_material_id)
		for path in paths:
			path.set_is_line(false)
			path.set_material(fill_material)
			path.update_thumbnail()
	_need_update_children_thumbnaisl = false


## 線幅を更新する。
func update_outline_polygon() -> void:
	for path in paths:
		path.update_line_polygon()


## ドキュメントサイズの変更を適用する。
func change_document_size(new_document_size: Vector2, anchor: PaintLayer.ScaleAnchor) -> void:
	for path in paths:
		path.change_document_size(new_document_size, anchor)


## レイヤーをクリアする。
func clear_layer() -> void:
	for path in paths:
		Main.path_pool.free_path(path)

	clipped = false
	visible = true
	parent_visible = true
	locked = false
	parent_locked = false
	blend_mode = BlendMode.Normal
	alpha = 100
	layer_name = ""

	filled = true
	fill_material_id = ""
	outlined = true
	outline_material_id = ""
	outline_width = 2.0
	collapsed = false
	paths = []

	set_need_composite()


## レイヤーを作成する。
static func new_layer() -> PathPaintLayer:
	var path_layer := PathPaintLayer.new()
	path_layer._construct()
	path_layer.fill_material_id = Main.materials.new_path_layer_fill_material_id
	path_layer.outline_material_id = Main.materials.new_path_layer_line_material_id

	path_layer.layer_name = Main.layers.get_new_layer_name()

	var scene_tree := Engine.get_main_loop() as SceneTree
	var root := scene_tree.root
	var sub_viewport_root := root.get_node("/root/App/LayerSubViewports")
	sub_viewport_root.add_child(path_layer)
	return path_layer

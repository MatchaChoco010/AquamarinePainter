class_name PaintLayerPool
extends RefCounted


const uuid_util = preload('res://addons/uuid/uuid.gd')

## PathPaintLayerのプール
var _path_layer_pool: Array[PathPaintLayer] = []
## FillPaintLayerのプール
var _fill_layer_pool: Array[FillPaintLayer] = []
## GroupPaintLayerのプール
var _group_layer_pool: Array[GroupPaintLayer] = []


## PathPaintLayerを取得する。
func get_path_layer(new_layer_name: bool = true) -> PathPaintLayer:
	if _path_layer_pool.size() > 1:
		var path_layer: PathPaintLayer = _path_layer_pool.pop_back()
		path_layer.fill_material_id = Main.materials.new_path_layer_fill_material_id
		path_layer.outline_material_id = Main.materials.new_path_layer_line_material_id
		if new_layer_name:
			path_layer.layer_name = Main.layers.get_new_layer_name()
		path_layer.id = uuid_util.v4()
		return path_layer
	return PathPaintLayer.new_layer()


## FillPaintLayerを取得する。
func get_fill_layer(new_layer_name: bool = true) -> FillPaintLayer:
	if _fill_layer_pool.size() > 1:
		var fill_layer: FillPaintLayer = _fill_layer_pool.pop_back()
		fill_layer.fill_material_id = Main.materials.new_fill_layer_material_id
		if new_layer_name:
			fill_layer.layer_name = Main.layers.get_new_layer_name()
		fill_layer.id = uuid_util.v4()
		return fill_layer
	return FillPaintLayer.new_layer()


## GroupPaintLayerを取得する。
func get_group_layer(new_layer_name: bool = true) -> GroupPaintLayer:
	if _group_layer_pool.size() > 1:
		var group_layer: GroupPaintLayer = _group_layer_pool.pop_back()
		if new_layer_name:
			group_layer.layer_name = Main.layers.get_new_layer_name()
		group_layer.id = uuid_util.v4()
		return group_layer
	return GroupPaintLayer.new_layer()


## レイヤーをプールに返却する。
func free_layer(layer: PaintLayer) -> void:
	if layer is PathPaintLayer:
		var path_layer := layer as PathPaintLayer
		path_layer.clear_layer()
		_path_layer_pool.push_back(path_layer)
	elif layer is FillPaintLayer:
		var fill_layer := layer as FillPaintLayer
		fill_layer.clear_layer()
		_fill_layer_pool.push_back(fill_layer)
	elif layer is GroupPaintLayer:
		var group_layer := layer as GroupPaintLayer
		for l in group_layer.child_layers:
			var already_free := false
			if l is PathPaintLayer:
				already_free = already_free or l in _path_layer_pool
			if l is FillPaintLayer:
				already_free = already_free or l in _fill_layer_pool
			if l is GroupPaintLayer:
				already_free = already_free or l in _group_layer_pool
			if not already_free:
				free_layer(l)
		group_layer.clear_layer()
		_group_layer_pool.push_back(group_layer)


## プールをクリアする。
func clear() -> void:
	_path_layer_pool.clear()
	_fill_layer_pool.clear()
	_group_layer_pool.clear()

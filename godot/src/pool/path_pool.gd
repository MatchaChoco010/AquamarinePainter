class_name PathPool
extends RefCounted


const uuid_util = preload('res://addons/uuid/uuid.gd')

## Pathのプール
var _path_pool: Array[Path] = []


## PathPaintLayerを取得する。
func get_path(new_path_name: bool = true) -> Path:
	if _path_pool.size() > 1:
		var path: Path = _path_pool.pop_back()
		if new_path_name:
			path.path_name = Main.layers.get_new_path_name()
		path.id = uuid_util.v4()
		return path
	return Path.new_path()


## Pathをプールに返却する。
func free_path(path: Path) -> void:
	path.clear_path()
	_path_pool.push_back(path)


## プールをクリアする。
func clear() -> void:
	_path_pool.clear()

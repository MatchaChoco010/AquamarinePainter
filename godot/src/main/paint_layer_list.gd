## レイヤーのリストを保持/操作を提供するクラス。
class_name PaintLayerList
extends RefCounted


## documentのレイヤーのルート。
var root: Array[PaintLayer] = []

## 現在選択されているレイヤーの配列。
var selected_layers: Array[PaintLayer] = []
## 現在選択されているパスの配列。
var selected_paths: Array[Path] = []

## 最後に選択したPaintLayerの参照。
## 新しいレイヤーはこのレイヤーの後ろに追加される。
## 選択中のレイヤーが削除された場合などにnullになる。
var last_selected_layer: PaintLayer = null
## 最後に選択したPathの参照。
## 選択中のパスが削除された場合などにnullになる。
var last_selected_path: Path = null
## 最後に選択したPaintLayerもしくはPathの参照。
var last_selected_item: Variant = null

## 現在描画先になっているPathPaintLayerの参照。
## 新しいパスはこのレイヤーに追加される。
## PathPaintLayerが存在しない場合などにnullになる。
var drawing_path_layer: PathPaintLayer = null

## ドラッグ中のレイヤーのルートの配列。
## ドラッグ中以外は空の配列となる。
var dragging_root_layers: Array[PaintLayer] = []
## ドラッグ中のレイヤーの配列。
## ドラッグ中以外は空の配列となる。
var dragging_layers: Array[PaintLayer] = []
## ドラッグ中のパスの配列。
## ドラッグ中以外は空の配列となる。
var dragging_paths: Array[Path] = []


## 新しくドキュメントを作る。
func new_document(new_document_size: Vector2i) -> void:
	Main.document_size = new_document_size
	root.append(Main.layer_pool.get_fill_layer())
	root.append(Main.layer_pool.get_path_layer())
	selected_layers = []
	selected_paths = []

	var path_layer := root[1] as PathPaintLayer
	last_selected_layer = path_layer as PaintLayer
	last_selected_item = path_layer
	drawing_path_layer = path_layer

	Main.compositor.update()
	Main.emit_selected_paths_changed()
	Main.emit_update_layer_list_tab()


## ドキュメントを閉じる。
func clear() -> void:
	for layer in root:
		Main.layer_pool.free_layer(layer)
	root.clear()
	selected_layers.clear()
	selected_paths.clear()
	last_selected_layer = null
	last_selected_path = null
	last_selected_item = null
	drawing_path_layer = null
	dragging_root_layers.clear()
	dragging_layers.clear()
	dragging_paths.clear()


## 新しいレイヤーの名前を取得する。
func get_new_layer_name() -> String:
	var new_layer_regex := RegEx.new()
	new_layer_regex.compile("^" + tr("LAYER") + " (\\d+)$")
	var nums: Array[int] = []
	for layer in get_flatten_layers():
		var result := new_layer_regex.search(layer.layer_name)
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

	return tr("LAYER") + " " + str(num)


## 新しいパスの名前を取得する。
func get_new_path_name() -> String:
	var new_path_regex := RegEx.new()
	new_path_regex.compile("^" + tr("PATH") + " (\\d+)$")
	var nums: Array[int] = []
	for layer in get_flatten_layers():
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			for path in path_layer.paths:
				var result := new_path_regex.search(path.path_name)
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

	return tr("PATH") + " " + str(num)


## 現在選択中のPaintLayerもしくは現在選択中のパスを含むPathPaintLayerのリストを取得する。
func _get_selected_path_layers() -> Array[PaintLayer]:
	var ret: Array[PaintLayer] = []

	for selected_layer in selected_layers:
		ret.append(selected_layer)

	for path in selected_paths:
		@warning_ignore("unsafe_cast")
		var parent := path.parent_path_layer.get_ref() as PathPaintLayer
		if not parent in ret:
			ret.append(parent)

	return ret


## グループレイヤーの中の選択中のレイヤーの後ろにレイヤーを挿入する。
func _insert_layer_to_group(group: GroupPaintLayer, layer: PaintLayer) -> bool:
	for index in group.child_layers.size():
		var l := group.child_layers[index]
		if l == last_selected_layer:
			group.child_layers.insert(index + 1, layer)
			return true
		if l is GroupPaintLayer:
			var gl := l as GroupPaintLayer
			if _insert_layer_to_group(gl, layer):
				return true
	return false


## 新しいパスレイヤーを最後に選択したレイヤーの後ろに挿入する。
func add_path_layer() -> PathPaintLayer:
	var layer := Main.layer_pool.get_path_layer()

	var inserted := false

	# last_selected_layerがGroupPaintLayerで折りたたまれていなかったらその末尾に追加する。
	if last_selected_layer is GroupPaintLayer:
		var gl := last_selected_layer as GroupPaintLayer
		if not gl.collapsed:
			gl.child_layers.append(layer)
			inserted = true

	if not inserted:
		# rootからたどってlast_selected_layerを見つけたら直後に追加する
		for index in root.size():
			var l := root[index]
			if l == last_selected_layer:
				root.insert(index + 1, layer)
				inserted = true
				break
			if l is GroupPaintLayer:
				var gl := l as GroupPaintLayer
				if _insert_layer_to_group(gl, layer):
					inserted = true
					break

	# last_selected_layerを見つけられなかった場合、先頭に追加する
	if not inserted:
		root.append(layer)

	update_parent_visible()
	set_selected_layer(layer)

	Main.compositor.update()

	return layer


## 新しい塗りつぶしレイヤーを最後に選択したレイヤーの後ろに挿入する。
func add_fill_layer() -> FillPaintLayer:
	var layer := Main.layer_pool.get_fill_layer()

	var inserted := false

	# last_selected_layerがGroupPaintLayerで折りたたまれていなかったらその末尾に追加する。
	if last_selected_layer is GroupPaintLayer:
		var gl := last_selected_layer as GroupPaintLayer
		if not gl.collapsed:
			gl.child_layers.append(layer)
			inserted = true

	# rootからたどってlast_selected_layerを見つけたら直後に追加する
	if not inserted:
		for index in root.size():
			var l := root[index]
			if l == last_selected_layer:
				root.insert(index + 1, layer)
				inserted = true
				break
			if l is GroupPaintLayer:
				var gl := l as GroupPaintLayer
				if _insert_layer_to_group(gl, layer):
					inserted = true
					break

	# last_selected_layerを見つけられなかった場合、先頭に追加する
	if not inserted:
		root.append(layer)

	update_parent_visible()
	set_selected_layer(layer)

	Main.compositor.update()

	return layer


## 新しいグループレイヤーを最後に選択したレイヤーの後ろに挿入する。
func add_group_layer() -> GroupPaintLayer:
	var layer := Main.layer_pool.get_group_layer()

	var inserted := false

	# last_selected_layerがGroupPaintLayerで折りたたまれていなかったらその末尾に追加する。
	if last_selected_layer is GroupPaintLayer:
		var gl := last_selected_layer as GroupPaintLayer
		if not gl.collapsed:
			gl.child_layers.append(layer)
			inserted = true

	# rootからたどってlast_selected_layerを見つけたら直後に追加する
	if not inserted:
		for index in root.size():
			var l := root[index]
			if l == last_selected_layer:
				root.insert(index + 1, layer)
				inserted = true
				break
			if l is GroupPaintLayer:
				var gl := l as GroupPaintLayer
				if _insert_layer_to_group(gl, layer):
					inserted = true
					break

	# last_selected_layerを見つけられなかった場合、先頭に追加する
	if not inserted:
		root.append(layer)

	update_parent_visible()
	set_selected_layer(layer)

	Main.compositor.update()

	return layer


## グループレイヤー内の選択中のレイヤー/パスを削除する。
func _delete_selected_layer_path_in_group(group: GroupPaintLayer) -> void:
	var layer_index: int = 0
	while layer_index < group.child_layers.size():
		var layer := group.child_layers[layer_index]
		# 選択中のパスがPathPaintLayerに含まれていたらそのPathを削除する
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			var path_deleted := false
			for path in selected_paths:
				var index := 0
				while index < path_layer.paths.size():
					if path_layer.paths[index] == path:
						path_layer.paths.remove_at(index)
						path_deleted = true
					else:
						index += 1
			if path_deleted:
				path_layer.set_need_composite()

		# グループレイヤーだったら再帰的に中身を削除する
		if layer is GroupPaintLayer:
			var group_layer := layer as GroupPaintLayer
			_delete_selected_layer_path_in_group(group_layer)

		# レイヤーが選択中レイヤーに含まれていたらレイヤーを削除する
		var layer_deleted := false
		for index in selected_layers.size():
			var l := selected_layers[index]
			if l == layer:
				selected_layers.remove_at(index)
				Main.layer_pool.free_layer(layer)

				for i in group.child_layers.size():
					if layer == group.child_layers[i]:
						group.child_layers.remove_at(i)
						layer_deleted = true
						break
				break

		if layer_deleted and layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			if path_layer == drawing_path_layer:
				drawing_path_layer = null

		if layer_deleted:
			group.need_composite = true
		else:
			layer_index += 1


## 選択中のレイヤー/パスを削除する。
func delete_selected_layer_path() -> void:
	# selected_layersをrootからたどって削除する
	var layer_index: int = 0
	while layer_index < root.size():
		var layer := root[layer_index]

		# 選択中のパスがPathPaintLayerに含まれていたらそのPathを削除する
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			var path_deleted := false
			for path in selected_paths:
				var i := 0
				while i < path_layer.paths.size():
					if path_layer.paths[i] == path:
						path_layer.paths.remove_at(i)
						path_deleted = true
					else:
						i += 1
			if path_deleted:
				path_layer.set_need_composite()

		# グループレイヤーだったら再帰的に中身を削除する
		if layer is GroupPaintLayer:
			var group_layer := layer as GroupPaintLayer
			_delete_selected_layer_path_in_group(group_layer)

		# レイヤーが選択中レイヤーに含まれていたらレイヤーを削除する
		var layer_deleted := false
		for index in selected_layers.size():
			var l := selected_layers[index]
			if l == layer:
				selected_layers.remove_at(index)
				Main.layer_pool.free_layer(layer)

				for i in root.size():
					if layer == root[i]:
						root.remove_at(i)
						layer_deleted = true
						break
				break

		if layer_deleted and layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			if path_layer == drawing_path_layer:
				drawing_path_layer = null

		if layer_deleted:
			Main.compositor.need_composite = true
		else:
			layer_index += 1

	Main.compositor.update()

	# last_selected_layerやdrawing_path_layerをnullにする
	last_selected_layer = null
	last_selected_path = null
	last_selected_item = null
	# selected_layers/selected_pathsをクリアする
	selected_layers.clear()
	selected_paths.clear()
	# シグナルを発火する
	Main.emit_selected_paths_changed()
	Main.emit_update_layer_list_tab()


## 子孫要素の選択状況を変える。
func _select_change_children(layer: PaintLayer, select: bool) -> void:
	if layer is PathPaintLayer:
		var path_layer := layer as PathPaintLayer
		for path in path_layer.paths:
			if select:
				if not path in selected_paths:
					selected_paths.append(path)
			else:
				var index := 0
				while index < selected_paths.size():
					var selected_path := selected_paths[index]
					if selected_path == path:
						selected_paths.remove_at(index)

	if layer is GroupPaintLayer:
		var group_layer := layer as GroupPaintLayer
		for child_layer in group_layer.child_layers:
			if select:
				if not child_layer in selected_layers:
					selected_layers.append(child_layer)
			else:
				var index := 0
				while index < selected_layers.size():
					var selected_layer := selected_layers[index]
					if selected_layer == layer:
						selected_layers.remove_at(index)

			_select_change_children(child_layer, select)


## 折りたたみなども見つつ選択状況を変更する。
func _set_selection_of_layer(layer: PaintLayer, select: bool) -> void:
	if select:
		if not layer in selected_layers:
			selected_layers.append(layer)
	else:
		var index := 0
		while index < selected_layers.size():
			var selected_layer := selected_layers[index]
			if selected_layer == layer:
				selected_layers.remove_at(index)

	if layer is PathPaintLayer:
		var path_layer := layer as PathPaintLayer
		if path_layer.collapsed:
			_select_change_children(layer, select)
	if layer is GroupPaintLayer:
		var group_layer := layer as GroupPaintLayer
		if group_layer.collapsed:
			_select_change_children(layer, select)


## 選択中のレイヤーを変更する。
## そのレイヤーがPathPaintLayerの場合、drawing_path_layerも更新する。
func set_selected_layer(layer: PaintLayer) -> void:
	selected_layers.clear()
	selected_paths.clear()
	_set_selection_of_layer(layer, true)
	last_selected_layer = layer
	last_selected_item = layer
	if layer is PathPaintLayer:
		drawing_path_layer = layer as PathPaintLayer

	Main.materials.clear_selected_index()
	Main.emit_selected_paths_changed()
	Main.emit_update_layer_list_tab()


## レイヤーの選択状態を更新する。
## そのレイヤーがPathPaintLayerの場合、drawing_path_layerも更新する。
func add_or_remove_selected_layer(layer: PaintLayer) -> void:
	if layer in selected_layers:
		_set_selection_of_layer(layer, false)
		Main.emit_selected_paths_changed()
		Main.emit_update_layer_list_tab()
	else:
		_set_selection_of_layer(layer, true)
		last_selected_layer = layer
		last_selected_item = layer
		if layer is PathPaintLayer:
			drawing_path_layer = layer as PathPaintLayer

		Main.materials.clear_selected_index()
		Main.emit_selected_paths_changed()
		Main.emit_update_layer_list_tab()


## last_selected_itmeからfinish_layerまでの範囲を選択する。
## 順に辿っていってlast_selected_itemを見つけたらflagをtrueに、finish_layerにたどり着いたらflagをfalseにする。
func _add_selected_items_layer_range_in_group(group_layer: GroupPaintLayer, finish_layer: PaintLayer, flag: bool) -> bool:
	for index in group_layer.child_layers.size():
		var layer := group_layer.child_layers[group_layer.child_layers.size() - index - 1]
		var prev_flag := flag
		if layer == last_selected_item:
			flag = not flag
		if layer == finish_layer:
			flag = not flag
		if prev_flag or flag:
			_set_selection_of_layer(layer, true)
		if layer is PathPaintLayer:
			var pl := layer as PathPaintLayer
			for i in pl.paths.size():
				var path := pl.paths[pl.paths.size() - i - 1]
				prev_flag = flag
				if path == last_selected_item:
					flag = not flag
				if prev_flag or flag:
					if not path in selected_paths:
						selected_paths.append(path)
		if layer is GroupPaintLayer:
			var gl := layer as GroupPaintLayer
			flag = _add_selected_items_layer_range_in_group(gl, finish_layer, flag)
	return flag


## last_selected_itmeからfinish_layerまでの範囲を選択する。
## 順に辿っていってlast_selected_itemを見つけたらflagをtrueに、finish_layerにたどり着いたらflagをfalseにする。
func _add_selected_items_layer_range(finish_layer: PaintLayer) -> void:
	var flag := false
	for index in root.size():
		var layer := root[root.size() - index - 1]
		var prev_flag := flag
		if layer == last_selected_item:
			flag = not flag
		if layer == finish_layer:
			flag = not flag
		if prev_flag or flag:
			_set_selection_of_layer(layer, true)
		if layer is PathPaintLayer:
			var pl := layer as PathPaintLayer
			for i in pl.paths.size():
				var path := pl.paths[pl.paths.size() - i - 1]
				prev_flag = flag
				if path == last_selected_item:
					flag = not flag
				if prev_flag or flag:
					if not path in selected_paths:
						selected_paths.append(path)
		if layer is GroupPaintLayer:
			var gl := layer as GroupPaintLayer
			flag = _add_selected_items_layer_range_in_group(gl, finish_layer, flag)


## 最後に選択したアイテムから引数のlayerまでの範囲を選択する。
## 必要に応じてdrawing_path_layerも更新する。
func set_selected_layer_range(layer: PaintLayer) -> void:
	if last_selected_item == null:
		set_selected_layer(layer)
		return
	if last_selected_item == layer:
		return
	selected_layers.clear()
	selected_paths.clear()
	_add_selected_items_layer_range(layer)
	last_selected_item = layer
	last_selected_layer = layer
	if last_selected_layer is PathPaintLayer:
		drawing_path_layer = last_selected_layer as PathPaintLayer

	Main.materials.clear_selected_index()
	Main.emit_selected_paths_changed()
	Main.emit_update_layer_list_tab()


## 最後に選択したアイテムから引数のlayerまでの範囲を追加で選択する。
## 必要に応じてdrawing_path_layerも更新する。
func add_selected_layer_range(layer: PaintLayer) -> void:
	if last_selected_item == null:
		set_selected_layer(layer)
		return
	if last_selected_item == layer:
		return
	_add_selected_items_layer_range(layer)
	last_selected_item = layer
	last_selected_layer = layer
	if last_selected_layer is PathPaintLayer:
		drawing_path_layer = last_selected_layer as PathPaintLayer

	Main.materials.clear_selected_index()
	Main.emit_selected_paths_changed()
	Main.emit_update_layer_list_tab()


## 選択中のパスを変更する。
## その親のレイヤーをdrawing_path_layerとlast_selected_layerに変更する。
func set_selected_path(path: Path) -> void:
	selected_layers.clear()
	selected_paths.clear()
	selected_paths.append(path)
	last_selected_path = path
	last_selected_item = path

	@warning_ignore("unsafe_cast")
	var parent := path.parent_path_layer.get_ref() as PathPaintLayer
	if parent:
		drawing_path_layer = parent
		last_selected_layer = parent

	Main.materials.clear_selected_index()
	Main.emit_selected_paths_changed()
	Main.emit_update_layer_list_tab()


## パスの選択状態を変更する。
## その親のレイヤーをdrawing_path_layerとlast_selected_layerに変更する。
func add_or_remove_selected_path(path: Path) -> void:
	if path in selected_paths:
		var index := 0
		while index < selected_paths.size():
			var selected_path := selected_paths[index]
			if selected_path == path:
				selected_paths.remove_at(index)
				Main.emit_selected_paths_changed()
				Main.emit_update_layer_list_tab()
				return
			else:
				index += 1
	selected_paths.append(path)
	last_selected_path = path
	last_selected_item = path

	@warning_ignore("unsafe_cast")
	var parent := path.parent_path_layer.get_ref() as PathPaintLayer
	if parent:
		drawing_path_layer = parent
		last_selected_layer = parent

	Main.materials.clear_selected_index()
	Main.emit_selected_paths_changed()
	Main.emit_update_layer_list_tab()


## last_selected_itmeからfinish_pathまでの範囲を選択する。
## 順に辿っていってlast_selected_itemを見つけたらflagをtrueに、finish_layerにたどり着いたらflagをfalseにする。
func _add_selected_items_path_range_in_group(group_layer: GroupPaintLayer, finish_path: Path, flag: bool) -> bool:
	for index in group_layer.child_layers.size():
		var layer := group_layer.child_layers[group_layer.child_layers.size() - index - 1]
		var prev_flag := flag
		if layer == last_selected_item:
			flag = not flag
		if prev_flag or flag:
			if not layer in selected_layers:
				selected_layers.append(layer)
		if layer is PathPaintLayer:
			var pl := layer as PathPaintLayer
			for i in pl.paths.size():
				var path := pl.paths[pl.paths.size() - i - 1]
				prev_flag = flag
				if path == last_selected_item:
					flag = not flag
				if path == finish_path:
					flag = not flag
				if prev_flag or flag:
					if not path in selected_paths:
						selected_paths.append(path)
		if layer is GroupPaintLayer:
			var gl := layer as GroupPaintLayer
			flag = _add_selected_items_path_range_in_group(gl, finish_path, flag)
	return flag


## last_selected_itmeからfinish_layerまでの範囲を選択する。
## 順に辿っていってlast_selected_itemを見つけたらflagをtrueに、finish_layerにたどり着いたらflagをfalseにする。
func _add_selected_items_path_range(finish_path: Path) -> void:
	var flag := false
	for index in root.size():
		var layer := root[root.size() - index - 1]
		var prev_flag := flag
		if layer == last_selected_item:
			flag = not flag
		if prev_flag or flag:
			if not layer in selected_layers:
				selected_layers.append(layer)
		if layer is PathPaintLayer:
			var pl := layer as PathPaintLayer
			for i in pl.paths.size():
				var path := pl.paths[pl.paths.size() - i - 1]
				prev_flag = flag
				if path == last_selected_item:
					flag = not flag
				if path == finish_path:
					flag = not flag
				if prev_flag or flag:
					if not path in selected_paths:
						selected_paths.append(path)
		if layer is GroupPaintLayer:
			var gl := layer as GroupPaintLayer
			flag = _add_selected_items_path_range_in_group(gl, finish_path, flag)


## 最後に選択したアイテムから引数のpathまでの範囲を選択する。
## 必要に応じてdrawing_path_layerも更新する。
func set_selected_path_range(path: Path) -> void:
	if last_selected_item == null:
		set_selected_path(path)
		return
	if last_selected_item == path:
		return
	selected_layers.clear()
	selected_paths.clear()
	_add_selected_items_path_range(path)
	last_selected_item = path
	last_selected_path = path

	@warning_ignore("unsafe_cast")
	var parent := path.parent_path_layer.get_ref() as PathPaintLayer
	if parent:
		drawing_path_layer = parent
		last_selected_layer = parent

	Main.materials.clear_selected_index()
	Main.emit_selected_paths_changed()
	Main.emit_update_layer_list_tab()


## 最後に選択したアイテムから引数のpathまでの範囲を追加で選択する。
## 必要に応じてdrawing_path_layerも更新する。
func add_selected_path_range(path: Path) -> void:
	if last_selected_item == null:
		set_selected_path(path)
		return
	if last_selected_item == path:
		return
	_add_selected_items_path_range(path)
	last_selected_item = path
	last_selected_path = path

	@warning_ignore("unsafe_cast")
	var parent := path.parent_path_layer.get_ref() as PathPaintLayer
	if parent:
		drawing_path_layer = parent
		last_selected_layer = parent

	Main.materials.clear_selected_index()
	Main.emit_selected_paths_changed()
	Main.emit_update_layer_list_tab()


## 選択中のレイヤー/パスをクリアする。
func clear_selected_items() -> void:
	selected_layers.clear()
	selected_paths.clear()
	Main.emit_selected_paths_changed()
	Main.emit_update_layer_list_tab()


## 引数のGroupPaintLayerの中のすべてのレイヤーをdragging_layersに追加する。
func _add_group_layer_to_dragging(group_layer: GroupPaintLayer) -> void:
	for layer in group_layer.child_layers:
		dragging_layers.append(layer)
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			for path in path_layer.paths:
				dragging_paths.append(path)
		if layer is GroupPaintLayer:
			var gl := layer as GroupPaintLayer
			_drag_start_layer_group(gl)


## 引数のGroupPaintLayerの中のドラッグ中のレイヤーをdragging_layersに追加する。
func _drag_start_layer_group(group_layer: GroupPaintLayer) -> void:
	for layer in group_layer.child_layers:
		var layer_selected := layer in selected_layers
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			for path in path_layer.paths:
				if path in selected_paths:
					layer_selected = true
		if layer_selected:
			dragging_layers.append(layer)
			if layer is PathPaintLayer:
				var path_layer := layer as PathPaintLayer
				for path in path_layer.paths:
					dragging_paths.append(path)
			if layer is GroupPaintLayer:
				var gl := layer as GroupPaintLayer
				_add_group_layer_to_dragging(gl)
		elif layer is GroupPaintLayer:
			var gl := layer as GroupPaintLayer
			_drag_start_layer_group(gl)


## ドラッグ中のPathとLayerを計算し、dragging_pathsとdragging_layersを埋める。
func drag_start() -> void:
	if selected_layers.size() > 0:
		for layer in root:
			var layer_selected := layer in selected_layers
			if layer is PathPaintLayer:
				var path_layer := layer as PathPaintLayer
				for path in path_layer.paths:
					if path in selected_paths:
						layer_selected = true
			if layer_selected:
				dragging_layers.append(layer)
				if layer is PathPaintLayer:
					var path_layer := layer as PathPaintLayer
					for path in path_layer.paths:
						dragging_paths.append(path)
				if layer is GroupPaintLayer:
					var gl := layer as GroupPaintLayer
					_add_group_layer_to_dragging(gl)
			elif layer is GroupPaintLayer:
				var gl := layer as GroupPaintLayer
				_drag_start_layer_group(gl)

		# ドラッグ中のレイヤーのうち、ルート側のものを取得
		for layer in dragging_layers:
			var has_parent := false
			for l in dragging_layers:
				if l is GroupPaintLayer:
					var gl := l as GroupPaintLayer
					for ll in gl.child_layers:
						if ll == layer:
							has_parent = true
			if not has_parent:
				dragging_root_layers.append(layer)

		dragging_root_layers.reverse()
	else:
		dragging_paths = selected_paths.duplicate()


## 現在ドラッグ中のパスを引数のGroupPaintLayerの中から除去する。
func _remove_dragging_paths_from_group_layer(gl: GroupPaintLayer, parent: PathPaintLayer, insert_at: int) -> int:
	for layer in gl.child_layers:
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			var index := 0
			var dirty_path_layer := false
			while index < path_layer.paths.size():
				var path := path_layer.paths[index]
				if path in dragging_paths:
					path_layer.paths.remove_at(index)
					dirty_path_layer = true
					if path_layer == parent and insert_at > index:
						insert_at -= 1
				else:
					index += 1
			if dirty_path_layer:
				path_layer.set_need_composite()
		elif layer is GroupPaintLayer:
			var group_layer := layer as GroupPaintLayer
			insert_at = _remove_dragging_paths_from_group_layer(group_layer, parent, insert_at)
	return insert_at


## ドラッグ中のパスを特定の位置に移動する。
func drag_move_path(insert_at: int, parent: PathPaintLayer) -> void:
	for layer in root:
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			var index := 0
			var dirty_path_layer := false
			while index < path_layer.paths.size():
				var path := path_layer.paths[index]
				if path in selected_paths:
					path_layer.paths.remove_at(index)
					dirty_path_layer = true
					if path_layer == parent and insert_at > index:
						insert_at -= 1
				else:
					index += 1
			if dirty_path_layer:
				path_layer.set_need_composite()
		elif layer is GroupPaintLayer:
			var group_layer := layer as GroupPaintLayer
			insert_at = _remove_dragging_paths_from_group_layer(group_layer, parent, insert_at)
	for path in dragging_paths:
		parent.paths.insert(insert_at, path)
		path.parent_path_layer = weakref(parent)
	parent.set_need_composite()
	update_parent_visible()
	update_parent_locked()


## 現在ドラッグ中のレイヤーのルート達を引数のGroupPaintLayerの中から除去する。
func _remove_dragging_root_layers_from_group_layer(gl: GroupPaintLayer, parent: GroupPaintLayer, insert_at: int) -> int:
	var index := 0
	while index < gl.child_layers.size():
		var layer := gl.child_layers[index]
		if layer in dragging_root_layers:
			gl.child_layers.remove_at(index)
			gl.need_composite = true
			if gl == parent and insert_at > index:
				insert_at -= 1
		else:
			index += 1
			if layer is GroupPaintLayer:
				var group_layer := layer as GroupPaintLayer
				insert_at = _remove_dragging_root_layers_from_group_layer(group_layer, parent, insert_at)
	return insert_at


## ドラッグ中のレイヤーを特定の位置に移動する。
func drag_move_layer(insert_at: int, parent: GroupPaintLayer) -> void:
	var index := 0
	while index < root.size():
		var layer := root[index]
		if layer in dragging_root_layers:
			root.remove_at(index)
			Main.compositor.need_composite = true
			if parent == null and insert_at > index:
				insert_at -= 1
		else:
			index += 1
			if layer is GroupPaintLayer:
				var group_layer := layer as GroupPaintLayer
				insert_at = _remove_dragging_root_layers_from_group_layer(group_layer, parent, insert_at)
	if parent:
		for layer in dragging_root_layers:
			parent.child_layers.insert(insert_at, layer)
			parent.need_composite = true
	else:
		for layer in dragging_root_layers:
			root.insert(insert_at, layer)
			Main.compositor.need_composite = true
	update_parent_visible()
	update_parent_locked()


## ドラッグ中の状態を解除する。
func drag_end() -> void:
	dragging_root_layers.clear()
	dragging_layers.clear()
	dragging_paths.clear()


## 新しいPathの追加。
## drawing_path_layerが存在する場合、そのレイヤーにパスを追加する。
## そうでない場合、新しいPathPaintLayerを作って追加する。
func add_path() -> Path:
	if not drawing_path_layer:
		drawing_path_layer = add_path_layer()

	if drawing_path_layer.is_locked():
		return null

	# 新しいパスを追加
	var new_path: Path = null
	if last_selected_path and selected_paths.size() > 0:
		# 現在パスが選択中の場合、最後に選択したパスの次に挿入する
		new_path = drawing_path_layer.add_insert_path_after_path(last_selected_path)
	else:
		# 現在パスが選択されていない場合、単純に末尾にパスを追加する
		new_path = drawing_path_layer.add_path()
	update_parent_visible()
	set_selected_path(new_path)

	return new_path


## 現在選択中のレイヤーの塗り色を変更する。
func set_fill_color_to_selected_layer(id: String) -> void:
	# マテリアルidが存在しない場合は何もしない
	var exists_material := false
	for item in Main.materials.list:
		if item.id == id:
			exists_material = true
	if not exists_material:
		return

	# 選択中のレイヤーのfillのマテリアルを変更する
	for layer in selected_layers:
		if layer.is_locked():
			continue
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			path_layer.fill_material_id = id

	# 新規作成時のマテリアルを現在セットしたマテリアルに更新しておく
	Main.materials.new_path_layer_fill_material_id = id

	Main.emit_update_layer_list_tab()


## 現在選択中のレイヤーの線の色を変更する。
func set_line_color_to_selected_layer(id: String) -> void:
	# マテリアルidが存在しない場合は何もしない
	var exists_material := false
	for item in Main.materials.list:
		if item.id == id:
			exists_material = true
	if not exists_material:
		return

	# 選択中のレイヤーのlineのマテリアルを変更する
	for layer in selected_layers:
		if layer.is_locked():
			continue
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			path_layer.outline_material_id = id

	# 新規作成時のマテリアルを現在セットしたマテリアルに更新しておく
	Main.materials.new_path_layer_line_material_id = id

	Main.emit_update_layer_list_tab()


## 現在選択中のレイヤーの塗りのオンオフを設定する。
func set_fill_of_selected_layers(fill: bool) -> void:
	for layer in _get_selected_path_layers():
		if layer.is_locked():
			continue
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			path_layer.filled = fill
			path_layer.set_need_composite()

	Main.emit_update_layer_list_tab()


## 現在選択中のレイヤーの線のオンオフを設定する。
func set_line_of_selected_layers(line: bool) -> void:
	for layer in _get_selected_path_layers():
		if layer.is_locked():
			continue
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			path_layer.outlined = line
			path_layer.set_need_composite()

	Main.emit_update_layer_list_tab()


## 現在選択中のパスレイヤーの塗りマテリアルを設定する。
func set_fill_material_of_selected_path_layers(material_id: String) -> void:
	for layer in _get_selected_path_layers():
		if layer.is_locked():
			continue
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			path_layer.fill_material_id = material_id
			path_layer.set_need_composite()

	Main.emit_update_layer_list_tab()


## 現在選択中のパスレイヤーの線マテリアルを設定する。
func set_line_material_of_selected_path_layers(material_id: String) -> void:
	for layer in _get_selected_path_layers():
		if layer.is_locked():
			continue
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			path_layer.outline_material_id = material_id
			path_layer.set_need_composite()

	Main.emit_update_layer_list_tab()


## 現在選択中のパスレイヤーの線幅を設定する。
func set_line_width_of_selected_path_layers(width: float) -> void:
	for layer in _get_selected_path_layers():
		if layer.is_locked():
			continue
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			path_layer.outline_width = width
			path_layer.update_outline_polygon()
			path_layer.set_need_composite()

	Main.emit_update_layer_list_tab()


## 現在選択中の塗りつぶしレイヤーの塗りマテリアルを設定する。
func set_fill_material_of_selected_fill_layers(material_id: String) -> void:
	for layer in _get_selected_path_layers():
		if layer.is_locked():
			continue
		if layer is FillPaintLayer:
			var fill_layer := layer as FillPaintLayer
			fill_layer.fill_material_id = material_id
			fill_layer.need_composite = true

	Main.emit_update_layer_list_tab()


## 現在選択中パスのopen/closedを切り替える。
func change_closed_of_selected_path() -> void:
	var closed := not last_selected_path.closed if last_selected_path else true
	for path in selected_paths:
		path.change_closed(closed)

	Main.emit_update_layer_list_tab()


## 現在選択中パスのbooleanを切り替える。
func change_boolean_of_selected_path(boolean: Path.Boolean) -> void:
	for path in selected_paths:
		path.change_boolean(boolean)

	Main.emit_update_layer_list_tab()


## 現在選択中のレイヤーのクリッピングを切り替える。
func change_clipping_of_selected_layer() -> void:
	var clipped := not last_selected_layer.clipped if last_selected_layer else true
	for layer in _get_selected_path_layers():
		layer.update_clipped(clipped)

	Main.emit_update_layer_list_tab()


## 現在選択中のレイヤーのブレンドモードを切り替える。
func set_blend_mode_of_selected_layer(blend_mode: PaintLayer.BlendMode) -> void:
	for layer in _get_selected_path_layers():
		layer.update_blend_mode(blend_mode)

	Main.emit_update_layer_list_tab()


## 現在選択中のレイヤーのアルファをセットする。
func set_alpha_of_selected_layer(alpha: int) -> void:
	for layer in _get_selected_path_layers():
		layer.update_alpha(alpha)

	Main.emit_update_layer_list_tab()


## 現在選択中のレイヤーのロック状態を切り替える。
func change_locked_of_selected_item() -> void:
	var locked := not all_locked_item_in_selected()
	for layer in selected_layers:
		layer.update_locked(locked)
	for path in selected_paths:
		path.update_locked(locked)
	update_parent_locked()

	Main.emit_update_layer_list_tab()
	Main.emit_selected_paths_changed()


## 選択中のレイヤー/パスにロック中のレイヤー/パスが含まれているかを取得する。
func any_locked_item_in_selected() -> bool:
	for layer in selected_layers:
		if layer.is_locked():
			return true
	for path in selected_paths:
		if path.is_locked():
			return true
	return false


## 選択中のレイヤー/パスがすべてロック中かどうかを取得する。
func all_locked_item_in_selected() -> bool:
	if selected_layers.size() == 0 and selected_paths.size() == 0:
		return false
	for layer in selected_layers:
		if not layer.locked:
			return false
	for path in selected_paths:
		if not path.locked:
			return false
	return true


## ルートから親の表示状態を更新する。
func update_parent_visible() -> void:
	for child_layer in root:
		if child_layer is PathPaintLayer:
			var path_layer := child_layer as PathPaintLayer
			path_layer.update_parent_visible(true)
		elif child_layer is FillPaintLayer:
			var fill_layer := child_layer as FillPaintLayer
			fill_layer.update_parent_visible(true)
		elif child_layer is GroupPaintLayer:
			var group_layer := child_layer as GroupPaintLayer
			group_layer.update_parent_visible(true)


## ルートから親のロック状態を更新する。
func update_parent_locked() -> void:
	for child_layer in root:
		if child_layer is PathPaintLayer:
			var path_layer := child_layer as PathPaintLayer
			path_layer.update_parent_locked(false)
		elif child_layer is FillPaintLayer:
			var fill_layer := child_layer as FillPaintLayer
			fill_layer.update_parent_locked(false)
		elif child_layer is GroupPaintLayer:
			var group_layer := child_layer as GroupPaintLayer
			group_layer.update_parent_locked(false)
	Main.emit_update_layer_list_tab()


## グループレイヤーの中の選択中のレイヤーの後ろにレイヤーの配列を挿入する。
func _insert_layers_to_group(group: GroupPaintLayer, layers: Array[PaintLayer]) -> bool:
	for index in group.child_layers.size():
		var l := group.child_layers[index]
		if l == last_selected_layer:
			for layer in layers:
				group.child_layers.insert(index + 1, layer)
			return true
		if l is GroupPaintLayer:
			var gl := l as GroupPaintLayer
			if _insert_layers_to_group(gl, layers):
				return true
	return false


## グループレイヤーの中に選択中のパスを含む場合にcollapseを開く。
func _open_collapsed_in_parent_in_group(group_layer: GroupPaintLayer, path_layer: PathPaintLayer) -> bool:
	for layer in group_layer.child_layers:
		if layer is PathPaintLayer:
			var pl := layer as PathPaintLayer
			if path_layer == pl:
				path_layer.collapsed = false
				return true
		if layer is GroupPaintLayer:
			var gl := layer as GroupPaintLayer
			if _open_collapsed_in_parent_in_group(gl, path_layer):
				gl.collapsed = false
				return true
	return false


## PathPaintLayerの親をたどってすべての先祖のレイヤーのcollapseを開く。
func _open_collapsed_in_parent(path_layer: PathPaintLayer) -> void:
	for layer in root:
		if layer is PathPaintLayer:
			var pl := layer as PathPaintLayer
			if path_layer == pl:
				path_layer.collapsed = false
				return
		if layer is GroupPaintLayer:
			var gl := layer as GroupPaintLayer
			if _open_collapsed_in_parent_in_group(gl, path_layer):
				gl.collapsed = false
				return


## コピーされたレイヤー/パスをペーストする。
func paste_copied_layers() -> void:
	var copied_layers := Main.copy_manager.get_copied_layers()
	var copied_paths := Main.copy_manager.get_copied_paths()
	if copied_layers.size() != 0:
		var inserted := false

		# last_selected_layerがGroupPaintLayerで折りたたまれていなかったらその末尾に追加する。
		if last_selected_layer is GroupPaintLayer:
			var gl := last_selected_layer as GroupPaintLayer
			if not gl.collapsed:
				gl.child_layers.append_array(copied_layers)
				inserted = true

		# rootからたどってlast_selected_layerを見つけたら直後に追加する
		if not inserted:
			for index in root.size():
				var l := root[index]
				if l == last_selected_layer:
					for layer in copied_layers:
						root.insert(index + 1, layer)
					inserted = true
					break
				if l is GroupPaintLayer:
					var gl := l as GroupPaintLayer
					if _insert_layers_to_group(gl, copied_layers):
						inserted = true
						break

		# last_selected_layerを見つけられなかった場合、先頭に追加する
		if not inserted:
			root.append_array(copied_layers)

		for layer in copied_layers:
			layer.need_composite = true
			if layer is PathPaintLayer:
				var path_layer := layer as PathPaintLayer
				path_layer.update_child_paths_thumbnail()

		selected_layers.clear()
		selected_paths.clear()
		for layer in copied_layers:
			add_or_remove_selected_layer(layer)
			if layer is PathPaintLayer:
				var path_layer := layer as PathPaintLayer
				path_layer.update_child_paths_thumbnail()

		update_parent_visible()

		Main.compositor.update()

		Main.emit_selected_paths_changed()
		Main.emit_update_layer_list_tab()

		Main.commit_history()

	elif copied_paths.size() != 0:
		if drawing_path_layer == null:
			drawing_path_layer = add_path_layer()
		copied_paths.reverse()
		drawing_path_layer.paths.append_array(copied_paths)
		for path in copied_paths:
			path.parent_path_layer = weakref(drawing_path_layer)
		drawing_path_layer.set_need_composite()

		selected_layers.clear()
		selected_paths.clear()
		for path in copied_paths:
			add_or_remove_selected_path(path)
		drawing_path_layer.update_child_paths_thumbnail()

		_open_collapsed_in_parent(drawing_path_layer)

		update_parent_visible()
		Main.emit_selected_paths_changed()
		Main.emit_update_layer_list_tab()

		Main.commit_history()


## idからグループレイヤー内のレイヤーを取得する。
func _get_layer_by_id_in_group(group: GroupPaintLayer, id: String) -> PaintLayer:
	for layer in group.child_layers:
		if layer.id == id:
			return layer
		elif layer is GroupPaintLayer:
			var gl := layer as GroupPaintLayer
			var l := _get_layer_by_id_in_group(gl, id)
			if l:
				return l
	return null


## idからレイヤーを取得する。
func get_layer_by_id(id: String) -> PaintLayer:
	for layer in root:
		if layer.id == id:
			return layer
		elif layer is GroupPaintLayer:
			var gl := layer as GroupPaintLayer
			var l := _get_layer_by_id_in_group(gl, id)
			if l:
				return l
	return null


## idからグループレイヤー内のパスを取得する。
func _get_path_by_id_in_group(group: GroupPaintLayer, id: String) -> Path:
	for layer in group.child_layers:
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			for path in path_layer.paths:
				if path.id == id:
					return path
		elif layer is GroupPaintLayer:
			var gl := layer as GroupPaintLayer
			var p := _get_path_by_id_in_group(gl, id)
			if p:
				return p
	return null


## idからパスを取得する。
func get_path_by_id(id: String) -> Path:
	for layer in root:
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			for path in path_layer.paths:
				if path.id == id:
					return path
		elif layer is GroupPaintLayer:
			var gl := layer as GroupPaintLayer
			var p := _get_path_by_id_in_group(gl, id)
			if p:
				return p
	return null


## ドキュメントサイズの変更を適用する。
func change_document_size(new_document_size: Vector2, _anchor: PaintLayer.ScaleAnchor) -> void:
	for layer in root:
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			path_layer.change_document_size(new_document_size, _anchor)
		elif layer is GroupPaintLayer:
			var group_layer := layer as GroupPaintLayer
			group_layer.change_document_size(new_document_size, _anchor)


## グループレイヤーをたどってflatten_layersに追加する。
func _add_flatten_layers_in_group(group: GroupPaintLayer, flatten_layers: Array[PaintLayer]) -> void:
	for layer in group.child_layers:
		flatten_layers.append(layer)
		if layer is GroupPaintLayer:
			var gl := layer as GroupPaintLayer
			_add_flatten_layers_in_group(gl, flatten_layers)


## flattenしたレイヤーを取得する。
func get_flatten_layers() -> Array[PaintLayer]:
	var flatten_layers: Array[PaintLayer] = []
	for layer in root:
		flatten_layers.append(layer)
		if layer is GroupPaintLayer:
			var group_layer := layer as GroupPaintLayer
			_add_flatten_layers_in_group(group_layer, flatten_layers)
	return flatten_layers

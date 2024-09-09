class_name DocumentSerializer
extends RefCounted


## パスレイヤーをdocumentエンコードする。
static func _encode_path_layer(path_layer: PathPaintLayer, encode_base64: bool) -> DocumentLayerPath:
	var document_layer_path := DocumentLayerPath.new()
	document_layer_path.id = path_layer.id
	document_layer_path.clipped = path_layer.clipped
	document_layer_path.visible = path_layer.visible
	document_layer_path.locked = path_layer.locked
	match path_layer.blend_mode:
		PaintLayer.BlendMode.Normal:
			document_layer_path.blend_mode = DocumentLayer.BlendMode.Normal
		PaintLayer.BlendMode.Add:
			document_layer_path.blend_mode = DocumentLayer.BlendMode.Add
		PaintLayer.BlendMode.Multiply:
			document_layer_path.blend_mode = DocumentLayer.BlendMode.Multiply
		PaintLayer.BlendMode.Screen:
			document_layer_path.blend_mode = DocumentLayer.BlendMode.Screen
		PaintLayer.BlendMode.Overlay:
			document_layer_path.blend_mode = DocumentLayer.BlendMode.Overlay
	document_layer_path.alpha = path_layer.alpha
	document_layer_path.layer_name = path_layer.layer_name

	document_layer_path.filled = path_layer.filled
	document_layer_path.fill_material_id = path_layer.fill_material_id
	document_layer_path.outlined = path_layer.outlined
	document_layer_path.outline_material_id = path_layer.outline_material_id
	document_layer_path.outline_width = path_layer.outline_width
	document_layer_path.collapsed = path_layer.collapsed
	document_layer_path.paths = []
	for path in path_layer.paths:
		var document_path := DocumentPath.new()
		document_path.id = path.id
		document_path.path_name = path.path_name
		document_path.visible = path.visible
		document_path.locked = path.locked
		document_path.closed = path.closed
		match path.boolean:
			Path.Boolean.Union:
				document_path.boolean = DocumentPath.Boolean.Union
			Path.Boolean.Diff:
				document_path.boolean = DocumentPath.Boolean.Diff
			Path.Boolean.Intersect:
				document_path.boolean = DocumentPath.Boolean.Intersect
			Path.Boolean.Xor:
				document_path.boolean = DocumentPath.Boolean.Xor

		if encode_base64:
			document_path.control_points = Marshalls.raw_to_base64(var_to_bytes(path.control_points))
			document_path.weights = Marshalls.raw_to_base64(var_to_bytes(path.weights))
			document_path.phis = Marshalls.raw_to_base64(var_to_bytes(path.phis))
			document_path.psis = Marshalls.raw_to_base64(var_to_bytes(path.psis))
			document_path.polygon = Marshalls.raw_to_base64(var_to_bytes(path.polygon))
			document_path.vertices = Marshalls.raw_to_base64(var_to_bytes(path.vertices))
			document_path.indices = Marshalls.raw_to_base64(var_to_bytes(path.indices))
			document_path.thumbnail_indices = []
			for i in path.thumbnail_indices:
				document_path.thumbnail_indices.append(Marshalls.raw_to_base64(var_to_bytes(i)))
			document_path.line_vertices = Marshalls.raw_to_base64(var_to_bytes(path.line_vertices))
			document_path.line_indices = Marshalls.raw_to_base64(var_to_bytes(path.line_indices))
			document_path.segments = []
			for s in path.segments:
				document_path.segments.append(Marshalls.raw_to_base64(var_to_bytes(s)))
		else:
			document_path.control_points_raw = path.control_points.duplicate()
			document_path.weights_raw = path.weights.duplicate()
			document_path.phis_raw = path.phis.duplicate()
			document_path.psis_raw = path.psis.duplicate()
			document_path.polygon_raw = path.polygon.duplicate()
			document_path.vertices_raw = path.vertices.duplicate()
			document_path.indices_raw = path.indices.duplicate()
			document_path.thumbnail_indices_raw = []
			for i in path.thumbnail_indices:
				document_path.thumbnail_indices_raw.append(i.duplicate())
			document_path.line_vertices_raw = path.line_vertices.duplicate()
			document_path.line_indices_raw = path.line_indices.duplicate()
			document_path.segments = []
			for s in path.segments:
				document_path.segments_raw.append(s.duplicate())

		document_layer_path.paths.append(document_path)
	return document_layer_path


## 塗りつぶしレイヤーをdocumentにエンコードする。
static func _encode_fill_layer(fill_layer: FillPaintLayer) -> DocumentLayerFill:
	var document_layer_fill := DocumentLayerFill.new()
	document_layer_fill.id = fill_layer.id
	document_layer_fill.clipped = fill_layer.clipped
	document_layer_fill.visible = fill_layer.visible
	document_layer_fill.locked = fill_layer.locked
	match fill_layer.blend_mode:
		PaintLayer.BlendMode.Normal:
			document_layer_fill.blend_mode = DocumentLayer.BlendMode.Normal
		PaintLayer.BlendMode.Add:
			document_layer_fill.blend_mode = DocumentLayer.BlendMode.Add
		PaintLayer.BlendMode.Multiply:
			document_layer_fill.blend_mode = DocumentLayer.BlendMode.Multiply
		PaintLayer.BlendMode.Screen:
			document_layer_fill.blend_mode = DocumentLayer.BlendMode.Screen
		PaintLayer.BlendMode.Overlay:
			document_layer_fill.blend_mode = DocumentLayer.BlendMode.Overlay
	document_layer_fill.alpha = fill_layer.alpha
	document_layer_fill.layer_name = fill_layer.layer_name

	document_layer_fill.fill_material_id = fill_layer.fill_material_id
	return document_layer_fill


## グループレイヤーをdocumentにエンコードする。
static func _encode_group_layer(group_layer: GroupPaintLayer, encode_base64: bool) -> DocumentLayerGroup:
	var document_layer_group := DocumentLayerGroup.new()
	document_layer_group.id = group_layer.id
	document_layer_group.clipped = group_layer.clipped
	document_layer_group.visible = group_layer.visible
	document_layer_group.locked = group_layer.locked
	match group_layer.blend_mode:
		PaintLayer.BlendMode.Normal:
			document_layer_group.blend_mode = DocumentLayer.BlendMode.Normal
		PaintLayer.BlendMode.Add:
			document_layer_group.blend_mode = DocumentLayer.BlendMode.Add
		PaintLayer.BlendMode.Multiply:
			document_layer_group.blend_mode = DocumentLayer.BlendMode.Multiply
		PaintLayer.BlendMode.Screen:
			document_layer_group.blend_mode = DocumentLayer.BlendMode.Screen
		PaintLayer.BlendMode.Overlay:
			document_layer_group.blend_mode = DocumentLayer.BlendMode.Overlay
	document_layer_group.alpha = group_layer.alpha
	document_layer_group.layer_name = group_layer.layer_name

	document_layer_group.collapsed = group_layer.collapsed
	document_layer_group.child_layers = []
	for layer in group_layer.child_layers:
		if layer is PathPaintLayer:
			var pl := layer as PathPaintLayer
			document_layer_group.child_layers.append(_encode_path_layer(pl, encode_base64))
		if layer is FillPaintLayer:
			var fl := layer as FillPaintLayer
			document_layer_group.child_layers.append(_encode_fill_layer(fl))
		if layer is GroupPaintLayer:
			var gl := layer as GroupPaintLayer
			document_layer_group.child_layers.append(_encode_group_layer(gl, encode_base64))

	return document_layer_group


## Mainをdocumentにストアする。
static func document_store(encode_base64: bool) -> Document:
	var document := Document.new()

	document.document_size = Main.document_size

	# マテリアルをエンコードする
	var document_materials: Array[DocumentMaterial] = []
	for item in Main.materials.list:
		if item.material is ColorPaintMaterial:
			var color_mat := item.material as ColorPaintMaterial
			var document_material_color := DocumentMaterialColor.new()
			document_material_color.id = item.id
			document_material_color.name = item.name
			document_material_color.color = color_mat.color
			document_materials.append(document_material_color)
		elif item.material is LinearGradientPaintMaterial:
			var linear_mat := item.material as LinearGradientPaintMaterial
			var document_material_linear := DocumentMaterialLinearGradient.new()
			document_material_linear.id = item.id
			document_material_linear.name = item.name
			document_material_linear.colors = Marshalls.raw_to_base64(var_to_bytes(linear_mat.gradient.colors))
			document_material_linear.offsets = Marshalls.raw_to_base64(var_to_bytes(linear_mat.gradient.offsets))
			document_material_linear.start_point = linear_mat.start_point
			document_material_linear.end_point = linear_mat.end_point
			document_materials.append(document_material_linear)
		elif item.material is RadialGradientPaintMaterial:
			var radial_mat := item.material as RadialGradientPaintMaterial
			var document_material_radial := DocumentMaterialRadialGradient.new()
			document_material_radial.id = item.id
			document_material_radial.name = item.name
			document_material_radial.colors = Marshalls.raw_to_base64(var_to_bytes(radial_mat.gradient.colors))
			document_material_radial.offsets = Marshalls.raw_to_base64(var_to_bytes(radial_mat.gradient.offsets))
			document_material_radial.center_point = radial_mat.center_point
			document_material_radial.handle_1_point = radial_mat.handle_1_point
			document_material_radial.handle_2_point = radial_mat.handle_2_point
			document_materials.append(document_material_radial)
	document.materials = document_materials
	document.new_fill_layer_material_id = Main.materials.new_fill_layer_material_id
	document.new_path_layer_fill_material_id = Main.materials.new_path_layer_fill_material_id
	document.new_path_layer_line_material_id = Main.materials.new_path_layer_line_material_id

	# レイヤーをエンコードする
	var document_layers: Array[DocumentLayer] = []
	for layer in Main.layers.root:
		if layer is PathPaintLayer:
			var path_layer := layer as PathPaintLayer
			document_layers.append(_encode_path_layer(path_layer, encode_base64))
		if layer is FillPaintLayer:
			var fill_layer := layer as FillPaintLayer
			document_layers.append(_encode_fill_layer(fill_layer))
		if layer is GroupPaintLayer:
			var group_layer := layer as GroupPaintLayer
			document_layers.append(_encode_group_layer(group_layer, encode_base64))
	document.layers = document_layers

	# 選択中のレイヤーなどを保存する。
	document.selected_layers = []
	for layer in Main.layers.selected_layers:
		document.selected_layers.append(layer.id)
	document.selected_paths = []
	for path in Main.layers.selected_paths:
		document.selected_paths.append(path.id)
	if Main.layers.last_selected_layer != null:
		document.last_selected_layer = Main.layers.last_selected_layer.id
	if Main.layers.last_selected_path != null:
		document.last_selected_path = Main.layers.last_selected_path.id
	if Main.layers.last_selected_item != null:
		document.last_selected_item = Main.layers.last_selected_item.id
	if Main.layers.drawing_path_layer != null:
		document.drawing_path_layer = Main.layers.drawing_path_layer.id

	return document


## パスレイヤーをdocumentデコードする。
static func _decode_path_layer(document_layer_path: DocumentLayerPath, decode_base64: bool) -> PathPaintLayer:
	var path_layer := Main.layer_pool.get_path_layer(false)
	if not document_layer_path.id.is_empty():
		path_layer.id = document_layer_path.id
	path_layer.clipped = document_layer_path.clipped
	path_layer.visible = document_layer_path.visible
	path_layer.locked = document_layer_path.locked
	match document_layer_path.blend_mode:
		DocumentLayer.BlendMode.Normal:
			path_layer.blend_mode = PaintLayer.BlendMode.Normal
		DocumentLayer.BlendMode.Add:
			path_layer.blend_mode = PaintLayer.BlendMode.Add
		DocumentLayer.BlendMode.Multiply:
			path_layer.blend_mode = PaintLayer.BlendMode.Multiply
		DocumentLayer.BlendMode.Screen:
			path_layer.blend_mode = PaintLayer.BlendMode.Screen
		DocumentLayer.BlendMode.Overlay:
			path_layer.blend_mode = PaintLayer.BlendMode.Overlay
	path_layer.alpha = document_layer_path.alpha
	path_layer.layer_name = document_layer_path.layer_name

	path_layer.filled = document_layer_path.filled
	path_layer.fill_material_id = document_layer_path.fill_material_id
	path_layer.outlined = document_layer_path.outlined
	path_layer.outline_material_id = document_layer_path.outline_material_id
	path_layer.outline_width = document_layer_path.outline_width
	path_layer.collapsed = document_layer_path.collapsed
	for document_path in document_layer_path.paths:
		var path := path_layer.add_path(false)
		if not document_path.id.is_empty():
			path.id = document_path.id
		path.path_name = document_path.path_name
		path.visible = document_path.visible
		path.locked = document_path.locked
		path.closed = document_path.closed
		match document_path.boolean:
			DocumentPath.Boolean.Union:
				path.boolean = Path.Boolean.Union
			DocumentPath.Boolean.Diff:
				path.boolean = Path.Boolean.Diff
			DocumentPath.Boolean.Intersect:
				path.boolean = Path.Boolean.Intersect
			DocumentPath.Boolean.Xor:
				path.boolean = Path.Boolean.Xor

		if decode_base64:
			var need_recalculate := false
			@warning_ignore("unsafe_cast")
			path.control_points = bytes_to_var(Marshalls.base64_to_raw(document_path.control_points)) as PackedVector2Array
			@warning_ignore("unsafe_cast")
			path.weights = bytes_to_var(Marshalls.base64_to_raw(document_path.weights)) as PackedFloat32Array
			@warning_ignore("unsafe_cast")
			path.phis = bytes_to_var(Marshalls.base64_to_raw(document_path.phis)) as PackedFloat32Array
			@warning_ignore("unsafe_cast")
			path.psis = bytes_to_var(Marshalls.base64_to_raw(document_path.psis)) as PackedFloat32Array
			if document_path.polygon.is_empty():
				need_recalculate = true
			else:
				@warning_ignore("unsafe_cast")
				path.polygon = bytes_to_var(Marshalls.base64_to_raw(document_path.polygon)) as PackedVector2Array
			if document_path.vertices.is_empty():
				need_recalculate = true
			else:
				@warning_ignore("unsafe_cast")
				path.vertices = bytes_to_var(Marshalls.base64_to_raw(document_path.vertices)) as PackedVector2Array
			if document_path.indices.is_empty():
				need_recalculate = true
			else:
				@warning_ignore("unsafe_cast")
				path.indices = bytes_to_var(Marshalls.base64_to_raw(document_path.indices)) as PackedInt32Array
			if document_path.thumbnail_indices.size() == 0:
				need_recalculate = true
			else:
				path.thumbnail_indices = []
				for i in document_path.thumbnail_indices:
					@warning_ignore("unsafe_cast")
					path.thumbnail_indices.append(bytes_to_var(Marshalls.base64_to_raw(i)) as PackedInt32Array)
			if document_path.line_vertices.is_empty():
				need_recalculate = true
			else:
				@warning_ignore("unsafe_cast")
				path.line_vertices = bytes_to_var(Marshalls.base64_to_raw(document_path.line_vertices)) as PackedVector2Array
			if document_path.line_indices.is_empty():
				need_recalculate = true
			else:
				@warning_ignore("unsafe_cast")
				path.line_indices = bytes_to_var(Marshalls.base64_to_raw(document_path.line_indices)) as PackedInt32Array
			if document_path.segments.size() == 0:
				need_recalculate = true
			else:
				path.segments = []
				for s in document_path.segments:
					@warning_ignore("unsafe_cast")
					path.segments.append(bytes_to_var(Marshalls.base64_to_raw(s)) as PackedVector2Array)
			if need_recalculate:
				path.recalculate_polygon()
		else:
			path.control_points = document_path.control_points_raw.duplicate()
			path.weights = document_path.weights_raw.duplicate()
			path.phis = document_path.phis_raw.duplicate()
			path.psis = document_path.psis_raw.duplicate()
			path.polygon = document_path.polygon_raw.duplicate()
			path.vertices = document_path.vertices_raw.duplicate()
			path.indices = document_path.indices_raw.duplicate()
			path.thumbnail_indices = []
			for i in document_path.thumbnail_indices_raw:
				path.thumbnail_indices.append(i.duplicate())
			path.line_vertices = document_path.line_vertices_raw.duplicate()
			path.line_indices = document_path.line_indices_raw.duplicate()
			path.segments = []
			for s in document_path.segments_raw:
				path.segments.append(s.duplicate())

	path_layer.need_composite = true
	path_layer.update_child_paths_thumbnail()

	return path_layer


## 塗りつぶしレイヤーをdocumentにデコードする。
static func _decode_fill_layer(document_layer_fill: DocumentLayerFill) -> FillPaintLayer:
	var fill_layer := Main.layer_pool.get_fill_layer(false)
	if not document_layer_fill.id.is_empty():
		fill_layer.id = document_layer_fill.id
	fill_layer.clipped = document_layer_fill.clipped
	fill_layer.visible = document_layer_fill.visible
	fill_layer.locked = document_layer_fill.locked
	match document_layer_fill.blend_mode:
		DocumentLayer.BlendMode.Normal:
			fill_layer.blend_mode = PaintLayer.BlendMode.Normal
		DocumentLayer.BlendMode.Add:
			fill_layer.blend_mode = PaintLayer.BlendMode.Add
		DocumentLayer.BlendMode.Multiply:
			fill_layer.blend_mode = PaintLayer.BlendMode.Multiply
		DocumentLayer.BlendMode.Screen:
			fill_layer.blend_mode = PaintLayer.BlendMode.Screen
		DocumentLayer.BlendMode.Overlay:
			fill_layer.blend_mode = PaintLayer.BlendMode.Overlay
	fill_layer.alpha = document_layer_fill.alpha
	fill_layer.layer_name = document_layer_fill.layer_name

	fill_layer.need_composite = true

	fill_layer.fill_material_id = document_layer_fill.fill_material_id
	return fill_layer


## グループレイヤーをdocumentにデコードする。
static func _decode_group_layer(document_layer_group: DocumentLayerGroup, decode_base64: bool) -> GroupPaintLayer:
	var group_layer := Main.layer_pool.get_group_layer(false)
	if not document_layer_group.id.is_empty():
		group_layer.id = document_layer_group.id
	group_layer.clipped = document_layer_group.clipped
	group_layer.visible = document_layer_group.visible
	group_layer.locked = document_layer_group.locked
	match document_layer_group.blend_mode:
		DocumentLayer.BlendMode.Normal:
			group_layer.blend_mode = PaintLayer.BlendMode.Normal
		DocumentLayer.BlendMode.Add:
			group_layer.blend_mode = PaintLayer.BlendMode.Add
		DocumentLayer.BlendMode.Multiply:
			group_layer.blend_mode = PaintLayer.BlendMode.Multiply
		DocumentLayer.BlendMode.Screen:
			group_layer.blend_mode = PaintLayer.BlendMode.Screen
		DocumentLayer.BlendMode.Overlay:
			group_layer.blend_mode = PaintLayer.BlendMode.Overlay
	group_layer.alpha = document_layer_group.alpha
	group_layer.layer_name = document_layer_group.layer_name

	group_layer.collapsed = document_layer_group.collapsed
	group_layer.child_layers = []
	for layer in document_layer_group.child_layers:
		if layer is DocumentLayerPath:
			var pl := layer as DocumentLayerPath
			group_layer.child_layers.append(_decode_path_layer(pl, decode_base64))
		if layer is DocumentLayerFill:
			var fl := layer as DocumentLayerFill
			group_layer.child_layers.append(_decode_fill_layer(fl))
		if layer is DocumentLayerGroup:
			var gl := layer as DocumentLayerGroup
			group_layer.child_layers.append(_decode_group_layer(gl, decode_base64))

	group_layer.need_composite = true

	return group_layer

## Mainにdocumentをロードする。
static func document_load(document: Document, decode_base64: bool) -> void:
	# 現在の状態をクリアする
	Main.materials.clear()
	Main.layers.clear()

	Main.document_size = document.document_size

	Main.compositor.resize(Main.document_size)

	# マテリアルを読み込む。
	for document_material in document.materials:
		if document_material is DocumentMaterialColor:
			var document_material_color := document_material as DocumentMaterialColor
			var material := ColorPaintMaterial.new()
			material.color = document_material_color.color
			var item := MaterialList.PaintMaterialListItem.new()
			item.id = document_material_color.id
			item.name = document_material_color.name
			item.material = material
			Main.materials.list.append(item)
		elif document_material is DocumentMaterialLinearGradient:
			var document_material_linear := document_material as DocumentMaterialLinearGradient
			var material := LinearGradientPaintMaterial.new()
			@warning_ignore("unsafe_cast")
			material.gradient.colors = bytes_to_var(Marshalls.base64_to_raw(document_material_linear.colors)) as PackedColorArray
			@warning_ignore("unsafe_cast")
			material.gradient.offsets = bytes_to_var(Marshalls.base64_to_raw(document_material_linear.offsets)) as PackedFloat32Array
			material.start_point = document_material_linear.start_point
			material.end_point = document_material_linear.end_point
			var item := MaterialList.PaintMaterialListItem.new()
			item.id = document_material_linear.id
			item.name = document_material_linear.name
			item.material = material
			Main.materials.list.append(item)
		elif document_material is DocumentMaterialRadialGradient:
			var document_material_radial := document_material as DocumentMaterialRadialGradient
			var material := RadialGradientPaintMaterial.new()
			@warning_ignore("unsafe_cast")
			material.gradient.colors = bytes_to_var(Marshalls.base64_to_raw(document_material_radial.colors)) as PackedColorArray
			@warning_ignore("unsafe_cast")
			material.gradient.offsets = bytes_to_var(Marshalls.base64_to_raw(document_material_radial.offsets)) as PackedFloat32Array
			material.center_point = document_material_radial.center_point
			material.handle_1_point = document_material_radial.handle_1_point
			material.handle_2_point = document_material_radial.handle_2_point
			var item := MaterialList.PaintMaterialListItem.new()
			item.id = document_material_radial.id
			item.name = document_material_radial.name
			item.material = material
			Main.materials.list.append(item)
	Main.materials.new_fill_layer_material_id = document.new_fill_layer_material_id
	Main.materials.new_path_layer_fill_material_id = document.new_path_layer_fill_material_id
	Main.materials.new_path_layer_line_material_id = document.new_path_layer_line_material_id

	# レイヤーを読み込む。
	for layer in document.layers:
		if layer is DocumentLayerPath:
			var path_layer := layer as DocumentLayerPath
			Main.layers.root.append(_decode_path_layer(path_layer, decode_base64))
		if layer is DocumentLayerFill:
			var fill_layer := layer as DocumentLayerFill
			Main.layers.root.append(_decode_fill_layer(fill_layer))
		if layer is DocumentLayerGroup:
			var group_layer := layer as DocumentLayerGroup
			Main.layers.root.append(_decode_group_layer(group_layer, decode_base64))

	# 選択中のレイヤーなどを復元する。
	for layer_id in document.selected_layers:
		var layer := Main.layers.get_layer_by_id(layer_id)
		if layer:
			Main.layers.selected_layers.append(layer)
	for path_id in document.selected_paths:
		var path := Main.layers.get_path_by_id(path_id)
		if path:
			Main.layers.selected_paths.append(path)
	if not document.last_selected_layer.is_empty():
		Main.layers.last_selected_layer = Main.layers.get_layer_by_id(document.last_selected_layer)
	if not document.last_selected_path.is_empty():
		Main.layers.last_selected_path = Main.layers.get_path_by_id(document.last_selected_path)
	if not document.last_selected_item.is_empty():
		if Main.layers.get_layer_by_id(document.last_selected_item):
			Main.layers.last_selected_item = Main.layers.get_layer_by_id(document.last_selected_item)
		else:
			Main.layers.last_selected_item = Main.layers.get_path_by_id(document.last_selected_item)
	if not document.drawing_path_layer.is_empty():
		Main.layers.drawing_path_layer = Main.layers.get_layer_by_id(document.drawing_path_layer)

	Main.compositor.update()

	Main.document_opened = true

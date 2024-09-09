class_name CopyManager
extends RefCounted


## コピーしたレイヤー。
var _copied_layers: Array[PaintLayer] = []
## コピーしたパス。
var _copied_paths: Array[Path] = []
## コピーしたマテリアル。
var _copied_material: MaterialList.PaintMaterialListItem = null


## 選択中のデータをコピーする。
func copy() -> void:
  clear()
  if Main.layers.selected_layers.size() > 0:
    _copy_layers()
  elif Main.layers.selected_paths.size() > 0:
    _copy_paths()
  elif Main.materials.selected_index != -1:
    _copy_material()


## レイヤーを複製して保持する。
func _copy_layers() -> void:
  var selected_layers: Array[PaintLayer] = Main.layers._get_selected_path_layers()

  # 選択中のレイヤーのうち、ルート側のものを取得
  var selected_root_layers: Array[PaintLayer] = []
  for layer in selected_layers:
    var has_parent := false
    for l in selected_layers:
      if l is GroupPaintLayer:
        var gl := l as GroupPaintLayer
        for ll in gl.child_layers:
          if ll == layer:
            has_parent = true
    if not has_parent:
      selected_root_layers.append(layer)

  for selected_layer in selected_root_layers:
    if selected_layer is PathPaintLayer:
        var selected_path_layer := selected_layer as PathPaintLayer
        _copied_layers.append(_duplicate_path_layer(selected_path_layer, false))
    elif selected_layer is FillPaintLayer:
        var selected_fill_layer := selected_layer as FillPaintLayer
        _copied_layers.append(_duplicate_fill_layer(selected_fill_layer, false))
    elif selected_layer is GroupPaintLayer:
        var selected_group_layer := selected_layer as GroupPaintLayer
        _copied_layers.append(_duplicate_group_layer(selected_group_layer, false))


func _duplicate_path_layer(path_layer: PathPaintLayer, add_suffix: bool) -> PathPaintLayer:
  var new_path_layer := Main.layer_pool.get_path_layer()

  if add_suffix:
    new_path_layer.layer_name = path_layer.layer_name + " (" + tr("COPY") + ")"
  else:
    new_path_layer.layer_name = path_layer.layer_name

  new_path_layer.clipped = path_layer.clipped
  new_path_layer.visible = path_layer.visible
  new_path_layer.locked = path_layer.locked
  new_path_layer.blend_mode = path_layer.blend_mode
  new_path_layer.alpha = path_layer.alpha

  new_path_layer.filled = path_layer.filled
  new_path_layer.fill_material_id = path_layer.fill_material_id
  new_path_layer.outlined = path_layer.outlined
  new_path_layer.outline_material_id = path_layer.outline_material_id
  new_path_layer.outline_width = path_layer.outline_width
  new_path_layer.collapsed = path_layer.collapsed

  for path in path_layer.paths:
    var new_path := new_path_layer.add_path()

    if add_suffix:
      new_path.path_name = path.path_name + " (" + tr("COPY") + ")"
    else:
      new_path.path_name = path.path_name

    new_path.visible = path.visible
    new_path.locked = path.locked
    new_path.control_points = path.control_points.duplicate()
    new_path.weights = path.weights.duplicate()
    new_path.phis = path.phis.duplicate()
    new_path.psis = path.psis.duplicate()
    new_path.closed = path.closed
    new_path.polygon = path.polygon.duplicate()
    new_path.vertices = path.vertices.duplicate()
    new_path.indices = path.indices.duplicate()
    new_path.thumbnail_indices = path.thumbnail_indices.duplicate()
    new_path.line_vertices = path.line_vertices.duplicate()
    new_path.line_indices = path.line_indices.duplicate()
    new_path.segments = path.segments.duplicate()
    new_path.boolean = path.boolean

  return new_path_layer


func _duplicate_fill_layer(fill_layer: FillPaintLayer, add_suffix: bool) -> FillPaintLayer:
  var new_fill_layer := Main.layer_pool.get_fill_layer()

  if add_suffix:
    new_fill_layer.layer_name = fill_layer.layer_name + " (" + tr("COPY") + ")"
  else:
    new_fill_layer.layer_name = fill_layer.layer_name

  new_fill_layer.clipped = fill_layer.clipped
  new_fill_layer.visible = fill_layer.visible
  new_fill_layer.locked = fill_layer.locked
  new_fill_layer.blend_mode = fill_layer.blend_mode
  new_fill_layer.alpha = fill_layer.alpha

  new_fill_layer.fill_material_id = fill_layer.fill_material_id

  return new_fill_layer


func _duplicate_group_layer(group_layer: GroupPaintLayer, add_suffix: bool) -> GroupPaintLayer:
  var new_group_layer := Main.layer_pool.get_group_layer()

  if add_suffix:
    new_group_layer.layer_name = group_layer.layer_name + " (" + tr("COPY") + ")"
  else:
    new_group_layer.layer_name = group_layer.layer_name

  new_group_layer.clipped = group_layer.clipped
  new_group_layer.visible = group_layer.visible
  new_group_layer.locked = group_layer.locked
  new_group_layer.blend_mode = group_layer.blend_mode
  new_group_layer.alpha = group_layer.alpha

  new_group_layer.collapsed = group_layer.collapsed

  for child_layer in group_layer.child_layers:
    if child_layer is PathPaintLayer:
        var child_path_layer := child_layer as PathPaintLayer
        new_group_layer.child_layers.append(_duplicate_path_layer(child_path_layer, add_suffix))
    elif child_layer is FillPaintLayer:
        var child_fill_layer := child_layer as FillPaintLayer
        new_group_layer.child_layers.append(_duplicate_fill_layer(child_fill_layer, add_suffix))
    elif child_layer is GroupPaintLayer:
        var child_group_layer := child_layer as GroupPaintLayer
        new_group_layer.child_layers.append(_duplicate_group_layer(child_group_layer, add_suffix))

  return new_group_layer


## パスを複製して保持する。
func _copy_paths() -> void:
  for path in Main.layers.selected_paths:
    var new_path := _duplicate_path(path)
    _copied_paths.append(new_path)


## パスを複製する。
func _duplicate_path(path: Path) -> Path:
  var new_path := Main.path_pool.get_path()

  new_path.path_name = path.path_name
  new_path.visible = path.visible
  new_path.locked = path.locked
  new_path.control_points = path.control_points.duplicate()
  new_path.weights = path.weights.duplicate()
  new_path.phis = path.phis.duplicate()
  new_path.psis = path.psis.duplicate()
  new_path.closed = path.closed
  new_path.polygon = path.polygon.duplicate()
  new_path.vertices = path.vertices.duplicate()
  new_path.indices = path.indices.duplicate()
  new_path.thumbnail_indices = path.thumbnail_indices.duplicate()
  new_path.line_vertices = path.line_vertices.duplicate()
  new_path.line_indices = path.line_indices.duplicate()
  new_path.segments = path.segments.duplicate()
  new_path.boolean = path.boolean

  return new_path


## マテリアルを複製して保持する。
func _copy_material() -> void:
  var selected_material := Main.materials.list[Main.materials.selected_index]

  var new_material := MaterialList.PaintMaterialListItem.new()
  new_material.name = selected_material.name + " (" + tr("COPY") + ")"

  if selected_material.material is ColorPaintMaterial:
      var selected_color_material := selected_material.material as ColorPaintMaterial
      var color_material := ColorPaintMaterial.new()
      color_material.color = selected_color_material.color
      new_material.material = color_material
      print("color material copied")

  _copied_material = new_material


## コピーのために保持しているデータの破棄をする。
func clear() -> void:
  for layer in _copied_layers:
    Main.layer_pool.free_layer(layer)
  _copied_layers = []
  for path in _copied_paths:
    Main.path_pool.free_path(path)
  _copied_paths = []
  _copied_material = null


## コピーされたレイヤーのリストを複製して返す。
func get_copied_layers() -> Array[PaintLayer]:
  var new_layers: Array[PaintLayer] = []

  for layer in _copied_layers:
    if layer is PathPaintLayer:
        var path_layer := layer as PathPaintLayer
        new_layers.append(_duplicate_path_layer(path_layer, true))
    elif layer is FillPaintLayer:
        var fill_layer := layer as FillPaintLayer
        new_layers.append(_duplicate_fill_layer(fill_layer, true))
    elif layer is GroupPaintLayer:
        var group_layer := layer as GroupPaintLayer
        new_layers.append(_duplicate_group_layer(group_layer, true))

  return new_layers


## コピーされたパスのリストを複製して返す。
func get_copied_paths() -> Array[Path]:
  var new_paths: Array[Path] = []

  for path in _copied_paths:
    var new_path := _duplicate_path(path)
    new_path.path_name += " (" + tr("COPY") + ")"
    new_paths.append(new_path)

  return new_paths


## コピーされたマテリアルを複製して返す。
func get_copied_material() -> MaterialList.PaintMaterialListItem:
  if _copied_material == null:
    return null

  var new_material := MaterialList.PaintMaterialListItem.new()
  new_material.name = _copied_material.name

  if _copied_material.material is ColorPaintMaterial:
      var copied_color_material := _copied_material.material as ColorPaintMaterial
      var color_material := ColorPaintMaterial.new()
      color_material.color = copied_color_material.color
      new_material.material = color_material

  return new_material


## ドキュメントサイズ変更に対応する。
func change_document_size(new_document_size: Vector2, anchor: PaintLayer.ScaleAnchor) -> void:
  for layer in _copied_layers:
    if layer is PathPaintLayer:
        var path_layer := layer as PathPaintLayer
        path_layer.change_document_size(new_document_size, anchor)
    elif layer is GroupPaintLayer:
        var group_layer := layer as GroupPaintLayer
        group_layer.change_document_size(new_document_size, anchor)
  for path in _copied_paths:
    path.change_document_size(new_document_size, anchor)

## レイヤー内に含まれる一つのパスを表現するクラス。
class_name Path
extends Node


const uuid_util = preload('res://addons/uuid/uuid.gd')


@onready var _sub_viewport: SubViewport = $"."
@onready var _polygon2d: Polygon2D = $Polygon2D
@onready var _line2d: Line2D = $Line2D

## マテリアルmissing時の表示用マテリアル。
@export var missing_material: ShaderMaterial
## 線形グラデーションの表示用マテリアル。
@export var linear_gradient_material: ShaderMaterial
## 放射グラデーションの表示用マテリアル。
@export var radial_gradient_material: ShaderMaterial

## 親のパスレイヤーのWeakRef。
var parent_path_layer: WeakRef

## レイヤーのID。
var id: String

## レイヤーが表示されているかどうか。
var visible: bool = true
## 親のレイヤーが表示されているかどうか。
var parent_visible: bool = true

## レイヤーがロックされているかどうか。
var locked: bool = false
## 親のレイヤーがロックされているかどうか。
var parent_locked: bool = false

## ControlPointの配列。
var control_points: PackedVector2Array = PackedVector2Array()
## weightの配列。
var weights: PackedFloat32Array = PackedFloat32Array()
## phiの配列。
var phis: PackedFloat32Array = PackedFloat32Array()
## psiの配列。
var psis: PackedFloat32Array = PackedFloat32Array()
## closed pathかどうか。
var closed: bool = false

## パスのポリゴン形状のPackedVector2Array。
var polygon: PackedVector2Array = PackedVector2Array()
## polygonの頂点列のPackedVector2Array。
var vertices: PackedVector2Array = PackedVector2Array()
## polygonのindicesのPackedInt32Array。
var indices: PackedInt32Array = PackedInt32Array()
## パスのサムネ用のindices
var thumbnail_indices: Array[PackedInt32Array] = []
## polygonの頂点列のPackedVector2Array。
var line_vertices: PackedVector2Array = PackedVector2Array()
## polygonのindicesのPackedInt32Array。
var line_indices: PackedInt32Array = PackedInt32Array()
## segmentsのPackedVector2Arrayの配列。
var segments: Array[PackedVector2Array] = []

## パスのブーリアンの列挙子
enum Boolean {
	Union,
	Diff,
	Intersect,
	Xor,
}

## パスのブーリアンの種類。
var boolean: Boolean = Boolean.Union

## パスの名前。
var path_name: String = "パス"

const NEW_PHI_VALUE: float = 1.0
const NEW_PSI_VALUE: float = 0.0

## このフレームで再計算を予約したかどうかのフラグ。
var _need_recalculate_polygon: bool = false

## コントロールポイントを増減したかどうかのフラグ。
var _change_controls_count: bool = false

## レイヤーの線の状態。
var _is_line: bool = true
## サムネ用マテリアル。
var _material: PaintMaterial
## 線の太さ。
var _line_width: float = 2.0


## Pathのシーン。
static var _path_scene: PackedScene


func _init() -> void:
	id = uuid_util.v4()


func _process(_delta: float) -> void:
	if _need_recalculate_polygon:
		recalculate_polygon()
		_need_recalculate_polygon = false


## 単色の塗りつぶしとしてサムネをアップデートする
func _update_fill_thumbnail_color(color: Color) -> void:
	_polygon2d.visible = true
	_polygon2d.material = null
	_polygon2d.color = color
	_polygon2d.polygon = vertices
	_polygon2d.polygons = thumbnail_indices
	_line2d.visible = false
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## 単色のラインとしてサムネをアップデートする
func _update_line_thumbnail_color(color: Color) -> void:
	_polygon2d.visible = false
	_line2d.visible = true
	_line2d.material = null
	_line2d.default_color = color
	_line2d.points = polygon
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## 線形グラデーションの塗りつぶしとしてサムネをアップデートする
func _update_fill_thumbnail_linear_gradient(material: LinearGradientPaintMaterial) -> void:
	_polygon2d.visible = true
	var mat := linear_gradient_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("gradient_texture", material.gradient_texture)
	mat.set_shader_parameter("start_point", material.start_point / Main.document_size)
	mat.set_shader_parameter("end_point", material.end_point / Main.document_size)
	_polygon2d.material = mat
	_polygon2d.polygon = vertices
	_polygon2d.polygons = thumbnail_indices
	_polygon2d.color = Color.WHITE
	_line2d.visible = false
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## 線形グラデーションのラインとしてサムネをアップデートする
func _update_line_thumbnail_linear_gradient(material: LinearGradientPaintMaterial) -> void:
	_polygon2d.visible = false
	_line2d.visible = true
	var mat := linear_gradient_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("gradient_texture", material.gradient_texture)
	mat.set_shader_parameter("start_point", material.start_point / Main.document_size)
	mat.set_shader_parameter("end_point", material.end_point / Main.document_size)
	_line2d.material = mat
	_line2d.points = polygon
	_line2d.default_color = Color.WHITE
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## 放射グラデーションの塗りつぶしとしてサムネをアップデートする
func _update_fill_thumbnail_radial_gradient(material: RadialGradientPaintMaterial) -> void:
	_polygon2d.visible = true
	var mat := radial_gradient_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("gradient_texture", material.gradient_texture)
	mat.set_shader_parameter("center_point", material.center_point / Main.document_size)
	mat.set_shader_parameter("handle_1_point", material.handle_1_point / Main.document_size)
	mat.set_shader_parameter("handle_2_point", material.handle_2_point / Main.document_size)
	_polygon2d.material = mat
	_polygon2d.polygon = vertices
	_polygon2d.polygons = thumbnail_indices
	_polygon2d.color = Color.WHITE
	_line2d.visible = false
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## 放射グラデーションのラインとしてサムネをアップデートする
func _update_line_thumbnail_radial_gradient(material: RadialGradientPaintMaterial) -> void:
	_polygon2d.visible = false
	_line2d.visible = true
	var mat := radial_gradient_material.duplicate() as ShaderMaterial
	mat.set_shader_parameter("gradient_texture", material.gradient_texture)
	mat.set_shader_parameter("center_point", material.center_point / Main.document_size)
	mat.set_shader_parameter("handle_1_point", material.handle_1_point / Main.document_size)
	mat.set_shader_parameter("handle_2_point", material.handle_2_point / Main.document_size)
	_line2d.material = mat
	_line2d.points = polygon
	_line2d.default_color = Color.WHITE
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## マテリアルが存在しない状態で塗りつぶしとしてサムネをアップデートする
func _update_fill_thumbnail_missing() -> void:
	_polygon2d.visible = true
	_polygon2d.material = missing_material
	_polygon2d.polygon = vertices
	_polygon2d.polygons = thumbnail_indices
	_polygon2d.color = Color.WHITE
	_line2d.visible = false
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## マテリアルが存在しない状態でラインとしてサムネをアップデートする
func _update_line_thumbnail_missing() -> void:
	_polygon2d.visible = false
	_line2d.visible = true
	_line2d.material = missing_material
	_line2d.points = polygon
	_line2d.default_color = Color.WHITE
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func update_thumbnail() -> void:
	if _is_line:
		if _material is ColorPaintMaterial:
			var color_material := _material as ColorPaintMaterial
			_update_line_thumbnail_color(color_material.color)
		elif _material is LinearGradientPaintMaterial:
			var gradient_material := _material as LinearGradientPaintMaterial
			_update_line_thumbnail_linear_gradient(gradient_material)
		elif _material is RadialGradientPaintMaterial:
			var gradient_material := _material as RadialGradientPaintMaterial
			_update_line_thumbnail_radial_gradient(gradient_material)
		else:
			_update_line_thumbnail_missing()
	else:
		if _material is ColorPaintMaterial:
			var color_material := _material as ColorPaintMaterial
			_update_fill_thumbnail_color(color_material.color)
		elif _material is LinearGradientPaintMaterial:
			var gradient_material := _material as LinearGradientPaintMaterial
			_update_fill_thumbnail_linear_gradient(gradient_material)
		elif _material is RadialGradientPaintMaterial:
			var gradient_material := _material as RadialGradientPaintMaterial
			_update_fill_thumbnail_radial_gradient(gradient_material)
		else:
			_update_fill_thumbnail_missing()
	Main.emit_update_layer_list_tab()


## polygonの形状の（再）計算。
func recalculate_polygon() -> void:
	if control_points.size() < 2:
		polygon = PackedVector2Array()
		vertices = PackedVector2Array()
		indices = PackedInt32Array()
		thumbnail_indices = []
		line_vertices = PackedVector2Array()
		line_indices = PackedInt32Array()
		segments = []
	elif control_points.size() == 2:
		polygon = control_points.duplicate()
		vertices = polygon.duplicate()
		indices = PackedInt32Array([0, 1])
		thumbnail_indices = []

		var line_polygons: Array[PackedVector2Array] = Geometry2D.offset_polyline(polygon, _line_width / 2.0, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
		var line_triangulate := ShapeUtil.triangulate_polygons_non_zero(line_polygons)
		line_vertices = line_triangulate.vertices
		line_indices = line_triangulate.indices

		segments = [control_points.duplicate()]
	else:
		var ppwpath := PPWPath.new()
		ppwpath.control_points = control_points
		ppwpath.weights = weights
		ppwpath.phis = phis
		ppwpath.psis = psis
		ppwpath.is_closed = closed

		var ppwpoly := PPWCurve.convert(ppwpath)
		polygon = ppwpoly.polygon

		var fill_triangulate := ShapeUtil.triangulate(polygon)
		vertices = fill_triangulate.vertices
		indices = fill_triangulate.indices

		thumbnail_indices = []
		for i in indices.size():
			if i % 3 == 0:
				thumbnail_indices.append(PackedInt32Array())
			thumbnail_indices[-1].append(indices[i])

		var line_polygons: Array[PackedVector2Array] = Geometry2D.offset_polyline(polygon, _line_width / 2.0, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
		var line_triangulate := ShapeUtil.triangulate_polygons_non_zero(line_polygons)
		line_vertices = line_triangulate.vertices
		line_indices = line_triangulate.indices

		segments = ppwpoly.segments

	_request_parent_composite()

	if _change_controls_count:
		_change_controls_count = false
		Main.emit_path_shape_changed()

	Main.emit_update_control_segments()


## 再計算を反映させる。
func schedule_recalculate() -> void:
	# このフレームで再計算の予約をしたフラグをいれる
	_need_recalculate_polygon = true


## ControlPointの追加。
func add_control_point(pos: Vector2) -> void:
	control_points.append(pos)
	weights.append(1.0)
	if control_points.size() > 1:
		if closed:
			phis.remove_at(phis.size() - 1)
			phis.append(NEW_PHI_VALUE)
			phis.append(NEW_PHI_VALUE)
			psis.remove_at(psis.size() - 1)
			psis.append(NEW_PSI_VALUE)
			psis.append(NEW_PSI_VALUE)
		else:
			phis.append(NEW_PHI_VALUE)
			psis.append(NEW_PSI_VALUE)
	if closed:
		for i in psis.size():
			psis[i] = 0.0
	else:
		for i in psis.size():
			if i == 0:
				psis[i] = 2.0
			elif i == psis.size() - 1:
				psis[i] = -2.0
			else:
				psis[i] = 0.0
	_change_controls_count = true
	schedule_recalculate()


## ControlPointの挿入。
func insert_control_point(pos: Vector2, index: int) -> void:
	control_points.insert(index, pos)
	weights.insert(index, 1.0)
	phis.remove_at(index - 1)
	phis.insert(index - 1, NEW_PHI_VALUE)
	phis.insert(index, NEW_PHI_VALUE)
	psis.remove_at(index - 1)
	psis.insert(index - 1, NEW_PSI_VALUE)
	psis.insert(index, NEW_PSI_VALUE)
	if not closed and index == 1:
		psis[0] = 2.0
	if not closed and index == psis.size() - 1:
		psis[psis.size() - 1] = -2.0
	_change_controls_count = true
	schedule_recalculate()


## ControlPointの除去。
func delete_control_point(index: int) -> void:
	if index == 0 or index == 1:
		control_points.remove_at(index)
		weights.remove_at(index)
		phis.remove_at(0)
		psis.remove_at(0)
		# openの場合最初のpsiを端点のものに上書き
		if not closed:
			psis[0] = 2.0
	else:
		control_points.remove_at(index)
		weights.remove_at(index)
		phis.remove_at(index - 1)
		psis.remove_at(index - 1)
		# openで最後もしくは最後から2番目を消した場合にpsiを端点のものに上書き
		if not closed and (index == psis.size() or index - 1 == psis.size()):
			psis[psis.size() - 1] = -2.0
	_change_controls_count = true
	schedule_recalculate()


## ControlPointの移動。
func move_control_point(pos: Vector2, index: int) -> void:
	if not control_points[index].is_equal_approx(pos):
		control_points[index] = pos
		schedule_recalculate()


## weightの変更。
func change_weight(weight: float, index: int) -> void:
	if not weights[index] == weight:
		weights[index] = weight
		schedule_recalculate()


## phiの変更。
func change_phi(phi: float, index: int) -> void:
	if not phis[index] == phi:
		phis[index] = phi
		schedule_recalculate()


## psiの変更。
func change_psi(psi: float, index: int) -> void:
	if not psis[index] == psi:
		psis[index] = psi
		schedule_recalculate()


## open/closedの変更。
func change_closed(is_close: bool) -> void:
	if is_close and not closed:
		# closedに変化したときには最初と最後のpsiの値を0にリセットしてからつなげる
		if psis.size() > 1:
			psis[0] = 0.0
			psis[psis.size() - 1] = 0.0

		phis.append(1.0)
		psis.append(0.0)
	elif not is_close and closed:
		phis.remove_at(phis.size() - 1)
		psis.remove_at(psis.size() - 1)

		# openに変化したときは最初と最後のパスのpsiを2.0と-2.0にする
		if psis.size() > 1:
			psis[0] = 2.0
			psis[psis.size() - 1] = -2.0
	closed = is_close
	_change_controls_count = true
	schedule_recalculate()


## booleanの変更
func change_boolean(new_boolean: Boolean) -> void:
	boolean = new_boolean
	_request_parent_composite()


## 表示状態を更新する
func update_visible(new_visible: bool) -> void:
	visible = new_visible
	Main.layers.update_parent_visible.call_deferred()
	_request_parent_composite()


## ロック状態を更新する。
func update_locked(new_locked: bool) -> void:
	locked = new_locked


## ロック状態かどうかを返す。
func is_locked() -> bool:
	if locked or parent_locked:
		return true
	return false


## 線の太さを設定する。
func set_line_width(line_width: float) -> void:
	_line_width = line_width
	_line2d.width = line_width


## 線のポリゴン形状を再計算する。
func update_line_polygon() -> void:
	var line_polygons: Array[PackedVector2Array] = Geometry2D.offset_polyline(polygon, _line_width / 2.0, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
	var line_triangulate := ShapeUtil.triangulate_polygons_non_zero(line_polygons)
	line_vertices = line_triangulate.vertices
	line_indices = line_triangulate.indices


## このパスが線か塗りかを指定する。
func set_is_line(is_line: bool) -> void:
	_is_line = is_line


## このパスが線かどうかを取得する。
func get_is_line() -> bool:
	return _is_line


func set_material(material: PaintMaterial) -> void:
	_material = material


## SubViewportのテクスチャを取得する。
func get_path_texture() -> Texture2D:
	return _sub_viewport.get_texture()


## ドキュメントサイズの変更を適用する。
func change_document_size(new_document_size: Vector2, anchor: PaintLayer.ScaleAnchor) -> void:
	var prev_document_size := Main.document_size

	# サムネ
	if new_document_size.x > new_document_size.y:
		_sub_viewport.size = Vector2(38, 38 * new_document_size.y / new_document_size.x)
	else:
		_sub_viewport.size = Vector2(38 * new_document_size.x / new_document_size.y, 38)
	_sub_viewport.size_2d_override = new_document_size
	_sub_viewport.size_2d_override_stretch = true

	# パス
	var delta_x := 0.0
	var delta_y := 0.0
	match anchor:
		PaintLayer.ScaleAnchor.TopLeft:
			pass
		PaintLayer.ScaleAnchor.TopCenter:
			delta_x = (new_document_size.x - prev_document_size.x) / 2
		PaintLayer.ScaleAnchor.TopRight:
			delta_x = new_document_size.x - prev_document_size.x
		PaintLayer.ScaleAnchor.Left:
			delta_y = (new_document_size.y - prev_document_size.y) / 2
		PaintLayer.ScaleAnchor.Center:
			delta_x = (new_document_size.x - prev_document_size.x) / 2
			delta_y = (new_document_size.y - prev_document_size.y) / 2
		PaintLayer.ScaleAnchor.Right:
			delta_x = new_document_size.x - prev_document_size.x
			delta_y = (new_document_size.y - prev_document_size.y) / 2
		PaintLayer.ScaleAnchor.BottomLeft:
			delta_y = new_document_size.y - prev_document_size.y
		PaintLayer.ScaleAnchor.BottomCenter:
			delta_x = (new_document_size.x - prev_document_size.x) / 2
			delta_y = new_document_size.y - prev_document_size.y
		PaintLayer.ScaleAnchor.BottomRight:
			delta_x = new_document_size.x - prev_document_size.x
			delta_y = new_document_size.y - prev_document_size.y

	for i in control_points.size():
		control_points[i] += Vector2(delta_x, delta_y)

	for i in polygon.size():
		polygon[i] += Vector2(delta_x, delta_y)
	for i in vertices.size():
		vertices[i] += Vector2(delta_x, delta_y)
	for i in line_vertices.size():
		line_vertices[i] += Vector2(delta_x, delta_y)
	for i in segments.size():
		for j in segments[i].size():
			segments[i][j] += Vector2(delta_x, delta_y)


## 親のcompositeを要求する。
func _request_parent_composite() -> void:
	@warning_ignore("unsafe_cast")
	var parent := parent_path_layer.get_ref() as PathPaintLayer
	if parent:
		parent.set_need_composite()


## パスを初期化する
func clear_path() -> void:
	parent_path_layer = null
	id = uuid_util.v4()
	visible = true
	locked = false
	control_points = PackedVector2Array()
	weights = PackedFloat32Array()
	phis = PackedFloat32Array()
	psis = PackedFloat32Array()
	closed = false
	polygon = PackedVector2Array()
	vertices = PackedVector2Array()
	indices = PackedInt32Array()
	thumbnail_indices = []
	line_vertices = PackedVector2Array()
	line_indices = PackedInt32Array()
	segments = []
	boolean = Boolean.Union
	path_name = ""


## パスを作成する。
static func new_path(use_new_path_name: bool = true) -> Path:
	if not _path_scene:
		_path_scene = load("res://scenes/node/path.tscn")
	var path := _path_scene.instantiate() as Path
	path.change_document_size.call_deferred(Main.document_size, PaintLayer.ScaleAnchor.Center)

	if use_new_path_name:
		path.path_name = Main.layers.get_new_path_name()

	var scene_tree := Engine.get_main_loop() as SceneTree
	var root := scene_tree.root
	var sub_viewport_root := root.get_node("/root/App/LayerSubViewports")
	sub_viewport_root.add_child(path)
	return path

class_name DocumentPath
extends Resource

## パスのブーリアンの列挙子
enum Boolean {
	Union,
	Diff,
	Intersect,
	Xor,
}


## パスのid。
@export var id: String

## パスが表示されているかどうか。
@export var visible: bool
## パスがロックされているかどうか。
@export var locked: bool
## closed pathかどうか。
@export var closed: bool
## パスのブーリアンの種類。
@export var boolean: Boolean
## パスの名前。
@export var path_name: String

## ControlPointの配列。
@export var control_points: String
## weightの配列。
@export var weights: String
## phiの配列。
@export var phis: String
## psiの配列。
@export var psis: String
## パスのポリゴン形状のPackedVector2Array。
@export var polygon: String
## polygonの頂点列のPackedVector2Array。
@export var vertices: String
## polygonのindicesのPackedInt32Array。
@export var indices: String
## polygonのthumbnail_indicesのPackedInt32Array。
@export var thumbnail_indices: Array[String]
## polygonの頂点列のPackedVector2Array。
@export var line_vertices: String
## polygonのindicesのPackedInt32Array。
@export var line_indices: String
## segmentsのPackedVector2Arrayの配列。
@export var segments: Array[String]

## ControlPointの配列。
var control_points_raw: PackedVector2Array = PackedVector2Array()
## weightの配列。
var weights_raw: PackedFloat32Array = PackedFloat32Array()
## phiの配列。
var phis_raw: PackedFloat32Array = PackedFloat32Array()
## psiの配列。
var psis_raw: PackedFloat32Array = PackedFloat32Array()
## パスのポリゴン形状のPackedVector2Array。
var polygon_raw: PackedVector2Array = PackedVector2Array()
## polygonの頂点列のPackedVector2Array。
var vertices_raw: PackedVector2Array = PackedVector2Array()
## polygonのindicesのPackedInt32Array。
var indices_raw: PackedInt32Array = PackedInt32Array()
## パスのサムネ用のindices
var thumbnail_indices_raw: Array[PackedInt32Array] = []
## polygonの頂点列のPackedVector2Array。
var line_vertices_raw: PackedVector2Array = PackedVector2Array()
## polygonのindicesのPackedInt32Array。
var line_indices_raw: PackedInt32Array = PackedInt32Array()
## segmentsのPackedVector2Arrayの配列。
var segments_raw: Array[PackedVector2Array] = []

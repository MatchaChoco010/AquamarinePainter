class_name Document
extends Resource


## レイヤーのリスト。
@export var layers: Array[DocumentLayer]
## ドキュメントのサイズ。
@export var document_size: Vector2i

## マテリアルのリスト。
@export var materials: Array[DocumentMaterial]
## 新規レイヤー作成時の塗りのマテリアルid。
@export var new_path_layer_fill_material_id: String
## 新規レイヤー作成時の線のマテリアルid。
@export var new_path_layer_line_material_id: String
## 新規レイヤー作成時の塗りのマテリアルid。
@export var new_fill_layer_material_id: String

## 現在選択されているレイヤーのidの配列。
@export var selected_layers: Array[String]
## 現在選択されているパスのidの配列。
@export var selected_paths: Array[String]

## 最後に選択したPaintLayerのid。存在しない場合は空文字。
@export var last_selected_layer: String
## 最後に選択したPathのid。存在しない場合は空文字。
@export var last_selected_path: String
## 最後に選択したPaintLayerもしくはPathのid。存在しない場合は空文字。
@export var last_selected_item: String

## 現在描画先になっているPathPaintLayerのid。存在しない場合は空文字。
@export var drawing_path_layer: String

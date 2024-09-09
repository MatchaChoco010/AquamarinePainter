class_name DocumentLayerPath
extends DocumentLayer

## レイヤーのid。
@export var id: String

## 下のレイヤーでクリップされているかどうか。
@export var clipped: bool
## レイヤーが表示されているかどうか。
@export var visible: bool
## レイヤーがロックされているかどうか。
@export var locked: bool
## レイヤーのブレンドモード。
@export var blend_mode: DocumentLayer.BlendMode
## alphaの%値
@export var alpha: int
## レイヤーの名前。
@export var layer_name: String

## fillするかどうか。
@export var filled: bool
## fillの色。
@export var fill_material_id: String
## outlineのオンオフ。
@export var outlined: bool
## outlineの色。
@export var outline_material_id: String
## outlineの幅。
@export var outline_width: float
## 折りたたまれているか。
@export var collapsed: bool

## レイヤーの保持するパスの配列。
@export var paths: Array[DocumentPath]

class_name DocumentLayerGroup
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

## 折りたたまれているか。
@export var collapsed: bool

## このグループレイヤーの子要素のレイヤー
@export var child_layers: Array[DocumentLayer] = []

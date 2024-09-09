## レイヤーを表す基底クラス。
class_name PaintLayer
extends Node


const uuid_util = preload('res://addons/uuid/uuid.gd')

## レイヤーのID。
var id: String

## 下のレイヤーでクリップされているかどうか。
var clipped: bool = false

## レイヤーが表示されているかどうか。
var visible: bool = true
## 親のレイヤーが表示されているかどうか。
var parent_visible: bool = true

## レイヤーがロックされているかどうか。
var locked: bool = false
## 親のレイヤーがロックされているかどうか。
var parent_locked: bool = false


## このレイヤーのコンポジットが必要かどうか。
var need_composite: bool = false
## このレイヤーの親のコンポジットが必要かどうか。
var need_parent_composite: bool = false
## コンポジットをする場合にオンにするマーク。
var mark_composite: bool = false

## レイヤーのブレンドモードの列挙子。
enum BlendMode {
	Normal,
	Add,
	Multiply,
	Screen,
	Overlay,
}

## レイヤーのブレンドモード。
var blend_mode: BlendMode = BlendMode.Normal

## alphaの%値
var alpha: int = 100

## レイヤーの名前。
var layer_name: String = tr("LAYER")

## レイヤーの拡大縮小の基準の列挙子。
enum ScaleAnchor {
	TopLeft,
	TopCenter,
	TopRight,
	Left,
	Center,
	Right,
	BottomLeft,
	BottomCenter,
	BottomRight,
}


func _init() -> void:
	id = uuid_util.v4()


## 表示状態を更新する。
func update_visible(new_visible: bool) -> void:
	visible = new_visible
	need_parent_composite = true
	Main.layers.update_parent_visible()


## クリッピング状態を変更する。
func update_clipped(new_clipped: bool) -> void:
	clipped = new_clipped
	need_parent_composite = true


## ブレンドモードを更新する。
func update_blend_mode(new_blend_mode: BlendMode) -> void:
	blend_mode = new_blend_mode
	need_parent_composite = true


## アルファを更新する。
func update_alpha(new_alpha: int) -> void:
	alpha = new_alpha
	need_parent_composite = true


## ロック状態を更新する。
func update_locked(new_locked: bool) -> void:
	locked = new_locked


## ロック状態かどうかを返す。
func is_locked() -> bool:
	if locked or parent_locked:
		return true
	return false

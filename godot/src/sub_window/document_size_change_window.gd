class_name DocumentSizeChangeWindow
extends Window


## ドキュメントのサイズ変更が押されたときのシグナル。
signal on_change_document_size(document_size: Vector2, anchor: PaintLayer.ScaleAnchor)

@onready var _width_spin_box: SpinBox = %WidthSpinBox
@onready var _height_spin_box: SpinBox = %HeightSpinBox
@onready var _top_left_rect: ColorRect = %TopLeftButton/ColorRect
@onready var _top_rect: ColorRect = %TopButton/ColorRect
@onready var _top_right_rect: ColorRect = %TopRightButton/ColorRect
@onready var _left_rect: ColorRect = %LeftButton/ColorRect
@onready var _center_rect: ColorRect = %CenterButton/ColorRect
@onready var _right_rect: ColorRect = %RightButton/ColorRect
@onready var _bottom_left_rect: ColorRect = %BottomLeftButton/ColorRect
@onready var _bottom_rect: ColorRect = %BottomButton/ColorRect
@onready var _bottom_right_rect: ColorRect = %BottomRightButton/ColorRect


var _anchor: PaintLayer.ScaleAnchor = PaintLayer.ScaleAnchor.Center


## 表示するドキュメントサイズとアンカーを変える。
func set_document_size_and_anchor(document_size: Vector2, anchor: PaintLayer.ScaleAnchor) -> void:
	_width_spin_box.value = document_size.x
	_height_spin_box.value = document_size.y
	_update_anchor(anchor)


## アンカーボタンを見た目に反映する。
func _update_anchor(anchor: PaintLayer.ScaleAnchor) -> void:
	_anchor = anchor

	_top_left_rect.color = Color.GRAY
	_top_rect.color = Color.GRAY
	_top_right_rect.color = Color.GRAY
	_left_rect.color = Color.GRAY
	_center_rect.color = Color.GRAY
	_right_rect.color = Color.GRAY
	_bottom_left_rect.color = Color.GRAY
	_bottom_rect.color = Color.GRAY
	_bottom_right_rect.color = Color.GRAY
	match anchor:
		PaintLayer.ScaleAnchor.TopLeft:
			_top_left_rect.color = Color.WHITE
		PaintLayer.ScaleAnchor.TopCenter:
			_top_rect.color = Color.WHITE
		PaintLayer.ScaleAnchor.TopRight:
			_top_right_rect.color = Color.WHITE
		PaintLayer.ScaleAnchor.Left:
			_left_rect.color = Color.WHITE
		PaintLayer.ScaleAnchor.Center:
			_center_rect.color = Color.WHITE
		PaintLayer.ScaleAnchor.Right:
			_right_rect.color = Color.WHITE
		PaintLayer.ScaleAnchor.BottomLeft:
			_bottom_left_rect.color = Color.WHITE
		PaintLayer.ScaleAnchor.BottomCenter:
			_bottom_rect.color = Color.WHITE
		PaintLayer.ScaleAnchor.BottomRight:
			_bottom_right_rect.color = Color.WHITE


## サイズ変更ボタンが押された際のコールバック。
func _on_create_button_pressed() -> void:
	hide()
	on_change_document_size.emit(Vector2(_width_spin_box.value, _height_spin_box.value), _anchor)


## キャンセルボタンが押された際のコールバック。
func _on_cancel_button_pressed() -> void:
	hide()


## windowのcloseがリクエストされた際のコールバック。
func _on_close_requested() -> void:
	hide()


## サイズの縦横入れ替えのコールバック。
func _on_switch_button_pressed() -> void:
	var prev_size := Vector2(_width_spin_box.value, _height_spin_box.value)
	_width_spin_box.value = prev_size.y
	_height_spin_box.value = prev_size.x


## 左上のアンカーボタンが押された際のコールバック。
func _on_top_left_button_pressed() -> void:
	_update_anchor(PaintLayer.ScaleAnchor.TopLeft)


## 上のアンカーボタンが押された際のコールバック。
func _on_top_button_pressed() -> void:
	_update_anchor(PaintLayer.ScaleAnchor.TopCenter)


## 右上のアンカーボタンが押された際のコールバック。
func _on_top_right_button_pressed() -> void:
	_update_anchor(PaintLayer.ScaleAnchor.TopRight)


## 左のアンカーボタンが押された際のコールバック。
func _on_left_button_pressed() -> void:
	_update_anchor(PaintLayer.ScaleAnchor.Left)


## 中央のアンカーボタンが押された際のコールバック。
func _on_center_button_pressed() -> void:
	_update_anchor(PaintLayer.ScaleAnchor.Center)


## 右のアンカーボタンが押された際のコールバック。
func _on_right_button_pressed() -> void:
	_update_anchor(PaintLayer.ScaleAnchor.Right)


## 左下のアンカーボタンが押された際のコールバック。
func _on_bottom_left_button_pressed() -> void:
	_update_anchor(PaintLayer.ScaleAnchor.BottomLeft)


## 下のアンカーボタンが押された際のコールバック。
func _on_bottom_button_pressed() -> void:
	_update_anchor(PaintLayer.ScaleAnchor.BottomCenter)


## 右下のアンカーボタンが押された際のコールバック。
func _on_bottom_right_button_pressed() -> void:
	_update_anchor(PaintLayer.ScaleAnchor.BottomRight)

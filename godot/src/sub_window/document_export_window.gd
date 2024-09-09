class_name DocumentExportWindow
extends Window


## ドキュメントの作成が押されたときのシグナル。
signal on_export_document(document_size: Vector2)

@onready var _width_spin_box: SpinBox = %WidthSpinBox
@onready var _height_spin_box: SpinBox = %HeightSpinBox


## 表示するドキュメントサイズを変える。
func set_document_size(document_size: Vector2) -> void:
	_width_spin_box.value = document_size.x
	_height_spin_box.value = document_size.y


## 作成ボタンが押された際のコールバック。
func _on_create_button_pressed() -> void:
	hide()
	on_export_document.emit(Vector2(_width_spin_box.value, _height_spin_box.value))


## キャンセルボタンが押された際のコールバック。
func _on_cancel_button_pressed() -> void:
	hide()


## windowのcloseがリクエストされた際のコールバック。
func _on_close_requested() -> void:
	hide()


## 幅の値が変更された際のコールバック。
func _on_width_spin_box_value_changed(value: float) -> void:
	var new_width := roundi(value)
	var new_height := int(Main.document_size.y * new_width / Main.document_size.x)
	_height_spin_box.set_value_no_signal(new_height)


## 高さの値が変更された際のコールバック。
func _on_height_spin_box_value_changed(value: float) -> void:
	var new_height := roundi(value)
	var new_width := int(Main.document_size.x * new_height / Main.document_size.y)
	_width_spin_box.set_value_no_signal(new_width)

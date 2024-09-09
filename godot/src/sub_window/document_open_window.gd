class_name DocumentOpenWindow
extends Window


## ドキュメントの作成が押されたときのシグナル。
signal on_create_document(document_size: Vector2)

@onready var _preset_menu: MenuButton = %MenuButton
@onready var _width_spin_box: SpinBox = %WidthSpinBox
@onready var _height_spin_box: SpinBox = %HeightSpinBox


func _ready() -> void:
	_preset_menu.get_popup().id_pressed.connect(_on_preset)


## 表示するドキュメントサイズを変える。
func set_document_size(document_size: Vector2) -> void:
	_width_spin_box.value = document_size.x
	_height_spin_box.value = document_size.y


## プリセットの選択。
func _on_preset(id: int) -> void:
	match id:
		0:
			_width_spin_box.value = 800
			_height_spin_box.value = 600
		1:
			_width_spin_box.value = 1024
			_height_spin_box.value = 600
		2:
			_width_spin_box.value = 1024
			_height_spin_box.value = 768
		3:
			_width_spin_box.value = 1280
			_height_spin_box.value = 720
		4:
			_width_spin_box.value = 1280
			_height_spin_box.value = 960
		5:
			_width_spin_box.value = 1600
			_height_spin_box.value = 900
		6:
			_width_spin_box.value = 1600
			_height_spin_box.value = 1200
		7:
			_width_spin_box.value = 1920
			_height_spin_box.value = 1080


## 作成ボタンが押された際のコールバック。
func _on_create_button_pressed() -> void:
	hide()
	on_create_document.emit(Vector2(_width_spin_box.value, _height_spin_box.value))


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

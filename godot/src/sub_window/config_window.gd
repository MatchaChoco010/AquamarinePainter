class_name ConfigWindow
extends Window


@onready var _language_menu_button: MenuButton = %LanguageMenuButton
@onready var _auto_save_check_box: CheckBox = %AutoSaveCheckBox
@onready var _auto_save_spin_box: SpinBox = %AutoSaveSpinBox


func _ready() -> void:
	_language_menu_button.get_popup().id_pressed.connect(_on_language_menu_button_id_pressed)

## 設定値を表示する。
func show_config() -> void:
	var config := ConfigFile.new()

	var ret := config.load("user://config.cfg")
	if ret == OK:
		if config.has_section_key("auto_save", "enabled"):
			_auto_save_check_box.button_pressed = config.get_value("auto_save", "enabled")
		if config.has_section_key("auto_save", "interval"):
			_auto_save_spin_box.value = config.get_value("auto_save", "interval")

	show()


## 言語が変更されたときの処理。
func _on_language_menu_button_id_pressed(id: int) -> void:
	var config := ConfigFile.new()
	config.load("user://config.cfg")
	match id:
		0:
			TranslationServer.set_locale("ja")
			config.set_value("language", "locale", "ja")
		1:
			TranslationServer.set_locale("en")
			config.set_value("language", "locale", "en")
	config.save("user://config.cfg")
	Main.emit_locale_changed()


## オートセーブのチェックボックスをトグルしたときの処理。
func _on_auto_save_check_box_toggled(toggled_on: bool) -> void:
	var config := ConfigFile.new()

	config.load("user://config.cfg")
	config.set_value("auto_save", "enabled", toggled_on)
	config.save("user://config.cfg")

	_auto_save_check_box.button_pressed = toggled_on
	Main.auto_save_enabled = toggled_on


## オートセーブの間隔を変更したときの処理。
func _on_auto_save_spin_box_value_changed(value: float) -> void:
	var config := ConfigFile.new()

	config.load("user://config.cfg")
	config.set_value("auto_save", "interval", int(value))
	config.save("user://config.cfg")

	_auto_save_spin_box.value = int(value)
	Main.auto_save_interval = int(value)


## ウィンドウが閉じられるときの処理。
func _on_close_requested() -> void:
	hide()


## 閉じるボタンが押されたときの処理。
func _on_close_button_pressed() -> void:
	hide()

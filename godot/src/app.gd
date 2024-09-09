class_name App
extends PanelContainer


@onready var _file_menu_button: MenuButton = %FileMenuButton
@onready var _edit_menu_button: MenuButton = %EditMenuButton
@onready var _tool_menu_button: MenuButton = %ToolMenuButton
@onready var _document_open_window: DocumentOpenWindow = %DocumentOpenWindow
@onready var _document_export_window: DocumentExportWindow = %DocumentExportWindow
@onready var _document_size_change_window: DocumentSizeChangeWindow = %DocumentSizeChangeWindow
@onready var _configwindow: ConfigWindow = %ConfigWindow
@onready var _licenses_window: LicensesWindow = %LicensesWindow
@onready var _file_dialog: FileDialog = %FileDialog
@onready var _close_confirm_dialog: ConfirmationDialog = %CloseConfirmationDialog
@onready var _canvas_tab: CanvasTab = %CanvasTab
@onready var _layer_list_tab: LayerListTab = %Layer
@onready var _layer_setting_tab: LayerSettingTab = %LayerSetting
@onready var _material_list_tab: MaterialListTab = %MaterialList

## 破棄するかのダイアログの結果のシグナル。
signal on_confirm_close(discard: bool)


func _ready() -> void:
	DisplayServer.window_set_title("AquamarinePainter")
	Main.on_document_dirty_changed.connect(_document_dirty_changed)

	_file_menu_button.get_popup().id_pressed.connect(_file_menu)
	_edit_menu_button.get_popup().id_pressed.connect(_edit_menu)
	_tool_menu_button.get_popup().id_pressed.connect(_tool_menu)

	_close_confirm_dialog.confirmed.connect(func() -> void: on_confirm_close.emit(true))
	_close_confirm_dialog.canceled.connect(func() -> void: on_confirm_close.emit(false))

	# 閉じるボタンをしても閉じないようにする
	get_tree().set_auto_accept_quit(false)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("save"):
		_document_save()
	elif event.is_action_pressed("save_as"):
		_document_save_as()
	elif event.is_action_pressed("redo"):
		Main.redo_history()
	elif event.is_action_pressed("undo"):
		Main.undo_hisotry()
	elif event.is_action_pressed("ui_copy"):
		Main.copy_manager.copy()
	elif event.is_action_pressed("ui_paste"):
		Main.materials.paste_copied_material()
		Main.layers.paste_copied_layers()


func _notification(what: int) -> void:
	# ウィンドウの閉じるボタンが押されたときの確認ダイアログ
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not Main.document_opened or not Main.document_dirty:
			get_tree().quit()
		else:
			_close_confirm_dialog.show()
			if await on_confirm_close:
				get_tree().quit()


## 操作中かどうかを計算する。
func get_is_manipulating() -> bool:
	var is_manipulating := false
	is_manipulating = is_manipulating or _canvas_tab.get_manipulating()
	is_manipulating = is_manipulating or _material_list_tab.is_manipulate_color()
	is_manipulating = is_manipulating or _layer_list_tab.is_manipulating_alpha()
	is_manipulating = is_manipulating or _layer_setting_tab.is_manipulating_line_width()
	return is_manipulating


## ドキュメントのdirtyが切り替わったときに呼び出すコールバック。
func _document_dirty_changed() -> void:
	if Main.document_file_path.is_empty():
		DisplayServer.window_set_title("AquamarinePainter")
	else:
		var filename := Main.document_file_path.split("/")[-1]
		if Main.document_dirty:
			filename = "* " + filename
		DisplayServer.window_set_title(filename + " - AquamarinePainter")


## ファイルメニューのコールバック。
func _file_menu(id: int) -> void:
	match id:
		0:
			# 新規ドキュメント
			if not Main.document_opened or not Main.document_dirty:
				_document_open_window.set_document_size(Vector2(800, 600))
				_document_open_window.show()
			else:
				_close_confirm_dialog.show()
				if await on_confirm_close:
					_document_open_window.set_document_size(Vector2(800, 600))
					_document_open_window.show()
		1:
			# ドキュメントを開く
			if not Main.document_opened or not Main.document_dirty:
				_document_open()
			else:
				_close_confirm_dialog.show()
				if await on_confirm_close:
					_document_open()
		2:
			# 上書き保存
			_document_save()
		3:
			# 別名で保存
			_document_save_as()
		4:
			# ドキュメントを閉じる
			if not Main.document_dirty:
				Main.close_document()
			else:
				_close_confirm_dialog.show()
				if await on_confirm_close:
					Main.close_document()
		6:
			# エクスポート
			if Main.document_opened:
				_document_export_window.set_document_size(Main.document_size)
				_document_export_window.show()


## 編集メニューのコールバック。
func _edit_menu(id: int) -> void:
	match id:
		0:
			# 元に戻す
			Main.undo_hisotry()
		1:
			# やり直し
			Main.redo_history()
		3:
			# ドキュメントサイズの変更
			if Main.document_opened:
				_document_size_change_window.set_document_size_and_anchor(
					Main.document_size, PaintLayer.ScaleAnchor.Center)
				_document_size_change_window.show()


## ツールメニューのコールバック。
func _tool_menu(id: int) -> void:
	match id:
		0:
			# 環境設定
			_configwindow.show_config()
		1:
			# ライセンス
			_licenses_window.show()


## ドキュメントを読み込む。
func _document_open() -> void:
	_file_dialog.clear_filters()
	_file_dialog.add_filter("*.ampi", "AquamarinePainter Document")
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.current_file = ""
	_file_dialog.show()
	if not _file_dialog.current_file.is_empty():
		Main.load_document(_file_dialog.current_file)


## ドキュメントを上書き保存する。
func _document_save() -> void:
	Main.save_document()


## ドキュメントを別名で保存する。
func _document_save_as() -> void:
	if not Main.document_opened:
		return
	_file_dialog.clear_filters()
	_file_dialog.add_filter("*.ampi", "AquamarinePainter Document")
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file_dialog.current_file = ""
	_file_dialog.show()
	if not _file_dialog.current_file.is_empty():
		Main.save_as_document(_file_dialog.current_file)


## ドキュメントを新しく作成するコールバック。
func _on_document_open_window_on_create_document(document_size: Vector2) -> void:
	_file_dialog.clear_filters()
	_file_dialog.add_filter("*.ampi", "AquamarinePainter Document")
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file_dialog.current_file = ""
	_file_dialog.show()
	if not _file_dialog.current_file.is_empty():
		Main.create_document(document_size, _file_dialog.current_file)


## ドキュメントをpngでエクスポートする。
func _on_document_export_window_on_export_document(document_size: Vector2) -> void:
	_file_dialog.clear_filters()
	_file_dialog.add_filter("*.png", "Portable Network Graphics")
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file_dialog.current_file = ""
	_file_dialog.show()
	if not _file_dialog.current_file.is_empty():
		Main.export_document(_file_dialog.current_file, document_size)


## ドキュメントサイズ変更ウィンドウのコールバック。
func _on_document_size_change_window_on_change_document_size(
	document_size: Vector2, anchor: PaintLayer.ScaleAnchor) -> void:
	Main.copy_manager.change_document_size(document_size, anchor)
	Main.materials.change_document_size(document_size, anchor)
	Main.layers.change_document_size(document_size, anchor)
	Main.compositor.resize(document_size)
	Main.document_size = document_size

	# レイヤーリストのサムネのテクスチャがinvalidになるので、一旦更新する
	Main.emit_update_layer_list_tab()

	# compositが成功するまでフレームを進める
	while not Main.compositor.composite(Main.layers.root, true):
		await (Engine.get_main_loop() as SceneTree).process_frame
		Main.compositor.step_create_texture()

	# 改めてレイヤーリストのサムネの更新を行う
	Main.emit_update_layer_list_tab()

	Main.commit_history()

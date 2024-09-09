## メインの処理を書くシングルトンのクラス。
extends Node


## ドキュメントが開かれたときに発火されるシグナル。
signal on_document_open()
## ドキュメントが閉じたときに発火されるシグナル。
signal on_document_close()
## ドキュメントをリロードしたときに発火されるシグナル。
signal on_document_reload()
## ドキュメントのdirtyに変更があったときに発火されるシグナル。
signal on_document_dirty_changed()
## ミラー状態の変更があったときに発火されるシグナル。
signal on_mirror_changed()
## 線形グラデーションの編集ボタンが押されたときに発火されるシグナル。
signal on_start_edit_linear_gradient(gradient_material: LinearGradientPaintMaterial)
## 放射グラデーションの編集ボタンが押されたときに発火されるシグナル。
signal on_start_edit_radial_gradient(gradient_material: RadialGradientPaintMaterial)
## グラデーションの編集が終わったときに発火されるシグナル。
signal on_end_edit_gradient()
## マテリアルリストタブの更新が必要な際に発火されるシグナル。
signal on_update_material_list_tab()
## マテリアルのパラメータに変更が加わったときに呼び出されるシグナル。
signal on_change_material_parameters_changed()
## レイヤーリストタブの更新が必要な際に発火されるシグナル。
signal on_update_layer_list_tab()
## 選択中のパスが変更されたときに発火されるシグナル。
signal on_selected_paths_changed()
## コントロールセグメントの更新が必要な際に発火されるシグナル。
signal on_update_control_segments()
## パスの形状が変更されたときに発火されるシグナル。
signal on_path_shape_changed()
## ロケールが変更されたときに発火されるシグナル。
signal on_locale_changed()

## ドキュメントが開かれているかどうか。
var document_opened: bool = false

## ドキュメントのパス。
var document_file_path: String

## ドキュメントに未保存の変更があるかどうか。
var document_dirty: bool = false:
	set(value):
		document_dirty = value
		on_document_dirty_changed.emit()
	get:
		return document_dirty

## ドキュメントのサイズ。
var document_size: Vector2 = Vector2(480, 720)

## マテリアルのリスト。
var materials: MaterialList = MaterialList.new()
## レイヤーのリスト。
var layers: PaintLayerList = PaintLayerList.new()
## レイヤーのプール。
var layer_pool: PaintLayerPool = PaintLayerPool.new()
## Pathのプール。
var path_pool: PathPool = PathPool.new()

## コピー舌アイテムの管理者。
var copy_manager: CopyManager = CopyManager.new()

## メインのコンポジター。
var compositor := PaintCompositor.new()

## 現在のヒストリ。
var history_current: Document = null
## アンドゥのヒストリのリスト。
var history_undo_list: Array[Document] = []
## リドゥのヒストリのリスト。
var history_redo_list: Array[Document] = []

## コントローラー、カラーパレットなどを操作中かどうかのフラグをグローバルに置く。
var is_manipulating: bool:
	get:
		var scene_tree := Engine.get_main_loop() as SceneTree
		var root := scene_tree.root
		var app := root.get_node("/root/App") as App
		return app.get_is_manipulating()

## ビューポートの拡大率。
var viewport_scale: float = 1

## 表示のミラー状態。
var mirror: bool = false:
	set(value):
		mirror = value
		compositor.need_composite = true
		on_mirror_changed.emit()
	get:
		return mirror

## 自動保存が有効かどうか。
var auto_save_enabled: bool = false
## 自動保存の間隔。
var auto_save_interval: int = 5 * 60
## 最後に自動保存した時刻。
var auto_save_last_time: float = Time.get_unix_time_from_system()


func _ready() -> void:
	var config := ConfigFile.new()
	var ret := config.load("user://config.cfg")
	if ret == OK:
		if config.has_section_key("language", "locale"):
			@warning_ignore("unsafe_cast")
			var local := config.get_value("language", "locale") as String
			TranslationServer.set_locale(local)
		if config.has_section_key("auto_save", "enabled"):
			auto_save_enabled = config.get_value("auto_save", "enabled")
		if config.has_section_key("auto_save", "interval"):
			auto_save_interval = config.get_value("auto_save", "interval")


func _process(_delta: float) -> void:
	# ドキュメントが開かれている場合、compositorのテクスチャ生成を更新する。
	if document_opened:
		compositor.step_create_texture()

		# 自動保存が有効で、一定時間経過していたら自動保存する。
		if auto_save_enabled:
			var current_time := Time.get_unix_time_from_system()
			if current_time - auto_save_last_time > auto_save_interval:
				var file := FileAccess.open(document_file_path + "1", FileAccess.WRITE)
				var document := DocumentSerializer.document_store(true)
				file.store_string(var_to_str(document))
				file.close()

				auto_save_last_time = current_time


## 線形グラデーションの編集ボタンを押したときに呼び出す関数。
func emit_start_edit_linear_gradient(gradient_material: LinearGradientPaintMaterial) -> void:
	on_start_edit_linear_gradient.emit(gradient_material)


## 放射グラデーションの編集ボタンを押したときに呼び出す関数。
func emit_start_edit_radial_gradient(gradient_material: RadialGradientPaintMaterial) -> void:
	on_start_edit_radial_gradient.emit(gradient_material)


## グラデーションの編集が終わったときに呼び出す関数。
func emit_end_edit_gradient() -> void:
	on_end_edit_gradient.emit()


## マテリアルリストタブの更新が必要なときに呼び出す関数。
func emit_update_material_list_tab() -> void:
	on_update_material_list_tab.emit()


## マテリアルのパラメータに変更が加わったときに呼び出す関数。
func emit_change_material_parameters_changed() -> void:
	on_change_material_parameters_changed.emit()


## レイヤーリストタブの更新が必要なときに呼び出す関数。
func emit_update_layer_list_tab() -> void:
	on_update_layer_list_tab.emit()


## 選択中のパスが変更されたときに呼び出す関数。
func emit_selected_paths_changed() -> void:
	on_selected_paths_changed.emit()


## コントロールセグメントの更新が必要なときに呼び出す関数。
func emit_update_control_segments() -> void:
	on_update_control_segments.emit()


## パスの形状が変更されたときに呼び出す関数。
func emit_path_shape_changed() -> void:
	on_path_shape_changed.emit()


## ロケールが変更されたときに呼び出す関数。
func emit_locale_changed() -> void:
	on_locale_changed.emit()


## ドキュメントを新規作成する。
func create_document(new_document_size: Vector2, file_path: String) -> void:
	close_document()
	compositor.resize(new_document_size)
	document_file_path = file_path
	document_opened = true
	document_dirty = false
	history_undo_list.clear()
	history_redo_list.clear()
	materials.create_materials_for_new_documet()
	layers.new_document(new_document_size)
	mirror = false

	history_current = DocumentSerializer.document_store(false)
	save_document()

	auto_save_last_time = Time.get_unix_time_from_system()
	on_document_open.emit()
	on_update_layer_list_tab.emit()


## ドキュメントを上書き保存する。
func save_document() -> void:
	if not document_opened:
		return
	var file := FileAccess.open(document_file_path, FileAccess.WRITE)
	var document := DocumentSerializer.document_store(true)
	file.store_string(var_to_str(document))
	file.close()
	document_dirty = false


## ドキュメントを別名で保存する。
func save_as_document(file_path: String) -> void:
	if not document_opened:
		return
	document_file_path = file_path
	var file := FileAccess.open(document_file_path, FileAccess.WRITE)
	var document := DocumentSerializer.document_store(true)
	file.store_string(var_to_str(document))
	file.close()
	document_dirty = false


## ドキュメントを読み込む。
func load_document(file_path: String) -> void:
	close_document()
	var file := FileAccess.open(file_path, FileAccess.READ)
	@warning_ignore("unsafe_cast")
	var document := str_to_var(file.get_as_text()) as Document
	file.close()
	if document:
		history_undo_list.clear()
		history_redo_list.clear()
		document_file_path = file_path
		DocumentSerializer.document_load(document, true)
		document_dirty = false
		history_current = DocumentSerializer.document_store(false)
		mirror = false

		auto_save_last_time = Time.get_unix_time_from_system()
		on_document_open.emit()
		on_update_layer_list_tab.emit()


## ドキュメントを閉じる。
func close_document() -> void:
	document_file_path = ""
	history_current = null
	history_undo_list.clear()
	history_redo_list.clear()
	materials.clear()
	layers.clear()
	document_opened = false
	document_dirty = false
	mirror = false
	on_document_close.emit()
	on_update_layer_list_tab.emit()


## 操作をヒストリに積む。
func commit_history() -> void:
	# パスの計算を反映させるために2フレーム待機する。
	# パスに変更があった場合、1フレーム後にパスの再計算が予約されるので、
	# その結果にアクセスするのは2フレーム後とする。
	await (Engine.get_main_loop() as SceneTree).process_frame
	await (Engine.get_main_loop() as SceneTree).process_frame

	history_redo_list.clear()
	history_undo_list.append(history_current)
	history_current = DocumentSerializer.document_store(false)
	# 履歴は無限にメモリを使わないために適当に上限最大1024でキャップする
	while history_undo_list.size() > 1024:
		history_undo_list.remove_at(0)
	document_dirty = true


## アンドゥする。
func undo_hisotry() -> void:
	if history_undo_list.size() == 0:
		return
	history_redo_list.append(history_current)
	history_current = history_undo_list.pop_back()
	DocumentSerializer.document_load(history_current, false)
	document_dirty = true
	on_document_reload.emit()
	on_update_layer_list_tab.emit()


## リドゥする。
func redo_history() -> void:
	if history_redo_list.size() == 0:
		return
	history_undo_list.append(history_current)
	history_current = history_redo_list.pop_back()
	DocumentSerializer.document_load(history_current, false)
	document_dirty = true
	on_document_reload.emit()
	on_update_layer_list_tab.emit()


## documentをpngで書き出す。
func export_document(file_path: String, save_document_size: Vector2) -> void:
	var save_compositor := PaintCompositor.new()
	if save_document_size.x > document_size.x:
		save_compositor.resize(save_document_size)
	else:
		save_compositor.resize(document_size)

	save_compositor.update()
	save_compositor.step_create_texture()

	# compositが成功するまでフレームを進める
	while not save_compositor.composite(layers.root, true):
		await (Engine.get_main_loop() as SceneTree).process_frame
		save_compositor.step_create_texture()

	var texture := save_compositor.root_composite_texture.texture
	var image := texture.get_image()
	image.resize(int(save_document_size.x), int(save_document_size.y), Image.INTERPOLATE_LANCZOS)
	image.save_png(file_path)

	compositor.update()
	compositor.composite(layers.root, true)

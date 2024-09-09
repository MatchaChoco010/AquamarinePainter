class_name RadialGradientPaintMaterial
extends PaintMaterial


## グラデーション。
var gradient: Gradient = Gradient.new()
## グラデーションのテクスチャ。
var gradient_texture: GradientTexture1D = GradientTexture1D.new()

## グラデーションの中心点。
var center_point: Vector2 = Vector2(0, 0)
## グラデーションのハンドル1。
var handle_1_point: Vector2 = Vector2(1, 0)
## グラデーションのハンドル2。
var handle_2_point: Vector2 = Vector2(0, 1)


func _init() -> void:
  gradient_texture.set_gradient(gradient)
  gradient_texture.set_width(512)

  gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 0, 0, 1), Color(0, 0, 0, 1)])
  gradient.offsets = PackedFloat32Array([0, 0.5, 1])

  var quater_size := Main.document_size / 4
  center_point = quater_size * 2
  handle_1_point = quater_size * 2 + Vector2(quater_size.x, 0)
  handle_2_point = quater_size * 2 - Vector2(0, quater_size.y)


## ドキュメントサイズの変更を適用する。
func change_document_size(new_document_size: Vector2, anchor: PaintLayer.ScaleAnchor) -> void:
  var prev_document_size := Main.document_size

  var delta_x := 0.0
  var delta_y := 0.0
  match anchor:
    PaintLayer.ScaleAnchor.TopLeft:
      pass
    PaintLayer.ScaleAnchor.TopCenter:
      delta_x = (new_document_size.x - prev_document_size.x) / 2
    PaintLayer.ScaleAnchor.TopRight:
      delta_x = new_document_size.x - prev_document_size.x
    PaintLayer.ScaleAnchor.Left:
      delta_y = (new_document_size.y - prev_document_size.y) / 2
    PaintLayer.ScaleAnchor.Center:
      delta_x = (new_document_size.x - prev_document_size.x) / 2
      delta_y = (new_document_size.y - prev_document_size.y) / 2
    PaintLayer.ScaleAnchor.Right:
      delta_x = new_document_size.x - prev_document_size.x
      delta_y = (new_document_size.y - prev_document_size.y) / 2
    PaintLayer.ScaleAnchor.BottomLeft:
      delta_y = new_document_size.y - prev_document_size.y
    PaintLayer.ScaleAnchor.BottomCenter:
      delta_x = (new_document_size.x - prev_document_size.x) / 2
      delta_y = new_document_size.y - prev_document_size.y
    PaintLayer.ScaleAnchor.BottomRight:
      delta_x = new_document_size.x - prev_document_size.x
      delta_y = new_document_size.y - prev_document_size.y

  center_point += Vector2(delta_x, delta_y)
  handle_1_point += Vector2(delta_x, delta_y)
  handle_2_point += Vector2(delta_x, delta_y)

use godot::prelude::*;
use i_float::f64_point::F64Point;
use i_overlay::core::fill_rule::FillRule;
use i_triangle::triangulation::float::FloatTriangulate;

#[derive(GodotClass)]
#[class(init)]
pub struct BooleanPath {
    #[var]
    polygon: PackedVector2Array,
    #[var]
    operation: i64,
}

#[derive(GodotClass)]
#[class(init)]
#[derive(Debug)]
pub struct TriangulateResult {
    #[var]
    vertices: PackedVector2Array,
    #[var]
    indices: PackedInt32Array,
    #[var]
    counter_lines: Array<PackedVector2Array>,
}
impl TriangulateResult {
    pub fn empty() -> Self {
        Self {
            vertices: PackedVector2Array::new(),
            indices: PackedInt32Array::new(),
            counter_lines: Array::new(),
        }
    }
}

#[derive(GodotClass)]
#[class(init, base=Object)]
pub struct ShapeUtil {
    base: Base<Object>,
}
#[godot_api]
impl ShapeUtil {
    #[func]
    fn triangulate(polygon: PackedVector2Array) -> Gd<TriangulateResult> {
        let shape = vec![polygon
            .as_slice()
            .into_iter()
            .map(|v| F64Point::new(v.x as f64, v.y as f64))
            .collect::<Vec<_>>()];

        let triangulate = shape.to_triangulation(Some(FillRule::EvenOdd), 0.0);

        let mut result = TriangulateResult::empty();
        result.vertices = PackedVector2Array::from_iter(
            triangulate
                .points
                .iter()
                .map(|v| Vector2::new(v.x as f32, v.y as f32)),
        );
        result.indices = triangulate
            .indices
            .iter()
            .map(|v| *v as i32)
            .collect::<PackedInt32Array>();
        result.counter_lines = shape
            .into_iter()
            .map(|poly| {
                PackedVector2Array::from_iter(
                    poly.iter().map(|v| Vector2::new(v.x as f32, v.y as f32)),
                )
            })
            .collect::<Array<_>>();
        Gd::from_object(result)
    }

    #[func]
    fn triangulate_polygons_non_zero(polygons: Array<PackedVector2Array>) -> Gd<TriangulateResult> {
        let shape = polygons
            .iter_shared()
            .map(|polygon| {
                polygon
                    .as_slice()
                    .into_iter()
                    .map(|v| F64Point::new(v.x as f64, v.y as f64))
                    .collect::<Vec<_>>()
            })
            .collect::<Vec<_>>();

        let triangulate = shape.to_triangulation(Some(FillRule::NonZero), 0.0);

        let mut result = TriangulateResult::empty();
        result.vertices = PackedVector2Array::from_iter(
            triangulate
                .points
                .iter()
                .map(|v| Vector2::new(v.x as f32, v.y as f32)),
        );
        result.indices = triangulate
            .indices
            .iter()
            .map(|v| *v as i32)
            .collect::<PackedInt32Array>();
        result.counter_lines = shape
            .into_iter()
            .map(|poly| {
                PackedVector2Array::from_iter(
                    poly.iter().map(|v| Vector2::new(v.x as f32, v.y as f32)),
                )
            })
            .collect::<Array<_>>();
        Gd::from_object(result)
    }

    #[func]
    fn distance_segment_and_point(segment: PackedVector2Array, point: Vector2) -> f32 {
        let mut distance = f32::MAX;
        for i in 0..(segment.len() - 1) {
            let a = segment.get(i).unwrap();
            let b = segment.get(i + 1).unwrap();
            let ab = b - a;
            let ap = point - a;
            let bp = point - b;
            if ap.dot(ab) < 0.0 {
                distance = distance.min(ap.length());
            } else if bp.dot(ab) > 0.0 {
                distance = distance.min(bp.length());
            } else {
                distance = distance.min(ap.cross(ab).abs() / ab.length());
            }
        }
        return distance;
    }
}

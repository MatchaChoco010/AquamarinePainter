use godot::prelude::*;

#[derive(GodotClass)]
#[class(init)]
pub struct PPWPolygon {
    #[var]
    polygon: PackedVector2Array,
    #[var]
    segments: Array<PackedVector2Array>,
}
impl PPWPolygon {
    pub fn empty() -> Self {
        Self {
            polygon: PackedVector2Array::new(),
            segments: Array::new(),
        }
    }
}

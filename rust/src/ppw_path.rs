use godot::prelude::*;

#[derive(GodotClass)]
#[class(init)]
pub struct PPWPath {
    #[var]
    is_closed: bool,
    #[var]
    control_points: PackedVector2Array,
    #[var]
    weights: PackedFloat32Array,
    #[var]
    phis: PackedFloat32Array,
    #[var]
    psis: PackedFloat32Array,
}
impl PPWPath {
    pub fn validate(&self) -> bool {
        let control_points_len = self.control_points.len();
        let weights_len = self.weights.len();
        let phis_len = self.phis.len();
        let psis_len = self.psis.len();
        if self.get_is_closed() {
            control_points_len == weights_len
                && control_points_len == phis_len
                && control_points_len == psis_len
        } else {
            control_points_len == weights_len
                && control_points_len == phis_len + 1
                && control_points_len == psis_len + 1
        }
    }
}

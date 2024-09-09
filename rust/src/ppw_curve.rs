use godot::prelude::*;

use crate::ppw_path::PPWPath;
use crate::ppw_polygon::PPWPolygon;

#[derive(GodotClass)]
#[class(init, base=Object)]
pub struct PPWCurve {
    base: Base<Object>,
}
#[godot_api]
impl PPWCurve {
    const POINTS_PER_SEGMENT: usize = 50;
    const PSI_INFINITY: f32 = 2.0;
    const NEWTON_EPSILON: f64 = 0.001;
    const MAX_NEWTON_ITERATION: usize = 300;

    fn calc_rational_bezier_point(
        p0: Vector2,
        p1: Vector2,
        p2: Vector2,
        w: f32,
        t: f32,
    ) -> Vector2 {
        return ((1.0 - t) * (1.0 - t) * p0 + 2.0 * w * t * (1.0 - t) * p1 + t * t * p2)
            / ((1.0 - t) * (1.0 - t) + 2.0 * w * t * (1.0 - t) + t * t);
    }

    fn calc_max_curvature_p1(cp0: Vector2, cp1: Vector2, cp2: Vector2, w: f32) -> (Vector2, f32) {
        // セグメントが潰れている場合0.5とする
        if (cp0 - cp2).is_zero_approx() {
            return (cp0, 0.5);
        }

        // セグメントの端にCPがある場合も特殊扱い
        if (cp1 - cp0).is_zero_approx() {
            return (cp1, 0.0);
        }
        if (cp1 - cp2).is_zero_approx() {
            return (cp1, 1.0);
        }

        let w = w as f64;
        let p = cp0 - cp1;
        let r = cp2 - cp1;
        let p_length = p.length() as f64;
        let r_length = r.length() as f64;
        let p_sqr_length = p_length * p_length;
        let r_sqr_length = r_length * r_length;
        let p_plus_r_sqr_length = (p + r).length_squared() as f64;
        let p_minus_r_sqr_length = (p - r).length_squared() as f64;
        let p_dot_r = p.dot(r) as f64;
        let ww = w * w;

        let alpha_beta_to_q_t = |alpha: f64, beta: f64| -> (Vector2, f32) {
            let l0 = (alpha + beta) / 2.0;
            let l2 = (alpha - beta) / 2.0;
            let l1 = 1.0 - alpha;
            let q = (cp1 - l0 as f32 * cp0 - l2 as f32 * cp2) / l1 as f32;
            let sqrt = if l0 * l2 < 0.0 { 0.0 } else { (l0 * l2).sqrt() };
            let t = (2.0 * w * l2 + l1) / (2.0 * w * (alpha + 2.0 * sqrt));
            (q, t as f32)
        };

        // 特殊解: cp1がcp0とcp2の垂直二等分線上にある場合
        if (p_sqr_length - r_sqr_length).abs() < 0.0001 {
            return alpha_beta_to_q_t(1.0 / (1.0 + w) as f64, 0.0);
        }

        // 特殊解: cp1がcp0とcp2を結んだ直線上にある場合
        if (p_dot_r.abs() - p_length * r_length).abs() < 0.0001 {
            let m = (cp0 + cp2) / 2.0;
            let sign = (r_length - p_length).sign();
            let k = sign * (cp0 - m).length() as f64 / (cp1 - m).length() as f64;
            if p_dot_r < 0.0 {
                let beta = sign / (1.0 - ww * (1.0 - k * k)).sqrt();
                let alpha = (beta * (beta + k)) / (1.0 + k * beta);
                return alpha_beta_to_q_t(alpha as f64, beta as f64);
            } else {
                let dby = 1.0 + w * (1.0 - k * k).sqrt();
                let alpha = 1.0 / dby;
                let beta = k / dby;
                return alpha_beta_to_q_t(alpha as f64, beta as f64);
            }
        }

        // ニュートン法の初期値をヒューリスティックで決める
        let (mut alpha, mut beta) = {
            if w <= 1.0 {
                let now_a = 1.0 / (1.0 + w as f64);
                let tmp_b =
                    (p_sqr_length - r_sqr_length) * (1.0 - 2.0 * now_a) / 3.0 / p_plus_r_sqr_length;
                let now_b = if tmp_b < -now_a {
                    -now_a
                } else if tmp_b > now_a {
                    now_a
                } else {
                    tmp_b
                };
                (now_a, now_b)
            } else {
                let chord = 2.0 * r_length / (p_length + r_length) - 1.0;
                let now_b = 2.0 / (1.0 + (std::f64::consts::E.powf(-2.0 * chord / w as f64))) - 1.0;
                let now_a = 1.0 / (1.0 - ww)
                    + (ww / (1.0 - ww) / (1.0 - ww) - ww * now_b * now_b / (1.0 - ww)).sqrt();
                (now_a, now_b)
            }
        };

        let f = |a: f64, b: f64| (1.0 - ww) * a * a - 2.0 * a + 1.0 + ww * b * b;
        let g = |a: f64, b: f64| {
            p_plus_r_sqr_length * b * b * b
                - (p_sqr_length - r_sqr_length) * (1.0 - 2.0 * a) * b * b
                + (p_minus_r_sqr_length * a - 2.0 * (p_sqr_length + r_sqr_length)) * a * b
                - (p_sqr_length - r_sqr_length) * a * a
        };
        let fda = |a: f64| 2.0 * (1.0 - ww) * a - 2.0;
        let fdb = |b: f64| 2.0 * ww * b;
        let gda = |a: f64, b: f64| {
            2.0 * (p_sqr_length - r_sqr_length) * b * b + 2.0 * b * p_minus_r_sqr_length * a
                - 2.0 * b * (p_sqr_length + r_sqr_length)
                - 2.0 * (p_sqr_length - r_sqr_length) * a
        };
        let gdb = |a: f64, b: f64| {
            3.0 * p_plus_r_sqr_length * b * b
                - 2.0 * (p_sqr_length - r_sqr_length) * (1.0 - 2.0 * a) * b
                + (p_minus_r_sqr_length * a - 2.0 * (p_sqr_length + r_sqr_length)) * a
        };

        for _ in 0..Self::MAX_NEWTON_ITERATION {
            let rf = f(alpha, beta);
            let rg = g(alpha, beta);
            if rf.abs() < Self::NEWTON_EPSILON && rg.abs() < Self::NEWTON_EPSILON {
                break;
            }
            let rfda = fda(alpha);
            let rfdb = fdb(beta);
            let rgda = gda(alpha, beta);
            let rgdb = gdb(alpha, beta);
            let det = rfda * rgdb - rfdb * rgda;
            alpha -= (rf * rgdb - rg * rfdb) / det;
            beta -= (-rf * rgda + rg * rfda) / det;
        }

        alpha_beta_to_q_t(alpha, beta)
    }

    fn blend_coefficient(t: f32, phi: f32, psi: f32) -> (f32, f32) {
        let ephi = std::f32::consts::E.powf(phi);
        let sigma = 2.0 / (1.0 + ephi);
        let delta =
            -0.5 * (ephi - (ephi + 1.0).sqrt() * (ephi - 1.0).sqrt()).log(std::f32::consts::E);
        let t2 = if psi <= -Self::PSI_INFINITY {
            0.0
        } else if psi >= Self::PSI_INFINITY {
            1.0
        } else {
            t / (std::f32::consts::E.powf(-psi) * (1.0 - t) + t)
        };
        let t3 = delta * (2.0 * t2 - 1.0);
        let ht = t3.tanh() - sigma * t3;
        let ha = delta.tanh() - sigma * delta;
        let b1 = (1.0 - ht / ha) / 2.0;
        let b2 = 1.0 - b1;
        (b1, b2)
    }

    fn calc_segment(
        cp0: Vector2,
        cp1: Vector2,
        cp2: Vector2,
        cp3: Vector2,
        w1: f32,
        w2: f32,
        phi: f32,
        psi: f32,
    ) -> PackedVector2Array {
        let mut curve1 = [Vector2::ZERO; Self::POINTS_PER_SEGMENT];
        let p0 = cp0;
        let (p1, tt) = Self::calc_max_curvature_p1(cp0, cp1, cp2, w1);
        let p2 = cp2;
        for i in 0..Self::POINTS_PER_SEGMENT {
            let t = tt + (1.0 - tt) * i as f32 / (Self::POINTS_PER_SEGMENT - 1) as f32;
            let p = Self::calc_rational_bezier_point(p0, p1, p2, w1, t);
            curve1[i] = p;
        }

        let mut curve2 = [Vector2::ZERO; Self::POINTS_PER_SEGMENT];
        let p1 = cp1;
        let (p2, tt) = Self::calc_max_curvature_p1(cp1, cp2, cp3, w2);
        let p3 = cp3;
        for i in 0..Self::POINTS_PER_SEGMENT {
            let t = tt * i as f32 / (Self::POINTS_PER_SEGMENT - 1) as f32;
            let p = Self::calc_rational_bezier_point(p1, p2, p3, w2, t);
            curve2[i] = p;
        }

        let mut segment = PackedVector2Array::new();
        for i in 0..Self::POINTS_PER_SEGMENT {
            let t = i as f32 / (Self::POINTS_PER_SEGMENT - 1) as f32;
            let (b1, b2) = Self::blend_coefficient(t, phi, psi);
            let p = b1 * curve1[i] + b2 * curve2[i];
            segment.push(p);
        }
        segment
    }

    fn calc_start_segment(
        cp1: Vector2,
        cp2: Vector2,
        cp3: Vector2,
        w2: f32,
        phi: f32,
        psi: f32,
    ) -> PackedVector2Array {
        let mut curve1 = [Vector2::ZERO; Self::POINTS_PER_SEGMENT];
        for i in 0..Self::POINTS_PER_SEGMENT {
            let t = i as f32 / (Self::POINTS_PER_SEGMENT - 1) as f32;
            let p = cp2 * t + (1.0 - t) * cp1;
            curve1[i] = p;
        }

        let mut curve2 = [Vector2::ZERO; Self::POINTS_PER_SEGMENT];
        let p1 = cp1;
        let (p2, tt) = Self::calc_max_curvature_p1(cp1, cp2, cp3, w2);
        let p3 = cp3;
        for i in 0..Self::POINTS_PER_SEGMENT {
            let t = tt * i as f32 / (Self::POINTS_PER_SEGMENT - 1) as f32;
            let p = Self::calc_rational_bezier_point(p1, p2, p3, w2, t);
            curve2[i] = p;
        }

        let mut segment = PackedVector2Array::new();
        for i in 0..Self::POINTS_PER_SEGMENT {
            let t = i as f32 / (Self::POINTS_PER_SEGMENT - 1) as f32;
            let (b1, b2) = Self::blend_coefficient(t, phi, psi);
            let p = b1 * curve1[i] + b2 * curve2[i];
            segment.push(p);
        }
        segment
    }

    fn calc_end_segment(
        cp0: Vector2,
        cp1: Vector2,
        cp2: Vector2,
        w1: f32,
        phi: f32,
        psi: f32,
    ) -> PackedVector2Array {
        let mut curve1 = [Vector2::ZERO; Self::POINTS_PER_SEGMENT];
        let p0 = cp0;
        let (p1, tt) = Self::calc_max_curvature_p1(cp0, cp1, cp2, w1);
        let p2 = cp2;
        for i in 0..Self::POINTS_PER_SEGMENT {
            let t = tt + (1.0 - tt) * i as f32 / (Self::POINTS_PER_SEGMENT - 1) as f32;
            let p = Self::calc_rational_bezier_point(p0, p1, p2, w1, t);
            curve1[i] = p;
        }

        let mut curve2 = [Vector2::ZERO; Self::POINTS_PER_SEGMENT];
        for i in 0..Self::POINTS_PER_SEGMENT {
            let t = i as f32 / (Self::POINTS_PER_SEGMENT - 1) as f32;
            let p = cp2 * t + (1.0 - t) * cp1;
            curve2[i] = p;
        }

        let mut segment = PackedVector2Array::new();
        for i in 0..Self::POINTS_PER_SEGMENT {
            let t = i as f32 / (Self::POINTS_PER_SEGMENT - 1) as f32;
            let (b1, b2) = Self::blend_coefficient(t, phi, psi);
            let p = b1 * curve1[i] + b2 * curve2[i];
            segment.push(p);
        }
        segment
    }

    #[func]
    fn convert(&self, path: Gd<PPWPath>) -> Gd<PPWPolygon> {
        let path = path.bind();

        if !path.validate() {
            godot_error!("Invalid path");
            return Gd::from_object(PPWPolygon::empty());
        }

        if path.get_control_points().len() == 1 {
            return Gd::from_object(PPWPolygon::empty());
        }

        if path.get_control_points().len() == 2 {
            let poly = PPWPolygon::empty();
            let mut polygon = poly.get_polygon();
            polygon.push(path.get_control_points()[0]);
            polygon.push(path.get_control_points()[1]);
            let mut segments = poly.get_segments();
            let mut segment = PackedVector2Array::new();
            segment.push(path.get_control_points()[0]);
            segment.push(path.get_control_points()[1]);
            segments.push(segment);
            return Gd::from_object(poly);
        }

        if path.get_is_closed() {
            let mut segments = Array::new();
            let cp_len = path.get_control_points().len();
            for i in 0..cp_len {
                let cp0 = path.get_control_points()[(i + cp_len - 1) % cp_len];
                let cp1 = path.get_control_points()[i];
                let cp2 = path.get_control_points()[(i + 1) % cp_len];
                let cp3 = path.get_control_points()[(i + 2) % cp_len];
                let w1 = path.get_weights()[i % cp_len];
                let w2 = path.get_weights()[(i + 1) % cp_len];
                let phi = path.get_phis()[i];
                let psi = path.get_psis()[i];
                let segment = Self::calc_segment(cp0, cp1, cp2, cp3, w1, w2, phi, psi);
                segments.push(segment);
            }
            let mut polygon = PackedVector2Array::new();
            for i in 0..segments.len() {
                let seg = segments.at(i);
                for j in 0..seg.len() {
                    polygon.push(seg[j]);
                }
            }
            let mut poly = PPWPolygon::empty();
            poly.set_polygon(polygon);
            poly.set_segments(segments);
            Gd::from_object(poly)
        } else {
            let mut segments = Array::new();
            let cp_len = path.get_control_points().len();
            segments.push(Self::calc_start_segment(
                path.get_control_points()[0],
                path.get_control_points()[1],
                path.get_control_points()[2],
                path.get_weights()[1],
                path.get_phis()[0],
                path.get_psis()[0],
            ));
            for i in 1..(cp_len - 2) {
                let cp0 = path.get_control_points()[i - 1];
                let cp1 = path.get_control_points()[i];
                let cp2 = path.get_control_points()[i + 1];
                let cp3 = path.get_control_points()[i + 2];
                let w1 = path.get_weights()[i];
                let w2 = path.get_weights()[i + 1];
                let phi = path.get_phis()[i];
                let psi = path.get_psis()[i];
                let segment = Self::calc_segment(cp0, cp1, cp2, cp3, w1, w2, phi, psi);
                segments.push(segment);
            }
            segments.push(Self::calc_end_segment(
                path.get_control_points()[cp_len - 3],
                path.get_control_points()[cp_len - 2],
                path.get_control_points()[cp_len - 1],
                path.get_weights()[cp_len - 2],
                path.get_phis()[cp_len - 2],
                path.get_psis()[cp_len - 2],
            ));
            let mut polygon = PackedVector2Array::new();
            for i in 0..segments.len() {
                let seg = segments.at(i);
                for j in 0..seg.len() {
                    polygon.push(seg[j]);
                }
            }
            let mut poly = PPWPolygon::empty();
            poly.set_polygon(polygon);
            poly.set_segments(segments);
            Gd::from_object(poly)
        }
    }
}

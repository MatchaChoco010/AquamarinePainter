use godot::engine::Engine;
use godot::prelude::*;

mod ppw_curve;
mod ppw_path;
mod ppw_polygon;
mod shape_util;

struct PPWPExtension;

#[gdextension]
unsafe impl ExtensionLibrary for PPWPExtension {
    fn on_level_init(level: InitLevel) {
        if level == InitLevel::Scene {
            Engine::singleton().register_singleton(
                StringName::from("PPWCurve"),
                ppw_curve::PPWCurve::new_alloc().upcast(),
            );
            Engine::singleton().register_singleton(
                StringName::from("ShapeUtil"),
                shape_util::ShapeUtil::new_alloc().upcast(),
            );
        }
    }

    fn on_level_deinit(level: InitLevel) {
        if level == InitLevel::Scene {
            let mut engine = Engine::singleton();

            let singleton_name = StringName::from("PPWCurve");
            let singleton = engine
                .get_singleton(singleton_name.clone())
                .expect("cannot retrieve the singleton");
            engine.unregister_singleton(singleton_name);
            singleton.free();

            let singleton_name = StringName::from("ShapeUtil");
            let singleton = engine
                .get_singleton(singleton_name.clone())
                .expect("cannot retrieve the singleton");
            engine.unregister_singleton(singleton_name);
            singleton.free();
        }
    }
}

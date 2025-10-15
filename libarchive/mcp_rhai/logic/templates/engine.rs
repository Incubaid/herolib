use rhai::{Engine, EvalAltResult, Map, Dynamic};
use crate::wrapper;

pub fn create_rhai_engine() -> Engine {
    let mut engine = Engine::new();
    
    @for function in functions
        engine.register_fn("@{function}", wrapper::@{function});
    @end
    
    engine
}
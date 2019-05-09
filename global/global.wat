(module
    (global $g (import "js" "global") (mut i32))
    (func (export "get_global") (result i32)
        (get_global $g)
    )
    (func (export "inc_global")
        (set_global $g 
            (i32.add (get_global $g) (i32.const 1) )
        )
    )
)
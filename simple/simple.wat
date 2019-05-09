(module
    (func $i (import "import" "import_func") (param i32))
    (func (export "export_func")
        i32.const 42
        call $i
    )
)
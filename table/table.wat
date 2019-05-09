(module
    (func $thirteen (result i32) (i32.const 13))
    (func $forty_two (result i32) (i32.const 42))
    (table (export "tbl") anyfunc (elem $thirteen $forty_two))
)
# WebAssembly Javascript API

## Tool required:

-   The WebAssembly Binary Toolkit: from [here](https://github.com/webassembly/wabt)

---

## Introduction To WAT

The `simple.wat` file contains the webassembly text format. This file is complied to `simple.wasm` file that can be serve to the web application. The compilation is done using the WebAssembly Binary Toolkit.

The `simple.wat` file contains:

```wat
(module
    (func $i (import "import" "import_func") (param i32))
    (func (export "export_func")
        i32.const 42
        call $i
    )
)
```

Here the line `(func $i (import "import" "import_func") (param i32))` says:

> Import the **import_func** function from the **import** object in to **\$i** that takes a parameter of **32 bit integer**.

Then the line

```
(func (export "export_func")
    i32.const 42
    call $i
)
```

says:

> Export a function of name **export_func** that calls function **\$i** with **42** as argument.

In short, this module takes in a javascript function and executes it with an argument.

To compile the `simple.wat` file to `simple.wasm`, run:

```
wat2wasm simple.wat -o simple.wasm
```

---

## Running WASM on Browser

There are two ways of fetching the `.wasm` file to be executed in the browser. One way is to fetch the `.wasm` file as a blob and load it as `ArrayBuffer` to be used in `WebAssembly.instantiate()` to create an module/instance. The other way is to compile and instantiate WebAssembly module directly form the `.wasm` file. This is achieved by using `WebAssembly.compileStreaming()` and `WebAssembly.instantiateStreaming()` methods.

#### The Javascript Function To Pass To Simple.wasm:

Form the above `simple.wat` source code we know that the module takes in a function from an object which it then executes with the parameter 42. Let us write that object:

```javascript
const importObject = {
    import: {
        import_func: args => (document.getElementById("root").innerHTML = args)
    }
};
```

#### Non Streaming Way:

To execute the `simple.wasm` file in a non streaming way:

```javascript
fetch("simple.wasm")
    .then(res => res.arrayBuffer())
    .then(bytes => WebAssembly.instantiate(bytes, importObject))
    .then(res => res.instance.exports.export_func());
```

#### Streaming Way:

To execute the `simple.wasm` file in a streaming way:

```javascript
WebAssembly.instantiateStreaming(fetch('simple.was'), importObject)
    .then(obj => obj.instance.exports.export_func();)
```

---

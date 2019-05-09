# WebAssembly Javascript API

---

Stolen from (here)[https://developer.mozilla.org/en-US/docs/WebAssembly/Using_the_JavaScript_API]

---

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
        import_func: args => {
            document.getElementById("root").innerHTML = args;
        }
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

## Memory Of WASM

Each WebAssembly Module has it's own linear module that can be read and written into. This memory buffer can be accessed by pointers. This memory buffer is created in a blocks of `64 kb` and can be created using Javascript as such:

```javascript
var memory = new WebAssembly.Memory({ initial: 10, maximum: 100 });
```

This will create an initial memory buffer of `(64 * 10) kb = 640 kb` and reserve a memory for `6.4 mb`.

WebAssembly exposes it's memory by providing a buffer getter/setter that returns an ArrayBuffer.

```javascript
// Writing 42 to buffer:
new Uint32Array(memory.buffer)[0] = 42;

// Getting value from buffer:
const fortyTwo = new UnitArray(memory.buffer)[0];
```

The memory instance can be grown by calling `Memory.prototype.grow()`. It takes units as parameter that grows the memory by `64 * supplied_unit kb`. For example:

```javascript
memory.grow(1);
```

If growth of memory more than the max limit is attempted, it would result in `WebAssembly.RangeError`. **Note**, since `ArrayBuffer` is of immutable type, growing the size of memory results in new `ArrayBuffer` object being returned, and the previous buffer is detached.

The linear memory can be defined inside the WebAssembly module or can be imported, and the memory can also be exported. You can import the **memory buffer from WebAssembly in Javascript** by calling the `Instance.prototypes.exports`. Similarly, **memory can be created in Javascript by `WebAssembly.memory` and passed to the WebAssembly module as import**.

#### Memory imports are useful for two reasons:

-   It allows JS to fetch and create initial contents of the memory before or concurrently with module compilation.
-   It can shared between module instances, which can be a critical building block for implementing dynamic linking in WebAssembly.

---

## Memory Example

Let's make a wasm module that imports a memory buffer with numbers in them and then computes and returns the sum of the numbers when a function named as accumulate is called. The `memory.wat` file will be as such:

```wat
(module
    (memory (import "js" "mem") 1)
    (func (export "accumulate") (param $ptr i32) (param $len i32) (result i32)
        (local $end i32)
        (local $sum i32)
        (set_local $end (i32.add (get_local $ptr) (i32.mul (get_local $len) (i32.const 4))))
        (block $break (loop $top
            (br_if $break (i32.eq (get_local $ptr) (get_local $end)))
            (set_local $sum (i32.add (get_local $sum) (i32.load (get_local $ptr))))
            (set_local $ptr (i32.add (get_local $ptr) (i32.const 4)))
            (br $top)
        ))
        (get_local $sum)
    )
)
```

Here we import the memory from the `mem` attribute of the `js` object in the line `(memory (import "js" "mem") 1)`. Then we export a function `accumulate` that takes in two parameter: `(param $ptr i32)` the starting of the memory index, `(param $len i32)` the total length of the array to traverse. It then creates an end index by `(local $end i32)` and instantiate it to the end memory location by `(set_local $end (i32.add (get_local $ptr) (i32.mul (get_local $len) (i32.const 4) ) ))`. Then it starts looping from `(block $break (loop $top /*...*/))`. First it checks if the `$ptr` has reached `$end` and breaks if it does by `(br_if $break (i32.eq (get_local $ptr) (get_local $end) ))`. Then it sets the value of `$sum` as `$sum` + value at `$ptr`, by `(set_local $sum (i32.add (get_local $sum) (i32.load (get_local $ptr))))`. And the moved to the next pointer by `(set_local $ptr (i32.add (get_local $ptr) (i32.const 4)))`. At the end, it return the value of `$sum` by `(get_local $sum)`. This is fairly the program flow of the `memory.wasm` code.

Let us look at the Javascript to code to understand how to put the memory to the module and get the sum of the array using the `accumulate` function created above.

```javascript
// Create a memory buffer of 640kb inital and 6.4mb maximum
const memory = new WebAssembly.Memory({ initial: 10, maximum: 100 });

// Fetch and compile `memory.wasm` file and pass the memory buffer
WebAssembly.instantiateStreaming(fetch("memory.wasm"), {
    js: { mem: memory }
}).then(res => {
    // Get the memory buffer as an unsigned 32 bit integer array
    const i32 = new Uint32Array(memory.buffer);

    // Fille the array with values from 1 to 10
    [...Array(10).keys()].map((v, i) => (i32[i] = v + 1));

    // Get and display the sum of the array by calling
    // the accumulate function of the module
    const sum = res.instance.exports.accumulate(0, 10);
    console.log(sum);
});
```

**NOTE**: We are getting the `memory.buffer` as a `Uint32Array` view and not the memory itself.

---

## Table In WASM

A WebAssembly table is a typed array that can be accessed by both Javascript and WebAssembly code. This array currently only is capable of holding references of functions. The table can be mutated by calling the `Table.prototype.set()` which updates on the values in the table. The table can be grown by `Table.prototype.grow()` which increased the size of the table. The values are accessible by `Table.prototype.get()`.

---

## Table Example

Let us write a WAT file that creates two functions, one returns 13 and the other returns 42; and export a table that contains the pointers to those functions.

```wat
(module
    (func $thirteen (result i32) (i32.const 13))
    (func $forty_two (result i32) (i32.const 43))
    (table (export "tbl") anyfunc (elem $thirteen $forty_two))
)
```

Here `(table (export "tbl") anyfunc (elem $thirteen $forty_two))` we have stated that `thirteen` as the first element and `forty_two` as the second.

Let us create the Javascript code to get and execute the functions defined above.

```javascript
WebAssembly.instantiateStreaming(fetch("table.wasm")).then(res => {
    // Get the table from the module
    const tbl = res.instance.exports.tbl;

    // Get and execute the first function on the table
    // which is the `thirteen` function
    // logs: 13
    console.log(tbl.get(0)());

    // Get and execute the second (`forty_two`) function on the table
    // logs: 42
    console.log(tbl.get(1)());
});
```

---

# Global In WASM

WebAssembly gives an ability to create a global variable shared between both Javascript and WebAssembly module instances. This is useful for dynamic linking. To create a global variable:

```javascript
const global = new WebAssembly.Global({ value: "i32", mutable: true }, 0);
```

Here the `WebAssembly.Global` API takes two parameters.

-   First is the object `{value: "i32", mutable: true}` which states the _datatype as integer of 32 bits_ and _that it is mutable_.
-   Second is the actual value, which here is initialized to `0`.

---

## Global Example

Let us write the WAT code that imports a global variable from the `global` attribute of `js` object and exports two functions: `get_global` and `inc_global` to get and increment global by one.

```wat
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
```

Then let us write the Javascript code to create, supply, modify and extract the global variable.

```javascript
// Create a global variable of type i32
// and mutable with 0 as initial value
const gbl = new WebAssembly.Global({ value: "i32", mutable: true }, 0);

// Fetch `global.wasm` file and put the global variable to it.
WebAssembly.instantiateStreaming(fetch("global.wasm"), {
    js: { global: gbl }
}).then(({ instance }) => {
    // Display the original value: 0
    console.log(instance.exports.get_global());

    // Change the global value from javascript to
    gbl.value = 42;

    // Display the changed value by fetching value form wasm: 42
    console.log(instance.exports.get_global());

    // Increment the global value by one in wasm
    instance.exports.inc_global();

    // Display the global value by extraction in js: 43
    console.log(gbl.value);
});
```

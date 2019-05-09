simple-wasm:
	wat2wasm simple/simple.wat -o simple/simple.wasm

serve-simple:
	http-server simple

memory-wasm:
	wat2wasm memory/memory.wat -o memory/memory.wasm

serve-memory:
	http-server memory

table-wasm:
	wat2wasm table/table.wat -o table/table.wasm

serve-table:
	http-server table

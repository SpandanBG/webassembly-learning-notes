make-simple:
	wat2wasm simple/simple.wat -o simple/simple.wasm

serve-simple:
	http-server simple
make-wasm: simple.wat
	wat2wasm simple.wat -o simple.wasm

serve:
	http-server
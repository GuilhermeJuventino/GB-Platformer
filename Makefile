.PHONY: main clean

main:
	rgbasm -o main.o main.asm
	rgblink -n GBPlatformer.sym -o GBPlatformer.gb main.o
	rgbfix -v -p 0xFF GBPlatformer.gb


clean:
	rm -rf GBPlatformer.gb
	rm -rf GBPlatformer.sym
	rm -rf main.o

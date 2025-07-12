.PHONY: main clean

main:
	rgbasm -o main.o main.asm
	rgblink -n GBPlatformer.sym -m GBPlatformer.map -o GBPlatformer.gb main.o
	rgbfix -v -p 0xFF GBPlatformer.gb


clean:
	rm -rf GBPlatformer.gb
	rm -rf GBPlatformer.sym
	rm -rf GBPlatformer.map
	rm -rf main.o

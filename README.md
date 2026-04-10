# Mini Proyecto: Coin Runner

## Assembling and Linking Instructions
```
ca65 src/tiles.asm
ca65 src/reset.asm
ld65 src/reset.o src/tiles.o -C nes.cfg -o tiles.nes
```

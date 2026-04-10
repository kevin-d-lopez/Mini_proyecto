.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
baseHi:   .res 1
baseLo:   .res 1
megatile: .res 1
stripNo:  .res 1

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  LDA #$00
  STA OAMADDR
  LDA #$02
  STA OAMDMA
  LDA #$00
  STA PPUSCROLL
  STA PPUSCROLL
  RTI
.endproc

.import reset_handler

.export main
.proc main
  ; write a palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR
  load_palettes:
    LDA palettes,X
    STA PPUDATA
    INX
    CPX #$20
    BNE load_palettes

  ; write background
  ; where to start writing background
  LDA PPUSTATUS
  LDA #$20
  STA PPUADDR
  LDA #$00
  STA PPUADDR

  ; if set to #$00 indicates the top-part of the megatile is written to the PPU,
  ; else the bottom-part of the megatile is written to the PPU.
  LDA #$00
  STA stripNo

  LDX #$00
  write_background:
    ; write 1st megatile's top-part of the current 2x8 row.
    LDY background,X
    STY megatile
    JSR write_megatile
    INX

    ; write 2nd megatile's top-part of the current 2x8 row.
    LDY background,X
    STY megatile
    JSR write_megatile
    INX

    ; write 3rd megatile's top-part of the current 2x8 row.
    LDY background,X
    STY megatile
    JSR write_megatile
    INX

    ; write 4th megatile's top-part of the current 2x8 row.
    LDY background,X
    STY megatile
    JSR write_megatile
    INX

    ; decrease X by 4, and set stripNo to a number different than #$00 so that
    ; the bottom-part of megatiles get written to the PPU.
    DEX
    DEX
    DEX
    DEX
    LDA #$01
    STA stripNo

    ; write 1st megatile's bottom-part of the current 2x8 row.
    LDY background,X
    STY megatile
    JSR write_megatile
    INX

    ; write 2nd megatile's bottom-part of the current 2x8 row.
    LDY background,X
    STY megatile
    JSR write_megatile
    INX

    ; write 3rd megatile's bottom-part of the current 2x8 row.
    LDY background,X
    STY megatile
    JSR write_megatile
    INX

    ; write 4th megatile's bottom-part of the current 2x8 row.
    LDY background,X
    STY megatile
    JSR write_megatile
    INX

    ; set stripNo to #$00 again so next iteration begins writing a megatile's
    ; top-part
    LDA #$00
    STA stripNo

    ; end loop when counter reaches 60
    CPX #$3C
    BNE write_background

  ; write attributes
  ; where to start writing attribute table
  LDA PPUSTATUS
  LDX #$23
  STX baseHi
  LDX #$C0
  STX baseLo

  LDX #$00
  write_attributes:
    LDA baseHi
    STA PPUADDR
    LDA baseLo
    STA PPUADDR

    LDY attributes,X
    STY PPUDATA
    INX
    INC baseLo

    ; end loop when counter reaches 64
    CPX #$40
    BNE write_attributes

vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc

.proc write_megatile
  PHA
  TXA
  PHA

  ; mask the megatile to get the offset where the metatile starts under the
  ; "metatiles" label, then shift the masked bits to the lowest bit position.

  ; 1st metatile strip of the current 1x8 row.
  LDA megatile
  AND #%11000000
  LSR A
  LSR A
  LSR A
  LSR A
  LSR A
  LSR A
  JSR write_metatile_strip

  ; 2nd metatile strip of the current 1x8 row.
  LDA megatile
  AND #%00110000
  LSR A
  LSR A
  LSR A
  LSR A
  JSR write_metatile_strip

  ; 3rd metatile strip of the current 1x8 row.
  LDA megatile
  AND #%00001100
  LSR A
  LSR A
  JSR write_metatile_strip

  ; 4th metatile strip of the current 1x8 row.
  LDA megatile
  AND #%00000011
  JSR write_metatile_strip

  PLA
  TAX
  PLA
  RTS
.endproc

; macro called by the `write_megatile` method to write the megatile strip tiles
; to the PPU. the accumulator must have "metatiles" table row index where the
; desired tile starts.
.proc write_metatile_strip
  ; calculate offset inside of "metatiles" table of the tile to be written
  ; multiplying by 4
  ASL A
  ASL A

  ; if stripNo is not #$00, add #$02 to the calculated offset so that the
  ; bottom-part of the metatile is written to the PPU.
  LDY stripNo
  CPY #$00
  BEQ :+
  CLC
  ADC #$02
  
  :
  ; transfer the calculated offset to Y register and load to X register the tile
  ; to be written to the PPU
  TAY
  LDX metatiles,Y
  STX PPUDATA

  ; increment Y register and repreat loading to X register the tile to be
  ; written to the PPU for completing the metatile strip
  INY
  LDX metatiles,Y
  STX PPUDATA

  RTS
.endproc

.segment "RODATA"
palettes:
  ; background
  .byte $2a, $2d, $3d, $20
  .byte $2a, $1a, $18, $28
  .byte $2a, $16, $27, $37
  .byte $2a, $02, $21, $31

  ; sprites
  .byte $2a, $22, $00, $00
  .byte $2a, $11, $00, $00
  .byte $2a, $27, $00, $00
  .byte $2a, $2c, $00, $00

metatiles:
  .byte $10, $11, $20, $21  ; wall1
  .byte $12, $13, $22, $23  ; wall2
  .byte $30, $31, $40, $41  ; pebbl
  .byte $00, $00, $00, $00  ; backg

background:
	.byte %00000000, %00000000, %00000000, %00000000
	.byte %00101111, %11111010, %10111111, %11101000
	.byte %00100001, %00110001, %00100001, %00101000
	.byte %00111111, %11111111, %11111111, %11111100
	.byte %00110001, %00010011, %00010011, %00011100
	.byte %00111111, %11011111, %11110111, %11111100
	.byte %00010001, %00110001, %00010011, %00011100
	.byte %00111111, %11111111, %11111111, %11111100
	.byte %00110001, %00010001, %00010001, %00011100
	.byte %00111111, %11111101, %11111111, %11111100
	.byte %00100001, %00010011, %00010001, %00011000
	.byte %00111111, %11111111, %11111111, %11111100
	.byte %00110001, %00010001, %00010001, %00011100
	.byte %00101111, %11111010, %11111111, %11101100
	.byte %00000000, %00000000, %00000000, %00000000

attributes:
	.byte $80,$00,$d0,$a0,$e0,$00,$90,$20,$48,$00,$04,$d0,$18,$80,$18,$12
	.byte $44,$00,$00,$14,$00,$4c,$00,$11,$40,$00,$44,$00,$00,$44,$00,$13
	.byte $44,$00,$00,$00,$00,$00,$00,$11,$48,$00,$00,$44,$00,$00,$00,$12
	.byte $84,$00,$c0,$a0,$d0,$00,$80,$11,$00,$00,$00,$00,$00,$00,$00,$00

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "include/graphics.chr"

.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"

; background generation
megatile: .res 1
stripNo:  .res 1

; sprite positions
player_x: .res 1
player_y: .res 1
enemy_x:  .res 1
enemy_y:  .res 1
coin_x:   .res 1
coin_y:   .res 1
.exportzp player_x, player_y, enemy_x, enemy_y, coin_x, coin_y

; player parameters
player_spe:  .res 1
.exportzp player_spe

; controller
controller1: .res 1
.exportzp controller1

timer: .res 1
.exportzp timer

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.import read_controller1, update_player, draw_player, draw_enemy, draw_coin

.proc nmi_handler
  ; copy the memory from $0200-$02ff into OAM
  LDA #$00
  STA OAMADDR    ; prepare the PPU for a transfer to OAM starting at byte $00
  LDA #$02
  STA OAMDMA     ; initiate transfer of the 256 bytes from $0200-$02ff into OAM

  ; set PPUSCROLL x-position and y-position to #$00
  LDA #$00
  STA PPUSCROLL
  STA PPUSCROLL

  ; read controller input and update player position
  JSR read_controller1
  JSR update_player

  ; once player position is updated, draw the player
  JSR draw_player
  JSR draw_enemy
  JSR draw_coin

  INC timer
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

  ; write the first 64 uncompressed background tiles (these tiles are part of
  ; the game's heads up display).
  LDX #$00
  write_hud:
    LDY hud,X
    STY PPUDATA
    INX
    CPX #$40
    BNE write_hud

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

    ; end loop when counter reaches 56
    CPX #$38
    BNE write_background

  ; write attributes
  ; where to start writing attribute table
  LDA PPUSTATUS
  LDX #$23
  STX PPUADDR
  LDX #$C0
  STX PPUADDR

  LDX #$00
  write_attributes:
    LDY attributes,X
    STY PPUDATA
    INX

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
  .byte $2B, $0F, $00, $10
  .byte $2B, $20, $2D, $28
  .byte $2B, $0B, $1A, $29
  .byte $2B, $00, $00, $00

  ; sprites
  .byte $2B, $0F, $10, $3C
  .byte $2B, $03, $14, $24
  .byte $2B, $0F, $38, $28
  .byte $2B, $0F, $16, $26

metatiles:
  .byte $00, $01, $10, $11  ; meta1
  .byte $02, $03, $12, $13  ; meta2
  .byte $06, $07, $16, $17  ; meta3
  .byte $08, $09, $18, $19  ; backg

hud:
	.byte $08,$09,$08,$09,$08,$09,$08,$09,$08,$09,$08,$09,$08,$09,$08,$09
  .byte $08,$09,$08,$09,$08,$09,$08,$09,$08,$09,$26,$28,$ee,$ef,$ef,$09
  .byte $20,$21,$22,$23,$24,$25,$c6,$c6,$c6,$c6,$c6,$19,$18,$ff,$ff,$ff
  .byte $18,$19,$18,$19,$7d,$19,$18,$19,$4b,$19,$27,$28,$fe,$ff,$ff,$19

background:
	.byte %00000000, %00000000, %00000000, %00000000
	.byte %00011111, %11111111, %11111111, %11111100
	.byte %00111111, %00101111, %11111111, %11111100
	.byte %00111111, %11111111, %11111111, %00100100
	.byte %00111111, %11111111, %11111111, %10111000
	.byte %00111111, %11111111, %11111111, %11111100
	.byte %00111111, %11111111, %01111111, %11111100
	.byte %00110010, %11111101, %01011111, %11111100
	.byte %00111010, %11111111, %11011111, %11001000
	.byte %00111111, %11111111, %11111111, %11111100
	.byte %00111111, %11111111, %11111111, %11111100
	.byte %00011111, %11011111, %11100011, %11111100
	.byte %00010111, %11101111, %11111111, %11010100
	.byte %00000000, %00000000, %00000000, %00000000

attributes:
	.byte $0a,$02,$00,$0a,$00,$02,$02,$00,$cc,$ff,$4f,$ff,$ff,$ff,$ff,$33
	.byte $0c,$0f,$0f,$0f,$0f,$0f,$54,$12,$00,$00,$00,$80,$20,$00,$00,$00
	.byte $00,$54,$10,$08,$8a,$00,$00,$12,$00,$00,$00,$00,$00,$00,$00,$02
	.byte $cc,$30,$48,$00,$04,$00,$c0,$30,$00,$00,$00,$00,$00,$00,$00,$00

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "CHR"
.incbin "include/graphics.chr"

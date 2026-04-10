.include "constants.inc"

.segment "ZEROPAGE"
.importzp tileIndex, sprite_attr, player_dir, baseLo, baseHi
.importzp player_x, player_y, enemy_x, enemy_y, coin_x, coin_y

.segment "CODE"
.export write_sprite

; subroutine receives the screen coordinates for a sprite through the `player_x`
; and `player_y`, and the index where the sprite starts from its sprite table
; through `tileIndex`. 
.proc write_sprite
  PHA
  TXA
  PHA

  start_writing_sprites:
  LDX tileIndex
  LDY #$00

  ; if player direction is $02, flip sprites horizontally and alter the write
  ; sequence of the sprites
  LDA player_dir
  CMP #$02
  BNE top_left
  LDA #%01000000
  STA sprite_attr
  JMP top_right

  ; write top-left tile of sprite
  top_left:
  LDA player_y
  STA (baseLo),Y ; Y-coord
  INY
  LDA player_sprites,X
  STA (baseLo),Y ; tile number
  INY
  LDA #%00000000
  ORA sprite_attr
  STA (baseLo),Y ; attributes
  INY
  LDA player_x
  STA (baseLo),Y ; X-coord
  INY
  INX
  LDA player_dir
  CMP #$02
  BEQ bottom_right

  ; write top-right tile of sprite (must add 8 to the sprite's x position)
  top_right:
  LDA player_y
  STA (baseLo),Y ; Y-coord
  INY
  LDA player_sprites,X
  STA (baseLo),Y ; tile number
  INY
  LDA #%00000000
  ORA sprite_attr
  STA (baseLo),Y ; attributes
  INY
  LDA player_x
  CLC
  ADC #$08
  STA (baseLo),Y ; X-coord
  INY
  INX
  LDA player_dir
  CMP #$02
  BEQ top_left

  ; write bottom-left tile of sprite (must add 8 to the sprite's y position)
  bottom_left:
  LDA player_y
  CLC
  ADC #$08
  STA (baseLo),Y ; Y-coord
  INY
  LDA player_sprites,X
  STA (baseLo),Y ; tile number
  INY
  LDA #%00000000
  ORA sprite_attr
  STA (baseLo),Y ; attributes
  INY
  LDA player_x
  STA (baseLo),Y ; X-coord
  INY
  INX
  LDA player_dir
  CMP #$02
  BEQ end_writing_sprites

  ; write bottom-right tile of sprite (must add 8 to the sprite's x position and
  ; y position)
  bottom_right:
  LDA player_y
  CLC
  ADC #$08
  STA (baseLo),Y ; Y-coord
  INY
  LDA player_sprites,X
  STA (baseLo),Y ; tile number
  INY
  LDA #%00000000
  ORA sprite_attr
  STA (baseLo),Y ; attributes
  INY
  LDA player_x
  CLC
  ADC #$08
  STA (baseLo),Y ; X-coord
  INY
  INX
  LDA player_dir
  CMP #$02
  BEQ bottom_left

  end_writing_sprites:
  ; ; keep baseLo updated for future writes
  ; LDA baseLo
  ; CLC
  ; ADC #$10
  ; STA baseLo

  ; reset sprite attributes to $00
  LDA #$00
  STA sprite_attr 

  PLA
  TAX
  PLA
  RTS
.endproc

.segment "RODATA"
player_sprites:
  .byte $00, $01, $10, $11  ; Standing Still
  .byte $02, $03, $12, $13  ; Running-1
  .byte $04, $05, $14, $15  ; Running-2
  .byte $06, $07, $16, $17  ; Going Up-1
  .byte $08, $09, $18, $19  ; Going Up-2
  .byte $0a, $0b, $1a, $1b  ; Going Down-1
  .byte $0c, $0d, $1c, $1d  ; Going Down-2

enemy_sprites:
  .byte $20, $21, $30, $31  ; Flying-1
  .byte $22, $23, $32, $33  ; Flying-2
  .byte $24, $25, $34, $35  ; Flying-3

coin_sprites:
  .byte $53, $54, $63, $64  ; Observing-1
  .byte $55, $56, $65, $66  ; Observing-2
  .byte $57, $58, $67, $68  ; Observing-3

.include "constants.inc"

.segment "ZEROPAGE"
.importzp player_x, player_y, enemy_x, enemy_y, coin_x, coin_y, timer
.importzp coin_active

baseLo:      .res 1
baseHi:      .res 1
tileIndex:   .res 1
sprite_attr: .res 1
player_dir:  .res 1
.exportzp baseLo, baseHi, tileIndex, sprite_attr, player_dir

.segment "CODE"
.export draw_player, draw_enemy, draw_coin

.proc draw_player
  PHA
  TXA
  PHA

  LDA player_dir
  CMP #$00
  BEQ running_animation
  CMP #$01
  BEQ down_animation
  CMP #$03
  BEQ up_animation

  running_animation:
  LDA timer
  AND #%00010000
  BEQ running_frame1
  running_frame2:
  LDA #$01
  JMP write
  running_frame1:
  LDA #$02
  JMP write

  down_animation:
  LDA timer
  AND #%00010000
  BEQ down_frame1
  down_frame2:
  LDA #$05
  JMP write
  down_frame1:
  LDA #$06
  JMP write

  up_animation:
  LDA timer
  AND #%00010000
  BEQ up_frame1
  up_frame2:
  LDA #$03
  JMP write
  up_frame1:
  LDA #$04
  JMP write

  write:
  ASL A
  ASL A
  STA tileIndex
  JSR write_player_sprite

  PLA
  TAX
  PLA
  RTS
.endproc

.proc draw_enemy
  PHA
  TXA
  PHA

  flying_animation:
  LDA timer
  AND #%00010000
  BEQ flying_frame1
  flying_frame2:
  LDA #$01
  JMP write
  flying_frame1:
  LDA #$02
  JMP write

  write:
  ASL A
  ASL A
  STA tileIndex
  JSR write_enemy_sprite

  PLA
  TAX
  PLA
  RTS
.endproc

.proc draw_coin
  PHA
  TXA
  PHA

  LDA coin_active
  BNE coin_visible
  LDX #$00
hide_coin_oam:
  LDA #$FF
  STA $0220,X
  INX
  INX
  INX
  INX
  CPX #$10
  BNE hide_coin_oam
  PLA
  TAX
  PLA
  RTS

coin_visible:
  observing_animation:
  LDA timer
  AND #%00100000
  BEQ observing_frame1
  observing_frame2:
  LDA #$01
  JMP write
  observing_frame1:
  LDA #$02
  JMP write

  write:
  ASL A
  ASL A
  STA tileIndex
  JSR write_coin_sprite

  PLA
  TAX
  PLA
  RTS
.endproc

; subroutine receives the screen coordinates for a sprite through the `player_x`
; and `player_y`, and the index where the sprite starts from its sprite table
; through `tileIndex`. 
.proc write_player_sprite
  PHA
  TXA
  PHA

  LDA #$00
  STA baseLo

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
  ; reset sprite attributes to $00
  LDA #$00
  STA sprite_attr
  STA baseLo

  PLA
  TAX
  PLA
  RTS
.endproc

; subroutine receives the screen coordinates for a sprite through the `enemy_x`
; and `enemy_y`, and the index where the sprite starts from its sprite table
; through `tileIndex`.
.proc write_enemy_sprite
  PHA
  TXA
  PHA

  LDA #$10
  STA baseLo

  LDA #%00000001
  STA sprite_attr

  start_writing_sprites:
  LDX tileIndex
  LDY #$00

  ; if player is at the sprite's left side, flip sprites horizontally and alter
  ; the write sequence of the sprites so that enemy is always looking at the
  ; player
  LDA player_x
  CMP enemy_x
  BCS top_left
  LDA #%01000001
  STA sprite_attr
  JMP top_right

  ; write top-left tile of sprite
  top_left:
  LDA enemy_y
  STA (baseLo),Y ; Y-coord
  INY
  LDA enemy_sprites,X
  STA (baseLo),Y ; tile number
  INY
  LDA #%00000000
  ORA sprite_attr
  STA (baseLo),Y ; attributes
  INY
  LDA enemy_x
  STA (baseLo),Y ; X-coord
  INY
  INX
  LDA player_x
  CMP enemy_x
  BCC bottom_right

  ; write top-right tile of sprite (must add 8 to the sprite's x position)
  top_right:
  LDA enemy_y
  STA (baseLo),Y ; Y-coord
  INY
  LDA enemy_sprites,X
  STA (baseLo),Y ; tile number
  INY
  LDA #%00000000
  ORA sprite_attr
  STA (baseLo),Y ; attributes
  INY
  LDA enemy_x
  CLC
  ADC #$08
  STA (baseLo),Y ; X-coord
  INY
  INX
  LDA player_x
  CMP enemy_x
  BCC top_left

  ; write bottom-left tile of sprite (must add 8 to the sprite's y position)
  bottom_left:
  LDA enemy_y
  CLC
  ADC #$08
  STA (baseLo),Y ; Y-coord
  INY
  LDA enemy_sprites,X
  STA (baseLo),Y ; tile number
  INY
  LDA #%00000000
  ORA sprite_attr
  STA (baseLo),Y ; attributes
  INY
  LDA enemy_x
  STA (baseLo),Y ; X-coord
  INY
  INX
  LDA player_x
  CMP enemy_x
  BCC end_writing_sprites

  ; write bottom-right tile of sprite (must add 8 to the sprite's x position and
  ; y position)
  bottom_right:
  LDA enemy_y
  CLC
  ADC #$08
  STA (baseLo),Y ; Y-coord
  INY
  LDA enemy_sprites,X
  STA (baseLo),Y ; tile number
  INY
  LDA #%00000000
  ORA sprite_attr
  STA (baseLo),Y ; attributes
  INY
  LDA enemy_x
  CLC
  ADC #$08
  STA (baseLo),Y ; X-coord
  INY
  INX
  LDA player_x
  CMP enemy_x
  BCC bottom_left

  end_writing_sprites:
  ; reset sprite attributes to $00
  LDA #$00
  STA sprite_attr
  STA baseLo

  PLA
  TAX
  PLA
  RTS
.endproc

; subroutine receives the screen coordinates for a sprite through the `coin_x`
; and `coin_y`, and the index where the sprite starts from its sprite table
; through `tileIndex`. 
.proc write_coin_sprite
  PHA
  TXA
  PHA

  LDA #$20
  STA baseLo

  LDA #%00000010
  STA sprite_attr

  start_writing_sprites:
  LDX tileIndex
  LDY #$00

  ; if player is at the sprite's right side, flip sprites horizontally and alte
  ; the write sequence of the sprites so that coin is always looking at the
  ; player
  LDA player_x
  CMP coin_x
  BCC top_left
  LDA #%01000010
  STA sprite_attr
  JMP top_right

  ; write top-left tile of sprite
  top_left:
  LDA coin_y
  STA (baseLo),Y ; Y-coord
  INY
  LDA coin_sprites,X
  STA (baseLo),Y ; tile number
  INY
  LDA #%00000000
  ORA sprite_attr
  STA (baseLo),Y ; attributes
  INY
  LDA coin_x
  STA (baseLo),Y ; X-coord
  INY
  INX
  LDA player_x
  CMP coin_x
  BCS bottom_right

  ; write top-right tile of sprite (must add 8 to the sprite's x position)
  top_right:
  LDA coin_y
  STA (baseLo),Y ; Y-coord
  INY
  LDA coin_sprites,X
  STA (baseLo),Y ; tile number
  INY
  LDA #%00000000
  ORA sprite_attr
  STA (baseLo),Y ; attributes
  INY
  LDA coin_x
  CLC
  ADC #$08
  STA (baseLo),Y ; X-coord
  INY
  INX
  LDA player_x
  CMP coin_x
  BCS top_left

  ; write bottom-left tile of sprite (must add 8 to the sprite's y position)
  bottom_left:
  LDA coin_y
  CLC
  ADC #$08
  STA (baseLo),Y ; Y-coord
  INY
  LDA coin_sprites,X
  STA (baseLo),Y ; tile number
  INY
  LDA #%00000000
  ORA sprite_attr
  STA (baseLo),Y ; attributes
  INY
  LDA coin_x
  STA (baseLo),Y ; X-coord
  INY
  INX
  LDA player_x
  CMP coin_x
  BCS end_writing_sprites

  ; write bottom-right tile of sprite (must add 8 to the sprite's x position and
  ; y position)
  bottom_right:
  LDA coin_y
  CLC
  ADC #$08
  STA (baseLo),Y ; Y-coord
  INY
  LDA coin_sprites,X
  STA (baseLo),Y ; tile number
  INY
  LDA #%00000000
  ORA sprite_attr
  STA (baseLo),Y ; attributes
  INY
  LDA coin_x
  CLC
  ADC #$08
  STA (baseLo),Y ; X-coord
  INY
  INX
  LDA player_x
  CMP coin_x
  BCS bottom_left

  end_writing_sprites:
  ; reset sprite attributes to $00
  LDA #$00
  STA sprite_attr
  STA baseLo

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

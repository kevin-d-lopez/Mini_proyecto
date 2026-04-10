.include "constants.inc"

.segment "ZEROPAGE"
.importzp player_dir
.importzp player_x, player_y, enemy_x, enemy_y, coin_x, coin_y

.segment "CODE"
.export update_sprite

.proc update_sprite
  PHA
  TXA
  PHA

  LDA player_dir
  CMP #$00
  BEQ move_right
  CMP #$01
  BEQ move_down
  CMP #$02
  BEQ move_left
  CMP #$03
  BEQ move_up

  ; increment x position until x = 152
  move_right:
  LDA player_x
  CMP #152
  BEQ set_down
  INC player_x
  JMP end_move_sprite

  set_down:
  LDA #$01
  STA player_dir
  JMP end_move_sprite

  ; once x = 152 is reched, increment y until y = 136
  move_down:
  LDA player_y
  CMP #136
  BEQ set_left
  INC player_y
  JMP end_move_sprite

  set_left:
  LDA #$02
  STA player_dir
  JMP end_move_sprite

  ; once x = 152 and y = 136, decrement x until x = 80
  move_left:
  LDA player_x
  CMP #80
  BEQ set_up
  DEC player_x
  JMP end_move_sprite

  set_up:
  LDA #$03
  STA player_dir
  JMP end_move_sprite

  ; once x = 80, decrement y until y = 88
  move_up:
  LDA player_y
  CMP #88
  BEQ set_right
  DEC player_y
  JMP end_move_sprite

  set_right:
  LDA #$00
  STA player_dir

  end_move_sprite:
  PLA
  TAX
  PLA
  RTS
.endproc
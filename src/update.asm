.include "constants.inc"

.segment "ZEROPAGE"
.importzp player_dir, player_spe
.importzp player_x, player_y, enemy_x, enemy_y, coin_x, coin_y
.importzp controller1

.segment "CODE"
.export update_sprite

.proc update_player_dir
  LDA controller1  ; load button presses
  AND #BTN_LEFT    ; filter out all but left button
  BEQ check_right  ; if result is zero, left not pressed
  ; if the branch above is not taken, set player direction left
  LDA #$02
  STA player_dir

  check_right:
  LDA controller1
  AND #BTN_RIGHT
  BEQ check_up
  ; if the branch above is not taken, set player direction right
  LDA #$00
  STA player_dir

  check_up:
  LDA controller1
  AND #BTN_UP
  BEQ check_down
  ; if the branch above is not taken, set player direction up
  LDA #$03
  STA player_dir

  check_down:
  LDA controller1
  AND #BTN_DOWN
  BEQ done_checking
  ; if the branch above is not taken, set player direction down
  LDA #$01
  STA player_dir

  done_checking:
  RTS
.endproc

.proc update_sprite
  PHA
  TXA
  PHA

  JSR update_player_dir

  LDA player_dir
  CMP #$00
  BEQ move_right
  CMP #$01
  BEQ move_down
  CMP #$02
  BEQ move_left
  CMP #$03
  BEQ move_up

  move_right:
  LDA player_x
  CLC
  ADC player_spe
  STA player_x
  JMP end_move_sprite

  move_down:
  LDA player_y
  CLC
  ADC player_spe
  STA player_y
  JMP end_move_sprite

  move_left:
  LDA player_x
  SEC
  SBC player_spe
  STA player_x
  JMP end_move_sprite

  move_up:
  LDA player_y
  SEC
  SBC player_spe
  STA player_y
  JMP end_move_sprite

  end_move_sprite:
  PLA
  TAX
  PLA
  RTS
.endproc
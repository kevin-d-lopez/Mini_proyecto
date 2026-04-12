.include "constants.inc"

.segment "ZEROPAGE"
.importzp player_dir, player_spe
.importzp player_x, player_y, enemy_x, enemy_y, coin_x, coin_y
.importzp player_hit_l, player_hit_r, player_hit_t, player_hit_b
.importzp enemy_hit_l, enemy_hit_r, enemy_hit_t, enemy_hit_b
.importzp coin_hit_l, coin_hit_r, coin_hit_t, coin_hit_b
.importzp controller1

; scratch for metatile ↔ pixel mapping (update logic only)
coll_px:       .res 1
coll_py:       .res 1
coll_tx:       .res 1
coll_ty:       .res 1
coll_pair:     .res 1
coll_mega:     .res 1
coll_megabyte: .res 1

.segment "CODE"
.import background
.export update_player, update_enemy, update_player_hitbox, update_enemy_hitbox, update_coin_hitbox

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

; Refresh player AABB from player_x/player_y (call after position changes).
.proc update_player_hitbox
  LDA player_x
  CLC
  ADC #PLAYER_HIT_X_OFS
  STA player_hit_l
  CLC
  ADC #(PLAYER_HIT_W - 1)
  STA player_hit_r

  LDA player_y
  CLC
  ADC #PLAYER_HIT_Y_OFS
  STA player_hit_t
  CLC
  ADC #(PLAYER_HIT_H - 1)
  STA player_hit_b
  RTS
.endproc

; Refresh enemy AABB from enemy_x/enemy_y (call after position changes).
.proc update_enemy_hitbox
  LDA enemy_x
  CLC
  ADC #ENEMY_HIT_X_OFS
  STA enemy_hit_l
  CLC
  ADC #(ENEMY_HIT_W - 1)
  STA enemy_hit_r

  LDA enemy_y
  CLC
  ADC #ENEMY_HIT_Y_OFS
  STA enemy_hit_t
  CLC
  ADC #(ENEMY_HIT_H - 1)
  STA enemy_hit_b
  RTS
.endproc

; Refresh coin AABB from coin_x/coin_y (call after position changes).
.proc update_coin_hitbox
  LDA coin_x
  CLC
  ADC #COIN_HIT_X_OFS
  STA coin_hit_l
  CLC
  ADC #(COIN_HIT_W - 1)
  STA coin_hit_r

  LDA coin_y
  CLC
  ADC #COIN_HIT_Y_OFS
  STA coin_hit_t
  CLC
  ADC #(COIN_HIT_H - 1)
  STA coin_hit_b
  RTS
.endproc

; SEC if this pixel lies on a blocking metatile (anything except METATILE_IDX_BACKG).
; CLC if walkable. HUD rows (tile y 0–1) and off-map rows (tile y ≥ 30) block.
.proc metatile_point_solid
  STA coll_px
  STY coll_py

  LDA coll_px
  LSR A
  LSR A
  LSR A
  STA coll_tx

  LDA coll_py
  LSR A
  LSR A
  LSR A
  STA coll_ty

  LDA coll_ty
  CMP #2
  BCC solid_ps
  CMP #30
  BCS solid_ps

  SEC
  SBC #2
  LSR A
  STA coll_pair

  LDA coll_tx
  LSR A
  LSR A
  LSR A
  STA coll_mega

  LDA coll_pair
  ASL A
  ASL A
  ORA coll_mega
  TAX
  LDA background,X
  STA coll_megabyte

  LDA coll_tx
  AND #$07
  LSR A
  BEQ strip0
  CMP #1
  BEQ strip1
  CMP #2
  BEQ strip2
  JMP strip3

  strip0:
  LDA coll_megabyte
  AND #$C0
  LSR A
  LSR A
  LSR A
  LSR A
  LSR A
  LSR A
  JMP cmp_walk

  strip1:
  LDA coll_megabyte
  AND #$30
  LSR A
  LSR A
  LSR A
  LSR A
  JMP cmp_walk

  strip2:
  LDA coll_megabyte
  AND #$0C
  LSR A
  LSR A
  JMP cmp_walk

  strip3:
  LDA coll_megabyte
  AND #$03

  cmp_walk:
  CMP #METATILE_IDX_BACKG
  BEQ walkable_ps
  solid_ps:
  SEC
  RTS
  walkable_ps:
  CLC
  RTS
.endproc

.proc metatile_player_blocked
  LDA player_hit_l
  LDY player_hit_t
  JSR metatile_point_solid
  BCS blocked_pb
  LDA player_hit_r
  LDY player_hit_t
  JSR metatile_point_solid
  BCS blocked_pb
  LDA player_hit_l
  LDY player_hit_b
  JSR metatile_point_solid
  BCS blocked_pb
  LDA player_hit_r
  LDY player_hit_b
  JSR metatile_point_solid
  BCS blocked_pb
  CLC
  RTS
  blocked_pb:
  SEC
  RTS
.endproc

.proc metatile_enemy_blocked
  LDA enemy_hit_l
  LDY enemy_hit_t
  JSR metatile_point_solid
  BCS blocked_eb
  LDA enemy_hit_r
  LDY enemy_hit_t
  JSR metatile_point_solid
  BCS blocked_eb
  LDA enemy_hit_l
  LDY enemy_hit_b
  JSR metatile_point_solid
  BCS blocked_eb
  LDA enemy_hit_r
  LDY enemy_hit_b
  JSR metatile_point_solid
  BCS blocked_eb
  CLC
  RTS
  blocked_eb:
  SEC
  RTS
.endproc

.proc update_player
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
  PHA
  CLC
  ADC player_spe
  STA player_x
  JSR update_player_hitbox
  JSR metatile_player_blocked
  BCS revert_move_x
  PLA
  JMP end_move_sprite
  revert_move_x:
  PLA
  STA player_x
  JMP end_move_sprite

  move_down:
  LDA player_y
  PHA
  CLC
  ADC player_spe
  STA player_y
  JSR update_player_hitbox
  JSR metatile_player_blocked
  BCS revert_move_y
  PLA
  JMP end_move_sprite
  revert_move_y:
  PLA
  STA player_y
  JMP end_move_sprite

  move_left:
  LDA player_x
  PHA
  SEC
  SBC player_spe
  STA player_x
  JSR update_player_hitbox
  JSR metatile_player_blocked
  BCS revert_move_x2
  PLA
  JMP end_move_sprite
  revert_move_x2:
  PLA
  STA player_x
  JMP end_move_sprite

  move_up:
  LDA player_y
  PHA
  SEC
  SBC player_spe
  STA player_y
  JSR update_player_hitbox
  JSR metatile_player_blocked
  BCS revert_move_y2
  PLA
  JMP end_move_sprite
  revert_move_y2:
  PLA
  STA player_y
  JMP end_move_sprite

  end_move_sprite:
  JSR update_player_hitbox
  PLA
  TAX
  PLA
  RTS
.endproc

.proc update_enemy
  PHA
  TXA
  PHA

  LDA enemy_x
  PHA
  LDA player_x
  CMP enemy_x
  BCS enemy_move_right

  enemy_move_left:
  DEC enemy_x
  JMP enemy_after_x_try

  enemy_move_right:
  INC enemy_x

  enemy_after_x_try:
  JSR update_enemy_hitbox
  JSR metatile_enemy_blocked
  BCS enemy_revert_x
  PLA
  JMP enemy_x_ok
  enemy_revert_x:
  PLA
  STA enemy_x
  JSR update_enemy_hitbox

  enemy_x_ok:
  LDA enemy_y
  PHA
  LDA player_y
  CMP enemy_y
  BCS enemy_move_down

  enemy_move_up:
  DEC enemy_y
  JMP enemy_after_y_try

  enemy_move_down:
  INC enemy_y

  enemy_after_y_try:
  JSR update_enemy_hitbox
  JSR metatile_enemy_blocked
  BCS enemy_revert_y
  PLA
  JMP end_move_sprite
  enemy_revert_y:
  PLA
  STA enemy_y

  end_move_sprite:
  JSR update_enemy_hitbox
  PLA
  TAX
  PLA
  RTS
.endproc

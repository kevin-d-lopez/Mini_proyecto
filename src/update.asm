.include "constants.inc"

.segment "ZEROPAGE"
.importzp player_dir
.importzp player_x, player_y, enemy_x, enemy_y, coin_x, coin_y
.importzp player_hit_l, player_hit_r, player_hit_t, player_hit_b
.importzp enemy_hit_l, enemy_hit_r, enemy_hit_t, enemy_hit_b
.importzp coin_hit_l, coin_hit_r, coin_hit_t, coin_hit_b
.importzp player_lives, player_score, player_iframes, coin_active
.importzp game_over
.importzp coin_cooldown
.importzp player_spe, enemy_spe, enemy_axis_phase
.importzp game_paused, prev_controller1
.importzp rand_l, rand_h
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
.export update_interactions, handle_pause_input, sync_enemy_speed_from_player

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

.proc coin_spawn_blocked
  LDA coin_hit_l
  LDY coin_hit_t
  JSR metatile_point_solid
  BCS csb_yes
  LDA coin_hit_r
  LDY coin_hit_t
  JSR metatile_point_solid
  BCS csb_yes
  LDA coin_hit_l
  LDY coin_hit_b
  JSR metatile_point_solid
  BCS csb_yes
  LDA coin_hit_r
  LDY coin_hit_b
  JSR metatile_point_solid
  BCS csb_yes
  CLC
  RTS
csb_yes:
  SEC
  RTS
.endproc

.proc player_take_damage
  LDA player_iframes
  BNE ptd_done
  LDA player_lives
  BEQ ptd_done
  DEC player_lives
  LDA #DAMAGE_IFRAMES
  STA player_iframes
  LDA player_lives
  BNE ptd_done
  LDA #$01
  STA game_over
ptd_done:
  RTS
.endproc

.proc rand_byte
  LDA rand_l
  ASL A
  ROL rand_h
  BCC rand_done
  LDA rand_l
  EOR #$B4
  STA rand_l
  LDA rand_h
  EOR #$C1
  STA rand_h
rand_done:
  LDA rand_l
  EOR rand_h
  RTS
.endproc

.proc player_enemy_overlap
  LDA player_hit_r
  CMP enemy_hit_l
  BCC peo_no
  LDA enemy_hit_r
  CMP player_hit_l
  BCC peo_no
  LDA player_hit_b
  CMP enemy_hit_t
  BCC peo_no
  LDA enemy_hit_b
  CMP player_hit_t
  BCC peo_no
  SEC
  RTS
peo_no:
  CLC
  RTS
.endproc

.proc player_coin_overlap
  LDA player_hit_r
  CMP coin_hit_l
  BCC pco_no
  LDA coin_hit_r
  CMP player_hit_l
  BCC pco_no
  LDA player_hit_b
  CMP coin_hit_t
  BCC pco_no
  LDA coin_hit_b
  CMP player_hit_t
  BCC pco_no
  SEC
  RTS
pco_no:
  CLC
  RTS
.endproc

.proc coin_overlaps_actor
  LDA coin_hit_r
  CMP player_hit_l
  BCC coa_try_enemy
  LDA player_hit_r
  CMP coin_hit_l
  BCC coa_try_enemy
  LDA coin_hit_b
  CMP player_hit_t
  BCC coa_try_enemy
  LDA player_hit_b
  CMP coin_hit_t
  BCC coa_try_enemy
  SEC
  RTS
coa_try_enemy:
  LDA coin_hit_r
  CMP enemy_hit_l
  BCC coa_clear
  LDA enemy_hit_r
  CMP coin_hit_l
  BCC coa_clear
  LDA coin_hit_b
  CMP enemy_hit_t
  BCC coa_clear
  LDA enemy_hit_b
  CMP coin_hit_t
  BCC coa_clear
  SEC
  RTS
coa_clear:
  CLC
  RTS
.endproc

.proc respawn_coin_random
  LDX #0
rc_try:
  JSR rand_byte
  AND #$1F
  CMP #1
  BCC rc_next
  CMP #29
  BCS rc_next
  ASL A
  ASL A
  ASL A
  STA coin_x

  JSR rand_byte
  AND #$1F
  CMP #3
  BCC rc_next
  CMP #29
  BCS rc_next
  ASL A
  ASL A
  ASL A
  STA coin_y

  JSR update_coin_hitbox
  JSR coin_spawn_blocked
  BCS rc_next
  JSR coin_overlaps_actor
  BCS rc_next

  LDA #1
  STA coin_active
  RTS

rc_next:
  INX
  CPX #COIN_RESPAWN_ATTEMPTS
  BNE rc_try

  LDA #INITIAL_COIN_X
  STA coin_x
  LDA #INITIAL_COIN_Y
  STA coin_y
  LDA #1
  STA coin_active
  JSR update_coin_hitbox
  JSR coin_spawn_blocked
  BCS fb_nudge
  JSR coin_overlaps_actor
  BCC fb_ok

fb_nudge:
  LDX #$00
fb_nudge_loop:
  LDA coin_x
  CLC
  ADC #16
  STA coin_x
  JSR update_coin_hitbox
  JSR coin_spawn_blocked
  BCS fb_nudge_next
  JSR coin_overlaps_actor
  BCC fb_ok
fb_nudge_next:
  INX
  CPX #$10
  BNE fb_nudge_loop
fb_ok:
  RTS
.endproc

.proc update_interactions
  LDA coin_cooldown
  BEQ ui_cd_done
  DEC coin_cooldown
ui_cd_done:

  JSR player_enemy_overlap
  BCC ui_coin
  JSR player_take_damage

ui_coin:
  LDA coin_cooldown
  BNE ui_done
  LDA coin_active
  BEQ ui_done
  JSR player_coin_overlap
  BCC ui_done

  INC player_score

  LDA player_spe
  CMP #MAX_PLAYER_SPE
  BCS ui_sp
  INC player_spe
ui_sp:

  JSR sync_enemy_speed_from_player

  LDA #COIN_PICKUP_COOLDOWN
  STA coin_cooldown
  JSR respawn_coin_random

ui_done:
  RTS
.endproc

; enemy_spe = min(MAX_ENEMY_SPE, max(1, player_spe - 1)) so enemy stays slower.
.proc sync_enemy_speed_from_player
  LDA player_spe
  CMP #$01
  BEQ sync_es_min
  SEC
  SBC #$01
  JMP sync_es_cap
sync_es_min:
  LDA #$01
sync_es_cap:
  CMP #MAX_ENEMY_SPE
  BCC sync_es_store
  BEQ sync_es_store
  LDA #MAX_ENEMY_SPE
sync_es_store:
  STA enemy_spe
  RTS
.endproc

.proc handle_pause_input
  LDA controller1
  AND #BTN_START
  BEQ hp_store
  LDA prev_controller1
  AND #BTN_START
  BNE hp_store
  LDA game_paused
  EOR #$01
  STA game_paused
hp_store:
  LDA controller1
  STA prev_controller1
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
  JSR player_take_damage
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
  JSR player_take_damage
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
  JSR player_take_damage
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
  JSR player_take_damage
  JMP end_move_sprite

  end_move_sprite:
  JSR update_player_hitbox
  PLA
  TAX
  PLA
  RTS
.endproc

; One axis per logic tick (alternates X / Y) so total step matches player style.
.proc update_enemy
  PHA
  TXA
  PHA

  LDA enemy_axis_phase
  BNE enemy_tick_y

  LDA enemy_x
  PHA
  LDA player_x
  CMP enemy_x
  BCS en_x_right
  SEC
  LDA enemy_x
  SBC enemy_spe
  STA enemy_x
  JMP en_after_x
en_x_right:
  CLC
  LDA enemy_x
  ADC enemy_spe
  STA enemy_x
en_after_x:
  JSR update_enemy_hitbox
  JSR metatile_enemy_blocked
  BCS en_rev_x
  PLA
  JMP en_toggle_phase
en_rev_x:
  PLA
  STA enemy_x
  JSR update_enemy_hitbox
  JMP en_toggle_phase

enemy_tick_y:
  LDA enemy_y
  PHA
  LDA player_y
  CMP enemy_y
  BCS en_y_down
  SEC
  LDA enemy_y
  SBC enemy_spe
  STA enemy_y
  JMP en_after_y
en_y_down:
  CLC
  LDA enemy_y
  ADC enemy_spe
  STA enemy_y
en_after_y:
  JSR update_enemy_hitbox
  JSR metatile_enemy_blocked
  BCS en_rev_y
  PLA
  JMP en_toggle_phase
en_rev_y:
  PLA
  STA enemy_y
  JSR update_enemy_hitbox

en_toggle_phase:
  LDA enemy_axis_phase
  EOR #$01
  STA enemy_axis_phase
  PLA
  TAX
  PLA
  RTS
.endproc

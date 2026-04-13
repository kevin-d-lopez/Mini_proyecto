.include "constants.inc"

.segment "ZEROPAGE"
; zeropage variables from main.asm
.importzp player_x, player_y, enemy_x, enemy_y, coin_x, coin_y, player_spe, timer, nmi_counter, enemy_spe
.importzp player_lives, player_score, player_iframes, coin_active, game_paused, prev_controller1
.importzp rand_l, rand_h
.importzp game_over
.importzp game_over_done
.importzp coin_cooldown
.importzp enemy_axis_phase

; zeropage variables from draw.asm
.importzp baseLo, baseHi, sprite_attr, player_dir

.segment "CODE"
.import main
.import update_player_hitbox
.import update_enemy_hitbox
.import update_coin_hitbox
.import sync_enemy_speed_from_player
.export reset_handler
.proc reset_handler
  SEI
  CLD
  LDX #$40
  STX $4017
  LDX #$FF
  TXS
  INX
  STX $2000
  STX $2001
  STX $4010
  BIT $2002
vblankwait:
  BIT $2002
  BPL vblankwait

	LDX #$00
	LDA #$FF
clear_oam:
	STA $0200,X ; set sprite y-positions off the screen
	INX
	INX
	INX
	INX
	BNE clear_oam

  ; initialize zero-page variables
  LDA #INITIAL_PLAYER_X
  STA player_x
  LDA #INITIAL_PLAYER_Y
  STA player_y
  JSR update_player_hitbox

  LDA #INITIAL_ENEMY_X
  STA enemy_x
  LDA #INITIAL_ENEMY_Y
  STA enemy_y
  JSR update_enemy_hitbox

  LDA #INITIAL_COIN_X
  STA coin_x
  LDA #INITIAL_COIN_Y
  STA coin_y
  JSR update_coin_hitbox

  LDA #INITIAL_PLAYER_SPE
  STA player_spe
  JSR sync_enemy_speed_from_player
  LDA #$00
  STA enemy_axis_phase

  LDA #INITIAL_PLAYER_LIVES
  STA player_lives
  LDA #$00
  STA player_score
  STA player_iframes
  LDA #$01
  STA coin_active
  LDA #$00
  STA game_paused
  STA prev_controller1
  STA game_over
  STA game_over_done
  STA coin_cooldown
  LDA #$C5
  STA rand_l
  LDA #$9A
  STA rand_h

  ; initialize player attributes, initial direction, and a timer to $00
  LDA #$00
  STA sprite_attr
  STA player_dir
  STA timer
  STA nmi_counter

  ; where to start writing sprites
  LDA #$02
  STA baseHi
  LDA #$00
  STA baseLo

vblankwait2:
  BIT $2002
  BPL vblankwait2
  JMP main
.endproc

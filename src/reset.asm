.include "constants.inc"

.segment "ZEROPAGE"
.importzp player_x, player_y, enemy_x, enemy_y, coin_x, coin_y, sprite_attr, player_dir, nmi_counter, player_spe

.segment "CODE"
.import main
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

  LDA #INITIAL_ENEMY_X
  STA enemy_x
  LDA #INITIAL_ENEMY_Y
  STA enemy_y

  LDA #INITIAL_COIN_X
  STA coin_x
  LDA #INITIAL_COIN_Y
  STA coin_y

  LDA #INITIAL_PLAYER_SPE
  STA player_spe

  ; initialize player attributes, initial direction, and nmi counter to $00
  LDA #$00
  STA sprite_attr
  STA player_dir
  STA nmi_counter

vblankwait2:
  BIT $2002
  BPL vblankwait2
  JMP main
.endproc

PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
OAMADDR   = $2003
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007
OAMDMA    = $4014

; controllers
CONTROLLER1 = $4016
CONTROLLER2 = $4017
BTN_RIGHT   = %00000001
BTN_LEFT    = %00000010
BTN_DOWN    = %00000100
BTN_UP      = %00001000
BTN_START   = %00010000
BTN_SELECT  = %00100000
BTN_B       = %01000000
BTN_A       = %10000000

; sprite initial positions
INITIAL_PLAYER_X = $20
INITIAL_PLAYER_Y = $70
INITIAL_ENEMY_X  = $E0
INITIAL_ENEMY_Y  = $30
INITIAL_COIN_X   = $20
INITIAL_COIN_Y   = $C0

; player initial parameters
INITIAL_PLAYER_SPE = $02
INITIAL_ENEMY_SPE  = $01

; player hitbox (pixels, inclusive edges; relative to sprite top-left player_x/player_y)
PLAYER_HIT_X_OFS = 0
PLAYER_HIT_Y_OFS = 0
PLAYER_HIT_W     = 16
PLAYER_HIT_H     = 16

; enemy hitbox (same convention, relative to enemy_x/enemy_y)
ENEMY_HIT_X_OFS = 0
ENEMY_HIT_Y_OFS = 0
ENEMY_HIT_W     = 16
ENEMY_HIT_H     = 16

; coin hitbox (write_coin_sprite is 2×2 tiles from coin_x/coin_y)
COIN_HIT_X_OFS = 0
COIN_HIT_Y_OFS = 0
COIN_HIT_W     = 16
COIN_HIT_H     = 16

; Packed megatile row index for "backg" (.byte $08,$09,$18,$19) — walkable floor
METATILE_IDX_BACKG = 3

INITIAL_PLAYER_LIVES = 3
DAMAGE_IFRAMES       = 60

MAX_PLAYER_SPE = $08
MAX_ENEMY_SPE  = $06

COIN_RESPAWN_ATTEMPTS = 64

; Logic ticks before coin pickup can register again (avoids double-collect / speed spike)
COIN_PICKUP_COOLDOWN = 12

; Score as sprites: tiles $42–$4B = digits 0–9; align with nametable cell $2026 (row 1, col 6)
SCORE_DIGIT_TILE_0 = $42
SCORE_SPRITE_Y     = 8
SCORE_SPRITE_X0    = 48

; =============================================================================
; GAME OVER — nametable text template (edit tile numbers to match your CHR)
; Background uses pattern table 0 ($2000 side); use the same tile IDs as BG art.
; =============================================================================

; First character cell: row 0 = top of nametable ($2000), col 0 = left (32 wide).
GAME_OVER_NMT_ROW = 14
GAME_OVER_NMT_COL = 10

; Length of the message below (must match number of .byte entries)
GAME_OVER_LEN = 9

; One byte per on-screen character, left to right:  G A M E [space] O V E R
GAME_OVER_T_G     = $30      
GAME_OVER_T_A     = $31    
GAME_OVER_T_M     = $32    
GAME_OVER_T_E1    = $33    
GAME_OVER_T_SPACE = $0d     
GAME_OVER_T_O     = $34    
GAME_OVER_T_V     = $35    
GAME_OVER_T_E2    = $33    
GAME_OVER_T_R     = $36   

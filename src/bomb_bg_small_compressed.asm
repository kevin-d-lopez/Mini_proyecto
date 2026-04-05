.segment "RODATA"
.export bomb_bg_mt2b_small

; 2-bit-per-metatile index map for a FULL SCREEN REGION.
; - Metatile grid size: 16 columns × 15 rows = 240 metatiles
; - Packing: 4 metatile indices per byte (2 bits each)
;   bits 1..0 = mt0, 3..2 = mt1, 5..4 = mt2, 7..6 = mt3
;
; Metatile indices correspond to metatile_sets entries:
;   0..3 only (fits in 2 bits)
;
; Row 0 and 1 mirror the top of bomb_bg (approximate),
; the remaining rows use simple repeating patterns with indices 0..3.

bomb_bg_mt2b_small:
  ; Row 0 (metatile indices): 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
  ; Packed: [1,1,1,1] x4 -> $55 each
  .byte $55,$55,$55,$55

  ; Row 1 (metatile indices, '?' approximated as 0):
  ; 1,0,2,3, 3,0,0,0, 0,0,2,2, 0,0,0,1
  .byte $E1,$03,$A0,$40

  ; Row 2: simple pattern 0,1,2,3 repeated
  ; indices: 0,1,2,3, 0,1,2,3, 0,1,2,3, 0,1,2,3
  ; [0,1,2,3] -> 0 | (1<<2) | (2<<4) | (3<<6) = $D4
  .byte $D4,$D4,$D4,$D4

  ; Row 3: 1,2,3,0 repeated
  ; [1,2,3,0] -> 1 | (2<<2) | (3<<4) | (0<<6) = $39
  .byte $39,$39,$39,$39

  ; Row 4: stripe of metatile 2
  ; indices: all 2 -> [2,2,2,2] -> 2 | (2<<2) | (2<<4) | (2<<6) = $AA
  .byte $AA,$AA,$AA,$AA

  ; Row 5: stripe of metatile 3
  ; [3,3,3,3] -> $FF
  .byte $FF,$FF,$FF,$FF

  ; Row 6: alternating 0 and 1 (0,1,0,1,...)
  ; [0,1,0,1] -> 0 | (1<<2) | (0<<4) | (1<<6) = $44
  .byte $44,$44,$44,$44

  ; Row 7: alternating 2 and 3 (2,3,2,3,...)
  ; [2,3,2,3] -> 2 | (3<<2) | (2<<4) | (3<<6) = $FE
  .byte $FE,$FE,$FE,$FE

  ; Row 8: gradient 0,0,1,1,2,2,3,3 repeated twice
  ; groups: [0,0,1,1] -> 0 | (0<<2) | (1<<4) | (1<<6) = $50
  ;         [2,2,3,3] -> 2 | (2<<2) | (3<<4) | (3<<6) = $FA
  .byte $50,$FA,$50,$FA

  ; Row 9: inverse gradient 3,3,2,2,1,1,0,0 repeated twice
  ; groups: [3,3,2,2] -> 3 | (3<<2) | (2<<4) | (2<<6) = $BB
  ;         [1,1,0,0] -> 1 | (1<<2) | (0<<4) | (0<<6) = $05
  .byte $BB,$05,$BB,$05

  ; Row 10: checker of 0 and 2 (0,2,0,2,...)
  ; [0,2,0,2] -> 0 | (2<<2) | (0<<4) | (2<<6) = $88
  .byte $88,$88,$88,$88

  ; Row 11: checker of 1 and 3 (1,3,1,3,...)
  ; [1,3,1,3] -> 1 | (3<<2) | (1<<4) | (3<<6) = $DD
  .byte $DD,$DD,$DD,$DD

  ; Row 12: mostly 0 with 1s at ends: 1,0,0,0, 0,0,0,1, ... repeated
  ; [1,0,0,0] -> 1 | 0 | 0 | 0 = $01
  ; [0,0,0,1] -> 0 | 0 | 0 | (1<<6) = $40
  .byte $01,$40,$01,$40

  ; Row 13: mostly 3 with 2s in middle: 3,3,2,2 repeated
  ; [3,3,2,2] -> $BB
  .byte $BB,$BB,$BB,$BB

  ; Row 14: bottom row all metatile 0
  ; [0,0,0,0] -> $00
  .byte $00,$00,$00,$00


.include "constants.inc"
.include "header.inc"

.segment "ZEROPAGE"
mt_rows_left: .res 1   ; how many metatile rows left to draw
mt_packed:    .res 1   ; current packed 2bpp byte
mt_row_buf:   .res 16  ; unpacked metatile indices for one row

mt_nt_lo:     .res 1   ; pointer to top-left tile in bomb_bg (low)
mt_nt_hi:     .res 1   ; pointer to top-left tile in bomb_bg (high)
mt_col:       .res 1   ; metatile column (0..15)
mt_mtidx:     .res 1   ; current metatile index being tested (0..3)
mt_tmp0:      .res 1   ; TL
mt_tmp1:      .res 1   ; TR
mt_tmp2:      .res 1   ; BL
mt_tmp3:      .res 1   ; BR

mt_build_rows_left: .res 1   ; how many metatile rows to derive
mt_build_row_idx:   .res 1   ; metatile row index 0..7 (for debug)
mt_out_pos:          .res 1   ; write position (0..59) in mt2b_stream_0_14

.segment "BSS"
mt_index_row0: .res 16  ; derived metatile indices for row 0 (debug)

mt2b_stream_0_14: .res 60 ; derived 2-bit metatile stream for rows 0..14 (15 rows × 4 bytes)

.segment "CODE"
.proc irq_handler
  RTI
.endproc

.proc nmi_handler
  RTI ; Return from interrupt
.endproc

.import reset_handler

.proc build_mt_index_row0
    ; Start at bomb_bg + 0 (top-left tile of screen)
    LDA #<bomb_bg
    STA mt_nt_lo
    LDA #>bomb_bg
    STA mt_nt_hi

    LDA #$00
    STA mt_col          ; column = 0

next_metatile_col:
    ; Read TL and TR (top row)
    LDY #$00
    LDA (mt_nt_lo),Y    ; TL
    STA mt_tmp0
    INY
    LDA (mt_nt_lo),Y    ; TR
    STA mt_tmp1

    ; Read BL and BR (bottom row) at +32 bytes
    CLC
    LDA mt_nt_lo
    ADC #32
    STA mt_nt_lo
    LDA mt_nt_hi
    ADC #0
    STA mt_nt_hi

    LDY #$00
    LDA (mt_nt_lo),Y    ; BL
    STA mt_tmp2
    INY
    LDA (mt_nt_lo),Y    ; BR
    STA mt_tmp3

    ; Restore pointer to top row for next column (-32)
    SEC
    LDA mt_nt_lo
    SBC #32
    STA mt_nt_lo
    LDA mt_nt_hi
    SBC #0
    STA mt_nt_hi

    ; Find matching metatile index 0..3
    LDA #$00
    STA mt_mtidx

find_match_loop:
    LDA mt_mtidx
    CMP #$04
    BEQ no_match

    ASL A               ; *2
    ASL A               ; *4
    TAY                 ; Y = offset into metatile_sets

    LDA metatile_sets,Y
    CMP mt_tmp0
    BNE next_idx
    INY
    LDA metatile_sets,Y
    CMP mt_tmp1
    BNE next_idx
    INY
    LDA metatile_sets,Y
    CMP mt_tmp2
    BNE next_idx
    INY
    LDA metatile_sets,Y
    CMP mt_tmp3
    BNE next_idx

    JMP matched

next_idx:
    INC mt_mtidx
    JMP find_match_loop

no_match:
    LDA #$00
    STA mt_mtidx

matched:
    ; Store index into mt_index_row0[col]
    LDX mt_col
    LDA mt_mtidx
    STA mt_index_row0,X

    ; Advance to next metatile column: +2 tiles in top row
    CLC
    LDA mt_nt_lo
    ADC #2
    STA mt_nt_lo
    BCC :+
    INC mt_nt_hi
:
    INC mt_col
    LDA mt_col
    CMP #16
    BCS mt_row0_done
    JMP next_metatile_col

mt_row0_done:
    RTS
.endproc

.proc build_mt2b_rows_0_14
  ; Derive metatile indices for metatile rows 0..14 directly from bomb_bg,
  ; then pack them into the 2-bit format your decompressor expects.
  ;
  ; Option A: if a 2x2 tile block doesn't match any entry in metatile_sets,
  ; fall back to metatile index 0.

  ; Start pointer at bomb_bg + top-left tile (tile row 0, col 0)
  LDA #<bomb_bg
  STA mt_nt_lo
  LDA #>bomb_bg
  STA mt_nt_hi

  LDA #$0F
  STA mt_build_rows_left

  LDA #$00
  STA mt_build_row_idx

  ; Output position = 0
  STA mt_out_pos

outer_mt_row_loop:
  ; Build one metatile row (16 metatiles => mt_row_buf[0..15])
  LDX #$00               ; metatile column index (0..15)

inner_mt_col_loop:
  ; TL = (ptr + 0)
  LDY #$00
  LDA (mt_nt_lo),Y
  STA mt_tmp0

  ; TR = (ptr + 1)
  INY
  LDA (mt_nt_lo),Y
  STA mt_tmp1

  ; BL = (ptr + 32)
  LDY #$20
  LDA (mt_nt_lo),Y
  STA mt_tmp2

  ; BR = (ptr + 33)
  INY
  LDA (mt_nt_lo),Y
  STA mt_tmp3

  ; Find exact match in metatile_sets[0..3], else fallback to 0
  LDA #$00
  STA mt_mtidx

find_match_loop_2:
  LDA mt_mtidx
  CMP #$04
  BEQ no_match_2

  ; Y = metatile_sets + mt_mtidx*4
  ASL A
  ASL A
  TAY

  LDA metatile_sets,Y
  CMP mt_tmp0
  BNE next_idx_2
  INY
  LDA metatile_sets,Y
  CMP mt_tmp1
  BNE next_idx_2
  INY
  LDA metatile_sets,Y
  CMP mt_tmp2
  BNE next_idx_2
  INY
  LDA metatile_sets,Y
  CMP mt_tmp3
  BNE next_idx_2

  JMP matched_2

next_idx_2:
  INC mt_mtidx
  JMP find_match_loop_2

no_match_2:
  LDA #$00
  STA mt_mtidx

matched_2:
  ; Store derived index into mt_row_buf[col]
  LDA mt_mtidx
  STA mt_row_buf,X

  ; If this is row 0, also write to debug mt_index_row0
  LDA mt_build_row_idx
  BNE skip_mt_index_row0_store
  LDA mt_mtidx
  STA mt_index_row0,X

skip_mt_index_row0_store:
  ; Advance to next metatile column (top-left tile moves +2 tiles => +2 bytes)
  CLC
  LDA mt_nt_lo
  ADC #$02
  STA mt_nt_lo
  BCC :+
  INC mt_nt_hi
:
  INX
  CPX #$10
  BNE inner_mt_col_loop

  ; Pack 16 indices into 4 bytes and store into mt2b_stream_0_14 at mt_out_pos..+3
  LDY mt_out_pos

  ; byte0 from indices 0..3
  LDA mt_row_buf
  STA mt_packed
  LDA mt_row_buf+1
  ASL A
  ASL A
  ORA mt_packed
  STA mt_packed
  LDA mt_row_buf+2
  ASL A
  ASL A
  ASL A
  ASL A
  ORA mt_packed
  STA mt_packed
  LDA mt_row_buf+3
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ORA mt_packed
  STA mt2b_stream_0_14,Y
  INY

  ; byte1 from indices 4..7
  LDA mt_row_buf+4
  STA mt_packed
  LDA mt_row_buf+5
  ASL A
  ASL A
  ORA mt_packed
  STA mt_packed
  LDA mt_row_buf+6
  ASL A
  ASL A
  ASL A
  ASL A
  ORA mt_packed
  STA mt_packed
  LDA mt_row_buf+7
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ORA mt_packed
  STA mt2b_stream_0_14,Y
  INY

  ; byte2 from indices 8..11
  LDA mt_row_buf+8
  STA mt_packed
  LDA mt_row_buf+9
  ASL A
  ASL A
  ORA mt_packed
  STA mt_packed
  LDA mt_row_buf+10
  ASL A
  ASL A
  ASL A
  ASL A
  ORA mt_packed
  STA mt_packed
  LDA mt_row_buf+11
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ORA mt_packed
  STA mt2b_stream_0_14,Y
  INY

  ; byte3 from indices 12..15
  LDA mt_row_buf+12
  STA mt_packed
  LDA mt_row_buf+13
  ASL A
  ASL A
  ORA mt_packed
  STA mt_packed
  LDA mt_row_buf+14
  ASL A
  ASL A
  ASL A
  ASL A
  ORA mt_packed
  STA mt_packed
  LDA mt_row_buf+15
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ASL A
  ORA mt_packed
  STA mt2b_stream_0_14,Y
  INY

  STY mt_out_pos

  ; After finishing 16 columns, mt_nt is already 32 bytes to the right
  ; (because we advanced +2 × 16). To get to the next metatile row at
  ; column 0, add +32 bytes total.
  CLC
  LDA mt_nt_lo
  ADC #$20
  STA mt_nt_lo
  BCC :+
  INC mt_nt_hi
:

  ; mt_build_row_idx++
  INC mt_build_row_idx
  DEC mt_build_rows_left
  LDA mt_build_rows_left
  BEQ mt2b_done
  JMP outer_mt_row_loop

mt2b_done:

  RTS
.endproc

.proc draw_bg_small_mt2b
  ; Draw TOP REGION using a 2bpp metatile index map:
  ; - 16×8 metatiles => 32×16 tiles => 512 nametable bytes
  ; Then zero-fill the rest of the nametable.

  ; $00-$01: pointer to compressed metatile index bytes
  LDA #<mt2b_stream_0_14
  STA $00
  LDA #>mt2b_stream_0_14
  STA $01

  ; Set PPU address to $2000 (nametable 0)
  LDA PPUSTATUS
  LDA #$20
  STA PPUADDR
  LDA #$00
  STA PPUADDR

  ; We will draw 15 metatile rows.
  LDA #$0F
  STA mt_rows_left

mt_row_loop:
  ; Unpack 16 metatile indices (4 packed bytes) into mt_row_buf[0..15]
  LDY #$00                ; offset into compressed stream (0..3)
  LDX #$00                ; buffer index (0..15)

unpack_next_packed:
  ; Load one packed byte containing 4 metatile indices (2 bits each)
  LDA ($00),Y
  STA mt_packed

  ; idx0 = (packed & %00000011)
  LDA mt_packed
  AND #$03
  STA mt_row_buf,X
  INX

  ; idx1 = ((packed >> 2) & %00000011)
  LDA mt_packed
  LSR A
  LSR A
  AND #$03
  STA mt_row_buf,X
  INX

  ; idx2 = ((packed >> 4) & %00000011)
  LDA mt_packed
  LSR A
  LSR A
  LSR A
  LSR A
  AND #$03
  STA mt_row_buf,X
  INX

  ; idx3 = ((packed >> 6) & %00000011)
  LDA mt_packed
  LSR A
  LSR A
  LSR A
  LSR A
  LSR A
  LSR A
  AND #$03
  STA mt_row_buf,X
  INX

  INY
  CPY #$04
  BNE unpack_next_packed

  ; Write TOP tile row for this metatile row (32 bytes)
  LDX #$00
write_top_tiles:
  LDA mt_row_buf,X         ; idx 0..3
  ASL A
  ASL A                    ; idx*4
  TAY

  LDA metatile_sets,Y      ; top-left
  STA PPUDATA
  INY
  LDA metatile_sets,Y      ; top-right
  STA PPUDATA

  INX
  CPX #$10                 ; 16 metatiles
  BNE write_top_tiles

  ; Write BOTTOM tile row for this metatile row (32 bytes)
  LDX #$00
write_bottom_tiles:
  LDA mt_row_buf,X
  ASL A
  ASL A
  TAY
  INY
  INY                      ; +2 => bottom-left

  LDA metatile_sets,Y
  STA PPUDATA
  INY                      ; bottom-right
  LDA metatile_sets,Y
  STA PPUDATA

  INX
  CPX #$10
  BNE write_bottom_tiles

  ; Advance compressed pointer by 4 bytes (one metatile row)
  CLC
  LDA $00
  ADC #$04
  STA $00
  BCC :+
  INC $01
:

  ; Decrement rows remaining
  DEC mt_rows_left
  BNE mt_row_loop

  ; Zero-fill attribute table ($23C0..$23FF)
  LDA PPUSTATUS
  LDA #$23
  STA PPUADDR
  LDA #$C0
  STA PPUADDR

  LDA #$00
  LDX #$00
fill_attr_zeros:
  STA PPUDATA
  INX
  CPX #$40
  BNE fill_attr_zeros

  RTS
.endproc

.export main
.proc main
  ; write a palette
  LDX PPUSTATUS
  LDX #$3f
  STX PPUADDR
  LDX #$00
  STX PPUADDR
load_palettes:
  LDA palettes,X
  STA PPUDATA
  INX
  CPX #$20
  BNE load_palettes

  ; Derive and pack the 2-bit metatile stream from original bomb_bg (rows 0..14)
  JSR build_mt2b_rows_0_14

  ; Draw compressed background test region (rows 0..7)
  JSR draw_bg_small_mt2b

vblankwait:       ; wait for another vblank before continuing
  BIT PPUSTATUS
  BPL vblankwait

  LDA #%10000000;#%10010000  ; turn on NMIs, sprites use first pattern table
  STA PPUCTRL
  LDA #%00011110  ; turn on screen
  STA PPUMASK

forever:
  JMP forever
.endproc

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler

.segment "RODATA"
; Palette definitions: 8 palettes × 4 colors each = 32 bytes total
; Format: [universal color, color 1, color 2, color 3]
; Universal color ($3F00) is usually black and affects the background border
palettes:
  .byte $0f, $20, $2D, $0A ; Background palette 0: black, white, grey, green
  .byte $0f, $06, $00, $1C ; Background palette 1
  .byte $0f, $00, $00, $00 ; Background palette 2
  .byte $0f, $00, $00, $00 ; Background palette 3

  .byte $0f, $20, $00, $00 ; Sprite palette 0
  .byte $0f, $00, $00, $00 ; Sprite palette 1
  .byte $0f, $00, $00, $00 ; Sprite palette 2
  .byte $0f, $00, $00, $00 ; Sprite palette 3

; Background nametable and attribute data

metatile_sets:
  .byte $00, $00, $00, $00
  .byte $04, $05, $14, $15
  .byte $08, $09, $18, $19
  .byte $0A, $0B, $1A, $1B

.include "bomb_bg_small_compressed.asm"
.include "bomb_bg.asm"

.segment "CHR"
  .incbin "../maps.chr"
.include "constants.inc"

.segment "ZEROPAGE"
.importzp controller1

.segment "CODE"
.export read_controller1

.proc read_controller1
  PHP
  PHA
  TXA
  PHA

  ; write a 1, then a 0, to CONTROLLER1 to latch button states
  LDA #$01
  STA CONTROLLER1
  LDA #$00
  STA CONTROLLER1

  LDA #%00000001
  STA controller1

  get_controller1_buttons:
  LDA CONTROLLER1              ; Read next button's state
  LSR A                        ; Shift button state right, into carry flag
  ; Rotate button state from carry flag onto right side of controller1 and
  ; leftmost 0 of controller1 into carry flag
  ROL controller1              
  BCC get_controller1_buttons  ; Continue until original "1" is in carry flag

  PLA
  TAX
  PLA
  PLP
  RTS
.endproc

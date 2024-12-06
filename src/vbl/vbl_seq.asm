vbl_seq:
  call   RAMtoOAM

  call refresh_seq
  call show_play_head

  ld     hl,FRAME
  inc    (hl)

  call   readinput

  call   input_seq

  ld     hl,OAMCOPY
  ld     bc,$40
  call   clear
  
  call   changescreen           ;Always do this at end of VBL

  ret
  
redrawnote_seq:
  ld     a,(SEQ_CURY)
  ld     b,TXT_INVERT
redrawnote_seq_a:
  push   bc
  push   af
  call   getnotename
  pop    af
  ld     hl,$9800+(32*1)+1
  ld     bc,32
  inc    a
-:
  add    hl,bc
  dec    a
  jr     nz,-
  pop    bc
  call   maptext
  ret
  
redrawaccent_seq:
  ld     a,(SEQ_CURY)
  ld     b,TXT_INVERT
redrawaccent_seq_a:
  push   bc
  push   af
  ld     hl,$9800+(32*1)+5
  ld     bc,32
  inc    a
-:
  add    hl,bc
  dec    a
  jr     nz,-
  pop    af
  push   hl
  call   getnoteattrl
  pop    hl
  bit    0,a
  ld     a,'.'			;Checkmark
  jr     nz,+
  ld     a,'-'
+:
  pop    bc
  sub    b
  call   wait_write
  ld     (hl),a
  ret
  
redrawslide_seq:
  ld     a,(SEQ_CURY)
  ld     b,TXT_INVERT
redrawslide_seq_a:
  push   bc
  push   af
  ld     hl,$9800+(32*1)+7
  call   getline
  pop    af
  push   hl
  call   getnoteattrl
  pop    hl
  bit    1,a
  ld     a,'.'			;Checkmark
  jr     nz,+
  ld     a,'-'
+:
  pop    bc
  sub    b
  call   wait_write
  ld     (hl),a
  ret
  
redrawosc_seq:
  ld     a,(SEQ_CURY)
  ld     b,TXT_INVERT
redrawosc_seq_a:
  push   bc
  push   af
  ld     hl,$9800+(32*1)+9
  call   getline
  pop    af
  push   hl
  call   getnoteattrl
  pop    hl
  bit    2,a
  ld     a,'&'			;Oscillator icons
  jr     nz,+
  ld     a,'$'
+:
  pop    bc
  sub    b
  call   wait_write
  ld     (hl),a
  ret
  
redrawarp_seq:
  ld     a,(SEQ_CURY)
  ld     b,TXT_INVERT
redrawarp_seq_a:
  push   bc
  push   af
  ld     hl,$9800+(32*1)+11
  call   getline
  pop    af
  push   hl
  call   getnoteattrh
  pop    hl
  pop    bc
  call   writeAhex
  ret

redrawdrum_seq:
  ld     a,(SEQ_CURY)
  ld     b,TXT_INVERT
redrawdrum_seq_a:
  push   bc
  push   af
  ld     hl,$9800+(32*1)+14
  call   getline
  pop    af
  push   hl
  call   getnoteattrl
  srl    a
  srl    a
  srl    a
  and    $1F
  sla    a
  ld     b,a
  sla    a
  add    b			;*6
  ld     hl,text_drums
  ld     d,0
  ld     e,a
  add    hl,de
  ld     d,h
  ld     e,l
  pop    hl
  pop    bc
  call   maptext
  ret

refresh_seq:
  ld     hl,SEQ_CURX
  ld     a,(SEQ_PREVX)
  cp     (hl)
  jr     nz,+
  ld     hl,SEQ_PREVY
  ld     a,(SEQ_CURY)
  cp     (hl)
  ret    z
+:
  ld     a,(SEQ_PREVX)
  ld     (SEQ_TOERASEX),a
  ld     a,(SEQ_PREVY)
  ld     (SEQ_TOERASEY),a
  ld     a,(SEQ_CURX)
  ld     (SEQ_PREVX),a
  ld     a,(SEQ_CURY)
  ld     (SEQ_PREVY),a

  ;Set previous as normal
  ld     hl,$9800+(32*1)

  ld     a,(SEQ_TOERASEY)
  call   getline
  push   hl
  ld     hl,lut_seqlayout
  ld     a,(SEQ_TOERASEX)
  sla    a
  ld     d,0
  ld     e,a
  add    hl,de
  ldi    a,(hl)
  ld     b,a
  ldi    a,(hl)
  ld     c,a
  pop    hl
  ld     a,l
  add    b
  jr     nc,+
  inc    h
+:
  ld     l,a
-:
  di
  call   wait_write
  ld     a,(hl)
  ei
  and    %10111111		;Clear inverted
  di
  call   wait_write
  ldi    (hl),a
  ei
  dec    c
  jr     nz,-

  ;Set current as inverted
showcur_seq:			;Called just here by seq init
  ld     a,(SEQ_CURY)
  ld     hl,$9800+(32*1)
  call   getline
  push   hl
  ld     hl,lut_seqlayout
  ld     a,(SEQ_CURX)
  sla    a
  ld     d,0
  ld     e,a
  add    hl,de
  ldi    a,(hl)
  ld     b,a
  ldi    a,(hl)
  ld     c,a
  pop    hl
  ld     a,l
  add    b
  jr     nc,+
  inc    h
+:
  ld     l,a
-:
  di
  call   wait_write
  ld     a,(hl)
  ei
  or     %01000000		;Set inverted
  di
  call   wait_write
  ldi    (hl),a
  ei
  dec    c
  jr     nz,-
  ret

show_play_head:
  ; First, check if we're playing
  ld     a, (PLAYING)
  or     a
  jr     z, .stop_playback  ; If not playing, jump to stop playback routine

  ; If playing, update the playhead as normal
  ld     a, (PREV_PLAYHEAD_Y)
  cp     $FF
  jr     z, .draw_new_playhead
  ld     b, a
  xor    a
  ld     c, a
  call   .clear_single_playhead

.draw_new_playhead:
  ld     a, (NOTEIDX)
  ld     b, a
  call   .draw_playhead

  ; Update previous position
  ld     a, (NOTEIDX)
  ld     (PREV_PLAYHEAD_Y), a

  ret

.stop_playback:
  ; Clear the last playhead position
  ld     a, (PREV_PLAYHEAD_Y)
  cp     $FF
  jr     z, .clear_all_playheads  ; If no previous position, clear all
  ld     b, a
  xor    a
  ld     c, a
  call   .clear_single_playhead

.clear_all_playheads:
  ld     b, 16  ; Number of rows
  ld     c, 0   ; X position of playhead
.clear_loop:
  push  bc
  call  .clear_single_playhead
  pop   bc
  inc   b
  ld    a, b
  cp    18     ; Check if we've cleared all 16 rows (starting from row 2)
  jr    nz, .clear_loop

  ; Reset PREV_PLAYHEAD_Y to indicate no playhead
  ld    a, $FF
  ld    (PREV_PLAYHEAD_Y), a

  ret

.clear_single_playhead:
  ; B = Y position, C = X position
  push  bc
  xor   a      ; Load 0 (blank character) into A
  call  .write_character
  pop   bc
  ret

.draw_playhead:
  ; B = Y position, C = X position
  ld     a, $3B                ; Playhead character
  jr     .write_character

.write_character:
  ; B = Y position, C = X position, A = character to write
  push   af
  ld     a, b
  add    a, 2                  ; Add 2 to start from the third row
  ld     l, a
  ld     h, 0
  call   .calculate_position
  pop    af
  di
  call   wait_write
  ld     (hl), a
  ei
  ret

.calculate_position:
  add    hl, hl                ; Multiply by 32 (shift left 5 times)
  add    hl, hl
  add    hl, hl
  add    hl, hl
  add    hl, hl
  ld     de, $9800             ; VRAM start address
  add    hl, de                ; HL now points to the start of the row
  ld     a, c
  add    a, l
  ld     l, a
  ret    nc
  inc    h
  ret

; Helper function to multiply A by BC and add to HL
multiply_add:
  or     a
  ret    z
-:
  add    hl, bc
  dec    a
  jr     nz, -
  ret
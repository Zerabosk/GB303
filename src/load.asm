; Presumes the PATTERN_LOAD_BUFFER is already fullyloaded.
loadpattern_buffered:
  ld     a,(HWOK_EE)
  or     a
  ret    z			;No EE operation if EE boot check failed

  ld     a,(SAVECURPATTSLOT)
  cp     MAX_PATTERNS
  ret    nc			;Sanity check

; Check if PATTERN_LOAD_BUFFER is blank - if so, dont load.
  ld     a,(PATTERN_LOAD_BUFFER)
  or     a
  ret    z	

  ; Clear checksums in PATTERN_LOAD_BUFFER
  xor    a
  ld     (PATTERN_LOAD_BUFFER + $3F), a  ; Clear checksum at 3F
  ld     (PATTERN_LOAD_BUFFER + $7F), a  ; Clear checksum at 7F

  ; Clear the single byte after 7F
  ld     (PATTERN_LOAD_BUFFER + $80), a  ; Clear byte at 80 (128th byte)

  ; Load the pattern name from PATTERN_LOAD_BUFFER.
  ld     b,8
  ld     hl,PATTNAME
  ld     de,PATTERN_LOAD_BUFFER+1
-:
  ld     a,(de)
  ldi    (hl),a
  inc    de
  dec    b
  jr     nz,-
  
  ld     a,$FF			;Add security byte at the end
  ld     (PATTNAME+8),a

; Load the pattern parameters from PATTERN_LOAD_BUFFER.
  ld     hl,pparams
  ld     de,PATTERN_LOAD_BUFFER+$10
-:
  ldi    a,(hl)
  or     (hl)
  jr     z,+
  ldd    a,(hl)		;BC is pointer to variable
  ld     c,(hl)
  ld     b,a
  ld     a,(de)         ;Get EE value
  inc    hl
  inc    hl
  cp     (hl)
  jr     c,++		;<
  jr     z,++		;=
  inc    hl
  ld     a,(hl)		;OOB: Restore default
  jr     +++
++:
  inc    hl
+++:
  inc    hl
  ld     (bc),a
  inc    de
  jr     -
; Load the sequence from PATTERN_LOAD_BUFFER.
+:
  ld     b,16*4
  ld     hl,SEQ
  ld     de,PATTERN_LOAD_BUFFER+64
-:
  ld     a,(de)
  ldi    (hl),a
  inc    de
  dec    b
  jr     nz,-

  ; Reset loading flags
  xor    a
  ld     (PATTERN_LOAD_ACTIVE),a
  ld     (PATTERN_LOAD_PROGRESS),a

  ; Update CURPATTERN
  ld     a,(SAVECURPATTSLOT)
  ld     (CURPATTERN),a

  ld     a,(CURSCREEN)		; Update pattern name in specific screens (not table, nor memory)
  cp     1
  jr     z,+
  cp     6
  jr     nz,++
  ld    a,(CURSCREEN)
  cp    6
  call  z,setscreen
  ret
++:
  cp     2
  call   z,draw_seq
  jp     write_pattinfo		; Call+ret
+:
  or     a
  ret    nz
  call   liv_erasepotlinks	; To test !
  jp     liv_drawpotlinks       ; Call+ret

begin_load_pattern:
  ld     a,1
  ld     (PATTERN_LOAD_ACTIVE),a
  ret

load_pattern_section:
  ld     a,(PATTERN_LOAD_ACTIVE)
  or     a
  ret    z  ; Return if we're not actively loading

  ld     a,(PATTERN_LOAD_PROGRESS)
  cp     16
  jp     z,++  ; If we've loaded all 16 sections, finish up

  ; Calculate EEPROM address
  ld     a,(SONGPTR) ; Get current song pointer
  inc    a ; Increment it
  cp     160 ; Check if it's 160 (max song length)
  jr     nz,+ ; If not, skip the next part
  xor    a			;Loop at end of song if no $FF (stop) slot
+:
  ld     hl,SONG ; Load song value into HL
  rst    0 ; Send it to A
  ld     b,a ; Move A to B
  rrca
  and    $80
  ld     (EEWRADDRL),a
  ld     a,b
  srl    a
  and    $3F
  inc    a           ; Start at $0100
  ld     (EEWRADDRM),a

  ; Adjust address based on progress
  ld     a,(PATTERN_LOAD_PROGRESS)
  ld     l,a
  ld     h,0          ; HL now contains PATTERN_LOAD_PROGRESS
  add    hl,hl        ; Multiply by 2
  add    hl,hl        ; Multiply by 4
  add    hl,hl        ; Multiply by 8
  ld     a,(EEWRADDRL)
  ld     c,a
  ld     a,(EEWRADDRM)
  ld     b,a          ; BC now contains the full address
  add    hl,bc
  ld     a,l
  ld     (EEWRADDRL),a
  ld     a,h
  ld     (EEWRADDRM),a

; Setup EEPROM Read
  ld     a,$08			; CS high
  ld     ($2000),a
  nop
  ld     a,$00			; CS low
  ld     ($2000),a
  nop
  
  ld     a,(EEWRADDRL)
  ld     l,a
  ld     a,(EEWRADDRM)
  ld     h,a
  call   eesetr

  ; Load 8 bytes into PATTERN_LOAD_BUFFER
  ld     hl,PATTERN_LOAD_BUFFER
  ld     a,(PATTERN_LOAD_PROGRESS)
  ld     l,a
  ld     h,0          ; HL now contains PATTERN_LOAD_PROGRESS
  add    hl,hl        ; Multiply by 2
  add    hl,hl        ; Multiply by 4
  add    hl,hl        ; Multiply by 8
  ld     de,PATTERN_LOAD_BUFFER
  add    hl,de 

  ; Read 8 bytes from EEPROM
  ld     b,8
-:
  ld     c,$00
  call   spicom
  ld     a,d
  ldi    (hl),a
  dec    b
  jr     nz,-

  ld     a,$08        ; CS high
  ld     ($2000),a
  nop

  ; Increment progress
  ld     a,(PATTERN_LOAD_PROGRESS)
  inc    a
  ld     (PATTERN_LOAD_PROGRESS),a
++:
  ret
  
loadpattern:
  ld     a,(HWOK_EE)
  or     a
  ret    z			;No EE operation if EE boot check failed

  ld     a,(SAVECURPATTSLOT)
  cp     MAX_PATTERNS
  ret    nc			;Sanity check

  ld     b,a                    ;00000000 aAAAAAAA
  rrca                          ;0aAAAAAA A0000000
  and    $80
  ld     (EEWRADDRL),a
  ld     a,b
  srl    a
  and    $3F
  inc    a			;Start at $0100
  ld     (EEWRADDRM),a

  call   readts

  ld     c,$00
  call   spicom
  
  ld     a,$08			; CS high
  ld     ($2000),a
  nop

  ld     a,d
  cp     e
  jr     z,+
  ;Bad checksum: whatever, go on, defaults will be restored if needed...
  ret
  
  ld     a,(TEMPSECTOR)
  or     a
  ret    z			;Blank pattern, don't load

+:
  ld     b,8
  ld     hl,PATTNAME
  ld     de,TEMPSECTOR+1
-:
  ld     a,(de)
  ldi    (hl),a
  inc    de
  dec    b
  jr     nz,-
  
  ld     a,$FF			;Security
  ld     (PATTNAME+8),a

  ld     hl,pparams
  ld     de,TEMPSECTOR+$10
-:
  ldi    a,(hl)
  or     (hl)
  jr     z,+
  ldd    a,(hl)		;BC is pointer to variable
  ld     c,(hl)
  ld     b,a
  ld     a,(de)         ;Get EE value
  inc    hl
  inc    hl
  cp     (hl)
  jr     c,++		;<
  jr     z,++		;=
  inc    hl
  ld     a,(hl)		;OOB: Restore default
  jr     +++
++:
  inc    hl
+++:
  inc    hl
  ld     (bc),a
  inc    de
  jr     -
+:


  ld     a,(EEWRADDRL)
  or     $40
  ld     (EEWRADDRL),a

  call   readts

  ld     c,$00
  call   spicom
  
  ld     a,$08			; CS high
  ld     ($2000),a
  nop

  ld     a,d
  cp     e
  jr     z,+
  ;Bad checksum:
  ret

+:
  ld     b,16*4
  ld     hl,SEQ
  ld     de,TEMPSECTOR
-:
  ld     a,(de)
  ldi    (hl),a
  inc    de
  dec    b
  jr     nz,-

  ld    a,(SAVECURPATTSLOT)
  ld    (CURPATTERN),a

  ld     a,(CURSCREEN)		; Update pattern name in specific screens (not table, nor memory)
  cp     1
  jr     z,+
  cp     6
  jr     nz,++
  ld    a,(CURSCREEN)
  cp    6
  call  z,setscreen
  ret
++:
  cp     2
  call   z,draw_seq
  jp     write_pattinfo		; Call+ret
+:
  or     a
  ret    nz
  call   liv_erasepotlinks	; To test !
  jp     liv_drawpotlinks       ; Call+ret
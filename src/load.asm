; Updated load pattern - now presumes the TEMPSECTOR is already fullyloaded.
loadpattern:
  ld     a,(HWOK_EE)
  or     a
  ret    z			;No EE operation if EE boot check failed

  ld     a,(SAVECURPATTSLOT)
  cp     MAX_PATTERNS
  ret    nc			;Sanity check

  ; Check if TEMPSECTOR is blank - if so, dont load.
  ld     a,(TEMPSECTOR)
  or     a
  ret    z			
; Load the pattern name from TEMPSECTOR.
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
  
  ld     a,$FF			;Add security byte at the end
  ld     (PATTNAME+8),a

; Load the pattern parameters from TEMPSECTOR.
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
; Load the sequence from TEMPSECTOR.
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
  cp     8
  jr     z,+  ; If we've loaded all 8 sections, finish up

  ; Calculate EEPROM address
  ld     a,(SAVECURPATTSLOT)
  ld     b,a
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
  sla    a
  sla    a
  sla    a  ; Multiply by 8 (each section is 8 bytes)
  ld     b,0
  ld     c,a
  ld     hl,(EEWRADDRL)
  add    hl,bc
  ld     a,l
  ld     (EEWRADDRL),a
  ld     a,h
  ld     (EEWRADDRM),a

  ; Load 8 bytes into TEMPSECTOR
  ld     hl,TEMPSECTOR
  ld     a,(PATTERN_LOAD_PROGRESS)
  sla    a
  sla    a
  sla    a  ; Multiply by 8
  ld     d,0
  ld     e,a
  add    hl,de

  ; Read 8 bytes from EEPROM
  ld     b,8
-:
  call   spicom
  ld     (hl),d
  inc    hl
  dec    b
  jr     nz,-

  ld     a,$08        ; CS high
  ld     ($2000),a

  ; Increment progress
  ld     a,(PATTERN_LOAD_PROGRESS)
  inc    a
  ld     (PATTERN_LOAD_PROGRESS),a
+:
  ret
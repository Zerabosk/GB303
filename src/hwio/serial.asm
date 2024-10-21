serial:
  push    af
  push    bc
  push    de
  push    hl
  ld      h,>MIDIBUFFER ; Load the high byte of MIDIBUFFER (its aligned to $C000)
  ldh     a,(<MIDIBPUT) ; Load the low byte of MIDIBPUT (Its in HRAM, thus it always starts with $FF)
  ld      l,a
  ldh     a,($01)
  ld      (hl),a
  ld      a,(MIDIBPUT)
  inc     a
  and     $3F
  ld      (MIDIBPUT),a
  
  call    serialhnd

  pop     hl
  pop     de
  pop     bc
  pop     af
  reti


serialhnd:
  ld      a,(SYNCMODE)
  cp      SYNC_NONE
  ret     z
  cp      SYNC_LSDJS
  jr      z,synch_lsdjslave
  cp      SYNC_LSDJMIDI
  jr      z,sync_lsdjmidi
  cp      SYNC_NANO
  jr      z,synch_nanoslave
;  cp      SYNC_MIDI ; Just store the data in the buffer.
;  jp      z,synch_midi
  ret

sync_lsdjmidi:
  call    sy_common
  or      a
  ret     z
  cp      $80 ; anything below $80 we ignore
  ret     c
  cp      $F0 ; Think this is Velocity 0? (ignore for now)
  ret     z
  cp      $FF ; Usually disconnected link cable. (ignore)
  ret     z
  cp      $FD ; Start sequence (ignore)
  ret     z
  cp      $FE  ; Stop Sequence (ignore) 
  ret     z
  and     $7F
  jr      z,+
  ld      (MIDINOTENB),a
  ld      a,1			;Note on
  ld      (MIDINOTECMD),a
  ld      a,1
  ld      (PLAYING),a ; Start playing
  ret
+:
  ld      a,2			;Note off
  ld      (MIDINOTECMD),a
  ret
  
sy_common:
  ld      a,(MIDIBPUT)
  ld      (MIDIBGET),a
  dec     a
  and     $3F
  ld      h,>MIDIBUFFER ; Load the high byte of MIDIBUFFER (its aligned to $C000)
  ld      l,a
  ld      a,(hl)
  ret

synch_nanoslave:
  call    sy_common
  or      a
  ret     z
  ld      a,(PLAYING) ; Start playing as soon as we get a non-zero byte.
  or      a
  jr      nz,+
  xor     a
  ld      (SONGPTR),a
  ld      a,-1        ; First tick is ignored on start
  ld      (SYNCTICK),a
  ld      a,2			;Start to play song from start
  ld      (PLAYING),a
  call    pscommon
  ret
+:
  ld      a,(SYNCTICK)
  inc     a
  cp      3            ; 24 MIDI clocks per beat, 8 Gameboy clocks per byte, 1 byte per tick - so 24 / 8 = 3 bytes per beat!
  jr      nz,+
  ld      a,1
  ld      (BEAT),a
  xor     a
+:
  ld      (SYNCTICK),a
  ret

synch_lsdjslave:
  call    sy_common
  or      a
  jr      nz,+
  xor     a
  ld      (SONGPTR),a
  ld      (SYNCTICK),a
  ld      a,2			;Start to play song from start
  ld      (PLAYING),a
  call    pscommon
  ret
+:
  ld      a,(SYNCTICK)
  inc     a
  cp      6            ; 6 ticks per beat (One per groove tick)
  jr      nz,+
  ld      a,1
  ld      (BEAT),a
  xor     a
+:
  ld      (SYNCTICK),a
  ret

synch_midi:
  ld      a,1
  ld      (PLAYING),a
  
  ; Sort the bytes into the correct buckets for processing elsewhere...
  ldh     a,(<MIDIBGET) ; Load the low byte of MIDIBGET (Its in HRAM, thus it always starts with $FF)
  and     $3F ; Mask to 64 bytes
  ld      h,>MIDIBUFFER ; Load the high byte of MIDIBUFFER (its aligned to $C000)
  ld      l,a
  ld      a,(hl) ; hl is now the full address of the MIDI byte we want to process - load the new byte into a.
  
  bit     7,a            ; Check bit 7 Status byte (1) or data byte (0)?
  jr      nz,midi_status

  call    midi_data
  call    inc_midibget
  ret

inc_midibget:
  ldh     a,(<MIDIBGET) ; Load the low byte of MIDIBGET (Its in HRAM, thus it always starts with $FF)
  inc     a ; Increment to get the next byte
  and     $3F ; Mask to 64 bytes
  ld      (MIDIBGET),a ; Store the new low byte of MIDIBGET
  ret

midi_status:
  ld      (MIDISTATUSBYTE),a ; Store the status byte
  xor     a
  ld      (MIDICAPTADDRFLG),a ; Clear the address flag
  ld      (MIDIMESSAGERDYFLG),a ; Clear the message ready flag
  ldh     a,(<MIDIBGET) ; Load the low byte of MIDIBGET (Its in HRAM, thus it always starts with $FF)
  inc     a ; Increment to get the next byte
  and     $3F ; Mask to 64 bytes
  ld      (MIDIBGET),a ; Store the new low byte of MIDIBGET
  ret

midi_data:
  ld      b,a
  ld      a,(MIDICAPTADDRFLG) ; Check if we have captured an address already
  or      a
  jr      z,+
  ; We have captured an address already - so store it as a value byte
  ld      a,b
  ld      (MIDIVALUEBYTE),a ; Store the data byte
  xor     a
  ld      (MIDICAPTADDRFLG),a ; Clear the address flag
  ld      a,1
  ld      (MIDIMESSAGERDYFLG),a ; Set the message ready flag
  ret
+:
  ; We haven't captured an address yet - so store it as an address byte
  ld      a,b
  ld      (MIDIADDRESSBYTE),a ; Store the address byte
  ld      a,1
  ld      (MIDICAPTADDRFLG),a ; Set the address flag
  ld      a,(MIDISTATUSBYTE)
  and     $F0
  cp      $C0 ; If its a program change, the meesage is complete.
  ret     nz
  ld      a,1
  ld      (MIDIMESSAGERDYFLG),a ; Set the message ready flag
  ret

process_midi_message:
  ld      a,(MIDISTATUSBYTE)
  and     $F0			;Mask lower nibble to ignore channel (We only support 1 channel)
;  cp      $B0			;CC - Next two bytes are CC number and value
;  jr      z,midi_cc
;  cp      $C0     ;Program change - Next byte is program number
;  jr      z,midi_program
;  cp      $E0     ;Pitch bend - Next two bytes are pitch bend amount
;  jr      z,midi_pitchbend
  cp      $90			;Note on - Next two bytes are note and velocity
  jr      z,midi_noteon
  cp      $80     ;Note off - Next two bytes are note and velocity
  jr      z,midi_noteoff
  ret


midi_noteoff:
  ld      a,(MIDIADDRESSBYTE)
  and     $7F
  ld      c,a
  ld      a,(MIDINOTENB)
  cp      c
  ret     nz ; If the note value doesn't match current note, we don't need to send a note off.

  ;ld      a,(MIDIVALUEBYTE)        ;Velocity (ignore)
  ;and     $7F
  ;Could do somthing with velocity here?

noteoffvel:
  ld      a,2			;Note off
  ld      (MIDINOTECMD),a
  ret

midi_noteon:
  ld      a,(MIDIADDRESSBYTE)
  and     $7F
  ld      (MIDINOTENB),a

  ld      a,(MIDIVALUEBYTE)        ;Velocity (ignore)
  and     $7F
  jr      z,noteoffvel

  ld      a,1			;Note on
  ld      (MIDINOTECMD),a
  ret
serial:
  push    af
  push    bc
  push    de
  push    hl
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
  ret

sync_lsdjmidi:
  ldh     a,($01) ; Read the serial transfer register
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

synch_nanoslave:
  ldh     a,($01) ; Read the serial transfer register
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
  ldh     a,($01) ; Read the serial transfer register
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
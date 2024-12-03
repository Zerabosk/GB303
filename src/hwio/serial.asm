serial:
  push    af
  push    bc
  push    de
  push    hl
  call    serialhnd
  ld      a,(SYNCMODE)
  cp      SYNC_MIDI
  jr      nz,+
  ld      a,$80     ; Set to slave mode after midi sync
  ldh     ($02),a 
+:
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
  cp      SYNC_MIDI
  jp      z,synch_midi
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

synch_midi:
  ldh     a,($01) ; Read the serial transfer register
  bit     7,a            ; Check bit 7 Status byte (1) or data byte (0)?
  jr      z,+
  ;;;;; Status byte ;;;;;
  ld      (MIDISTATUSBYTE),a ; Store the status byte
  xor     a
  ld      (MIDICAPTADDRFLG),a ; Clear the address flag
  ret
+:
  ;;;;; Data byte ;;;;;
  ld      b,a
  ld      a,(MIDICAPTADDRFLG) ; Check if we have captured an address already
  or      a
  jr      z,+
  ; We have captured an address already - so store it as a value byte
  ld      a,b
  ld      (MIDIVALUEBYTE),a ; Store the data byte
  xor     a
  ld      (MIDICAPTADDRFLG),a ; Clear the address flag
  call    process_midi_message ; Message is complete - process it.
+:
  ; We haven't captured an address yet - so store it as an address byte
  ld      a,b
  ld      (MIDIADDRESSBYTE),a ; Store the address byte
  ld      a,1
  ld      (MIDICAPTADDRFLG),a ; Set the address flag
  ld      a,(MIDISTATUSBYTE)
;  We just done deal with Program Change yet
;  and     $F0
;  cp      $C0 ; If its a program change, the meesage is complete.
;  ret     nz
  ;call    process_midi_message ; Message is complete - process it. - But not yet - we dont do anything with program change.
  ret

process_midi_message:
  ld      a,1
  ld      (PLAYING),a
  ld      a,(MIDISTATUSBYTE)
  and     $F0			;Mask lower nibble to ignore channel (We only support whatever channel we are sent)
  cp      $B0			;CC - Next two bytes are CC number and value
  jr      z,midi_cc
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

;.org $0014
midi_cc:
  ld      a,(MIDIVALUEBYTE) ;(0-127)
  and     125 ; Limit to 0-125 - causes crashes otherwise
  sla     a     ;*2
  ld      b,a
  ld      a,(MIDIADDRESSBYTE) ; CC number
  cp      $05 ; CC 5 - Slide Speed
  call    z,pots_slide
  cp      $0E ; CC 14 - LFO Speed
  call    z,pots_lfospeed
  cp      $0F ; CC 15 - LFO Amp
  call    z,pots_lfoamp
  cp      $14 ; CC 20 - Pitch Mod
  call    z,pots_pitch
  cp      $47 ; CC 71 - Resonance
  call    z,pots_reson
  cp      $4A ; CC 74 - Cuttoff
  call    z,pots_cutoff
  ret     nz ; If the CC number isn't supported, we don't need to do anything.
;slide_speed:
;  ld      a,(MIDIVALUEBYTE);(0-127)
;  sla     a     ;*2
;  srl     a
;  ld      (SLIDESPEED),a
;  ret
;lfo_speed:
;  ld      a,(MIDIVALUEBYTE);(0-127)
;  sla     a     ;*2
;  srl     a
;  srl     a
;  srl     a
;  ld      (LFOSPEED),a
;  ret 
;lfo_amp:
;  ld      a,(MIDIVALUEBYTE);(0-127)
;  sla     a     ;*2
;  swap    a			;/16
;  and     $F
;  ld      (LFOAMP),a
;  ret
;bend:
;  ld      a,(MIDIVALUEBYTE);(0-127)
;  sla     a     ;*2
;  srl     a
;  ld      (BEND),a
;  ret
;resonance:
;  ld      a,(MIDIVALUEBYTE);(0-127)
;  sla     a     ;*2
;  swap    a			;/16
;  and     $F
;  ld      (RESON),a
;  ret
;cutoff:
;  ld      a,(MIDIVALUEBYTE) ;(0-127)
;  sla     a     ;*2
;  cpl     a
;  srl     a			;64
;  ld      b,a
;  srl     a			;32
;  add     b			;64+32=96
;  ld      (CUTOFFSET),a
;  ret

;TBC - This break existing pitch implementation. Maybe later.
;midi_pitchbend:
;  ; Pitch bend is 14 bits - 2 x 7 bits - value from 0-16383
;  ; Pitch bend $2000 is center (8192) [no pitch bend]
;  ; 0HHH HHHH - High byte of pitch bend
;  ; 0LLL LLLL - Low byte of pitch bend
;  ld    a,(MIDIVALUEBYTE)    ; 0HHH HHHH - High byte of pitch bend
;  ld    b,a
;  ld    a,(MIDIADDRESSBYTE)  ; 0LLL LLLL - Low byte of pitch bend
;  
;  ; First subtract 8192 to center around 0
;  ld    hl,$2000              ; 8192 in hex
;  sub   hl,a
;  ; Then divide by 64 to get a value from -128 to +127
;  srl   a ; /2 
;  srl   a ; /4
;  srl   a ; /8
;  srl   a ; /16
;  srl   a ; /32
;  srl   a ; /64
;  ; Then add 128 to get a value from 0 to 255
;  add   $80
;  ; Then divide by 2 to get final BEND value (0-127)
;  srl   a
;  ; Store result in BEND
;  ld    (BEND),a
;  ret
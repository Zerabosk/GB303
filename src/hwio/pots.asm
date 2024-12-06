pots_cutoff:
  ld     a,b
  cpl
  srl    a			;128
  srl    a			;64
  ld     b,a
  srl    a			;32
  add    b			;64+32=96
  ld     (CUTOFFSET),a
  ret
  
pots_reson:
  ld     a,b
  swap   a			;/16
  and    $F
  ld     (RESON),a
  ret

pots_pitch:
  ld     a,b
  srl    a
  ld     (BEND),a
  ret
  
pots_slide:
  ld     a,b
  srl    a
  ld     (SLIDESPEED),a
  ret

pots_lfospeed:
  ld     a,b
  srl    a
  srl    a
  srl    a
  ld     (LFOSPEED),a
  ret
  
pots_lfoamp:
  ld     a,b
  swap   a			;/16
  and    $F
  ld     (LFOAMP),a
  ret


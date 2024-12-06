vbl_loadsave:
  call   RAMtoOAM

  ld     hl,FRAME
  inc    (hl)

  call   readinput

  call   input_loadsave

  ld     hl,OAMCOPY
  ld     bc,$40
  call   clear

  call   changescreen           ;Always do this at end of VBL

  ret
  
  
vbl_loadsaveerr:
  call   RAMtoOAM

  ld     hl,FRAME
  inc    (hl)

  call   readinput
  
  ld     hl,OAMCOPY
  ld     bc,$40
  call   clear
  
  call   changescreen           ;Always do this at end of VBL

  ret

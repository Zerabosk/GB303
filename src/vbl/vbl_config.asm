vbl_config:
  call   RAMtoOAM

  ld     hl,FRAME
  inc    (hl)

  call   readinput

  call   input_config

  ld     hl,OAMCOPY
  ld     bc,$40
  call   clear
  
  call   changescreen           ;Always do this at end of VBL

  ret

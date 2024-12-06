vbl_table:
  call   RAMtoOAM

  ld     hl,FRAME
  inc    (hl)

  call   readinput

  call   input_table
  
  call   redraw_songptr

  ld     hl,OAMCOPY
  ld     bc,$40
  call   clear
  
  call   changescreen

  ret

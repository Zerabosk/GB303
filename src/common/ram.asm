.ENUM $C000 EXPORT
MIDINOTENB DB
MIDINOTECMD DB 

; Just copying mGB
MIDISTATUSBYTE DB ; MIDI Event type
MIDIADDRESSBYTE DB ; MIDI Note number
MIDIVALUEBYTE DB ; Other MIDI data 

MIDICAPTADDRFLG DB ; MIDI Captured addresss flag (0=no, 1=yes)


VBL DB
VBL_HANDLER DW
FRAME DB
CUTOFF DW
JOYP_CURRENT DB
JOYP_PREV DB
JOYP_ACTIVE DB
JOYP_RPTTIMER DB		;Repeat timer
JOYP_RPT DB
hblank DS 3
CURNOTE DB
LASTNOTE DB
WAVEMUTE DB
DRUMSMUTE DB
INITSEQLINE DB			;Only used in SEQ display init to avoid pushes/pops
NOTEIDX DB
CUTOFFI DB
CUTOFFSET DB
OSCTYPE DB
OSCTYPEOVD DB
FHIGH DB
FLOW DB
FNHIGH DB
FNLOW DB
PREVCUT DB
RESON DB
TEMPFF DB

TEMPSECTOR DS 64

ARPWORD DB			;Copy of last note's Arpeggio word from SEQ
ARPIDX DB			;Arpeggio index, 0=original 1=+MSB 2=+LSB
ARPOFFSET DB			;Current semitone offset caused by arpeggiator to add to current note
;ARPTMR DB			;Arpeggio timer (down-counter)
;ARPSPEED DB

MAP_FIRST DB
MAP_W DB
DOSLIDE DB
SYNCTICK DB
PLAYING DB			;0: Pause, 1: Playing pattern, 2: Playing song
ACCENT DB
CURSCREEN DB
SCREENMID DB			;Last screen number in middle screen row map
GOTSERIAL DB
DISTTYPE DB
BEND DB
BPM DB
BPM_MATCH DB
BPM_CNT DB
BEAT DB
FHIGHF DB
SLIDESPEED DB
CUTOFFEG DB

SYNTHLR DB
DRUMSLR DB

PATTERN_LOAD_PROGRESS: DB  ; Tracks how much of the pattern has been loaded
PATTERN_LOAD_ACTIVE: DB    ; Flag to indicate if we're in the process of loading
PATTERN_LOAD_BUFFER: DS 128 ; Too big...? Why is TEMPSECTOR 64?

;SEQTEMP DS 16		;Used for drawing preview in loadsave

SEQ DS 4*16

; Used for tracking cursor position in pattern editor
SEQ_CURX DB         
SEQ_CURY DB
SEQ_PREVX DB
SEQ_PREVY DB
SEQ_TOERASEX DB
SEQ_TOERASEY DB
PREV_PLAYHEAD_Y: DB ; Used for removing playhead from screen

LASTNOTEINPUT DB
LASTDRUMINPUT DB

NOTECUR_X DB

HWOK_ADC DB
HWOK_EE DB

POT1LP DS 4		;Lowpass filter "trails" for pots de-noising
POT2LP DS 4
POT3LP DS 4

POT1V DB
POT2V DB
POT3V DB

EEWRADDRL DB
EEWRADDRM DB

SAVECURSONGSLOT DB      ;Playhead save song number
SAVECURPATTSLOT DB	;Playhead save pattern number (Its a pointer to the pattern in SONG -Z)

CURPATTERN DB		;Currently loaded pattern (Its a pointer to the pattern in SONG -Z)
PATTNAME DS 9

SCREENMAP DB
COPPERI DB
COPPERFLIP DB
COPPEROA DB
COPPEROB DB   
COPPERANIM DB

POTLINK1 DB
POTLINK2 DB
POTLINK3 DB

KEYBOARDMODE DB
KBCALLBACK DW
KBX DB
KBY DB
NAMEPTR DB
TEMPNAME DS 9

SYNCMODE DB

LIVE_CURX DB
LIVE_PREVX DB
LIVE_CURY DB
LIVE_PREVY DB

LFOSPEED DB
LFOAMP DB
LFOROUTE DB
LFORESET DB
LFOACC DB

INVERTPOTS DB

LFOCUTOFF DB
LFORESON DB
LFOPITCH DB

LASTSAVED_SONG DB
LASTSAVED_PATT DB

POTPATTOVRD DB

SONG_CURX DB
SONG_CURY DB
SONG_PREVX DB
SONG_PREVY DB

CURSONG DB
SONG DS 160
SONGNAME DS 9
SONGOFS DB		;0 or 80 (screen 0 or 1)
SONGPTR DB

CFG_CUR DB
CFG_PREVCUR DB

MEM_CUR DB
MEM_PREVCUR DB
SELPATTNAME DS 9
SELSONGNAME DS 9

CONFIRM_YN DB
PREVSONGPTR DB
.ENDE

.DEFINE POTLINK_NOTHING		0
.DEFINE POTLINK_CUTOFF		1
.DEFINE POTLINK_RESON		2
.DEFINE POTLINK_LFOSPEED	3
.DEFINE POTLINK_LFOINT		4
.DEFINE POTLINK_SLIDE		5

.DEFINE WAVETABLE $DE00	;16 bytes
.DEFINE COPPERA $DE10	;72 bytes
.DEFINE COPPERB $DE58	;72 bytes
.DEFINE OAMCOPY $DF00
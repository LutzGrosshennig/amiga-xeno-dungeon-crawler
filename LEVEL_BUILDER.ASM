
; OFFSETS EXEC

OPENLIBRARY    = -552
CLOSELIBRARY   = -414

; OFFSETS INTUITION

OPENSCREEN     = -198
CLOSESCREEN    = -066
OPENWINDOW     = -204
CLOSEWINDOW    = -072
DRAWIMAGE      = -114

; OFFSETS GRAPHICS

DRAWTO         = -246
MOVETO         = -240
SETAPEN        = -342
RECTFILL       = -306
LOADRGB4       = -192
SETRGB4        = -288
PRINTTEXT      = -060
WAITTOF        = -270
MOVESPRITE     = -426
FREESPRITE     = -414
READPIXEL      = -318
WRITEPIXEL     = -324

; OFFSETS DOS

OPEN           = -30
CLOSE          = -36
READ           = -42
WRITE          = -48

; KONSTANTEN

EXECBASE       = 4
MOUSE          = $BFE001

;----------------------------------------------------------

WRITELN:MACRO *\TEXT,%\COUNT,%\X,%\Y

       PEN_TO  \X,\Y
       LEA     \TEXT,A0
       MOVEQ   #\COUNT,D0
       JSR     PRINTTEXT(A6)
       ENDM

OPENLIB:MACRO *\NAME,*\BASE

       MOVE.L  EXECBASE,A6
       LEA     \NAME,A1
       MOVEQ   #0,D0
       JSR     OPENLIBRARY(A6)
       MOVE.L  D0,\BASE
       ENDM

CLOSELIB:MACRO *\BASE

       MOVE.L  EXECBASE,A6
       MOVE.L  \BASE,A1
       JSR     CLOSELIBRARY(A6)
       ENDM

OPENSCR:MACRO *\DEVS,*\HD

       MOVE.L  INTBASE,A6
       LEA     \DEVS,A0
       JSR     OPENSCREEN(A6)
       MOVE.L  D0,\HD
       ENDM

CLOSESCR:MACRO *\HD

       MOVE.L  INTBASE,A6
       MOVE.L  \HD,A0
       JSR     CLOSESCREEN(A6)
       ENDM

OPENWIND:MACRO *\DEVS,*\HD

       MOVE.L  INTBASE,A6
       LEA     \DEVS,A0
       JSR     OPENWINDOW(A6)
       MOVE.L  D0,\HD
       ENDM

CLOSEWIND:MACRO *\HD

       MOVE.L  INTBASE,A6
       MOVE.L  \HD,A0
       JSR     CLOSEWINDOW(A6)
       ENDM

PEN_TO:MACRO %\X,%\Y

       MOVE.L  GFXBASE,A6
       MOVE.L  RASTPORT,A1
       MOVE.W  #\X,D0
       MOVE.W  #\Y,D1
       JSR     MOVETO(A6)
       ENDM

PEN_COLOR:MACRO %\COLOR

       MOVE.L  GFXBASE,A6
       MOVE.L  RASTPORT,A1
       MOVEQ   #\COLOR,D0
       JSR     SETAPEN(A6)
       ENDM

BOX:MACRO %\X1,%\Y1,%\X2,%\Y2,%\COLOR

       PEN_COLOR \COLOR

       MOVE.W  #\X1,D0
       MOVE.W  #\Y1,D1
       MOVE.W  #\X2,D2
       MOVE.W  #\Y2,D3
       JSR     RECTFILL(A6)
       ENDM

IMAGE:MACRO *\IMAGE,%\X,%\Y

       MOVE.L  INTBASE,A6
       MOVE.L  RASTPORT,A0
       LEA     \IMAGE,A1
       MOVE.W  #\X,D0
       MOVE.W  #\Y,D1
       JSR     DRAWIMAGE(A6)
       ENDM

;----------------------------------------------------------

START:

       OPENLIB INTNAME,INTBASE         ; INTUITION ÖFFNEN
       OPENLIB GFXNAME,GFXBASE         ; GRAPHICS ÖFFNEN
       OPENLIB DOSNAME,DOSBASE

       OPENSCR SCREENDEVS,SCREENHD     ; SCREEN ÖFFNEN
       OPENWIND WINDOWDEVS,WINDOWHD    ; WINDOW ÖFFNEN
       MOVE.L  D0,A0                   ; RASTPORT
       MOVE.L  50(A0),RASTPORT         ; ERMITTELN

       IMAGE   LEVEL,100,100

       BSR     CALCULATE
       BSR     DO_WRITE

MAINLOOP:

       BTST    #6,MOUSE
       BNE     MAINLOOP

ENDE:

       CLOSEWIND WINDOWHD              ; WINDOW SCHLIESSEN
       CLOSESCR SCREENHD               ; SCREEN SCHLIESSEN

       CLOSELIB GFXBASE                ; GRAPHICS SCHLIESSEN
       CLOSELIB INTBASE                ; INTUITION SCHLIESSEN
       CLOSELIB DOSBASE

       MOVEQ   #0,D0                   ; NACHRICHT AN DOS. ALLES OK !
       RTS                             ; ENDE !!!

;----------------------------------------------------------

CALCULATE:

       LEA     LEVEL_BYTE,A5
       MOVEQ   #19,D7
OUTERLOOP:
       MOVEQ   #19,D6
INNERLOOP:
       MOVE.W  BLOCK_X,D0
       MOVE.W  BLOCK_Y,D1
       BSR     GET_IT
       ADDQ.W  #1,BLOCK_X

       DBRA    D6,INNERLOOP

       MOVE.W  #100,BLOCK_X
       ADDQ.W  #1,BLOCK_Y

       DBRA    D7,OUTERLOOP
       RTS

GET_IT:

       MOVE.L  GFXBASE,A6
       MOVE.L  RASTPORT,A1
       JSR     READPIXEL(A6)
       MOVE.B  D0,(A5)+
       RTS

DO_WRITE:

       MOVE.L  DOSBASE,A6
       MOVE.L  #FILENAME,D1
       MOVE.L  #1006,D2
       JSR     OPEN(A6)
       MOVE.L  D0,FILEHD

       MOVE.L  D0,D1
       MOVE.L  #LEVEL_BYTE,D2
       MOVE.L  #400,D3
       JSR     WRITE(A6)

       MOVE.L  FILEHD,D1
       JSR     CLOSE(A6)
       RTS

;----------------------------------------------------------

SCREENDEVS:

       DC.W    0,0,320,256,5
       DC.B    0,1
       DC.W    $2,15
       DC.L    0,SCRNAME,0,0

WINDOWDEVS:

       DC.W    0,10,320,245
       DC.B    0,1
       DC.L    $0,$11800,0,0,0
SCREENHD: DC.L 0,0
       DC.W    300,200,640,256,15

;----------------------------------------------------------

WINDOWHD:      DC.L    0
RASTPORT:      DC.L    0
FILEHD:        DC.L    0
INTBASE:       DC.L    0
GFXBASE:       DC.L    0
DOSBASE:       DC.L    0
ZAEHLER:       DC.W    0

BLOCK_X:       DC.W    100
BLOCK_Y:       DC.W    100

;----------------------------------------------------------

LEVEL:
       DC.W    0,0,20,20,5
       DC.L    LEVEL_DATA
       DC.B    31,0
       DC.L    0

LEVEL_BYTE:

       DS.B    400,0

;----------------------------------------------------------

INTNAME:       DC.B    "intuition.library",0
GFXNAME:       DC.B    "graphics.library",0
DOSNAME:       DC.B    "dos.library",0
SCRNAME:       DC.B    "    LEVEL DESIGNER XENO © 1991 BY L.G.",0
FILENAME:      DC.B    "LEVEL/LEVEL1.MAP",0

;----------------------------------------------------------

 ALIGN.L

LEVEL_DATA:    IBYTES  "LEVEL/LEVEL1.BIT"

               END


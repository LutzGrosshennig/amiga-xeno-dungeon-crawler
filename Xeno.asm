;***********************************************
;*                                             *
;*           SCIFI DUNGEON CRAWLER             *
;*                                             *
;*          WRITTEN DECEMBER 1991 BY           *
;*             LUTZ GROSSHENNIG                *
;*                                             *
;*          GRAPHICS & TESTING BY              *
;*            ANDREAS GOLDBACH                 *
;*              BASTIAN KINNE                  *
;*              NIELS POLLEM                   *
;*                                             *
;***********************************************

; OFFSETS EXEC

FORBID         = -132           
PERMIT         = -138           
OPENLIBRARY    = -408
CLOSELIBRARY   = -414
ALLOCMEM       = -198
FREEMEM        = -210
FINDTASK       = -294
ADDDEVICE      = -432
OPENDEVICE     = -444
CLOSEDEVICE    = -450
ADDPORT        = -354
REMOVEPORT     = -360
DOIO           = -456

; OFFSETS INTUITION

OPENSCREEN     = -198
CLOSESCREEN    = -066
SCREENTOFRONT  = -252
DRAWIMAGE      = -114

; OFFSETS GRAPHICS

RECTFILL       = -306
LOADRGB4       = -192
DRAWTO         = -246
MOVEPEN        = -240
BLITCLEAR      = -300
SETAPEN        = -342
WRITEPIXEL     = -324
CLEARSCREEN    = -048
WAITTOF        = -270
INITRASTPORT   = -198
INITBITMAP     = -390

; OFFSETS DOS

DELAY          = -198 

; CONSTS

EXEC_BASE_PTR  = 4
CHIPREQUEST    = $10002
MOUSEBUTTON    = $BFE001
KEYCODE        = $BFEC01
INTENA         = $DFF09A
DMACON         = $DFF096

; SERIAL DEVICE

BAUD_RATE      = 19200
CMD_READ       = 2
CMD_WRITE      = 3
CMD_QUERY      = 9
CMD_SET        = 11

; INPUT

CURSOR_UP    = $67
CURSOR_DOWN  = $65
CURSOR_LEFT  = $61
CURSOR_RIGHT = $63

; DIRECTIONS

NORTH = %0001
WEST  = %0010
SOUTH = %0100
EAST  = %1000

; MAP SETTINGS, PADDING AND CLAMPING

LEVEL_DIMENSION = 20
MAX_X           = LEVEL_DIMENSION - 1
MAX_Y           = LEVEL_DIMENSION - 1 

; START LOCATION (SHOULD BE PART OF THE MAP)

START_POS_X         = 1
START_POS_Y         = MAX_Y

START_POS_X_PLAYER_2 = 1
START_POS_Y_PLAYER_2 = 8

OTHER_PLAYER_BIT   = 4 ; BIT TO INDICATE THE OTHER PLAYER 

PLAYER_DATA_LENGTH = 6 ; SIZE OF THE PLAYER DATA STRUCT (X, Y, HEADING)

; SCREEN DEFINITIONS

SCREEN_WIDTH    = 320
SCREEN_HEIGHT   = 240
PLANES          = 5
BYTES_PER_PLANE = (SCREEN_WIDTH * SCREEN_HEIGHT) / 8
PLAYFIELD_BYTES = BYTES_PER_PLANE * PLANES

; COMMAND BITS 

DO_DOUBLE_BUFFER = 0
DO_REDRAW        = 1 
DO_IO            = 2

;-- MACROS -------------------------------------------------------

OPEN_LIBRARY:MACRO *\NAME, *\BASE

       MOVE.L  EXEC_BASE_PTR, A6
       LEA     \NAME, A1
       JSR     OPENLIBRARY(A6)
       MOVE.L  D0, \BASE

 ENDM

CLOSE_LIBRARY:MACRO *\BASE

       MOVE.L  EXEC_BASE_PTR, A6
       MOVE.L  \BASE, A1
       JSR     CLOSELIBRARY(A6)

 ENDM

DRAW_BOX:MACRO %\X1, %\Y1, %\X2, %\Y2, %\COLOR

       MOVE.L  GFX_BASE_PTR, A6
       LEA     RASTPORT_STRUCT, A1

       MOVEQ   #\COLOR, D0
       JSR     SETAPEN(A6)

       MOVE.W  #\X1, D0
       MOVE.W  #\Y1, D1
       MOVE.W  #\X2, D2
       MOVE.W  #\Y2, D3
       JSR     RECTFILL(A6)

 ENDM

DRAW_IMAGE:MACRO *\IMAGE, %\X, %\Y

       MOVE.L  INTUITION_BASE_PTR, A6
       LEA     RASTPORT_STRUCT, A0
       LEA     \IMAGE, A1
       MOVE.W  #\X, D0
       MOVE.W  #\Y, D1
       JSR     DRAWIMAGE(A6)

 ENDM

SWAP_VALUES_L:MACRO *\NR1, *\NR2

       MOVE.L  \NR1, D0
       MOVE.L  \NR2, \NR1
       MOVE.L  D0, \NR2

 ENDM

SWAP_VALUES_W:MACRO *\NR1, *\NR2

       MOVE.W  \NR1, D0
       MOVE.W  \NR2, \NR1
       MOVE.W  D0, \NR2

 ENDM


DISABLE_MULTITASKING:MACRO

       MOVE.L EXEC_BASE_PTR,A6
       JSR    FORBID(A6)

 ENDM
 
ENABLE_MULTITASKING:MACRO

       MOVE.L EXEC_BASE_PTR, A6
       JSR    PERMIT(A6)

 ENDM
 
ALLOC_MEMORY:MACRO %\BYTES, %\REQ, *\POINTER

       MOVE.L  EXEC_BASE_PTR, A6
       MOVE.L  #\BYTES, D0
       MOVE.L  #\REQ, D1
       JSR     ALLOCMEM(A6)
       MOVE.L  D0, \POINTER
       
 ENDM

FREE_MEMORY:MACRO %\BYTES, *\POINTER

       MOVE.L  EXEC_BASE_PTR, A6
       MOVE.L  #\BYTES, D0
       MOVE.L  \POINTER, A1
       JSR     FREEMEM(A6)
       
 ENDM

;------------  M A I N  -  P R O G R A M  -----------------

START:

       CMPI.W #1, D0             ; NO CLI ARG GIVEN (EXCEPT A ZERO BYTE) MEANS WE ARE THE SERVER
       BEQ.S  START_AS_SERVER
 
       SWAP_VALUES_W PLAYER_X, PLAYER_2_X
       SWAP_VALUES_W PLAYER_Y, PLAYER_2_Y
       SWAP_VALUES_W PLAYER_HEADING, PLAYER_2_HEADING
       SWAP_VALUES_L PLAYER_MAP_PTR, PLAYER_2_MAP_PTR   

    BRA.S START_OPEN_LIBRARIES
 
START_AS_SERVER:

       MOVE.W #1, IS_SERVER     
    
START_OPEN_LIBRARIES:

       OPEN_LIBRARY INTUITION_LIB_NAME, INTUITION_BASE_PTR
       OPEN_LIBRARY GFX_LIB_NAME, GFX_BASE_PTR
       OPEN_LIBRARY DOS_LIB_NAME, DOS_BASE_PTR
    
       BSR OPEN_SERIAL_DEVICE
       BSR OPEN_SCREEN

       BSR UPDATE_PLAYER_POSITION
       BSR UPDATE_PLAYER_2_POSITION
  
       ; PREPARE THE FRONT BUFFER

       DRAW_IMAGE   BASE,  0, 0
       DRAW_IMAGE   HANDS, 0, 200
          
       BSR REDRAW_DUNGEON

       ; PREPARE THE BACK BUFFER

       MOVE.L  BACKBUFFER, D0
       BSR     UPDATE_RASTPORT_BITPLANE_PTRS
       
       DRAW_IMAGE   BASE,  0, 0
       DRAW_IMAGE   HANDS, 0, 200
       
       BSR REDRAW_DUNGEON

       ; START IRQ

       BSR INIT_NEW_IRQ
      
MAIN_LOOP:

       ; ARE WE SERVER OR CLIENT?

       CMP.W    #1, IS_SERVER
       BNE.S    MAIN_SERIAL_LINK_CLIENT

MAIN_SERIAL_LINK_SERVER:

       ; QUERY SERIAL.DEVICE STATUS

       LEA     IO_REQUEST_STRUCT, A1
       MOVE.L  EXEC_BASE_PTR, A6
       MOVE    #CMD_QUERY, 28(A1)
       JSR     DOIO(A6)
     
       ; IS ENOUGH DATA IN THE BUFFER?
 
       MOVE.L  32(A1), D0
       CMP.L   #PLAYER_DATA_LENGTH, D0
       BLT     MAIN_PROCESS_COMMAND    
       ; READ THE PLAYER DATA FROM THE CLIENT
    
	   BSET    #DO_IO, COMMAND
	
       MOVE    #CMD_READ, 28(A1)
       MOVE.L  #PLAYER_2_X, 40(A1)
       MOVE.L  #PLAYER_DATA_LENGTH, 36(A1)
       JSR     DOIO(A6)

       BSR     UPDATE_PLAYER_2_POSITION
       BSET    #DO_REDRAW, COMMAND
 
       ; SEND OUR PLAYER DATA TO THE CLIENT
 
       MOVE    #CMD_WRITE, 28(A1)
       MOVE.L  #PLAYER_X, 40(A1)
       MOVE.L  #PLAYER_DATA_LENGTH, 36(A1)
       JSR     DOIO(A6)
     
	   BCLR    #DO_IO, COMMAND
	 
       BRA.S   MAIN_PROCESS_COMMAND

MAIN_SERIAL_LINK_CLIENT:

       ; SEND OUR PLAYER DATA TO THE SERVER

       BSET    #DO_IO, COMMAND

       LEA     IO_REQUEST_STRUCT, A1
       MOVE.L  EXEC_BASE_PTR, A6
   
       MOVE    #CMD_WRITE, 28(A1)
       MOVE.L  #PLAYER_X, 40(A1)
       MOVE.L  #PLAYER_DATA_LENGTH, 36(A1)
       JSR     DOIO(A6)
   
       ; READ THE SERVER PLAYER DATA
    
       MOVE    #CMD_READ, 28(A1)
       MOVE.L  #PLAYER_2_X, 40(A1)
       MOVE.L  #PLAYER_DATA_LENGTH, 36(A1)
       JSR     DOIO(A6)
 
       BSR     UPDATE_PLAYER_2_POSITION
       BSET    #DO_REDRAW, COMMAND
	   BCLR    #DO_IO, COMMAND

MAIN_PROCESS_COMMAND:

       BTST    #DO_REDRAW, COMMAND
       BEQ.S   MAIN_TEST_MOUSE
    
       BSR REDRAW_DUNGEON

MAIN_TEST_MOUSE:

       MOVE.L  DOS_BASE_PTR, A6
       MOVEQ   #1, D1
       JSR     DELAY(A6)

       BTST    #6, MOUSEBUTTON
       BNE     MAIN_LOOP
MAIN_EXIT:
    
       BSR RESTORE_OLD_IRQ
       BSR CLOSE_SCREEN
       BSR CLOSE_SERIAL_DEVICE

SERIAL_DEVICE_ERROR:

       CLOSE_LIBRARY INTUITION_BASE_PTR
       CLOSE_LIBRARY GFX_BASE_PTR
       CLOSE_LIBRARY DOS_BASE_PTR

       ; RETURN CODE 0
       CLR.L D0
       RTS

;--------------------------------------

OPEN_SERIAL_DEVICE:

       MOVE.L  EXEC_BASE_PTR, A6
       SUB.L   A1, A1
       JSR     FINDTASK(A6)
 
       MOVE.L  D0, REPLY + $10
       LEA     REPLY, A1
       JSR     ADDPORT(A6)
 
       LEA     IO_REQUEST_STRUCT, A1
       CLR.L   D0
       CLR.L   D1
       LEA     SERIAL_DEVICE_NAME, A0
       JSR     OPENDEVICE(A6)
 
       TST.L   D0
       BNE     SERIAL_DEVICE_ERROR
 
       LEA     IO_REQUEST_STRUCT, A1
       MOVE.L  #REPLY, 14(A1)
 
       MOVE    #CMD_SET, 28(A1)
       MOVE.L  #BAUD_RATE, IOEXTD + 12
       JSR     DOIO(A6)
       RTS

;----------------------------------------------------------

CLOSE_SERIAL_DEVICE:

       LEA     REPLY, A1
       JSR     REMOVEPORT(A6)

       LEA     IO_REQUEST_STRUCT, A1
       JSR     CLOSEDEVICE(A6)
       RTS

;---------------------------------

REDRAW_DUNGEON:

       MOVE.W  PLAYER_HEADING, D0
       BTST    #0, D0
       BNE.S   DO_NORTH
       BTST    #1, D0
       BNE.S   DO_WEST
       BTST    #2, D0
       BNE.S   DO_SOUTH
       BTST    #3, D0
       BNE.S   DO_EAST
       RTS

DO_NORTH:

       BSR     BUILD_UP_NORTH
       BCLR    #DO_REDRAW, COMMAND
       BSET    #DO_DOUBLE_BUFFER, COMMAND
       RTS
    
DO_WEST:

       BSR     BUILD_UP_WEST
       BCLR    #DO_REDRAW, COMMAND
       BSET    #DO_DOUBLE_BUFFER, COMMAND
       RTS

DO_SOUTH:

       BSR     BUILD_UP_SOUTH
       BCLR    #DO_REDRAW, COMMAND
       BSET    #DO_DOUBLE_BUFFER, COMMAND
       RTS

DO_EAST:

       BSR     BUILD_UP_EAST
       BCLR    #DO_REDRAW, COMMAND
       BSET    #DO_DOUBLE_BUFFER, COMMAND
       RTS

;------------------------------------------

KEYS_NORTH:

       BSR     TESTKEYS_NORTH
       BRA     IRQ_END

KEYS_WEST:

       BSR     TESTKEYS_WEST
       BRA     IRQ_END

KEYS_SOUTH:

       BSR     TESTKEYS_SOUTH
       BRA     IRQ_END

KEYS_EAST:

       BSR     TESTKEYS_EAST
       BRA     IRQ_END

;----------------------------------------------------------

BUILD_UP_NORTH:

       BSR     DO_BASE_PIC

       MOVE.L  PLAYER_MAP_PTR, A4
       MOVE.B  (A4), D6

       BTST    #1, D6
       BNE     WALL_RIGHT_N1
BN11:
       BTST    #0, D6
       BNE     WALL_LEFT_N1
BN12:
       BTST    #2, D6
       BNE     WALL_FRONT_N1

       MOVE.B  -LEVEL_DIMENSION(A4), D6
       BTST    #1, D6
       BNE     WALL_RIGHT_N2
BN8:
       BTST    #0, D6
       BNE     WALL_LEFT_N2
BN9:
       BTST    #2, D6
       BNE     WALL_FRONT_N2

       MOVE.B  (-2 * LEVEL_DIMENSION)(A4), D6
       BTST    #1, D6
       BNE     WALL_RIGHT_N3
BN5:
       BTST    #0, D6
       BNE     WALL_LEFT_N3
BN6:
       BTST    #2, D6
       BNE     WALL_FRONT_N3

       MOVE.B  (-3 * LEVEL_DIMENSION)(A4), D6
       BTST    #1, D6
       BNE     WALL_RIGHT_N4
BN2:
       BTST    #0, D6
       BNE     WALL_LEFT_N4
BN3:
       BTST    #2, D6
       BNE     WALL_FRONT_N4

PLAYERTEST_N:

       MOVE.B  (A4), D6
       BTST    #2, D6
       BNE     TEST_N_EXIT

       MOVE.B  -LEVEL_DIMENSION(A4), D6
       BTST    #OTHER_PLAYER_BIT, D6
       BNE     PLAYER2

       BTST    #2, D6
       BNE     TEST_N_EXIT

       MOVE.B  (-2 * LEVEL_DIMENSION)(A4), D6
       BTST    #OTHER_PLAYER_BIT, D6
       BNE     PLAYER3

       BTST    #2, D6
       BNE     TEST_N_EXIT

       MOVE.B  (-3 * LEVEL_DIMENSION)(A4), D6
       BTST    #OTHER_PLAYER_BIT, D6
       BNE     PLAYER4

TEST_N_EXIT:
       RTS

;--------------------------------

WALL_FRONT_N4:
       BSR     WALL_FRONT4
       BRA     PLAYERTEST_N
WALL_RIGHT_N4:
       BSR     WALL_RIGHT4
       BRA     BN2
WALL_LEFT_N4:
       BSR     WALL_LEFT4
       BRA     BN3

WALL_FRONT_N3:
       BSR     WALL_FRONT3
       BRA     PLAYERTEST_N
WALL_RIGHT_N3:
       BSR     WALL_RIGHT3
       BRA     BN5
WALL_LEFT_N3:
       BSR     WALL_LEFT3
       BRA     BN6

WALL_FRONT_N2:
       BSR     WALL_FRONT2
       BRA     PLAYERTEST_N
WALL_RIGHT_N2:
       BSR     WALL_RIGHT2
       BRA     BN8
WALL_LEFT_N2:
       BSR     WALL_LEFT2
       BRA     BN9

WALL_FRONT_N1:
       BSR     WALL_FRONT1
       RTS
WALL_RIGHT_N1:
       BSR     WALL_RIGHT1
       BRA     BN11
WALL_LEFT_N1:
       BSR     WALL_LEFT1
       BRA     BN12

;----------------------------------------

WALL_FRONT4:
       DRAW_IMAGE   WALL4, 141, 108
       RTS
WALL_RIGHT4:
       DRAW_IMAGE   RIGHT4, 179, 90
       RTS
WALL_LEFT4:
       DRAW_IMAGE   LEFT4, 117, 90
       RTS

WALL_FRONT3:
       DRAW_IMAGE   WALL3, 117, 90
       RTS
WALL_RIGHT3:
       DRAW_IMAGE   RIGHT3, 203, 67
       RTS
WALL_LEFT3:
       DRAW_IMAGE   LEFT3, 87, 67
       RTS

WALL_FRONT2:
       DRAW_IMAGE   WALL2, 87, 67
       RTS
WALL_RIGHT2:
       DRAW_IMAGE   RIGHT2, 233, 25
       RTS
WALL_LEFT2:
       DRAW_IMAGE   LEFT2, 32, 25
       RTS

WALL_FRONT1:
       DRAW_IMAGE   WALL1, 32, 25
       RTS
WALL_RIGHT1:
       DRAW_IMAGE   RIGHT1, 288, 0
       RTS
WALL_LEFT1:
       DRAW_IMAGE   LEFT1, 0, 0
       RTS

PLAYER4:
       DRAW_BOX     150, 110, 170, 133, 5
       RTS
PLAYER3:
       DRAW_BOX     140, 100, 180, 144, 5
       RTS
PLAYER2:
       DRAW_BOX     130, 77, 190, 160, 5
       RTS

;----------------------------------------------------------

BUILD_UP_WEST:

       BSR     DO_BASE_PIC

       MOVE.L  PLAYER_MAP_PTR, A4
       MOVE.B  (A4), D6
       BTST    #2, D6
       BNE     WALL_RIGHT_W1
BW11:
       BTST    #3, D6
       BNE     WALL_LEFT_W1
BW12:
       BTST    #0, D6
       BNE     WALL_FRONT_W1

       MOVE.B  -1(A4), D6
       BTST    #2, D6
       BNE     WALL_RIGHT_W2
BW8:
       BTST    #3, D6
       BNE     WALL_LEFT_W2
BW9:
       BTST    #0, D6
       BNE     WALL_FRONT_W2

       MOVE.B  -2(A4), D6
       BTST    #2, D6
       BNE     WALL_RIGHT_W3
BW5:
       BTST    #3, D6
       BNE     WALL_LEFT_W3
BW6:
       BTST    #0, D6
       BNE     WALL_FRONT_W3

       MOVE.B  -3(A4), D6
       BTST    #2, D6
       BNE     WALL_RIGHT_W4
BW2:
       BTST    #3, D6
       BNE     WALL_LEFT_W4
BW3:
       BTST    #0, D6
       BNE     WALL_FRONT_W4
    
PLAYERTEST_W:

       MOVE.B  (A4), D6
       BTST    #0, D6
       BNE     TEST_W_EXIT

       MOVE.B  -1(A4), D6
       BTST    #OTHER_PLAYER_BIT, D6
       BNE     PLAYER2
       BTST    #0, D6
       BNE     TEST_W_EXIT

       MOVE.B  -2(A4), D6
       BTST    #OTHER_PLAYER_BIT, D6
       BNE     PLAYER3
       BTST    #0, D6
       BNE     TEST_W_EXIT

       MOVE.B  -3(A4), D6
       BTST    #OTHER_PLAYER_BIT, D6
       BNE     PLAYER4

TEST_W_EXIT:
       RTS

;----------------------------------------------------------

WALL_FRONT_W4:
       BSR     WALL_FRONT4
       BRA     PLAYERTEST_W
WALL_RIGHT_W4:
       BSR     WALL_RIGHT4
       BRA     BW2
WALL_LEFT_W4:
       BSR     WALL_LEFT4
       BRA     BW3

WALL_FRONT_W3:
       BSR     WALL_FRONT3
       BRA     PLAYERTEST_W
WALL_RIGHT_W3:
       BSR     WALL_RIGHT3
       BRA     BW5
WALL_LEFT_W3:
       BSR     WALL_LEFT3
       BRA     BW6

WALL_FRONT_W2:
       BSR     WALL_FRONT2
       BRA     PLAYERTEST_W
WALL_RIGHT_W2:
       BSR     WALL_RIGHT2
       BRA     BW8
WALL_LEFT_W2:
       BSR     WALL_LEFT2
       BRA     BW9

WALL_FRONT_W1:
       BSR     WALL_FRONT1
       RTS
WALL_RIGHT_W1:
       BSR     WALL_RIGHT1
       BRA     BW11
WALL_LEFT_W1:
       BSR     WALL_LEFT1
       BRA     BW12

;----------------------------------------------------------

BUILD_UP_SOUTH:

       BSR     DO_BASE_PIC

       MOVE.L  PLAYER_MAP_PTR, A4
       MOVE.B  (A4), D6
       BTST    #0, D6
       BNE     WALL_RIGHT_S1
BS11:
       BTST    #1, D6
       BNE     WALL_LEFT_S1
BS12:
       BTST    #3, D6
       BNE     WALL_FRONT_S1

       MOVE.B  LEVEL_DIMENSION(A4), D6
       BTST    #0, D6
       BNE     WALL_RIGHT_S2
BS8:
       BTST    #1, D6
       BNE     WALL_LEFT_S2
BS9:
       BTST    #3, D6
       BNE     WALL_FRONT_S2

       MOVE.B  (2 * LEVEL_DIMENSION)(A4), D6
       BTST    #0, D6
       BNE     WALL_RIGHT_S3
BS5:
       BTST    #1, D6
       BNE     WALL_LEFT_S3
BS6:
       BTST    #3, D6
       BNE     WALL_FRONT_S3

       MOVE.B  (3 * LEVEL_DIMENSION)(A4), D6
       BTST    #0, D6
       BNE     WALL_RIGHT_S4
BS2:
       BTST    #1, D6
       BNE     WALL_LEFT_S4
BS3:
       BTST    #3, D6
       BNE     WALL_FRONT_S4

PLAYERTEST_S:

       MOVE.B  (A4), D6
       BTST    #3, D6
       BNE     TEST_S_EXIT

       MOVE.B  LEVEL_DIMENSION(A4), D6
       BTST    #OTHER_PLAYER_BIT, D6
       BNE     PLAYER2
       BTST    #3, D6
       BNE     TEST_S_EXIT

       MOVE.B  (2 * LEVEL_DIMENSION)(A4), D6
       BTST    #OTHER_PLAYER_BIT, D6
       BNE     PLAYER3
       BTST    #3, D6
       BNE     TEST_S_EXIT

       MOVE.B  (3 * LEVEL_DIMENSION)(A4), D6
       BTST    #OTHER_PLAYER_BIT, D6
       BNE     PLAYER4

TEST_S_EXIT:
       RTS

;----------------------------------------------------------

WALL_FRONT_S4:
       BSR     WALL_FRONT4
       BRA     PLAYERTEST_S
WALL_RIGHT_S4:
       BSR     WALL_RIGHT4
       BRA     BS2
WALL_LEFT_S4:
       BSR     WALL_LEFT4
       BRA     BS3

WALL_FRONT_S3:
       BSR     WALL_FRONT3
       BRA     PLAYERTEST_S
WALL_RIGHT_S3:
       BSR     WALL_RIGHT3
       BRA     BS5
WALL_LEFT_S3:
       BSR     WALL_LEFT3
       BRA     BS6

WALL_FRONT_S2:
       BSR     WALL_FRONT2
       BRA     PLAYERTEST_S
WALL_RIGHT_S2:
       BSR     WALL_RIGHT2
       BRA     BS8
WALL_LEFT_S2:
       BSR     WALL_LEFT2
       BRA     BS9

WALL_FRONT_S1:
       BSR     WALL_FRONT1
       RTS
WALL_RIGHT_S1:
       BSR     WALL_RIGHT1
       BRA     BS11
WALL_LEFT_S1:
       BSR     WALL_LEFT1
       BRA     BS12

;----------------------------------------------------------

BUILD_UP_EAST:

       BSR     DO_BASE_PIC

       MOVE.L  PLAYER_MAP_PTR, A4
       MOVE.B  (A4), D6
       BTST    #3, D6
       BNE       WALL_RIGHT_O1BO11:
       BTST    #2, D6
       BNE     WALL_LEFT_O1BO12:
       BTST    #1, D6
       BNE     WALL_FRONT_O1
       MOVE.B  1(A4), D6
       BTST    #3, D6
       BNE     WALL_RIGHT_O2BO8:
       BTST    #2, D6
       BNE     WALL_LEFT_O2BO9:
       BTST    #1, D6
       BNE     WALL_FRONT_O2
       MOVE.B  2(A4), D6
       BTST    #3, D6
       BNE.S   WALL_RIGHT_O3
BO5:
       BTST    #2, D6
       BNE.S   WALL_LEFT_O3
BO6:
       BTST    #1, D6
       BNE.S   WALL_FRONT_O3

       MOVE.B  3(A4), D6
       BTST    #3, D6
       BNE.S   WALL_RIGHT_O4
BO2:
       BTST    #2, D6
       BNE.S   WALL_LEFT_O4
BO3:
       BTST    #1, D6
       BNE.S    WALL_FRONT_O4
  
PLAYERTEST_O:

       MOVE.B  (A4), D6
       BTST    #1, D6
       BNE.S   TEST_O_EXIT

       MOVE.B  1(A4), D6
       BTST    #OTHER_PLAYER_BIT, D6
       BNE     PLAYER2       BTST    #1, D6
       BNE.S   TEST_O_EXIT

       MOVE.B  2(A4), D6
       BTST    #OTHER_PLAYER_BIT, D6
       BNE     PLAYER3       BTST    #1, D6
       BNE.S   TEST_O_EXIT

       MOVE.B  3(A4), D6
       BTST    #OTHER_PLAYER_BIT, D6
       BNE     PLAYER4
TEST_O_EXIT:
       RTS

;----------------------------------------------------------

WALL_FRONT_O4:
       BSR     WALL_FRONT4
       BRA.S   PLAYERTEST_O
    
WALL_RIGHT_O4:
       BSR     WALL_RIGHT4
       BRA.S   BO2
    
WALL_LEFT_O4:
       BSR     WALL_LEFT4
       BRA.S   BO3

WALL_FRONT_O3:
       BSR     WALL_FRONT3
       BRA.S   PLAYERTEST_O
    
WALL_RIGHT_O3:
       BSR     WALL_RIGHT3
       BRA.S   BO5
    
WALL_LEFT_O3:
       BSR     WALL_LEFT3
       BRA.S   BO6

WALL_FRONT_O2:
       BSR     WALL_FRONT2
       BRA.S   PLAYERTEST_O
    
WALL_RIGHT_O2:
       BSR     WALL_RIGHT2
       BRA     BO8    
WALL_LEFT_O2:
       BSR     WALL_LEFT2
       BRA     BO9
WALL_FRONT_O1:
       BSR     WALL_FRONT1
       RTS
    
WALL_RIGHT_O1:
       BSR     WALL_RIGHT1
       BRA     BO11    
WALL_LEFT_O1:
       BSR     WALL_LEFT1
       BRA     BO12
;----------------------------------------------------------

TESTKEYS_NORTH:

       MOVE.L  PLAYER_MAP_PTR, A0
       MOVE.B  KEYCODE, D0
       CMP.B   #CURSOR_UP, D0
       BEQ.S   VORWARD_N
       CMP.B   #CURSOR_DOWN, D0
       BEQ.S   REVERS_N
       CMP.B   #CURSOR_LEFT, D0
       BEQ.S   MOVE_LEFT_N
       CMP.B   #CURSOR_RIGHT, D0
       BEQ.S   MOVE_RIGHT_N
       RTS

MOVE_LEFT_N:
       MOVE.W  #WEST,PLAYER_HEADING
       BSET    #DO_REDRAW, COMMAND
       RTS

MOVE_RIGHT_N:
       MOVE.W  #EAST,PLAYER_HEADING
       BSET    #DO_REDRAW, COMMAND
       RTS

VORWARD_N:
       CMP.W   #0, PLAYER_Y
       BEQ     TEST_EXIT       MOVE.B  (A0), D0
       BTST    #2, D0
       BNE     TEST_EXIT
       SUB.L   #LEVEL_DIMENSION, PLAYER_MAP_PTR
       SUBQ.W  #1, PLAYER_Y
       BSET    #DO_REDRAW, COMMAND
       RTS
    
REVERS_N:
       CMP.W   #MAX_Y, PLAYER_Y
       BEQ     TEST_EXIT       MOVE.B  (A0), D0
       BTST    #3, D0
       BNE     TEST_EXIT
       ADD.L   #LEVEL_DIMENSION, PLAYER_MAP_PTR
       ADDQ.W  #1, PLAYER_Y
       BSET    #DO_REDRAW, COMMAND
       RTS

;----------------------------------------------------------

TESTKEYS_WEST:

       MOVE.L  PLAYER_MAP_PTR, A0
       MOVE.B  KEYCODE, D0
       CMP.B   #CURSOR_UP, D0
       BEQ.S   VORWARD_W
       CMP.B   #CURSOR_DOWN, D0
       BEQ.S   REVERS_W
       CMP.B   #CURSOR_LEFT, D0
       BEQ.S   MOVE_LEFT_W
       CMP.B   #CURSOR_RIGHT, D0
       BEQ.S   MOVE_RIGHT_W
       RTS

MOVE_LEFT_W:
       MOVE.W  #SOUTH, PLAYER_HEADING
       BSET    #DO_REDRAW, COMMAND
       RTS

MOVE_RIGHT_W:
       MOVE.W  #NORTH, PLAYER_HEADING
       BSET    #DO_REDRAW, COMMAND
       RTS

VORWARD_W:
       CMP.W   #0, PLAYER_X
       BEQ     TEST_EXIT       MOVE.B  (A0), D0
       BTST    #0, D0
       BNE     TEST_EXIT
       SUBQ.L  #1, PLAYER_MAP_PTR
       SUBQ.W  #1, PLAYER_X
       BSET    #DO_REDRAW, COMMAND
       RTS
REVERS_W:
       CMP.W   #MAX_X, PLAYER_X
       BEQ     TEST_EXIT       MOVE.B  (A0), D0
       BTST    #1, D0
       BNE      TEST_EXIT
       ADDQ.L  #1, PLAYER_MAP_PTR
       ADDQ.W  #1, PLAYER_X
       BSET    #DO_REDRAW, COMMAND
       RTS

;----------------------------------------------------------

TESTKEYS_SOUTH:
       MOVE.L  PLAYER_MAP_PTR,A0
       MOVE.B  KEYCODE, D0
       CMP.B   #CURSOR_UP, D0
       BEQ.S   VORWARD_S
       CMP.B   #CURSOR_DOWN, D0
       BEQ.S   REVERS_S
       CMP.B   #CURSOR_LEFT, D0
       BEQ.S   MOVE_LEFT_S
       CMP.B   #CURSOR_RIGHT, D0
       BEQ.S   MOVE_RIGHT_S
       RTS

MOVE_LEFT_S:
       MOVE.W  #EAST, PLAYER_HEADING
       BSET    #DO_REDRAW, COMMAND
       RTS

MOVE_RIGHT_S:
       MOVE.W  #WEST, PLAYER_HEADING
       BSET    #DO_REDRAW, COMMAND
       RTS

VORWARD_S:
       CMP.W   #MAX_Y, PLAYER_Y
       BEQ     TEST_EXIT       MOVE.B  (A0), D0
       BTST    #3, D0
       BNE     TEST_EXIT

       ADD.L   #LEVEL_DIMENSION, PLAYER_MAP_PTR
       ADDQ.W  #1, PLAYER_Y
       BSET    #DO_REDRAW, COMMAND
       RTS
REVERS_S:
       CMP.W   #0, PLAYER_Y
       BEQ     TEST_EXIT       MOVE.B  (A0), D0
       BTST    #2, D0
       BNE     TEST_EXIT
       SUB.L   #LEVEL_DIMENSION, PLAYER_MAP_PTR
       SUBQ.W  #1, PLAYER_Y
       BSET    #DO_REDRAW, COMMAND
       RTS

;----------------------------------------------------------

TESTKEYS_EAST:
       MOVE.L  PLAYER_MAP_PTR, A0
       MOVE.B  KEYCODE, D0
       CMP.B   #CURSOR_UP, D0
       BEQ.S   VORWARD_O
       CMP.B   #CURSOR_DOWN, D0
       BEQ.S   REVERS_O
       CMP.B   #CURSOR_LEFT, D0
       BEQ.S   MOVE_LEFT_O
       CMP.B   #CURSOR_RIGHT, D0
       BEQ.S   MOVE_RIGHT_O
       RTS

MOVE_LEFT_O:
       MOVE.W  #NORTH, PLAYER_HEADING
       BSET    #DO_REDRAW, COMMAND
       RTS

MOVE_RIGHT_O:
       MOVE.W  #SOUTH, PLAYER_HEADING
       BSET    #DO_REDRAW, COMMAND
       RTS

VORWARD_O:
       CMP.W   #MAX_X, PLAYER_X
       BEQ.S   TEST_EXIT
       MOVE.B  (A0), D0
       BTST    #1, D0
       BNE.S   TEST_EXIT

       ADDQ.L  #1, PLAYER_MAP_PTR
       ADDQ.W  #1, PLAYER_X
       BSET    #DO_REDRAW, COMMAND
       RTS
REVERS_O:
       CMP.W   #0, PLAYER_X
       BEQ.S   TEST_EXIT
       MOVE.B  (A0), D0
       BTST    #0, D0
       BNE.S   TEST_EXIT

       SUBQ.L  #1, PLAYER_MAP_PTR
       SUBQ.W  #1, PLAYER_X
       BSET    #DO_REDRAW, COMMAND
       RTS

TEST_EXIT:
       RTS

;----------------------------------------------------------

DO_BASE_PIC:

       DRAW_IMAGE   BASE, 0, 0
       RTS

;----------------------------------------------------------

OPEN_SCREEN:

       ; GET SOME CHIP MEM

       ALLOC_MEMORY PLAYFIELD_BYTES, CHIPREQUEST, FRONTBUFFER
       ALLOC_MEMORY PLAYFIELD_BYTES, CHIPREQUEST, BACKBUFFER

       ; INIT BITMAP_STRUCT STRUCTURE

       MOVE.L  GFX_BASE_PTR, A6
       LEA     BITMAP_STRUCT, A0
       MOVEQ   #PLANES, D0
       MOVE.L  #SCREEN_WIDTH, D1
       MOVE.L  #SCREEN_HEIGHT, D2
       JSR     INITBITMAP(A6)

       ; INIT RASTPORT_STRUCT

       MOVE.L  FRONTBUFFER, D0
       BSR     UPDATE_RASTPORT_BITPLANE_PTRS

       LEA     RASTPORT_STRUCT, A1
       JSR     INITRASTPORT(A6)
       MOVE.L  #BITMAP_STRUCT, RASTPORT_BITMAP_PTR

       ; SETUP COPPER LIST

       BSR     UPDATE_COPPER_BITPLANE_PTRS
       BSR     SET_COLOR_PALETTE
       BSR     START_COPPER

       RTS

;-------------------------------------------

UPDATE_COPPER_BITPLANE_PTRS:

       LEA     COPPER_BITPLANES, A0
       MOVE.L  FRONTBUFFER, D0
       MOVE.L  D0, D1
       MOVEQ   #PLANES - 1, D7

INSTALL_POINTERS_LOOP:

       MOVE.W  D0, 6(A0)
       SWAP    D0
       MOVE.W  D0, 2(A0)
       ADD.L   #BYTES_PER_PLANE, D1
       MOVE.L  D1, D0
       ADD.L   #8, A0
       DBRA    D7, INSTALL_POINTERS_LOOP
       RTS

;-------------------------------------------

SET_COLOR_PALETTE:

       LEA     COPPER_PALETTE, A1
       LEA     PALETTE, A0
       MOVE.L  #$180, D0
       MOVEQ   #31, D7

SET_COLOR_PALETTE_LOOP:

       MOVE.W  D0, (A1)+
       MOVE.W  (A0)+, (A1)+
       ADDQ.W  #2, D0
       DBRA    D7, SET_COLOR_PALETTE_LOOP
       RTS

;-------------------------------------------

START_COPPER:

       MOVE.L  GFX_BASE_PTR, A0
       ADD.L   #$32, A0
       MOVE.W  #$0080, DMACON
       MOVE.L  (A0), OLD_COPPER_PTR
       MOVE.L  #NEW_COPPER_LIST, (A0)
       MOVE.W  #$8080, DMACON
       RTS

;-------------------------------------------

EXIT_COPPER:

       MOVE.L  GFX_BASE_PTR, A0
       ADD.L   #$32, A0
       MOVE.W  #$0080, DMACON
       MOVE.L  OLD_COPPER_PTR, (A0)
       MOVE.W  #$8080, DMACON
       RTS

;-------------------------------------------

UPDATE_RASTPORT_BITPLANE_PTRS:

       MOVEQ   #PLANES - 1, D7
       LEA     BITMAP_PLANES, A0
         
RASTPORT_LOOP:

       MOVE.L  D0, (A0)+
       ADD.L   #BYTES_PER_PLANE, D0
       DBRA    D7, RASTPORT_LOOP
       RTS

;----------------------------------

CLOSE_SCREEN:

       BSR     EXIT_COPPER

       FREE_MEMORY PLAYFIELD_BYTES, FRONTBUFFER
       FREE_MEMORY PLAYFIELD_BYTES, BACKBUFFER

       RTS

;--------------------------------

INIT_NEW_IRQ:

       MOVE.W  #$4000, INTENA
       MOVE.L  $6C, OLDIRQ
       MOVE.L  #NEWIRQ, $6C
       MOVE.W  #$C000, INTENA
       RTS

;----------------------------------------------------------

RESTORE_OLD_IRQ:

       MOVE.W  #$4000, INTENA
       MOVE.L  OLDIRQ, $6C
       MOVE.W  #$C000, INTENA
       RTS

;----------------------------------------------------------

UPDATE_PLAYER_POSITION:

       LEA     DUNGEON, A0
       MOVEQ   #0, D0
       MOVE.W  PLAYER_X, D0
       ADD.L   D0, A0
       MOVE.W  PLAYER_Y, D0
       MULU    #LEVEL_DIMENSION, D0
       ADD.L   D0, A0
       MOVE.L  A0, PLAYER_MAP_PTR

       RTS

;----------------------------------------------------------

UPDATE_PLAYER_2_POSITION:

       MOVE.L  PLAYER_2_MAP_PTR, A0
       BCLR    #OTHER_PLAYER_BIT, (A0)

       LEA     DUNGEON, A0
       MOVEQ   #0, D0
       MOVE.W  PLAYER_2_X, D0
       ADD.L   D0, A0
       MOVE.W  PLAYER_2_Y, D0
       MULU    #LEVEL_DIMENSION, D0
       ADD.L   D0, A0
       BSET    #OTHER_PLAYER_BIT, (A0)
       MOVE.L  A0, PLAYER_2_MAP_PTR

       RTS

;------------------------------------

NEWIRQ:

       MOVEM.L D0-D7/A0-A6,-(A7)

	   BTST    #DO_IO, COMMAND
	   BNE.S   IRQ_END

       BTST    #DO_REDRAW, COMMAND
       BNE.S   IRQ_END

       BTST    #DO_DOUBLE_BUFFER, COMMAND
       BEQ.S   IRQ_HANDLE_INPUT

       BSR     DOUBLE_BUFFER
       BCLR    #DO_DOUBLE_BUFFER, COMMAND

IRQ_HANDLE_INPUT:

       MOVE.W  PLAYER_HEADING, D0

       BTST    #0, D0
       BNE     KEYS_NORTH
       BTST    #1, D0
       BNE     KEYS_WEST
       BTST    #2, D0
       BNE     KEYS_SOUTH
       BTST    #3, D0
       BNE     KEYS_EAST
IRQ_END:

       MOVEM.L (A7)+, D0-D7/A0-A6
       DC.W   $4EF9
OLDIRQ:DC.L   0 ; NASTY I KNOW...

;-----------------------------

DOUBLE_BUFFER:

       MOVE.L  FRONTBUFFER, D0
       MOVE.L  BACKBUFFER, FRONTBUFFER

       MOVE.L  D0, BACKBUFFER
       BSR     UPDATE_COPPER_BITPLANE_PTRS

       MOVE.L  BACKBUFFER, D0  
       BSR     UPDATE_RASTPORT_BITPLANE_PTRS

       RTS

;--- BIT MAP STRUCTURES -----------------------------------

LEFT4:
       DC.W    0, 0, 24, 52, 5
       DC.L    LEFT4_DATA
       DC.B    31, 0
       DC.L    0

RIGHT4:
       DC.W    0, 0, 24, 52, 5
       DC.L    RIGHT4_DATA
       DC.B    31, 0
       DC.L    0
    
LEFT3:
       DC.W    0, 0, 30, 90, 5
       DC.L    LEFT3_DATA
       DC.B    31, 0
       DC.L    0

RIGHT3:
       DC.W    0, 0, 30, 90, 5
       DC.L    RIGHT3_DATA
       DC.B    31, 0
       DC.L    0

LEFT2:
       DC.W    0, 0, 55, 158, 5
       DC.L    LEFT2_DATA
       DC.B    31, 0
       DC.L    0

RIGHT2:
       DC.W    0, 0, 55, 158, 5
       DC.L    RIGHT2_DATA
       DC.B    31, 0
       DC.L    0

LEFT1:
       DC.W    0, 0, 32, 200, 5
       DC.L    LEFT1_DATA
       DC.B    31, 0
       DC.L    0

RIGHT1:
       DC.W    0, 0, 32, 200, 5
       DC.L    RIGHT1_DATA
       DC.B    31, 0
       DC.L    0

WALL4:
       DC.W    0, 0, 38, 23, 5
       DC.L    WALL4_DATA
       DC.B    31, 0
       DC.L    0

WALL3:
       DC.W    0, 0, 86, 52, 5
       DC.L    WALL3_DATA
       DC.B    31, 0
       DC.L    0

WALL2:
       DC.W    0, 0, 146, 90, 5
       DC.L    WALL2_DATA
       DC.B    31, 0
       DC.L    0

WALL1:
       DC.W    0, 0 , 256, 156, 5
       DC.L    WALL1_DATA
       DC.B    31, 0
       DC.L    0

BASE:
       DC.W    0, 0, 320, 200, 5
       DC.L    BASE_DATA
       DC.B    31, 0
       DC.L    0

HANDS:
       DC.W    0, 0, 320, 40, 5
       DC.L    HANDS_DATA
       DC.B    31, 0
       DC.L    0

PALETTE:
       DC.W    $000,$ECA,$E00,$A00,$D80,$FE0,$00F,$080
       DC.W    $E00,$0DD,$E00,$E40,$F90,$FE0,$950,$A60
       DC.W    $B70,$D80,$333,$555,$777,$888,$AAA,$CCC
       DC.W    $144,$255,$377,$599,$7AA,$9CC,$CDD,$FFF

DUNGEON:

       IBYTES  "LEVEL/LEVEL1.MAP"

   ALIGN.L

;----------------------------------------------------------

GFX_BASE_PTR:       DC.L    0
INTUITION_BASE_PTR: DC.L    0
DOS_BASE_PTR:       DC.L    0
FILE_HANDLE:        DC.L    0
OLD_COPPER_PTR:     DC.L    0
FRONTBUFFER:        DC.L    0
BACKBUFFER:         DC.L    0

COMMAND:            DC.W    0
IS_SERVER:          DC.W    0

;---------------------------
IO_REQUEST_STRUCT:
MESSAGE:            DS.W    10, 0
IO:                 DS.W    6, 0
IOREQ:              DS.W    8, 0
IOEXTD:             DS.W    17, 0
REPLY:              DS.L    8, 0

;---------------------------
BITMAP_STRUCT:
                     DC.W    0, 0
                     DC.B    0, 0
                     DC.W    0
BITMAP_PLANES:       DS.L    8, 0

;---------------------------
RASTPORT_STRUCT:     DC.L    0
RASTPORT_BITMAP_PTR: DC.L    0
                     DS.B    96, 0
;---------------------------

 ALIGN.L

PLAYER_MAP_PTR:     DC.L    DUNGEON + ((START_POS_Y * LEVEL_DIMENSION) + START_POS_X)
PLAYER_X:           DC.W    START_POS_X
PLAYER_Y:           DC.W    START_POS_Y
PLAYER_HEADING:     DC.W    NORTH
PLAYER_PAD:         DC.W    0

PLAYER_2_MAP_PTR:   DC.L    DUNGEON + ((START_POS_Y_PLAYER_2 * LEVEL_DIMENSION) + START_POS_X_PLAYER_2)
PLAYER_2_X:         DC.W    START_POS_X_PLAYER_2
PLAYER_2_Y:         DC.W    START_POS_Y_PLAYER_2
PLAYER_2_HEADING    DC.W    WEST
PLAYER_2_PAD:       DC.W    0
  
GFX_LIB_NAME:       DC.B    "graphics.library", 0
INTUITION_LIB_NAME: DC.B    "intuition.library", 0
DOS_LIB_NAME:       DC.B    "dos.library", 0
SERIAL_DEVICE_NAME: DC.B    "serial.device", 0

;--- NEEDS TO GO TO CHIPRAM! -------------------------------------------------------

 DATA 

NEW_COPPER_LIST:

       DC.W    $008E, $2C81 ; DIWSTART
       DC.W    $0090, $1CC1 ; DIWSTOP
       DC.W    $0092, $0038 ; DDFSTART
       DC.W    $0094, $00D0 ; DFFSTOP
       DC.W    $0100, $5200 ; 5 BITPLANES
       DC.W    $0108, $0000 ; MODULO 1
       DC.W    $010A, $0000 ; MODULO 2

COPPER_BITPLANES:

       DC.W    $00E0, 0 ; BITPLANE 1
       DC.W    $00E2, 0
       DC.W    $00E4, 0 ; BITPLANE 2
       DC.W    $00E6, 0
       DC.W    $00E8, 0 ; BITPLANE 3
       DC.W    $00EA, 0
       DC.W    $00EC, 0 ; BITPLANE 4
       DC.W    $00EE, 0
       DC.W    $00F0, 0 ; BITPLANE 5
       DC.W    $00F2, 0

COPPER_PALETTE:

       DS.W    64, 0 ; COLOR TABLE
       DC.W    $FFFF, $FFFE ; COPPER END

 ALIGN.L

; BITMAP_STRUCT DATA

BASE_DATA:     IBYTES  "BITS/BASE.BIT"
HANDS_DATA:    IBYTES  "BITS/HANDS.BIT"
WALL4_DATA:    IBYTES  "BITS/WALL4.BIT"
WALL3_DATA:    IBYTES  "BITS/WALL3.BIT"
WALL2_DATA:    IBYTES  "BITS/WALL2.BIT"
WALL1_DATA:    IBYTES  "BITS/WALL1.BIT"
LEFT4_DATA:    IBYTES  "BITS/LEFT4.BIT"
LEFT3_DATA:    IBYTES  "BITS/LEFT3.BIT"
LEFT2_DATA:    IBYTES  "BITS/LEFT2.BIT"
LEFT1_DATA:    IBYTES  "BITS/LEFT1.BIT"
RIGHT4_DATA:   IBYTES  "BITS/RIGHT4.BIT"
RIGHT3_DATA:   IBYTES  "BITS/RIGHT3.BIT"
RIGHT2_DATA:   IBYTES  "BITS/RIGHT2.BIT"
RIGHT1_DATA:   IBYTES  "BITS/RIGHT1.BIT"

 END

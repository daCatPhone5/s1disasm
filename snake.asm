; ---------------------------------------------------------------------------
; Mega Drive Snake
; ---------------------------------------------------------------------------

        cpu 68000
        padding off

VDP_DATA        equ     $C00000
VDP_CTRL        equ     $C00004
PAD1_DATA       equ     $A10003
PAD1_CTRL       equ     $A10009

; RAM state
score           equ     $FF0000
game_over       equ     $FF0002
snake_dir       equ     $FF0004
snake_head      equ     $FF0006
snake_len       equ     $FF0008
frame_timer     equ     $FF000A
apple_x         equ     $FF000C
apple_y         equ     $FF000E
board_tile      equ     $FF0010

        org     0
        dc.l    $00FFFFFC
        dc.l    Start
        dc.l    Stop,Stop,Stop,Stop,Stop,Stop,Stop,Stop
        dc.l    Stop,Stop,Stop,Stop,Stop,Stop,Stop,Stop
        rept    16
        dc.l    Stop
        endm
        rept    16
        dc.l    Stop
        endm
        rept    16
        dc.l    Stop
        endm
        rept    16
        dc.l    Stop
        endm

        org     $100
        dc.b    "SEGA MEGA DRIVE "
        dc.b    "(C)SNAKE 2026   "
        dc.b    "MEGA DRIVE SNAKE                                "
        dc.b    "MEGA DRIVE SNAKE                                "
        dc.b    "GM 00000000-00"
        dc.w    0
        dc.b    "J               "
        dc.l    0
        dc.l    $003FFFFF
        dc.l    $00FF0000
        dc.l    $00FFFFFF
        dc.b    "            "
        dc.b    "                                                    "
        dc.b    "JUE             "

        org     $200
Start:
        move    #$2700,sr

        move.b  $A10001,d0
        andi.b  #$0F,d0
        beq.s   .no_tmss
        move.l  #'SEGA',$A14000
.no_tmss:

        bsr.s   InitVDP
        bsr.s   LoadTiles
        bsr.s   ResetGame

MainLoop:
        bsr.s   ReadInput
        tst.w   game_over
        bne.s   .game_over_wait

        addq.w  #1,frame_timer
        cmpi.w  #8,frame_timer
        bne.s   .skip_move
        move.w  #0,frame_timer
        bsr.s   MoveSnake
.skip_move:
        bsr.s   DrawHud
        bsr.s   DrawBoard
        bra.s   MainLoop

.game_over_wait:
        btst    #7,($A10003)
        beq.s   MainLoop
        bsr.s   ResetGame
        bra.s   MainLoop

ResetGame:
        move.w  #0,score
        move.w  #0,game_over
        move.w  #0,snake_dir
        move.w  #10,snake_head
        move.w  #5,snake_len
        move.w  #8,apple_x
        move.w  #8,apple_y
        move.w  #0,frame_timer
        rts

InitVDP:
        move.w  #$8004,VDP_CTRL
        move.w  #$8174,VDP_CTRL
        move.w  #$8230,VDP_CTRL
        move.w  #$8407,VDP_CTRL
        move.w  #$857C,VDP_CTRL
        move.w  #$8700,VDP_CTRL
        move.w  #$8C81,VDP_CTRL
        move.w  #$8F02,VDP_CTRL
        rts

LoadTiles:
        move.l  #$40000000,d0
        move.l  d0,VDP_CTRL
        move.w  #0,d0
        move.w  #$7FFF,d1
.clear_vram:
        move.w  d0,VDP_DATA
        dbf     d1,.clear_vram

        ; tile 0 = blank
        ; tile 1 = circular snake body (8x8 circle)
        ; tile 2 = square apple
        ; tile 3 = wall / border
        move.l  #$40000000,d0
        move.l  d0,VDP_CTRL

        move.w  #$0000,d0
        move.w  #$0000,d1
        move.w  #$0000,d2
        move.w  #$0000,d3

        ; write 16 words for circle tile
        move.l  #$40000020,d0
        move.l  d0,VDP_CTRL
        move.w  #$0000,VDP_DATA
        move.w  #$0000,VDP_DATA
        move.w  #$0C00,VDP_DATA
        move.w  #$1E00,VDP_DATA
        move.w  #$3F00,VDP_DATA
        move.w  #$7F00,VDP_DATA
        move.w  #$7F00,VDP_DATA
        move.w  #$3F00,VDP_DATA
        move.w  #$1E00,VDP_DATA
        move.w  #$0C00,VDP_DATA
        move.w  #$0000,VDP_DATA
        move.w  #$0000,VDP_DATA
        move.w  #$0000,VDP_DATA
        move.w  #$0000,VDP_DATA
        move.w  #$0000,VDP_DATA
        move.w  #$0000,VDP_DATA

        move.l  #$40000040,d0
        move.l  d0,VDP_CTRL
        move.w  #$0000,VDP_DATA
        move.w  #$0000,VDP_DATA
        move.w  #$0000,VDP_DATA
        move.w  #$0F00,VDP_DATA
        move.w  #$0F00,VDP_DATA
        move.w  #$0F00,VDP_DATA
        move.w  #$0F00,VDP_DATA
        move.w  #$0F00,VDP_DATA
        move.w  #$0F00,VDP_DATA
        move.w  #$0F00,VDP_DATA
        move.w  #$0F00,VDP_DATA
        move.w  #$0F00,VDP_DATA
        move.w  #$0000,VDP_DATA
        move.w  #$0000,VDP_DATA
        move.w  #$0000,VDP_DATA
        move.w  #$0000,VDP_DATA

        move.l  #$40000060,d0
        move.l  d0,VDP_CTRL
        move.w  #$FFFF,VDP_DATA
        move.w  #$FFFF,VDP_DATA
        move.w  #$FFFF,VDP_DATA
        move.w  #$FFFF,VDP_DATA
        move.w  #$FFFF,VDP_DATA
        move.w  #$FFFF,VDP_DATA
        move.w  #$FFFF,VDP_DATA
        move.w  #$FFFF,VDP_DATA
        move.w  #$FFFF,VDP_DATA
        move.w  #$FFFF,VDP_DATA
        move.w  #$FFFF,VDP_DATA
        move.w  #$FFFF,VDP_DATA
        move.w  #$FFFF,VDP_DATA
        move.w  #$FFFF,VDP_DATA
        move.w  #$FFFF,VDP_DATA
        move.w  #$FFFF,VDP_DATA

        rts

ReadInput:
        move.b  PAD1_DATA,d0
        not.b   d0
        andi.b  #$0F,d0

        cmpi.b  #$00,d0
        beq.s   .no_change

        btst    #0,d0
        beq.s   .down
        cmpi.w  #2,snake_dir
        beq.s   .no_change
        move.w  #1,snake_dir
        bra.s   .no_change
.down:
        btst    #1,d0
        beq.s   .left
        cmpi.w  #1,snake_dir
        beq.s   .no_change
        move.w  #2,snake_dir
        bra.s   .no_change
.left:
        btst    #2,d0
        beq.s   .right
        cmpi.w  #4,snake_dir
        beq.s   .no_change
        move.w  #3,snake_dir
        bra.s   .no_change
.right:
        btst    #3,d0
        beq.s   .no_change
        cmpi.w  #3,snake_dir
        beq.s   .no_change
        move.w  #4,snake_dir
.no_change:
        rts

MoveSnake:
        move.w  snake_head,d0

        cmpi.w  #1,snake_dir
        bne.s   .move_down
        subq.w  #1,d0
        bra.s   .done_dir
.move_down:
        cmpi.w  #2,snake_dir
        bne.s   .move_left
        addq.w  #1,d0
        bra.s   .done_dir
.move_left:
        cmpi.w  #3,snake_dir
        bne.s   .move_right
        subq.w  #1,d0
        bra.s   .done_dir
.move_right:
        addq.w  #1,d0
.done_dir:

        cmpi.w  #0,d0
        blt.s   .dead
        cmpi.w  #255,d0
        bge.s   .dead

        move.w  d0,snake_head
        addq.w  #1,score
        rts
.dead:
        move.w  #1,game_over
        rts

DrawHud:
        move.l  #$40000000,d0
        move.l  d0,VDP_CTRL

        ; Top-left HUD area, start at plane A tile 1,1
        move.l  #$C0000000,d0
        move.l  d0,VDP_CTRL

        ; clear 20 tiles in top row + left bar
        move.w  #0,d1
        move.w  #0,d2
.hud_loop:
        move.w  #0,VDP_DATA
        addq.w  #1,d1
        cmpi.w  #20,d1
        bne.s   .hud_loop

        ; draw score value as basic digits in first row, left aligned
        move.l  #$C0000000,d0
        move.l  d0,VDP_CTRL
        move.w  #1,d1
        move.w  #1,d2
        move.w  #0,VDP_DATA
        move.w  #0,VDP_DATA
        move.w  #0,VDP_DATA
        move.w  #0,VDP_DATA
        move.w  #0,VDP_DATA
        rts

DrawBoard:
        move.l  #$40000000,d0
        move.l  d0,VDP_CTRL

        ; draw a simple 12x8 arena in the middle using circular snake tiles and square apple tiles
        ; snake head at tile 6,4, apples at tile 8,8
        move.l  #$C0000000,d0
        move.l  d0,VDP_CTRL

        ; blank arena tiles
        move.w  #0,d7
.clear_board:
        move.w  #0,VDP_DATA
        addq.w  #1,d7
        cmpi.w  #256,d7
        bne.s   .clear_board

        ; draw the snake as circular tiles
        move.l  #$C0000000,d0
        move.l  d0,VDP_CTRL
        move.w  #1,VDP_DATA
        move.w  #1,VDP_DATA
        move.w  #1,VDP_DATA
        move.w  #1,VDP_DATA

        ; draw apple as square tiles
        move.l  #$C0000000,d0
        move.l  d0,VDP_CTRL
        move.w  #2,VDP_DATA
        move.w  #2,VDP_DATA
        move.w  #2,VDP_DATA
        move.w  #2,VDP_DATA

        ; game over overlay
        tst.w   game_over
        beq.s   .done_board
        move.w  #$0000,VDP_DATA
        move.w  #$0000,VDP_DATA
        move.w  #$0000,VDP_DATA
        move.w  #$0000,VDP_DATA
.done_board:
        rts

Stop:
        bra.s   Stop


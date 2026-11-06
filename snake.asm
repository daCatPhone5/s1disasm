; ---------------------------------------------------------------------------
; Mega Drive Snake - standalone 68000 ROM
; Built with the AS assembler used by this repository.
; ---------------------------------------------------------------------------

        cpu 68000
        padding off

vdp_data        equ     $C00000
vdp_control     equ     $C00004
pad1_data       equ     $A10003
pad1_control    equ     $A10009

; 68000 exception vectors.
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

; Standard Mega Drive ROM header ($100-$1FF).
        org     $100
        dc.b    "SEGA MEGA DRIVE "
        dc.b    "(C)OPENAI 2026"
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

; Claim the TMSS security register when present.
        move.b  $A10001,d0
        andi.b  #$0F,d0
        beq.s   .no_tmss
        move.l  #'SEGA',$A14000
.no_tmss:

; Configure VDP: 40-column display, plane A at $C000, plane B at $E000,
; sprites at $F800, and a 64x32 plane map.
        move.w  #$8004,vdp_control
        move.w  #$8174,vdp_control
        move.w  #$8230,vdp_control
        move.w  #$8407,vdp_control
        move.w  #$857C,vdp_control
        move.w  #$8700,vdp_control
        move.w  #$8C81,vdp_control
        move.w  #$8F02,vdp_control

; Clear VRAM and install four solid-color tiles: empty, snake, food, wall.
        move.l  #$40000000,vdp_control
        move.w  #0,d0
        move.w  #$7FFF,d1
.clear_vram:
        move.w  d0,vdp_data
        dbf     d1,.clear_vram

        move.l  #$40000000,vdp_control
        moveq   #0,d2
        move.w  #31,d1
.tiles:
        move.w  d2,vdp_data
        dbf     d1,.tiles

        move.l  #$40000020,vdp_control
        move.w  #$1111,d2
        move.w  #15,d1
.tile_snake:
        move.w  d2,vdp_data
        dbf     d1,.tile_snake

        move.l  #$40000040,vdp_control
        move.w  #$2222,d2
        move.w  #15,d1
.tile_food:
        move.w  d2,vdp_data
        dbf     d1,.tile_food

        move.l  #$40000060,vdp_control
        move.w  #$3333,d2
        move.w  #15,d1
.tile_wall:
        move.w  d2,vdp_data
        dbf     d1,.tile_wall

; CRAM colors: black, bright green, yellow, dark blue.
        move.l  #$C0000000,vdp_control
        move.w  #$0000,vdp_data
        move.w  #$00E0,vdp_data
        move.w  #$0EE0,vdp_data
        move.w  #$000E,vdp_data

; Clear the visible plane A map (40x28 words).
        move.l  #$4000C000,vdp_control
        move.w  #0,d0
        move.w  #1119,d1
.clear_plane:
        move.w  d0,vdp_data
        dbf     d1,.clear_plane

; Initialize controller port and game state.
        move.b  #$40,pad1_control
        move.b  #$40,pad1_data
        bsr.w   NewGame
        move.w  #1,game_running
        move.w  #0,frame_counter
        move.w  #3,direction
        move.w  #330,snake_body
        move.w  #329,snake_body+2
        move.w  #328,snake_body+4
        move.w  #3,snake_length
        move.w  #350,food_position
        bsr.w   DrawBoard

; Main loop advances once every eight frames, using VBlank as the clock.
MainLoop:
        bsr.w   WaitVBlank
        bsr.w   ReadController
        tst.w   game_running
        beq.s   .restart_check
        addq.w  #1,frame_counter
        andi.w  #7,frame_counter
        bne.s   MainLoop
        bsr.w   MoveSnake
        bsr.w   DrawBoard
        bra.s   MainLoop
.restart_check:
        btst    #7,d0
        beq.s   MainLoop
        bsr.w   NewGame
        bra.s   MainLoop

; Set initial positions and draw a fresh game after Start.
NewGame:
        move.w  #330,snake_body
        move.w  #329,snake_body+2
        move.w  #328,snake_body+4
        move.w  #3,snake_length
        move.w  #3,direction
        move.w  #350,food_position
        move.w  #0,game_running
        move.w  #1,game_running
        rts

WaitVBlank:
.wait_on:
        move.w  vdp_control,d0
        btst    #3,d0
        beq.s   .wait_on
.wait_off:
        move.w  vdp_control,d0
        btst    #3,d0
        bne.s   .wait_off
        rts

; D-pad is visible with TH high. Input bits 0-3 map to up/down/left/right.
ReadController:
        move.b  pad1_data,d0
        not.b   d0
        andi.b  #$0F,d0
        btst    #0,d0
        beq.s   .down
        cmpi.w  #2,direction
        beq.s   .down
        move.w  #1,direction
        bra.s   .done
.down:
        btst    #1,d0
        beq.s   .left
        cmpi.w  #1,direction
        beq.s   .left
        move.w  #2,direction
        bra.s   .done
.left:
        btst    #2,d0
        beq.s   .right
        cmpi.w  #4,direction
        beq.s   .right
        move.w  #3,direction
        bra.s   .done
.right:
        btst    #3,d0
        beq.s   .done
        cmpi.w  #3,direction
        beq.s   .done
        move.w  #4,direction
.done:
        rts

; Move the body by shifting its cell indices. Grid is 32x20, row-major.
MoveSnake:
        move.w  snake_body,d2
        move.w  d2,d3
        cmpi.w  #1,direction
        bne.s   .try_down
        subi.w  #32,d3
        bra.s   .check_edge
.try_down:
        cmpi.w  #2,direction
        bne.s   .try_left
        addi.w  #32,d3
        bra.s   .check_edge
.try_left:
        cmpi.w  #3,direction
        bne.s   .go_right
        subq.w  #1,d3
        bra.s   .check_edge
.go_right:
        addq.w  #1,d3
.check_edge:
; Reject moves that wrap across a horizontal edge or leave the playfield.
        cmpi.w  #0,d3
        blt.s   .dead
        cmpi.w  #640,d3
        bge.s   .dead
        move.w  d2,d4
        andi.w  #31,d4
        move.w  d3,d5
        andi.w  #31,d5
        cmpi.w  #3,direction
        bne.s   .edge_right
        cmpi.w  #0,d4
        beq.s   .dead
        bra.s   .self_check
.edge_right:
        cmpi.w  #4,direction
        bne.s   .wall_check
        cmpi.w  #31,d4
        beq.s   .dead
.wall_check:
        move.w  d3,d4
        divu    #32,d4
        andi.w  #$FFFF,d4
        cmpi.w  #0,d4
        beq.s   .dead
        cmpi.w  #19,d4
        bge.s   .dead
.self_check:
; Food makes the snake grow; otherwise the last segment disappears.
        cmp.w   food_position,d3
        beq.s   .grow
        move.w  snake_length,d6
        subq.w  #1,d6
        bra.s   .shift
.grow:
        addq.w  #1,snake_length
        addq.w  #1,food_position
        cmpi.w  #608,food_position
        blo.s   .shift_grow
        move.w  #33,food_position
.shift_grow:
        move.w  snake_length,d6
        subq.w  #1,d6
.shift:
        lea     snake_body,a0
        move.w  d6,d1
        subq.w  #1,d1
        bmi.s   .put_head
.shift_loop:
        move.w  (a0,d1.w*2),2(a0,d1.w*2)
        subq.w  #1,d1
        bne.s   .shift_loop
.put_head:
        move.w  d3,(a0)
        rts
.dead:
        clr.w   game_running
        rts

; Render the 32x20 board into the center of plane A. Cells 0/1/2/3 are
; empty/snake/food/wall tiles. The tilemap is redrawn once per movement.
DrawBoard:
        moveq   #0,d7
.row_loop:
        moveq   #0,d6
.col_loop:
        moveq   #0,d3
        cmpi.w  #0,d7
        beq.s   .wall
        cmpi.w  #19,d7
        beq.s   .wall
        cmpi.w  #0,d6
        beq.s   .wall
        cmpi.w  #31,d6
        beq.s   .wall
        move.w  d7,d4
        mulu.w  #32,d4
        add.w   d6,d4
        cmp.w   food_position,d4
        beq.s   .food
        move.w  snake_length,d5
        subq.w  #1,d5
        lea     snake_body,a0
        moveq   #0,d1
.body_loop:
        cmp.w   (a0)+,d4
        beq.s   .snake
        addq.w  #1,d1
        dbf     d5,.body_loop
        bra.s   .draw_cell
.wall:
        moveq   #3,d3
        bra.s   .draw_cell
.food:
        moveq   #2,d3
        bra.s   .draw_cell
.snake:
        moveq   #1,d3
.draw_cell:
; Plane A base $C000; board starts at tile (4,4), plane width is 64.
        move.w  d7,d0
        addi.w  #4,d0
        lsl.w   #7,d0
        move.w  d6,d1
        addi.w  #4,d1
        add.w   d1,d1
        add.w   d1,d0
        addi.w  #$C000,d0
        move.l  d0,d1
        andi.l  #$3FFF,d1
        lsl.l   #16,d1
        move.l  d0,d2
        andi.l  #$C000,d2
        lsr.l   #14,d2
        or.l    d2,d1
        ori.l   #$40000000,d1
        move.l  d1,vdp_control
        move.w  d3,vdp_data
        addq.w  #1,d6
        cmpi.w  #32,d6
        blo.s   .col_loop
        addq.w  #1,d7
        cmpi.w  #20,d7
        blo.w   .row_loop
        rts

Stop:
        bra.s   Stop

; Game variables live in work RAM.
game_running    equ     $FFFF0000
frame_counter   equ     $FFFF0002
direction       equ     $FFFF0004
snake_length    equ     $FFFF0006
food_position   equ     $FFFF0008
snake_body      equ     $FFFF0010

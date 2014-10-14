; Ported from TIOS, original by Ahmed El-Helw
#include "kernel.inc"
#include "corelib.inc"
    .db "KEXC"
    .db KEXC_ENTRY_POINT
    .dw start
    .db KEXC_STACK_SIZE
    .dw 100
    .db KEXC_KERNEL_VER
    .db 0, 6
    .db KEXC_NAME
    .dw program_name
    .db KEXC_HEADER_END
program_name:
    .db "Periodic Table", 0
#include "shims.asm"
start:
    kld(de, corelib_path)
    pcall(loadLibrary)
    
    pcall(getLcdLock)
    pcall(getKeypadLock)

Restart:
    pcall(allocScreenBuffer)
    pcall(clearBuffer)

    xor a
    kld(hl, window_title)
    corelib(drawWindow)

    kcall(DrawTable);Draw out the Periodic Table Wireframe
    kjp(Selector)    ;Draw out the selector for the first time

KeyLoop:            ;The KeyLoop Starts here
    pcall(flushKeys)
    corelib(appWaitKey)
    cp kClear
    ret z
    cp kMODE
    ret z
    cp kLeft
    jr z, MoveLeft
    cp kRight
    jr z, MoveRight
    cp kEnter
    kjp(z, ElemInfo)
    cp kQuestion
    kjp(z, HelpScreen)
    jr KeyLoop        ;Reloop.

MoveLeft:            ;Similarly to the other routines,
    kld(a,(selectx))        ;this checks the uncrossable boundries
    cp 4            ;and if there is a boundry that shouldn't
    kjp(z,PrevRow)        ;be crossed, it doesn't draw it, else,
    cp 19            ;moves to the left.
    kjp(z,ContLeftC)
ContLeftMan:
    kld(a,(selectx))
    cp 89             
    kjp(z,SelectHyd)
    cp 19
    kjp(z,ContLCheck)
    cp 64
    kjp(z,CheckLeft)
ContLeft:
    kcall(RemSel)
    kld(a,(selectx))
    sub 5
    kld((selectx),a)
    kld(hl,current)
    dec (hl)
    kjp(Selector)

MoveRight:            ;Pretty similar to the other routines.
    kld(a,(selectx))        ;Checks boundries, draws in the right
    cp 89            ;location the right box.
    kjp(z,NextRow)
    cp 84
    kjp(z,LastRow)
ContRC:
    kld(a,(selectx))
    cp 4 
    kjp(z,SelectHel)
    cp 9
    kjp(z,CheckRight)
    cp 54
    kjp(z,ContRightC)
    cp 84
    kjp(z,ContRC2)
ContRight:
    kcall(RemSel)
    kld(a,(selectx))
    add a,5
    kld((selectx),a)
    kld(hl,current)
    inc (hl)
    kjp(Selector)

SelectHyd:
    kld(a,(selecty))
    cp 61
    kjp(nz,ContLeft)
    kcall(RemSel)
    ld a,4
    kld((selectx),a)
    kld(hl,current)
    dec (hl)
    kjp(Selector)

SelectHel:
    kld(a,(selecty))
    cp 61
    kjp(nz,ContRight)
    kcall(RemSel)
    ld a,89
    kld((selectx),a)
    kld(hl,current)
    inc (hl)
    kjp(Selector)

CheckRight:
    kld(a,(selecty))
    cp 48
    kjp(c,ContRChk)
    kcall(RemSel)
    ld a,64
    kld((selectx),a)
    kld(hl,current)
    inc (hl)
    kjp(Selector)
ContRChk:
    cp 41
    kjp(nc,ContRight)
    cp 36
    kjp(z,ContRight)
    kcall(RemSel)
    ld a,19
    kld((selectx),a)
    kld(hl,current)
    inc (hl)
    kjp(Selector)

ContLCheck:
    kld(a,(selecty))
    cp 31
    kjp(nz,ContLeft)
    kcall(RemSel)
    ld a,9
    kld((selectx),a)
    kld(hl,current)
    dec (hl)
    kjp(Selector)

CheckLeft:
    kld(a,(selecty))
    cp 48
    kjp(c,ContLeft)
    kcall(RemSel)
    ld a,9
    kld((selectx),a)
    kld(hl,current)
    dec (hl)

Selector:            ;Draws a 4x4 black box at coordinates selectx/selecty
    kcall(DrawSel)        ;Call the XOR routine
    kcall(DispData)        ;Display the Data!
    pcall(fastCopy)    ;Copy it
    kjp(KeyLoop)        ;Goto the loop

ContLeftC:
    kld(a,(selecty))
    cp 30
    kjp(c,MoveLBot)
    kjp(ContLeftMan)

MoveLBot:
    cp 19
    kjp(z,RetHistory)
    cp 14
    kjp(nz,KeyLoop)
    kcall(RemSel)
    ld a,19
    kld((selecty),a)
    ld a,84
    kld((selectx),a)
    kld(hl,current)
    dec (hl)
    kjp(Selector)

RetHistory:
    kcall(RemSel)
    ld a,31
    kld((selecty),a)
    ld a,54
    kld((selectx),a)
    kld(hl,current)
    dec (hl)
    kjp(Selector)

ContRightC:
    kld(a,(selecty))
    cp 31
    kjp(nz,ContRight)
    kcall(RemSel)
    kld(a,(selecty))
    sub 12
    kld((selecty),a)
    ld a,19
    kld((selectx),a)
    kld(hl,current)
    inc (hl)
    kjp(Selector)

ContRC2:
    kld(a,(selecty))
    cp 30
    kjp(c,KeyLoop)
    kjp(ContRight)

NextRow:
    kcall(RemSel)
    kld(a,(selecty))
    sub 5
    kld((selecty),a)
    ld a,4
    kld((selectx),a)
    kld(hl,current)
    inc (hl)
    kjp(Selector)

LastRow:
    kld(a,(selecty))
    cp 19
    kjp(nz,ContRC)
    kcall(RemSel)
    ld a,19
    kld((selectx),a)
    kld(a,(selecty))
    sub 5
    kld((selecty),a)
    kld(hl,current)
    inc (hl)
    kjp(Selector)

PrevRow:
    kld(a,(selecty))
    cp 61
    kjp(z,KeyLoop)
    kcall(RemSel)
    kld(a,(selecty))
    add a,5
    kld((selecty),a)
    ld a,89
    kld((selectx),a)
    kld(hl,current)
    dec (hl)
    kjp(Selector)

.equ table_x 2
.equ table_y 17

RemSel:                ;If we only want to remove it, then save time by not copying the
DrawSel:            ;grbuf and by returning rather than going to the KeyLoop.
    kld(a,(selectx))
    ld b,a            ;X-Position should go into b
    kld(a,(selecty))
    ld c,a            ;Y-Position should go into c
    kcall(VertLoop)        ;Draw 3 pixels
    dec c            ;Goto next line, this is decrease because 
    kcall(VertLoop)        ;Ti's _IPoint Y-Coordinates are flipped.
    dec c            ;Same with _ILine.  This VertLoop is gone
VertLoop:        ;Displays 4 pixels vertically
    kld(a,(selectx))
    ld b,a            ;Reset the X-Coordinate
    ld a,3            ;Loop 4 times, using a
Loop:
    kcall(_IPoint)        ;Draw the point ; TODO: Shim this
    inc b            ;Increase the X
    dec a            ;Decrease A
    jr nz,Loop        ;If its not 0, then reloop.
    ret

; Draws out the wireframe of the periodic table.
; This was not very easy to do, as you can imagine :P
DrawTable:
.equ lower_x 0 + table_x
.equ lower_y 0 + table_y
.equ upper_x 0 + table_x
.equ upper_y 10 + table_y
.macro line(x1, y1, x2, y2)
    ld bc, (x1 + upper_x) * 256 + (y1 + upper_y)
    ld de, (x2 + upper_x) * 256 + (y2 + upper_y)
    kcall(_ILine)
.endmacro
.macro looplines(x1, y1, x2, y2, rep)
    ld bc, (x1 + upper_x) * 256 + (y1 + upper_y)
    ld de, (x2 + upper_x) * 256 + (y2 + upper_y)
    ld a, rep
    kcall(LineLooper)
.endmacro
.macro lower_line(x1, y1, x2, y2)
    ld bc, (x1 + lower_x) * 256 + (y1 + lower_y)
    ld de, (x2 + lower_x) * 256 + (y2 + lower_y)
    kcall(_ILine)
.endmacro
.macro lower_looplines(x1, y1, x2, y2, rep)
    ld bc, (x1 + lower_x) * 256 + (y1 + lower_y)
    ld de, (x2 + lower_x) * 256 + (y2 + lower_y)
    ld a, rep
    kcall(LineLooper)
.endmacro

    ; Upper section, horizontal
    line(0, 29, 4, 29)   ; Upper left, top to bottom (staggered)
    line(68, 29, 72, 29) ; Upper right, bottom to top (staggered)
    line(0, 25, 8, 25)
    line(48, 25, 72, 25)
    line(0, 21, 8, 21)
    line(48, 21, 72, 21)

    line(0, 17, 72, 17)
    line(0, 13, 72, 13)
    line(0, 9, 72, 9)
    line(0, 5, 72, 5)
    line(12, 1, 44, 1) ; Main group, top to bottom

    line(0, 1, 8, 1) ; Bottom left, one-shot

    ; Upper section, vertical
    line(0, 29, 0, 1) ; Left to right
    line(4, 29, 4, 1)
    line(8, 24, 8, 1)
    looplines(8, 17, 8, 5, 16)
    looplines(8, 4, 8, 1, 9)
    line(48, 24, 48, 5)
    line(52, 24, 52, 5)
    line(56, 24, 56, 5)
    line(60, 24, 60, 5)
    line(64, 24, 64, 5)
    line(68, 29, 68, 5)
    line(72, 29, 72, 5)

    ; Lower section, horizontal
    lower_line(1, 1, 56, 1) ; Bottom to top
    lower_line(1, 5, 56, 5)
    lower_line(1, 9, 56, 9)

    ; Lower section, vertical
    lower_looplines(-4, 9, -4, 1, 15) ; Left to right
    ret

LineLooper:
    inc b \ inc b \ inc b \ inc b
    inc d \ inc d \ inc d \ inc d
    kcall(_ILine)
    dec a
    jr nz,LineLooper
    ret

DispData:
    ld bc, 6*256+50
    ld e, 2
    ld l, 50
    pcall(rectAND)
    kld(a,(current))
    dec a
    kld(hl,Elements)
    kcall(getString)
    ld de,2*256+50
    pcall(drawStr)

    ; Draw box
    ld bc, 21*256+21
    ld e, 73
    ld l, 34
    pcall(rectOR)
    ld bc, 19*256+19
    ld e, 74
    ld l, 35
    pcall(rectAND)
    kld(a, (current))
    ld de, 75*256+36
    pcall(drawDecA)
    kld(a, (current))
    dec a
    kld(hl, Symbols)
    kcall(getString)
    inc hl
    ld a, (hl)
    dec hl
    or a
    jr z, _
    ld de, 81*256+42
    jr ++_
_:  ld de, 82*256+42
_:  pcall(drawStr)
    kld(a, (current))
    dec a
    kld(hl, massNo)
    kcall(getString)
    ld de, 75*256+48
    pcall(drawStr)
    ret

ElemInfo:
    kcall(Clear)
    ; TODO: Fix this, too
    kld(hl,ElemText)
    ld de, 0
    pcall(drawStr)

    ld bc,11*256+55
    ld de,83*256+55
    kcall(_ILine)

    ld b, 1
    ld de,1*256+14
    kld(hl,Data)
    pcall(drawStr)
    pcall(newline)
    kld(hl,Data_2)
    pcall(drawStr)

    ld b, 45
    ld de,45*256+14
    kld(a,(current))
    dec a
    kld(hl,Elements)
    kcall(getString)
    pcall(drawStr)

    kld(a,(current))
    dec a
    pcall(newline)
    kld(hl,Symbols)
    kcall(getString)
    pcall(drawStr)

    kld(a,(current))
    dec a
    pcall(newline)
    kld(hl,AtomicNo)
    kcall(getString)
    pcall(drawStr)

    kld(a,(current))
    dec a
    pcall(newline)
    kld(hl,MassNo)
    kcall(getString)
    pcall(drawStr)

    pcall(fastCopy)
    pcall(flushKeys)
    pcall(waitKey)
RetStart:
    kcall(Clear)
    kjp(Restart)

Clear: ; TODO: This is useless, refactor it out
    pcall(clearBuffer)
    ret

HelpScreen:
    kcall(Clear)
    ; TODO: Probably rewriting this, too
    ld hl,HelpText
    ;bcall(_puts)

    ld bc,5*256+55
    ld de,89*256+55
    kcall(_ILine)

    pcall(waitKey)
    kcall(Clear)
    kjp(Restart)

;---------= Point hl to string a =---------;
; by: Joe Wingerbermuhle                   ;
; Thanks, this is a lot easier than my     ;
; method of multiplying string # * 12      ;
;                                          ;
; Input: a=string number (0 to 255)        ;
;     hl->string data                   ;
; Output: hl->string                       ;
;------------------------------------------;

getString:
    or a
    ret z
    ld b,a
    xor a
getStringL1:
    push bc
    ld c,-1
    cpir 
    pop bc
    djnz getStringL1
    ret

fvputs:
    kld((pencol),de)
    kcall(_vputs)
    ret

;---------------------------------------;
;            Data Begins Here           ;
;---------------------------------------;

selectx:
    .db 3 ; Initial X position
selecty:
    .db 55 ; Initial Y position (inverted)
current:
    .db 1 ; First element

#include "constants.asm"

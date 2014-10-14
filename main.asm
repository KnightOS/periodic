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

    pcall(allocScreenBuffer)

main_loop:
    kcall(draw_ui)
.key_loop:
    pcall(flushKeys)
    corelib(appWaitKey)
    kcall(nz, draw_ui)
    cp kMODE
    ret z
    cp kLeft
    jr z, .left
    cp kRight
    jr z, .right
    cp kDown
    jr z, .down
    cp kUp
    jr z, .up
    jr .key_loop

.left:
    kld(a, (current))
    dec a
    jr z, main_loop
    kld((current), a)
    jr main_loop

.right:
    kld(a, (current))
    inc a
    cp (cursorPos_end - cursorPos) / 2 + 1
    jr z, main_loop
    kld((current), a)
    jr main_loop

.down:
    ; Searches the cursor list for the next one with the same X value
    kld(a, (current))
    dec a
    kld(hl, CursorPos)
    ld d, a ; New "current" value
    push af
        add a, a
        add a, l \ ld l, a \ jr nc, $+3 \ inc h
        ld b, (hl) ; Current X position
        inc hl \ inc hl
.down_loop:
        inc d
        ld a, (hl)
        or a
        jr z, .down_restore
        cp b
        ld a, d
        jr z, .down_save
        inc hl \ inc hl
        jr .down_loop
.down_restore:
    pop af
    inc a
    kld((current), a)
    jr main_loop
.down_save:
    inc sp \ inc sp
    inc a
    kld((current), a)
    jr main_loop

.up:
    ; Searches the cursor list for the next one with the same X value
    kld(a, (current))
    dec a
    kld(hl, CursorPos)
    ld d, a ; New "current" value
    push af
        add a, a
        add a, l \ ld l, a \ jr nc, $+3 \ inc h
        ld b, (hl) ; Current X position
        dec hl \ dec hl
.up_loop:
        dec d
        ld a, (hl)
        or a
        jr z, .up_restore
        cp b
        ld a, d
        jr z, .up_save
        dec hl \ dec hl
        jr .up_loop
.up_restore:
    pop af
    inc a
    kld((current), a)
    kjp(main_loop)
.up_save:
    inc sp \ inc sp
    inc a
    kld((current), a)
    kjp(main_loop)

draw_ui:
    pcall(clearBuffer)
    xor a
    kld(hl, window_title)
    corelib(drawWindow)
    kcall(draw_table)
    kcall(draw_element_info)
    kcall(xor_selector)
    pcall(fastCopy)
    ret

.equ table_x 2
.equ table_y 17
xor_selector:
    push hl
        kld(a, (current)) \ dec a
        kld(hl, CursorPos)
        add a, a \ add a, l \ ld l, a
        jr nc, $+3 \ inc h
        ld b, (hl) \ inc hl \ ld c, (hl)
        ld a, b
        kld((.vertical_loop + 1), a) ; SMC
    pop hl
    kcall(.vertical_loop)
    dec c
    kcall(.vertical_loop)
    dec c
; Displays 4 pixels vertically
.vertical_loop:
    ld a, 0 ; SMC
    ld b, a
    ld a, 3
.loop:
    kcall(_IPoint)
    inc b
    dec a
    jr nz, .loop
    ret

; Draws out the wireframe of the periodic table.
; This was not very easy to do, as you can imagine :P
draw_table:
.equ lower_x 0 + table_x
.equ lower_y -1 + table_y
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
    kcall(draw_lines)
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
    kcall(draw_lines)
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
    lower_line(1, 1, 60, 1) ; Bottom to top
    lower_line(1, 5, 60, 5)
    lower_line(1, 9, 60, 9)

    ; Lower section, vertical
    lower_looplines(-4, 9, -4, 1, 16) ; Left to right

    ld d, 12
    ld e, 32
    ld h, 12
    ld l, 39
    pcall(drawLine) ; Connect the upper and lower tables
    ret

draw_lines:
    inc b \ inc b \ inc b \ inc b
    inc d \ inc d \ inc d \ inc d
    kcall(_ILine)
    dec a
    jr nz, draw_lines
    ret

draw_element_info:
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
    dec a
    ld de, 75*256+36
    kld(hl, AtomicNo)
    kcall(getString)
    pcall(drawStr)
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

current:
    .db 1 ; First element

#include "constants.asm"

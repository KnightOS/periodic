_ILine:
    ; Cannot destroy anything
    push hl
    push de
    push bc
    push af
        ld h, d \ ld l, e ; X2, Y2
        ld d, b \ ld e, c ; X1, Y1
        ; Apparently ILine is "backwards" on TIOS
        ; So we'll invert the Y coords
        ld a, e \ sub a, 32 \ neg \ add a, 32 \ ld e, a
        ld a, l \ sub a, 32 \ neg \ add a, 32 \ ld l, a
        pcall(drawLine)
    pop af
    pop bc
    pop de
    pop hl
    ret

_IPoint:
    ; Cannot destroy anything
    push af
    push hl
        ld l, c ; Y
        ; Invert Y coordinate
        ld a, l \ sub a, 32 \ neg \ add a, 32 \ ld l, a
        ld a, b ; X
        pcall(invertPixel)
    pop hl
    pop af
    ret

_vputmap:
    ; Safe to destroy DE, AF, IX
    kld(de, (pencol))
    pcall(drawChar)
    ret

_vputs:
    ; Must advance HL to end of string
    push de
    push bc
    kld(de, (pencol))
    ld b, d \ ld d, e \ ld e, d ; Reverse row/col to become x/y
    pcall(drawStr)
    ld b, d \ ld d, e \ ld e, d ; Reverse row/col to become x/y
    kld((pencol), de)
    pop bc
    pop de
    ret

pencol:
    .db 0
penrow:
    .db 0

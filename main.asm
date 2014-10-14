; Ported from TIOS, original by Ahmed El-Helw
#include "kernel.inc"
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

; Shims
_ILine:
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

start:
	ld a,4			;Set up some coordinates for the box
	kld((selectx),a)		;and for _IPoint routine.  Note that
	ld a,61			;the Y-Coordinates are actually flipped
	kld((selecty),a)		;due to Ti's _IPoint requirements.
	ld a,1
	kld((current),a)

	pcall(getLcdLock)
	pcall(getKeypadLock)

Restart:
	pcall(allocScreenBuffer)
	pcall(clearBuffer)

	kcall(DrawTable);Draw out the Periodic Table Wireframe
	kjp(Selector)	;Draw out the selector for the first time

KeyLoop:			;The KeyLoop Starts here
	pcall(flushKeys)
	pcall(waitKey)
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
	jr KeyLoop		;Reloop.

MoveLeft:			;Similarly to the other routines,
	kld(a,(selectx))		;this checks the uncrossable boundries
	cp 4			;and if there is a boundry that shouldn't
	kjp(z,PrevRow)		;be crossed, it doesn't draw it, else,
	cp 19			;moves to the left.
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

MoveRight:			;Pretty similar to the other routines.
	kld(a,(selectx))		;Checks boundries, draws in the right
	cp 89			;location the right box.
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

Selector:			;Draws a 4x4 black box at coordinates selectx/selecty
	kcall(DrawSel)		;Call the XOR routine
	ld bc,63*256+57
	ld de,63*256+33
	kcall(_ILine) ; TODO: Shim this
	kcall(DispData)		;Display the Data!
	pcall(fastCopy)	;Copy it
	kjp(KeyLoop)		;Goto the loop

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

RemSel:				;If we only want to remove it, then save time by not copying the
DrawSel:			;grbuf and by returning rather than going to the KeyLoop.
	kld(a,(selectx))
	ld b,a			;X-Position should go into b
	kld(a,(selecty))
	ld c,a			;Y-Position should go into c
	kcall(VertLoop)		;Draw 3 pixels
	dec c			;Goto next line, this is decrease because 
	kcall(VertLoop)		;Ti's _IPoint Y-Coordinates are flipped.
	dec c			;Same with _ILine.  This VertLoop is gone
	kcall(VertLoop)		;through four times to achieve 4 lines.
	dec c
VertLoop:		;Displays 4 pixels vertically
	kld(a,(selectx))
	ld b,a			;Reset the X-Coordinate
	ld a,4			;Loop 4 times, using a
Loop:
	kcall(_IPoint)		;Draw the point ; TODO: Shim this
	inc b			;Increase the X
	dec a			;Decrease A
	jr nz,Loop		;If its not 0, then reloop.
	ret

DrawTable:		;Draws out the wireframe of the periodic table.
			;This was not very easy to do, as you can imagine :P
	ld bc,3*256+47
	ld de,93*256+47
	kcall(_ILine)
	ld bc,3*256+42
	ld de,93*256+42
	kcall(_ILine)
	ld bc,3*256+37
	ld de,93*256+37
	kcall(_ILine)
	ld bc,3*256+32
	ld de,93*256+32
	kcall(_ILine)
	ld bc,18*256+27
	ld de,58*256+27
	kcall(_ILine)
	ld bc,63*256+52
	ld de,93*256+52
	kcall(_ILine)
	ld bc,63*256+57
	ld de,93*256+57
	kcall(_ILine)
	ld bc,88*256+62
	ld de,93*256+62
	kcall(_ILine)
	ld bc,3*256+57
	ld de,13*256+57
	kcall(_ILine)
	ld bc,3*256+52
	ld de,13*256+52
	kcall(_ILine)
	ld bc,18*256+10
	ld de,87*256+10
	kcall(_ILine)
	ld bc,18*256+15
	ld de,87*256+15
	kcall(_ILine)
	ld bc,18*256+20
	ld de,87*256+20
	kcall(_ILine)
	ld bc,3*256+62
	ld de,7*256+62
	kcall(_ILine)
	ld bc,3*256+47
	ld de,13*256+47
	kcall(_ILine)
	ld bc,3*256+42
	ld de,13*256+42
	kcall(_ILine)
	ld bc,3*256+37
	ld de,13*256+37
	kcall(_ILine)
	ld bc,3*256+27
	ld de,13*256+27
	kcall(_ILine)
	ld bc,3*256+62
	ld de,3*256+28
	kcall(_ILine)
	ld bc,93*256+62
	ld de,93*256+38
	kcall(_ILine)
	ld bc,8*256+62
	ld de,8*256+28
	kcall(_ILine)
	ld bc,13*256+57
	ld de,13*256+28
	kcall(_ILine)
	ld bc,88*256+62
	ld de,88*256+33
	kcall(_ILine)
	ld bc,83*256+57
	ld de,83*256+33
	kcall(_ILine)
	ld bc,78*256+57
	ld de,78*256+33
	kcall(_ILine)
	ld bc,73*256+57
	ld de,73*256+33
	kcall(_ILine)
	ld bc,68*256+57
	ld de,68*256+33
	kcall(_ILine)
	ld bc,63*256+57
	ld de,63*256+33
	kcall(_ILine)

	ld bc,13*256+47
	ld de,13*256+33
	ld a,16
	kcall(LineLooper)

	ld bc,13*256+38
	ld de,13*256+33
	ld a,10
	kcall(LineLooper)

	ld bc,13*256+33
	ld de,13*256+28
	ld a,9
	kcall(LineLooper)

	ld bc,13*256+20
	ld de,13*256+10
	ld a,15
LineLooper:
	inc b \ inc b \ inc b \ inc b \ inc b
	inc d \ inc d \ inc d \ inc d \ inc d
	kcall(_ILine)
	dec a
	jr nz,LineLooper
	ret

DispData:
	; TODO: This probably just needs to be rewritten
;--------------
	ld hl,6*256+15
	;kld((pencol),hl) ; bcall (for grep)
	ld b,48
DispBlank:			;This code clears the spots
	ld a,' '		;at which we want to write on.
	;bcall(_vputmap)
	djnz DispBlank
;--------------
	ld de,0*256+15
	kld(hl,Data)
	kcall(fvputs)
	kld(a,(current))
	dec a
	ld hl,Elements
	kcall(getString)
	ld de,6*256+15
	kcall(fvputs)

	ld de,34*256+61
	kld(hl,HelpStr)
	kcall(fvputs)
	ret

ElemInfo:
	kcall(Clear)
	; TODO: Fix this, too
	kld(hl,ElemText)
	;bcall(_puts)

	ld bc,11*256+55
	ld de,83*256+55
	kcall(_ILine)

	ld de,14*256+1
	ld hl,Data
	kcall(fvputs)
	ld de,21*256+1
	kcall(fvputs)
	ld de,28*256+1
	kcall(fvputs)
	ld de,35*256+1
	kcall(fvputs)

	kld(a,(current))
	dec a
	ld de,14*256+45
	kld(hl,Elements)
	kcall(getString)
	kcall(fvputs)

	kld(a,(current))
	dec a
	ld de,21*256+45
	kld(hl,Symbols)
	kcall(getString)
	kcall(fvputs)

	kld(a,(current))
	dec a
	ld de,28*256+45
	kld(hl,AtomicNo)
	kcall(getString)
	kcall(fvputs)

	kld(a,(current))
	dec a
	ld de,35*256+45
	kld(hl,MassNo)
	kcall(getString)
	kcall(fvputs)

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
;	 hl->string data                   ;
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
	; TODO: Shim this or something
	;ld (pencol),de
	;bcall(_vputs)
	ret

;---------------------------------------;
;            Data Begins Here           ;
;---------------------------------------;

selectx:
	.db 0
selecty:
	.db 0
current:
	.db 0

ElemText:
	.db	"  Element Info  ",0
Data:
	.db	"Element:",0
	.db	"Symbol:",0
	.db	"Atomic ",$23,":",0
	.db	"Atomic Mass:",0
HelpStr:
	.db	"Mode: Help",0

HelpText:
	.db	" Periodic Table ",
	.db	"                ",
	.db	"Arrows   -  Move",
	.db	"Enter    -  Info",
	.db	"Mode     -  Help",
	.db	"Clear    -  Quit",0

Elements:
	.db	"Hydrogen",0
	.db	"Helium",0
	.db	"Lithium",0
	.db	"Beryllium",0
	.db	"Boron",0
	.db	"Carbon",0
	.db	"Nitrogen",0
	.db	"Oxygen",0
	.db	"Fluorine",0
	.db	"Neon",0
	.db	"Sodium",0
	.db	"Magnesium",0
	.db	"Aluminum",0
	.db	"Silicon",0
	.db	"Phosphorus",0
	.db	"Sulfur",0
	.db	"Chlorine",0
	.db	"Argon",0
	.db	"Potassium",0
	.db	"Calcium",0
	.db	"Scandium",0
	.db	"Titanium",0
	.db	"Vandium",0
	.db	"Chromium",0
	.db	"Manganese",0
	.db	"Iron",0
	.db	"Cobalt",0
	.db	"Nickel",0
	.db	"Copper",0
	.db	"Zinc",0
	.db	"Gallium",0
	.db	"Germanium",0
	.db	"Arsenic",0
	.db	"Selenium",0
	.db	"Bromine",0
	.db	"Krypton",0
	.db	"Rubidium",0
	.db	"Strontium",0
	.db	"Yttrium",0
	.db	"Zirconium",0
	.db	"Niobium",0
	.db	"Molybdenum",0
	.db	"Technetium",0
	.db	"Ruthenium",0
	.db	"Rhodium",0
	.db	"Palladium",0
	.db	"Silver",0
	.db	"Cadmium",0
	.db	"Indium",0
	.db	"Tin",0
	.db	"Antimony",0
	.db	"Tellurium",0
	.db	"Iodine",0
	.db	"Xenon",0
	.db	"Cesium",0
	.db	"Barium",0
	.db	"Lanthanum",0
	.db	"Hafnium",0
	.db	"Tantalum",0
	.db	"Tungsten",0
	.db	"Rhenium",0
	.db	"Osmium",0
	.db	"Iridum",0
	.db	"Platinum",0
	.db	"Gold",0
	.db	"Mercury",0
	.db	"Thallium",0
	.db	"Lead",0
	.db	"Bismuth",0
	.db	"Polonium",0
	.db	"Astatine",0
	.db	"Radon",0
	.db	"Francium",0
	.db	"Radium",0
	.db	"Actinum",0
	.db	"Unnilquadium",0
	.db	"Unnilpentium",0
	.db	"Unnihexium",0
	.db	"Unnilseptium",0
	.db	"Unniloctium",0
	.db	"Unnilennium",0
	.db	"Ununnilium",0
	.db	"Cerium",0
	.db	"Praseodymium",0
	.db	"Neodymium",0
	.db	"Promethium",0
	.db	"Samarium",0
	.db	"Europium",0
	.db	"Gadolinium",0
	.db	"Terbium",0
	.db	"Dysprosium",0
	.db	"Homium",0
	.db	"Erbium",0
	.db	"Thulium",0
	.db	"Ytterbium",0
	.db	"Lutetium",0
	.db	"Thorium",0
	.db	"Protactinium",0
	.db	"Uranium",0
	.db	"Neptunium",0
	.db	"Plutonium",0
	.db	"Americium",0
	.db	"Curium",0
	.db	"Berkelium",0
	.db	"Californium",0
	.db	"Einsteinium",0
	.db	"Fermium",0
	.db	"Mendelevium",0
	.db	"Nobelium",0
	.db	"Lawrencium",0

AtomicNo:
	.db "1",0
	.db "2",0
	.db "3",0
	.db "4",0
	.db "5",0
	.db "6",0
	.db "7",0
	.db "8",0
	.db "9",0
	.db "10",0
	.db "11",0
	.db "12",0
	.db "13",0
	.db "14",0
	.db "15",0
	.db "16",0
	.db "17",0
	.db "18",0
	.db "19",0
	.db "20",0
	.db "21",0
	.db "22",0
	.db "23",0
	.db "24",0
	.db "25",0
	.db "26",0
	.db "27",0
	.db "28",0
	.db "29",0
	.db "30",0
	.db "31",0
	.db "32",0
	.db "33",0
	.db "34",0
	.db "35",0
	.db "36",0
	.db "37",0
	.db "38",0
	.db "39",0
	.db "40",0
	.db "41",0
	.db "42",0
	.db "43",0
	.db "44",0
	.db "45",0
	.db "46",0
	.db "47",0
	.db "48",0
	.db "49",0
	.db "50",0
	.db "51",0
	.db "52",0
	.db "53",0
	.db "54",0
	.db "55",0
	.db "56",0
	.db "57",0
	.db "72",0
	.db "73",0
	.db "74",0
	.db "75",0
	.db "76",0
	.db "77",0
	.db "78",0
	.db "79",0
	.db "80",0
	.db "81",0
	.db "82",0
	.db "83",0
	.db "84",0
	.db "85",0
	.db "86",0
	.db "87",0
	.db "88",0
	.db "89",0
	.db "104",0
	.db "105",0
	.db "106",0
	.db "107",0
	.db "108",0
	.db "109",0
	.db "110",0
	.db "58",0
	.db "59",0
	.db "60",0
	.db "61",0
	.db "62",0
	.db "63",0
	.db "64",0
	.db "65",0
	.db "66",0
	.db "67",0
	.db "68",0
	.db "69",0
	.db "70",0
	.db "71",0
	.db "90",0
	.db "91",0
	.db "92",0
	.db "93",0
	.db "94",0
	.db "95",0
	.db "96",0
	.db "97",0
	.db "98",0
	.db "99",0
	.db "100",0
	.db "101",0
	.db "102",0
	.db "103",0
	
Symbols:
	.db "H",0
	.db "He",0
	.db "Li",0
	.db "Be",0
	.db "B",0
	.db "C",0
	.db "N",0
	.db "O",0
	.db "F",0
	.db "Ne",0
	.db "Na",0
	.db "Mg",0
	.db "Al",0
	.db "Si",0
	.db "P",0
	.db "S",0
	.db "Cl",0
	.db "Ar",0
	.db "K",0
	.db "Ca",0
	.db "Sc",0
	.db "Ti",0
	.db "V",0
	.db "Cr",0
	.db "Mn",0
	.db "Fe",0
	.db "Co",0
	.db "Ni",0
	.db "Cu",0
	.db "Zn",0
	.db "Ga",0
	.db "Ge",0
	.db "As",0
	.db "Se",0
	.db "Br",0
	.db "Kr",0
	.db "Rb",0
	.db "Sr",0
	.db "Y",0
	.db "Zr",0
	.db "Nb",0
	.db "Mo",0
	.db "Tc",0
	.db "Ru",0
	.db "Rh",0
	.db "Pd",0
	.db "Ag",0
	.db "Cd",0
	.db "In",0
	.db "Sn",0
	.db "Sb",0
	.db "Te",0
	.db "I",0
	.db "Xe",0
	.db "Cs",0
	.db "Ba",0
	.db "La",0
	.db "Hf",0
	.db "Ta",0
	.db "W",0
	.db "Re",0
	.db "Os",0
	.db "Ir",0
	.db "Pt",0
	.db "Au",0
	.db "Hg",0
	.db "Tl",0
	.db "Pb",0
	.db "Bi",0
	.db "Po",0
	.db "At",0
	.db "Rn",0
	.db "Fr",0
	.db "Ra",0
	.db "Ac",0
	.db "Unq",0
	.db "Unp",0
	.db "Unh",0
	.db "Uns",0
	.db "Uno",0
	.db "Une",0
	.db "Uun",0
	.db "Ce",0
	.db "Pr",0
	.db "Nd",0
	.db "Pm",0
	.db "Sm",0
	.db "Eu",0
	.db "Gd",0
	.db "Tb",0
	.db "Dy",0
	.db "Ho",0
	.db "Er",0
	.db "Tm",0
	.db "Yb",0
	.db "Lu",0
	.db "Th",0
	.db "Pa",0
	.db "U",0
	.db "Np",0
	.db "Pu",0
	.db "Am",0
	.db "Cm",0
	.db "Bk",0
	.db "Cf",0
	.db "Es",0
	.db "Fm",0
	.db "Md",0
	.db "No",0
	.db "Lr",0

MassNo:
	.db "1.0079",0
	.db "4.003",0
	.db "6.941",0
	.db "9.012",0
	.db "10.811",0
	.db "12.011",0
	.db "14.007",0
	.db "15.999",0
	.db "18.998",0
	.db "20.180",0
	.db "22.990",0
	.db "24.305",0
	.db "26.982",0
	.db "28.086",0
	.db "30.974",0
	.db "32.066",0
	.db "35.453",0
	.db "39.948",0
	.db "39.098",0
	.db "40.08",0
	.db "44.956",0
	.db "47.88",0
	.db "50.942",0
	.db "51.996",0
	.db "54.938",0
	.db "55.847",0
	.db "58.933",0
	.db "58.69",0
	.db "63.546",0
	.db "65.39",0
	.db "69.723",0
	.db "72.61",0
	.db "74.922",0
	.db "78.96",0
	.db "79.904",0
	.db "83.80",0
	.db "85.47",0
	.db "87.62",0
	.db "88.906",0
	.db "91.224",0
	.db "92.906",0
	.db "95.94",0
	.db "(98)",0
	.db "101.07",0
	.db "102.91",0
	.db "106.42",0
	.db "107.87",0
	.db "112.41",0
	.db "114.82",0
	.db "118.71",0
	.db "121.75",0
	.db "127.60",0
	.db "126.90",0
	.db "131.29",0
	.db "132.90",0
	.db "137.33",0
	.db "138.91",0
	.db "178.49",0
	.db "180.95",0
	.db "183.85",0
	.db "186.21",0
	.db "190.2",0
	.db "192.22",0
	.db "195.08",0
	.db "196.97",0
	.db "200.59",0
	.db "204.38",0
	.db "207.2",0
	.db "208.98",0
	.db "(209)",0
	.db "(210)",0
	.db "(222)",0
	.db "(223)",0
	.db "(226)",0
	.db "(227)",0
	.db "(261)",0
	.db "(262)",0
	.db "(263)",0
	.db "(262)",0
	.db "(265)",0
	.db "(266)",0
	.db "(272)",0
	.db "140.12",0
	.db "140.91",0
	.db "144.24",0
	.db "(145)",0
	.db "150.36",0
	.db "151.96",0
	.db "157.25",0
	.db "158.92",0
	.db "162.50",0
	.db "164.93",0
	.db "167.26",0
	.db "168.93",0
	.db "173.04",0
	.db "174.97",0
	.db "232.04",0
	.db "231.04",0
	.db "238.03",0
	.db "(237.05",0
	.db "(244)",0
	.db "(243)",0
	.db "(247)",0
	.db "(247)",0
	.db "(251)",0
	.db "(254)",0
	.db "(257)",0
	.db "(258)",0
	.db "(259)",0
	.db "(260)",0

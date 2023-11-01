\ SPIRAL.F
\
\ This version translated to DX-Forth
\ Originally programmed by ...
\
\ Spiral.pas - by Mario van den Ancker
\                  E-Mail: mario@astro.uva.nl
\                  WWW: http://www.astro.uva.nl/mario/
\  Program to display a rotating spiral on the screen in 320x200x256 MCGA
\  mode using colour-cycling. Please be patient. Generating the spiral image
\  takes a little while. Requires TP 6.0 or higher. Donated to the public
\  domain.

empty forth definitions decimal

\ Compile-time option
0 value GENIMAGE         \ 1= generate spiral, 0= use SPIRAL.BMP

$A000 constant Screen    \ Screen address
319 constant MaxX        \ Screen dimensions
199 constant MaxY
MaxX 2/ constant MidX
MaxY 2/ constant MidY

: KeyPressed ( -- flag )
  key? dup if key drop then ;

: 3* ( n -- n*3 )  3 * ;

256 3* constant PSize    \ palette size (bytes)

\ Palette array definer
: Parray
  create ( -- ) PSize allot
  does> ( index -- adr ) swap 3* + ;

create PaletteData ( -- addr )
  0 c, 0 c, 0 c, 0 c, 0 c, 63 c, 3 c, 0 c, 60 c, 7 c, 0 c, 56 c,
  10 c, 0 c, 53 c, 13 c, 0 c, 50 c, 15 c, 0 c, 48 c, 17 c, 1 c, 46 c,
  19 c, 1 c, 44 c, 20 c, 1 c, 43 c, 21 c, 1 c, 42 c, 23 c, 1 c, 40 c,
  24 c, 1 c, 39 c, 25 c, 1 c, 38 c, 26 c, 1 c, 37 c, 27 c, 2 c, 36 c,
  28 c, 2 c, 35 c, 29 c, 2 c, 34 c, 30 c, 2 c, 33 c, 31 c, 2 c, 32 c,
  32 c, 2 c, 31 c, 33 c, 3 c, 30 c, 34 c, 3 c, 29 c, 34 c, 3 c, 29 c,
  35 c, 3 c, 28 c, 35 c, 3 c, 28 c, 36 c, 3 c, 27 c, 37 c, 4 c, 26 c,
  37 c, 4 c, 26 c, 38 c, 4 c, 25 c, 38 c, 4 c, 25 c, 39 c, 4 c, 24 c,
  40 c, 5 c, 23 c, 40 c, 5 c, 23 c, 41 c, 5 c, 22 c, 41 c, 5 c, 22 c,
  41 c, 5 c, 22 c, 42 c, 6 c, 21 c, 42 c, 6 c, 21 c, 43 c, 6 c, 20 c,
  43 c, 6 c, 20 c, 43 c, 6 c, 20 c, 44 c, 7 c, 19 c, 44 c, 7 c, 19 c,
  45 c, 7 c, 18 c, 45 c, 8 c, 18 c, 45 c, 8 c, 18 c, 46 c, 8 c, 17 c,
  46 c, 8 c, 17 c, 47 c, 9 c, 16 c, 47 c, 9 c, 16 c, 47 c, 9 c, 16 c,
  47 c, 9 c, 16 c, 48 c, 10 c, 15 c, 48 c, 10 c, 15 c, 48 c, 10 c, 15 c,
  49 c, 11 c, 14 c, 49 c, 11 c, 14 c, 49 c, 11 c, 14 c, 50 c, 12 c, 13 c,
  50 c, 12 c, 13 c, 50 c, 13 c, 13 c, 50 c, 13 c, 13 c, 51 c, 13 c, 12 c,
  51 c, 14 c, 12 c, 51 c, 14 c, 12 c, 51 c, 14 c, 12 c, 52 c, 15 c, 11 c,
  52 c, 15 c, 11 c, 52 c, 15 c, 11 c, 53 c, 16 c, 10 c, 53 c, 16 c, 10 c,
  53 c, 17 c, 10 c, 53 c, 17 c, 10 c, 54 c, 18 c, 9 c, 54 c, 18 c, 9 c,
  54 c, 19 c, 9 c, 54 c, 19 c, 9 c, 54 c, 20 c, 9 c, 55 c, 20 c, 8 c,
  55 c, 21 c, 8 c, 55 c, 21 c, 8 c, 55 c, 22 c, 8 c, 56 c, 22 c, 7 c,
  56 c, 23 c, 7 c, 56 c, 23 c, 7 c, 56 c, 24 c, 7 c, 56 c, 24 c, 7 c,
  57 c, 25 c, 6 c, 57 c, 26 c, 6 c, 57 c, 26 c, 6 c, 57 c, 27 c, 6 c,
  57 c, 28 c, 6 c, 57 c, 28 c, 6 c, 58 c, 29 c, 5 c, 58 c, 30 c, 5 c,
  58 c, 30 c, 5 c, 58 c, 31 c, 5 c, 59 c, 32 c, 4 c, 59 c, 33 c, 4 c,
  59 c, 33 c, 4 c, 59 c, 34 c, 4 c, 59 c, 35 c, 4 c, 59 c, 36 c, 4 c,
  59 c, 37 c, 4 c, 60 c, 38 c, 3 c, 60 c, 38 c, 3 c, 60 c, 39 c, 3 c,
  60 c, 40 c, 3 c, 60 c, 41 c, 3 c, 60 c, 42 c, 3 c, 61 c, 43 c, 2 c,
  61 c, 44 c, 2 c, 61 c, 45 c, 2 c, 61 c, 46 c, 2 c, 61 c, 47 c, 2 c,
  61 c, 48 c, 2 c, 61 c, 49 c, 2 c, 62 c, 50 c, 1 c, 62 c, 51 c, 1 c,
  62 c, 52 c, 1 c, 62 c, 54 c, 1 c, 62 c, 55 c, 1 c, 62 c, 56 c, 1 c,
  63 c, 57 c, 0 c, 63 c, 59 c, 0 c, 63 c, 60 c, 0 c, 63 c, 61 c, 0 c,
  63 c, 63 c, 0 c, 63 c, 61 c, 0 c, 63 c, 60 c, 0 c, 63 c, 59 c, 0 c,
  63 c, 57 c, 0 c, 62 c, 56 c, 1 c, 62 c, 55 c, 1 c, 62 c, 54 c, 1 c,
  62 c, 52 c, 1 c, 62 c, 51 c, 1 c, 62 c, 50 c, 1 c, 61 c, 49 c, 2 c,
  61 c, 48 c, 2 c, 61 c, 47 c, 2 c, 61 c, 46 c, 2 c, 61 c, 45 c, 2 c,
  61 c, 44 c, 2 c, 61 c, 43 c, 2 c, 60 c, 42 c, 3 c, 60 c, 41 c, 3 c,
  60 c, 40 c, 3 c, 60 c, 39 c, 3 c, 60 c, 38 c, 3 c, 60 c, 38 c, 3 c,
  59 c, 37 c, 4 c, 59 c, 36 c, 4 c, 59 c, 35 c, 4 c, 59 c, 34 c, 4 c,
  59 c, 33 c, 4 c, 59 c, 33 c, 4 c, 59 c, 32 c, 4 c, 58 c, 31 c, 5 c,
  58 c, 30 c, 5 c, 58 c, 30 c, 5 c, 58 c, 29 c, 5 c, 57 c, 28 c, 6 c,
  57 c, 28 c, 6 c, 57 c, 27 c, 6 c, 57 c, 26 c, 6 c, 57 c, 26 c, 6 c,
  57 c, 25 c, 6 c, 56 c, 24 c, 7 c, 56 c, 24 c, 7 c, 56 c, 23 c, 7 c,
  56 c, 23 c, 7 c, 56 c, 22 c, 7 c, 55 c, 22 c, 8 c, 55 c, 21 c, 8 c,
  55 c, 21 c, 8 c, 55 c, 20 c, 8 c, 54 c, 20 c, 9 c, 54 c, 19 c, 9 c,
  54 c, 19 c, 9 c, 54 c, 18 c, 9 c, 54 c, 18 c, 9 c, 53 c, 17 c, 10 c,
  53 c, 17 c, 10 c, 53 c, 16 c, 10 c, 53 c, 16 c, 10 c, 52 c, 15 c, 11 c,
  52 c, 15 c, 11 c, 52 c, 15 c, 11 c, 51 c, 14 c, 12 c, 51 c, 14 c, 12 c,
  51 c, 14 c, 12 c, 51 c, 13 c, 12 c, 50 c, 13 c, 13 c, 50 c, 13 c, 13 c,
  50 c, 12 c, 13 c, 50 c, 12 c, 13 c, 49 c, 11 c, 14 c, 49 c, 11 c, 14 c,
  49 c, 11 c, 14 c, 48 c, 10 c, 15 c, 48 c, 10 c, 15 c, 48 c, 10 c, 15 c,
  47 c, 9 c, 16 c, 47 c, 9 c, 16 c, 47 c, 9 c, 16 c, 47 c, 9 c, 16 c,
  46 c, 8 c, 17 c, 46 c, 8 c, 17 c, 45 c, 8 c, 18 c, 45 c, 8 c, 18 c,
  45 c, 7 c, 18 c, 44 c, 7 c, 19 c, 44 c, 7 c, 19 c, 43 c, 6 c, 20 c,
  43 c, 6 c, 20 c, 43 c, 6 c, 20 c, 42 c, 6 c, 21 c, 42 c, 6 c, 21 c,
  41 c, 5 c, 22 c, 41 c, 5 c, 22 c, 41 c, 5 c, 22 c, 40 c, 5 c, 23 c,
  40 c, 5 c, 23 c, 39 c, 4 c, 24 c, 38 c, 4 c, 25 c, 38 c, 4 c, 25 c,
  37 c, 4 c, 26 c, 37 c, 4 c, 26 c, 36 c, 3 c, 27 c, 35 c, 3 c, 28 c,
  35 c, 3 c, 28 c, 34 c, 3 c, 29 c, 34 c, 3 c, 29 c, 33 c, 3 c, 30 c,
  32 c, 2 c, 31 c, 31 c, 2 c, 32 c, 30 c, 2 c, 33 c, 29 c, 2 c, 34 c,
  28 c, 2 c, 35 c, 27 c, 2 c, 36 c, 26 c, 1 c, 37 c, 25 c, 1 c, 38 c,
  24 c, 1 c, 39 c, 23 c, 1 c, 40 c, 21 c, 1 c, 42 c, 20 c, 1 c, 43 c,
  19 c, 1 c, 44 c, 17 c, 1 c, 46 c, 15 c, 0 c, 48 c, 13 c, 0 c, 50 c,
  10 c, 0 c, 53 c, 7 c, 0 c, 56 c, 3 c, 0 c, 60 c, 0 c, 0 c, 63 c,

parray MyPal
parray InitPal

: InitPaletteData ( -- )
  PaletteData  0 MyPal   PSize cmove
  PaletteData  0 InitPal  PSize cmove ;

\ Waits for VGA's vertical retrace
label WaitVRetrace ( -- )
  $3DA # dx mov
  here  dx al in  $08 # al and  ( *) jnz
  here  dx al in  $08 # al and  ( *) jz  ret
end-code

\ Sets a complete palette
code SetPal ( Palet -- )
  WaitVRetrace ) call
  si bx mov  si pop
  $3c8 # dx mov  0 # al mov  al dx out  dx inc
  Psize # cx mov  here  byte lods  al dx out  ( *) loop
  bx si mov  next
end-code

\ Flips the screen to 320x200x256 MCGA mode
: SetMCGA ( -- )
  $13 'AX !  $10 intcall ;

\ Put all palette colours to black
: SetBlack ( -- )
  0 MyPal PSize erase
  0 MyPal SetPal ;

\ Flips screen back to text mode
: SetTextMode ( -- )
  $03 'AX !  $10 intcall ;

\ PutPixel in MCGA mode
code PutPixel ( x y Color -- )
  dx pop  ax pop  bx pop
  al ah xchg  ax bx add
  ax shr  ax shr  ax bx add
  Screen # ax mov  ax es mov
  es: dl 0 [bx] mov
  next
end-code

\ Cycles all colours in both Palettes
: CyclePalettes ( -- )
  1 MyPal  0 MyPal  255 3* cmove
  0 MyPal  255 MyPal  3 cmove

  1 InitPal  0 InitPal  255 3* cmove
  0 InitPal  255 InitPal  3 cmove

  0 MyPal SetPal ;


GENIMAGE [IF]

: Round ( r -- n )  fround f>s ;

fvariable Phase1
fvariable Phase2
variable Colour

\ Draws a spiral on the screen
: (drawspiral) ( Phi0 Colour -- )
  Colour !  Phase1 f!  0.E Phase2 f!

  1850 1+ 0 do
    Phase2 f@  Phase1 f@ fsin          f* Round  MidX + ( x)
    Phase2 f@  Phase1 f@ fcos  1.2E f/ f* Round  MidY + ( y)  \ correct for non-square pixels
    over ( x) 0 MaxX between
    over ( y) 0 MaxY between  and if
      ( x y ) Colour @ PutPixel
    else  2drop  then
    Phase1 f@  0.0035E Pi f*  f+  Phase1 f!
    Phase2 f@  0.035E  Pi f*  f+  Phase2 f!
  loop ;

\ Draw spirals in 255 different colours
: DrawSpiral ( -- )
  256 0 do
    i 2* s>f Pi f* 255e f/ ( 0..2Pi )
    i (drawspiral)
  loop ;

[ELSE]

here ," SPIRAL.BMP" count
( adr len ) 2constant BMPfile

\ simple disk byte I/O
variable Han         \ file handle
create   ChBuf  0 ,  \ byte buffer

\ Read a byte from file
: Chin ( -- byte | -1 )
  ChBuf 1  Han @  read-file nip  if -1 exit then
  ChBuf c@ ;

0 value W
0 value H
0 value Y320

\ Read in a 256-color .BMP file
: LoadBMP ( -- )
  BMPfile r/o open-file if ( err)
    SetTextMode  BMPfile type ."  file not found."  abort
  then  Han !

  18 0 do  Chin drop  loop        \ skip unused header info
  Chin Chin 8 lshift +  to W      \ Width 0..32764 (ample range)
  Chin Chin 2drop                 \ skip

  Chin Chin 8 lshift +  to H      \ Height 0..32764 (ample range)
  53 1+ 24 do  Chin drop  loop    \ skip

\  0 $3C8 pc!                      \ set color registers
\  256 0 do
\    Chin 2 rshift  \ B
\    Chin 2 rshift  \ G
\    Chin 2 rshift  \ R
\    Chin drop
\    $3C9 pc!
\    $3C9 pc!
\    $3C9 pc!
\  loop

  256 4 * 0 do  Chin drop  loop   \ skip palette info

  \ load .BMP image onto the video screen
  -1  H 1- do                     \ .BMP files are upside down!
    i 320 * to Y320
    W 0 do
      Chin  Screen Y320 i + c!l
    loop
  -1 +loop

  Han @ close-file drop           \ close handle so it can be used again
;

[THEN]


variable TimesRun

\ Start with turning colours up
: Turn-Up ( -- )
  TimesRun @ 256 < if
    256 0 do
      3 0 do
        j InitPal i + c@
        TimesRun @ 255 */
        j MyPal i + c!
      loop
    loop
  then ;

\ End with turning colours down
: Turn-Down ( -- )
  TimesRun @ 3000 256 - > if
    256 0 do ( i)
      3 0 do ( j)
        j InitPal i + c@
        3000 TimesRun @ - 255 */
        j MyPal i + c!
      loop
    loop
  then ;

\ Main
: Spiral ( -- )
  SetMCGA

  SetBlack
[ GENIMAGE ] [IF]
  DrawSpiral
[ELSE]
  LoadBMP
[THEN]

  InitPaletteData

  0 TimesRun !
  begin
    Turn-Up
    Turn-Down
    CyclePalettes
    1 TimesRun +!
    KeyPressed  TimesRun @ 3000 >  or
  until

  SetTextMode ;


cr .( Save to disk? )  y/n [if]

turnkey Spiral SPIRAL  \ make executable

[then]


\ Nixie.f - Adapted for DX-Forth (240*200 mode only)
\ Compile with DX-Forth: FORTH - INCLUDE NIXIE.F BYE

\ NixieClk.xpl	28-Jun-2011	Loren Blaney	loren.blaney@gmail.com
\ Nixie Clock - displays current time of day
\ Compile with 32-bit XPL (xpx.bat)

\ REVISIONS:
\ 27-Jan-2011, Original.
\ 28-Jun-2011, Display in five different graphic modes.

empty  forth definitions  decimal
application

1 fload XPLGRAPH  \ XPL0 graphics

\ Define functions we don't have

\ Safe ALLOT
: ?ALLOT ( u -- ) dup unused u> abort" Out of Memory" allot ;

\ Fetch array char
code C[]  ( index base -- char )
  bx pop  ax pop  ax bx add  0 [bx] al mov
  ah ah sub  ax push  next  end-code

\ Store array char
code C[]!  ( char index base -- )
  bx pop  ax pop  ax bx add  ax pop
  al 0 [bx] mov  next  end-code

\ simple disk byte I/O
variable Han         \ file handle
create   ChBuf  0 ,  \ byte buffer

\ Read a byte from file
: Chin ( -- byte | -1 )
  ChBuf 1  Han @  read-file nip  if -1 exit then
  ChBuf c@ ;

\ code Chin ( -- byte | -1 )
\  Han ) bx mov  1 # cx mov  ChBuf # dx mov
\  $3F # ah mov  $21 int  1 $ jnc  -1 # ChBuf ) mov
\ 1 $:  ChBuf ) push  next  end-code


0 value VidMode			\ graphic mode
0 value ScrW			\ screen width & height (pixels)
0 value ScrH
0 value Scaler 			\ needed to squeeze pizels into 320x200 screen
0 value	WinX			\ for centering window on the screen
0 value WinY
0 value	PenX			\ pen location for plotting pixels
0 value PenY

0 value Screen			\ 320x200 video graphic screen ($A000)

67 constant TubeW		\ tube width and gap between hours, minutes, sec.
TubeW 2/ constant GapW

48 44 * 2 + constant /Digits	\ graphic image data array size (bytes)
67 150 * 2 + constant /Tube

\ base address image arrays - allocated at run-time to keep EXE small
0 value	(Digits)
0 value (Tube)

: Digit() ( n -- adr )  /Digits * (Digits) + ;
aka (Tube) Tube ( -- adr )

\ temps
0 value X
0 value Y
0 value X0
0 value Y0
0 value X1
0 value Y1

0 value W	\ width, height (pixels)
0 value H
0 value C	\ color
0 value Y320

0 value W1	\ width, height (pixels)
0 value H1

: DrawFilledRectangle ( X0 Y0 W H C)	\ Draw a filled rectangle
  to C
  to H1
  to W1
  to Y0		\ upper left corner coordinates
  to X0

  Y0 H1 + Y0 do
	X0 i MoveTo
	X0 W1 + 1- i C Line
  loop
;

0 value Sp			\ address of sprite data

: DrawSprite ( X Y Sp )  \ Draw a sprite
  to Sp
  to Y0
  to X0

  0 Sp c[] to W			\ get width and height (in pixels)
  1 Sp c[] to H

  2 ( K )			\ point to image data

  Y0 H + Y0 do
          X0 W +  X0 do
             ( K) dup Sp c[]	\ get pixel's color
             ?dup if		\ background (0) is transparent
		i Scaler rshift  j Scaler rshift  rot Point
             then
             1+ ( K)
          loop
  loop
  ( K ) drop
;

aka DrawSprite Drawtube


: NumOut ( N )  \ Draw a 2-digit number, including leading zero
  10 /mod
  PenX PenY rot Digit() DrawSprite
  PenX TubeW + to PenX
  PenX PenY rot Digit() DrawSprite
  PenX TubeW + to PenX
;


: ShowTime ( ) 			\ Display current time (e.g: 15 03 45)
  $2C00 'AX !			\ call DOS function 2C (hex)
  $21 intcall			\ DOS calls are interrupt 21 (hex)
  'CX @  8 rshift  NumOut	\ the high byte of register CX contains the hours
  PenX GapW + to PenX
  'CX @ $00FF and NumOut	\ the low byte of CX contains the minutes
  PenX GapW + to PenX
  'DX @  8 rshift  NumOut	\ the high byte of DX contains the seconds
;


: LoadSp ( X0 Y0 W H Sp )       \ Load a sprite
  to Sp                 \ sprite to load
  dup to H  1 Sp c[]!   \ width and height (pixels)
  dup to W  0 Sp c[]!
  to Y0  to X0          \ coordinates in Screen to get sprite from

  2 ( K)

  Y0 H +  Y0 do
      X0 W +  X0 do
          Screen  j 320 *  i +  c@l  over Sp c[]!
          ( K) 1+
      loop
  loop
  ( K) drop
;


: LoadSprites                  \ Load sprite images from .BMP file
  \ read in a 256-color .BMP file
  \ open file for input
  s" NIXIE.BMP" r/w open-file if ( err)
        3 SetVid
           ." NIXIE.BMP file not found."
        cr ." WinZip users: Try CheckOut."
        abort
  then  Han !

  18 0 do  Chin drop  loop        \ skip unused header info
  Chin Chin 8 lshift +  to W      \ Width 0..32764 (ample range)
  Chin Chin 2drop                 \ skip

  Chin Chin 8 lshift +  to H      \ Height 0..32764 (ample range)
  53 1+ 24 do  Chin drop  loop    \ skip

  0 $3C8 pc!                      \ set color registers
  256 0 do
          Chin 2 rshift  \ B
          Chin 2 rshift  \ G
          Chin 2 rshift  \ R
          Chin drop
          $3C9 pc!
          $3C9 pc!
          $3C9 pc!
  loop

  \ load .BMP image onto the video screen
  -1  H 1- do       \ .BMP files are upside down!
        i 320 * to Y320
        W 0 do
                Chin  Screen Y320 i + c!l
        loop
  -1 +loop

  Han @ close-file drop           \ close handle so it can be used again

  \                        X, Y, W, H, Sprite
    0  0 48  44 0 Digit() LoadSp
   48  0 48  44 1 Digit() LoadSp
   96  0 48  44 2 Digit() LoadSp
  144  0 48  44 3 Digit() LoadSp
  192  0 48  44 4 Digit() LoadSp
    0 44 48  44 5 Digit() LoadSp
   48 44 48  44 6 Digit() LoadSp
   96 44 48  44 7 Digit() LoadSp
  144 44 48  44 8 Digit() LoadSp
  192 44 48  44 9 Digit() LoadSp
  240  0 67 150 Tube      LoadSp
;


: Main
  here to (Digits)  /Digits 10 * ?allot	\ allocate arrays
  here to (Tube)  /Tube ?allot

  $13 to VidMode
  320 to ScrW
  200 to ScrH
  1 to Scaler

  $A000 to Screen
  VidMode SetVid		\ set up graphic display

  LoadSprites
  Clear

  TubeW 6 * GapW 4 * +  Scaler rshift to W
  200 Scaler rshift to H
  ScrW W - 2/ to WinX		\ center window on screen
  ScrH H - 2/ to WinY

  WinX 12 - WinY 12 - W 24 + H 24 + $01 ( white) DrawFilledRectangle  \ frame
  WinX      WinY      W      H      $23 ( gray)  DrawFilledRectangle

  30 Scaler lshift WinY + to PenY  \ top edge of window + offset to tube
  WinX GapW + to PenX		\ left edge of window + offset to tube
  5 1+ 0 do			\ draw the tubes
	PenX PenY Tube DrawTube
	PenX TubeW + to PenX	\ move to next tube position
	i 1 =  i 3 =  or if
            PenX GapW + to PenX
        then
  loop

  PenY 55 + to PenY		\ offset to numbers inside tube
  begin	WinX GapW + 10 + to PenX  \ left edge of window + offset to number
	ShowTime		\ call routine to display the current time
  key? until			\ keep repeating until a key is struck

  $03 SetVid			\ restore normal text display (for DOS)
;


CR .( Save to disk? ) y/n
[if]  turnkey Main NIXIE  [then]

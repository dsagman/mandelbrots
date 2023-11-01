\ This version translated to DX-Forth
\
\   FORTH.EXE - INCLUDE WALKER BYE
\
\ -----------------------------------------------
\ Originally programmed in XPL0 see ...
\
\ http://www.xpl0.org/guess.html

\ Here's a simple animation that features a famous little guy from "Lemmings."

\ Walker.xpl     22-Feb-2010
\ Compile with 32-bit XPL0 (xpx.bat)

empty forth definitions decimal
application

: DRSHIFT ( xd1 n -- xd2 )  0 ?do d2/ $7FFF and loop ;

1 fload xplgraph

create GuyImage

$0002 , $0000 , $0022 , $2200 , $0022 , $9000 , $0009 , $9900 , $000F , $9000 , 
$000F , $9000 , $000F , $9000 , $0001 , $1000 , $00F1 , $1000 , $000F , $F000 ,
$0002 , $0200 , $0022 , $2000 , $0022 , $9000 , $0009 , $9900 , $000F , $9000 , 
$00F9 , $9000 , $00F9 , $90F0 , $0001 , $10F0 , $0011 , $0F00 , $00FF , $0000 ,
$0000 , $0000 , $0022 , $0200 , $0022 , $2000 , $0002 , $9000 , $0009 , $9900 , 
$00FF , $9000 , $00F9 , $9000 , $0FF9 , $9F00 , $0011 , $1110 , $0FF0 , $01FF ,
$0000 , $0000 , $0022 , $2200 , $0022 , $9000 , $0009 , $9900 , $000F , $9000 , 
$000F , $9000 , $00F9 , $9000 , $0001 , $1000 , $0FF1 , $1100 , $0F00 , $FF00 ,
$0002 , $0000 , $0022 , $2200 , $0022 , $9200 , $0029 , $9900 , $000F , $9000 , 
$0009 , $F000 , $000F , $9000 , $0001 , $1000 , $00F1 , $1000 , $000F , $F000 ,
$0002 , $0000 , $0022 , $2200 , $0022 , $9000 , $0009 , $9900 , $000F , $9000 , 
$0009 , $F000 , $0009 , $F0F0 , $0001 , $10F0 , $0011 , $0F00 , $00FF , $0000 ,
$0000 , $2000 , $0022 , $0200 , $0022 , $2000 , $0002 , $9000 , $0009 , $9900 , 
$0009 , $F000 , $0009 , $F000 , $0009 , $9F00 , $0011 , $1110 , $0FF0 , $01FF ,
$0000 , $0000 , $0002 , $2000 , $0022 , $9200 , $0029 , $9900 , $000F , $9000 , 
$000F , $9000 , $0009 , $F000 , $0001 , $1000 , $0F11 , $1100 , $0F00 , $FF00 ,

0 value Frame                        \ frame (0..7),
0 value X0                           \ and its upper-left coordinate
0 value Y0

: ShowGuy ( Frame X0 Y0 -- )         \ Display a frame of the walking guy
  to Y0  to X0  to Frame
  10 0 do                               \ for 10 horizontal scan lines...
    Frame 10 * i + 2* 2* GuyImage + 2@  \ get colors for 8 horizontal pixels
    0 7 do                              \ plot pixels from right to left
      i X0 +  j Y0 +  3 pick  $0F and  Point
      4 drshift
    -1 +loop  2drop
  loop ;

: (walker) ( -- )
  begin
    320 0 do                         \ move position across screen
      i 7 and  i  100 ShowGuy        \ show a frame of guy at position
      0 2 1 Soundx                   \ delay about 1/9 second
      key? if key drop unloop exit then  \ terminate program on key stroke
    loop
  again ;

: Walker ( -- )
  $13 SetVid                         \ set 320x200 graphics
  (walker)
  $03 SetVid                         \ restore text mode (for DOS)
;

cr .( Save to disk? ) y/n
[if]  turnkey Walker WALKER  [then]

\ 2048.F
\ Sliding squares game translated from XPL0 version
\ Compile with DX-Forth 4.2 or later:
\   FORTH.EXE - INCLUDE 2048

empty forth definitions decimal application

: D* ( ud1 ud2 -- ud ) \ multiply doubles
  >r swap >r 2dup um* rot r> * + rot r> * + ;

\ Random number generator
2variable Seed  1. seed 2!
: Random ( -- u )  seed 2@ $015A4E35. d* 1. d+ tuck seed 2! ;
: Rand ( u -- 0..u-1 )  random um* nip ;
: Randomize ( -- )  $40 $6C @l seed ! ;  \ from PC tick timer

\ Array access
: )  ( adr idx -- adr' )  cells + ;
: )@ ( adr idx -- n )  ) @ ;
: )! ( n adr idx -- )  ) ! ;

create Box  16 cells allot    \ Tiles array

0 value Moved
0 value Done
0 value I0
0 value DI
0 value K
variable Score

: ShowScore ( -- )
  30 5 at-xy  $F Attrib c!  ." Score: "  Score @ u. ;

: ShiftTiles ( I0 DI -- )     \ Shift tiles, add adjacents, shift again
  to DI  to I0

  false to Done
  begin
      3 0 do                  \ shift all tiles in a single row or column
          I0 to K
          3 0 do
              Box K )@ 0=  Box K DI + )@  and  if
                  Box K DI + )  dup @ Box K )!  0 swap !
                  true to Moved
              then
              K DI + to K
          loop
      loop
      Done if  exit  then

      true to Done
      I0 to K                 \ add identical adjacent tiles into a new tile
      3 0 do
          Box K )@  dup  Box K DI + )@  =  and  if  \ non-zero and equal
              1 Box K ) +!  0 Box K DI + )!  true to Moved
              1 Box K )@ lshift  Score +!  ShowScore
          then
          K DI + to K
      loop                    \ loop back to close any gaps that were opened
  again ;

0 value X
0 value Y
0 value Ch

: Program ( -- )
  Randomize
  Page
  Box 16 cells erase                           \ empty the box of tiles
  0 Score !  ShowScore
  begin
      begin  Box  16 Rand  dup to K  )@  0= until  \ in a random empty location
      2  10 Rand if 1- then  Box K )!          \ insert a 2^1=2 or 2^2=4
      16 0 do                                  \ show board with its tiles
          i  3 and     5 +  6 *  to X          \ get coordinates of tile
          i  2 rshift  3 *  6 +  to Y
          Box i )@  1+  7 and  4 lshift  $F +  Attrib c! \ set color based on tile value
          3 0 do                               \ draw a square (6*8x3*16)
              X  Y i +  at-xy  6 spaces
          loop
          Box i )@  if                         \ box contains a tile
              1  Box i )@ lshift  (u.)         \ get value & cvt to string
              6 1+ over - 2/ X +  Y 1+  at-xy  \ center it
              type                             \ display
          then
      loop

      false to Moved                           \ a tile must move to continue
      begin
          key to Ch                            \ get key code
          0 3 do                               \ for all rows or columns
              Ch case
                  $CB of  i 4 *      1 ShiftTiles   endof  \ left arrow
                  $CD of  i 4 * 3 + -1 ShiftTiles   endof  \ right arrow
                  $D0 of  i 12 +    -4 ShiftTiles   endof  \ down arrow
                  $C8 of  i          4 ShiftTiles   endof  \ up arrow
                  $1B of  Normal Page  quit         endof  \ Esc
                  ( other )                    \ ignore all other keys
              endcase
          -1 +loop
      Moved until
  again ;

cr .( Save to disk? ) y/n  [if]  turnkey program 2048 bye [then]

\ end

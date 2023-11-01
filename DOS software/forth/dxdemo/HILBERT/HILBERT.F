\ HILBERT.F
\
\ Adapted from XPL0 and Forth sources

empty forth definitions decimal

1 fload XPLGRAPH  \ XPL0 graphics library

variable X
variable Y
0 value X0
0 value Y0
variable COLOR

0 value H

: DRAW ( -- ) x @ y @ color @ Line ;

: UP    ( n -- ) y +! ;
: DOWN  ( n -- ) negate up ;
: RIGHT ( n -- ) x +! ;
: LEFT  ( n -- ) negate right ;

defer A  defer B  defer C  defer D

: (A) ( k -- )
  dup 0> if  1-
    dup D  H left   draw
    dup A  H down   draw
    dup A  H right  draw
    dup B
  then drop ;

: (B) ( k -- )
  dup 0> if  1-
    dup C  H up     draw
    dup B  H right  draw
    dup B  H down   draw
    dup A
  then drop ;

: (C) ( k -- )
  dup 0> if  1-
    dup B  H right  draw
    dup C  H up     draw
    dup C  H left   draw
    dup D
  then drop ;

: (D) ( k -- )
  dup 0> if  1-
    dup A  H down  draw
    dup D  H left  draw
    dup D  H up    draw
    dup C
  then drop ;

' (A) is A  ' (B) is B  ' (C) is C  ' (D) is D

: HILBERT ( -- )
  $12 SetVid \ 640x480x16
  320 to H  300 to X0  240 to Y0
  5  \ degree
  1+ 1 do
    H 2/ to H
    X0 H 2/ + to X0
    Y0 H 2/ + to Y0
    X0 x !  Y0 y !
    i 7 mod color !
    x @ y @ MoveTo
    \ DRAW CURVE OF ORDER I
    i A
  loop
  key drop
  $03 SetVid ; \ text mode


cr .( Save to disk? )  y/n [if]

turnkey HILBERT HILBERT  \ make executable

[then]


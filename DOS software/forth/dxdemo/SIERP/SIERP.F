\ SIERP.F
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
    dup A  H    right  H down  draw
    dup B  H 2* right          draw
    dup D  H    right  H up    draw
    dup A
  then drop ;

: (B) ( k -- )
  dup 0> if  1-
    dup B  H left   H    down  draw
    dup C           H 2* down  draw
    dup A  H right  H    down  draw
    dup B
  then drop ;

: (C) ( k -- )
  dup 0> if  1-
    dup C  H    left  H up    draw
    dup D  H 2* left          draw
    dup B  H    left  H down  draw
    dup C
  then drop ;

: (D) ( k -- )
  dup 0> if  1-
    dup D  H right  H    up  draw
    dup A           H 2* up  draw
    dup C  H left   H    up  draw
    dup D
  then drop ;

' (A) is A  ' (B) is B  ' (C) is C  ' (D) is D

: SIERPINSKI ( -- )
  $12 SetVid \ 640x480x16
  400 4 /  dup to H  3 *  dup to X0  to Y0
  4 ( degree) 1+ 1 do
    X0 H -  dup to X0  x !  H 2/ to H
    Y0 H +  dup to Y0  y !
    i 7 mod color !
    x @ y @ MoveTo
    \ DRAW CURVE OF ORDER I
    i A  H right  H down  draw
    i B  H left   H down  draw
    i C  H left   H up    draw
    i D  H right  H up    draw
  loop
  key drop
  $03 SetVid ; \ text mode


cr .( Save to disk? )  y/n [if]

turnkey SIERPINSKI SIERP  \ make executable

[then]


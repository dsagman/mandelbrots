\ This version translated to Forth
\
\ Compile with DX-Forth 3.7 or later:
\
\   FORTH-F.EXE - INCLUDE WW BYE
\
\ Originally programmed in XPL0 by ...
\
\ WW.XPL         23-Oct-2003     Loren Blaney    loren_blaney@idcomm.com
\ Lorenzian Waterwheel using flip screen animation
\ Compile with 16-bit XPL0

empty forth definitions  decimal
application

1 fload XPLGRAPH  \ load XPL0 graphics functions

\ Define functions we don't have:
: FLOAT ( n -- ; R: -- r )         s>d d>f ;
: FIX   ( R: r -- ; -- n )         f>d d>s ;
: F+!   ( R: r -- ; addr -- )      dup >r f@ f+ r> f! ;
: F>    ( R: r1 r2 -- ; -- flag )  fswap f< ;
: F<=   ( R: r1 r2 -- ; -- flag )  f> not ;
: >=    ( n1 n2 -- flag )          < not ;


8         constant Buckets  \ number of buckets in waterwheel
50        constant BWidth   \ bucket dimensions (pixels)
55        constant BHeight
BWidth 2/ constant B2Width
70        constant Base     \ Y coordinate for baseline (X axis) of speed graph
Base 13 - constant SLimit   \ limit for speed graph (so it doesn't mess up screen)
140 1+    constant ScnA     \ starting Y coords for alternating screens
ScnA 339 + 13 +
          constant ScnB

fvariable Speed  \ speed of waterwheel rotation (radians per iteration)
fvariable Fric   \ friction slowdown rate (percent slowdown per iteration)
fvariable WaterRate \ water fill rate (arbitrary units)
fvariable Leak   \ bucket leak rate (percent leaked per iteration)
fvariable Ang0   \ angle of reference point (bucket 0) on wheel (radians)
fvariable AngB   \ angle between buckets around wheel (radians)
fvariable Torque \ torque on wheel caused by weight of water in buckets

: farray  create ( n ) floats allot
          does>  ( n -- adr )  swap floats + ;

Buckets farray Water  \ amount of water in each bucket
Buckets farray BucX   \ X coordinate of center of bucket
Buckets farray BucY   \ Y coordinate of top of bucket     (0,0 = center)
Buckets farray Ang    \ angle of bucket around waterwheel (radians)

variable View  \ view selector (ScnA or ScnB)
\ variable B     \ bucket number (0..Buckets-1)
variable BX    \ coordinates for a bucket (pixels)
variable BY
variable SX    \ coordinates for plotting speed graph (pixels)
variable SY
variable SX0   \ steps per pixel for SX
variable WLev  \ depth of water level in a bucket (pixels)

$07 constant Bel  \ ASCII control characters
$1B constant Esc
$20 constant Sp
$40 constant Ctrl

: ENUM  ( n "name" -- n+1 ) dup constant 1+ ;

0
enum Black   \ attribute colors EGA palette
enum Blue
enum Green
enum Cyan
enum Red
enum Magenta
enum Brown
enum White
enum Gray
enum LBlue
enum LGreen
enum LCyan
enum LRed
enum LMagenta
enum Yellow
enum BWhite
drop

3.14159265358979323846E fconstant Pi
Pi 2.0E f*              fconstant Pi2
99.9E  Pi f*  180E f/   fconstant MaxSpeed

\ ------------------------- STANDARD LIBRARY ROUTINES ---------------------------

code ROR  ( n c -- n2 )         \ Rotate N right C bits
     cx pop  ax pop  ax cl ror  ax push  next
end-code

\ -------------------------------------------------------------------------------

: FlipView               \ Flip between video screens
\ Flip the Start Address Register between screens A and B.
\ Note that the effect of this register occurs after the next vertical retrace.
  View @ ScnB = if
        ScnA View !
        $0D $3D4 pc!     \ display screen A (ScnA)
        $10 $3D5 pc!     \ (140+1)*640/8 = $2C10
        $0C $3D4 pc!
        $2C $3D5 pc!
  else
        ScnB View !
        $0D $3D4 pc!     \ display screen B (ScnB)
        $10 $3D5 pc!     \ (140+1+339+13)*640/88 = $9A10
        $0C $3D4 pc!
        $9A $3D5 pc!
  then
;  \ FlipView

: CTxt2 ( X Y Str )      \ Display a text string at cursor position X, Y
  2over 9 + at-xy        \ This displays on both video screens
  2dup type
  2swap 31 + at-xy
  type
;  \ CTxt2

fvariable Num

: CRlout2  ( X Y Num )   \ Display a real number at cursor position X, Y
  Num f!                 \ This displays on both video screens
  2dup 9 + at-xy
  Num f@ 1 5 f.r
  31 + at-xy
  Num f@ 1 5 f.r
;  \ CRlout2

0 value H
0 value V

: DrawLine ( X0 Y0 X1 Y1 C )    \ Draw a straight line
\ Draw into the portion of video memory that is not currently being viewed
  -5 16 - to H  40 to V         \ centering adjustment (8 pixels per char cell)
  View @ ScnB = if
        >r  2swap
        >r  H +  r> ScnA +  V +      MoveTo
        >r  H +  r> ScnA +  V +  r>  Line
  else
        >r  2swap
        >r  H +  r> ScnB +  V +      MoveTo
        >r  H +  r> ScnB +  V +  r>  Line
  then
;  \ DrawLine

0 value X0
0 value Y0
0 value X1
0 value Y1
0 value C

: DrawBlock ( X0 Y0 X1 Y1 C )   \ Draw a filled rectangle
  to C  to Y1  to X1  to Y0  to X0   \ coordinates of opposite corners, fill color

  X1 X0 < if  X1  X0 to X1  to X0  then   \ put coordinates into
  Y1 Y0 < if  Y1  Y0 to Y1  to Y0  then   \ ascending order

  Y1 Y0 -  X1 X0 - 8 *  > if              \ if tall and skinny then
        X1 1+ X0 do                       \ draw vertical lines
                i Y0 i Y1 C DrawLine
        loop
  else
        Y1 1+ Y0 do               \ else draw fast horizontal lines
                X0 i X1 i C DrawLine
        loop
  then
;  \ DrawBlock


: DrawBucket  ( X0 Y0 X1 Y1 C )  \ Draw a bucket
  to C  to Y1  to X1  to Y0  to X0
  X0 Y0 X0 Y1 C DrawLine
  X0 Y1 X1 Y1 C DrawLine
  X1 Y1 X1 Y0 C DrawLine
;  \ DrawBucket

\ -------------------------------------------------------------------------------

: Empty-Buckets  ( -- )
  Buckets 0 do  0.0E i Water f!  loop ;

: Main
\ TrapC(true);    \ (prevents Ctrl-C'ing out of a program in graphic-screen mode)
\ Format(3,1);    \ display format of floating point numbers = XXX.X

  \ Set initial conditions
  0.04E  Speed     f!
  20.0E  WaterRate f!
  0.02E  Fric      f!
  0.006E Leak      f!

  \ no water in buckets
  empty-buckets

  0.0E                 Ang0 f!  \ angle of reference point on wheel for bucket 0
  Pi2 Buckets Float f/ AngB f!  \ angle between buckets

  0 SX !  0 SX0 !  \ start speed graph at left edge of screen

  $12 Setvid       \ set display for 640x480x16 graphics
  ScnA View !

  \ Set up the Line Compare Register (= index $18 under the CRT Controller
  \ Register = port $3D4) for split-screen operation. This causes the Horizontal
  \ Scan Counter Register to be reset to zero when the video beam reaches scan
  \ line 338 (the 339th line). Thus the next (340th) scan line displays the
  \ contents of video memory starting at $A000:0. The low 8 bits of the Line
  \ Compare Register are at index $18, but bit 8 is in index register 7 and bit 9
  \ is in index register 9 (it's a real mess).

  $18 $3D4 pc!    \ select Line Compare Register
  $52 $3D5 pc!    \ set low 8 bits of 338 (=$152)

  \ Clear bit 9 of Line Compare Reg by clearing bit 6 of Maximum Scan Line Reg
  $9 $3D4 pc!
  $3D5 pc@  $40 invert  and  $3D5 pc!

  \ (Bit 8 of Line Compare Reg is already set, so no code is needed)

  LCyan Attrib c!

  28 0 s" LORENZIAN WATERWHEEL" CTxt2

  White Attrib c!
  2 2 s" [S]peed:     "        CTxt2
  2 3 s" [F]riction:       %"  CTxt2
  2 4 s" [W]ater Rate:"        CTxt2
  2 5 s" [L]eak Rate:      %"  CTxt2

  54 2 s" Uppercase increases value" CTxt2
  54 3 s" Lowercase decreases value" CTxt2
  54 4 s" Spacebar empties buckets"  CTxt2
  54 5 s" Esc terminates program"    CTxt2

  Cyan Attrib c!
  2 19 s" Speed:"  CTxt2       \ label for graph

  0 Base MoveTo  639 Base Cyan Line  \ draw baseline of speed graph

  begin
        SX @ Base SLimit - MoveTo  SX @ Base SLimit + Cyan Line  \ vert graph line

        \ Limit max speed (not in XPL version)
        Speed f@ fabs  MaxSpeed f> if
          MaxSpeed  Speed f@  f0< if  fnegate  then  Speed f!
        then

        White Attrib c!
        15 2 Speed f@  180.0E Pi f/  f*  CRlout2  \ degrees/unit_time
        15 3 Fric  f@  100.0E f*         CRlout2  \ percent of slowdown
        15 4 WaterRate f@                CRlout2  \ arbitrary units
        15 5 Leak  f@  100.0E f*         CRlout2  \ percent of water in bucket

        Speed f@ Ang0 f+!    \ rotate wheel as a function of speed

        \ limit angle to one revolution
        begin  Ang0 f@ 0.0E f<  while  Pi2         Ang0 f+!  repeat
        begin  Ang0 f@ 0.0E f>  while  Pi2 fnegate Ang0 f+!  repeat

        0.0E Torque f!                          \ initialize torque accumulator
        Buckets 0 do                            \ for all of the buckets...
                Ang0 f@  AngB f@ i Float f*  f+  i Ang f!  \ bucket angle around wheel

                i Ang f@ fsin  100.0E f*  i BucX f!  \ bucket coordinates
                i Ang f@ fcos  100.0E f*  i BucY f!

                \ Fill bucket under faucet
                i BucX f@ fabs  B2Width Float  f<=
                i BucY f@ 0.0E  f>
                and if
                        WaterRate f@  i Water f+!
                then

                \ Leak water out (rate is proportional to amount of water)
                i Water f@  1.0E Leak f@ f-  f*  i Water f!

                i Water f@  BWidth Float f/  Fix  WLev !  \ limit amount of water

                WLev @ BHeight > if  BHeight BWidth * Float  i Water f!  then
                WLev @ 0 < if  0.0E i Water f!  then  \ (negative water is ugly!)

                \ Sum torques (proportional to amount of water * X coordinate)
                i Water f@  i BucX f@  f*  Torque f+!
        loop

        \ Change in speed is proportional to torque
        Torque f@ 80E6 f/ Speed f+!

        \ (Experimentally determined fudge factor; it keeps values reasonable)

        \ Reduce speed as a function of friction
        Speed f@  1.0E Fric f@ f-  f*  Speed f!
        \ (Linear friction (subtraction) doesn't cause chaos; this is more like
        \ air friction)

        \ Erase old wheel image
        [ 320 100 - B2Width - ] literal
        0
        [ 320 100 + B2Width + ] literal
        [ 200 20  + BHeight + ] literal
        Black
        DrawBlock

        \ Draw a picture of the results
        White Attrib c!
        37 2 s" o"  CTxt2              \ faucet

        Brown Attrib c!
        37 11 s" o"  CTxt2             \ axle

        \ Draw water from faucet
        [ 320 1- ] literal
        3
        [ 320 1+ ] literal
        75
        $63 SX @ ror  8 lshift  LBlue +
        DrawBlock

        \ Draw buckets
        Buckets 0 do
                     i BucX f@ Fix     320 +  BX !
                100  i BucY f@ Fix  -   20 +  BY !
                i Water f@  BWidth Float  f/  Fix  WLev !

                BX @ B2Width -
                BY @ BHeight +
                BX @ B2Width +
                BY @ BHeight +  WLev @ -
                LBlue
                DrawBlock

                BX @ B2Width -
                BY @
                BX @ B2Width +
                BY @ BHeight +
                i if  Brown  else  Yellow  then
                DrawBucket
        loop

        FlipView                                \ display what was just drawn
        begin  $3DA pc@  $08 and until          \ wait for vertical retrace

        \ Draw graph of speed vs. time
        SX @ Base SLimit -  MoveTo              \ erase old value
        SX @ Base SLimit +  Black Line
        SX @ Base Cyan Point                    \ restore baseline

        Speed f@  500.0E f*  Fix SY !           \ coordinate for speed
        SY @ SLimit > if  SLimit SY !  then     \ (amplitude is arbitrary)
        SY @ SLimit negate < if  SLimit negate SY !  then  \ limits prevent screen glitches
        SX @ Base SY @ -  LGreen  Point         \ make clockwise speed positive

        1 SX0 +!
        SX0 @ 4 = if
                0 SX0 !  1 SX +!                \ advance to next point
        then

        SX @ 640 >= if  0 SX !  then            \ wrap around screen

        0  \ quit flag

        \ Handle keyboard commands
        key? if
            case key
            [char] S  of    0.01E Speed     f+!  endof  \ speed adjustment
            [char] s  of   -0.01E Speed     f+!  endof  \ (sometimes it needs a nudge)
            [char] F  of   0.001E Fric      f+!  endof  \ friction adjustment
            [char] f  of  -0.001E Fric      f+!  endof
            [char] W  of     0.1E WaterRate f+!  endof
            [char] w  of    -0.1E WaterRate f+!  endof
            [char] L  of   0.001E Leak      f+!  endof
            [char] l  of  -0.001E Leak      f+!  endof
                  Sp  of  empty-buckets          endof  \ empty buckets
     [char] C CTRL -  of  1- ( quit )            endof
                  Esc of  1- ( quit )            endof  \ terminate program
                  Bel emit
            endcase  \ loop
        then
  until
  $03 Setvid             \ restore text mode
;  \ Main


CR .( Save to disk? ) y/n
[if]  turnkey Main WW  [then]


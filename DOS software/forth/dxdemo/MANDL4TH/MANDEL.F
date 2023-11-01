\ This version translated to Forth with modifications
\ Originally programmed in XPL0 by ...
\
\ MANDEL.XPL    APR-27-99
\ Mandelbrot Set Plotter
\ Loren Blaney
\
\ The Mandelbrot set is the set of points C that do not cause Z to go to
\ infinity when this equation is repeatedly calculated:
\
\       Z := Z^2 + C
\
\ Z and C are complex numbers (Z^2 is Z squared). They consist of two values
\ called real and imaginary, which are indicated like this:
\
\       Z  =  Zr + Zi*i
\       C  =  Cr + Ci*i
\
\       Z^2  =  (Zr + Zi*i)^2  =  Zr^2 + 2*Zr*Zi*i + Zi^2*i^2
\
\ By definition i^2 = -1, thus:
\
\       Z^2  =  Zr^2 - Zi^2 + 2*Zr*Zi*i
\
\ Keeping the real and imaginary parts separate, the original equation becomes:
\
\       Zr':= Zr^2 - Zi^2 + Cr
\       Zi := 2*Zr*Zi + Ci
\       Zr := Zr'
\ (Zr' is simply to keep from changing Zr prematurely.)
\
\ Plotting the points C in the Mandelbrot set gives the characteristic snowman
\ shape. The real part (Cr) is plotted on the X axis, and the imaginary part
\ (Ci) is plotted on the Y axis. If colors are plotted according to the rate
\ that Z approaches infinity, beautiful patterns emerge.


empty forth definitions  decimal
application

1 fload XPLGRAPH    \ XPL0 compatible graphics library

\ Screen constants
0 value   Xsize     \ pixels
fvariable Xsize.
0 value   Ysize/2   \ pixels/2
fvariable Ysize/2.

\ Set screen constants
: ScrInit ( -- )
  Xmax 1+    dup to Xsize    s>f Xsize.   f!
  Ymax 1+ 2/ dup to Ysize/2  s>f Ysize/2. f!
;

\ variable X          \ Screen coordinates of current point
\ variable Y
( don't need X,Y - will be using forth's built-in loop indexes I,J )

variable Cnt        \ Iteration counter

fvariable Cr        \ Coordinates scaled to +/-2 range
fvariable Ci
fvariable Zr        \ Complex accumulator
fvariable Zi
fvariable ZrZr      \ Complex accumulator squared
fvariable ZiZi

\ fvariable Temp      \ Temporary scratch
( don't need this either )

: ShowMandel  ( -- )
  Ysize/2 0 do      \ For the top half of the screen...
    Xsize 0 do      \ For all the points horizontally...

      i s>f  Xsize.   f@ f/  0.5e f-  4.0e f*  Cr f!  \ Range -2.0 to +2.0
      j s>f  Ysize/2. f@ f/  1.5e f*           Ci f!  \ Range  0.0 to +1.5

      0 Cnt !   0.0e Zr f!   0.0e Zi f!
      begin
        Zr f@  fdup f*  fdup ZrZr f!
        Zi f@  fdup f*  fdup ZiZi f!

        ( ZrZr ZiZi ) f+  2.0e  f> not  \ Heads toward infinity
      while

        Zi f@  Zr f@  f* ( Temp )   \ Rearranged to speed up calculations
        ZrZr f@  ZiZi f@ f-  Cr f@  f+  Zr f!
        ( Temp ) fdup f+     Ci f@  f+  Zi f!

        1 Cnt +!
        Cnt @ 64 >   \ Quit if in the Mandelbrot set
      until          \ (64 is close enough to infinity)
      then

      Cnt @ 64 < if   \ Leave points in Mandel set black
                      \ otherwise plot a pretty color
        i  Ysize/2 j -  Cnt @ $0F and  Point  \ Double speed by taking advantage
        i  Ysize/2 j +  Cnt @ $0F and  Point  \ of symmetry about X axis
      then

    loop  ( X )
  loop  ( Y )
;

$13 constant MCGA ( 320x200)
$10 constant EGA  ( 640x350)
$12 constant VGA  ( 640x480)
$6A constant VESA ( 800x600)

: SelectMode ( -- mode )
  cmdtail ( command-tail string)
  dup 0= ( empty) abort" Usage: mandel n  where n = 1..4"
  ( adr len) number? if drop else 0 then
  ( n) case
    2 of  EGA   endof
    3 of  VGA   endof
    4 of  VESA  endof
    ( default) MCGA  swap
  endcase
;

: Mandel ( -- )
  SelectMode   \ Select mode
  SetVid       \ Set graphic screen
  ScrInit      \ Set screen constants
  ShowMandel
  key drop     \ Wait for keystroke, so plot can be admired
  $03 SetVid   \ Restore standard text display
;

turnkey Mandel mandel  \ make executable


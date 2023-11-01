\ Adapted from Borland BGI demo program
\
\ To compile:  FORTH.EXE - INCLUDE BGIDEMO2 BYE
\

empty forth definitions  decimal
application

1 fload BGIGRAPH  ( load BGI graphics library )


0 value Speed  ( delay in mSecs )  0 to Speed


\ Simple random number generator from 'Starting Forth'

variable SEED  1 seed !

\ Get random number
: RAND  ( -- u )  seed @  31421 *  6727 +  dup seed ! ;

\ Get random number between 0 and u-1
: RANDOM  ( u -- 0..u-1 )  rand um* nip ;

\ Initialize random number generator
: RANDOMIZE  ( -- )  $40 $6C @l  seed ! ;


( temp string buffer )
create sb  255 dup , allot

\ Concatenate two strings placing result in temp buffer
: S+  ( a1 u1 a2 u2 -- a3 u3 )
  2>r  sb @ min  sb cell+ 0 +string
  sb @  over -  2r> rot min  2swap +string ;

\ Cell array
-? : ARRAY
  create ( size -- )  cells allot
  does>  ( index -- adr )  swap cells + ;

\ Define array string
-? : $set  ( c-addr len array -- )
  here 2>r  dup 1+ allot  r@ place  r> r> ! ;

\ Get array string
: $@  ( array -- c-addr u )
  @ count ;


: Int2Str  ( n -- adr len )  s>d (d.) ;
: v.height  ( -- n )  view.bottom view.top - ;
: v.width   ( -- n )  view.right view.left - ;


( The five fonts available )
5 array Fonts

s" DefaultFont"     0 fonts $set
s" TriplexFont"     1 fonts $set
s" SmallFont"       2 fonts $set
s" SansSerifFont"   3 fonts $set
s" GothicFont"      4 fonts $set

( The five predefined line styles supported )
5 array LineStyles

s" SolidLn"         0 linestyles $set
s" DottedLn"        1 linestyles $set
s" CenterLn"        2 linestyles $set
s" DashedLn"        3 linestyles $set
s" UserBitLn"       4 linestyles $set

( The twelve predefined fill styles supported )
12 array FillStyles

s" EmptyFill"       0  fillstyles $set
s" SolidFill"       1  fillstyles $set
s" LineFill"        2  fillstyles $set
s" LtSlashFill"     3  fillstyles $set
s" SlashFill"       4  fillstyles $set
s" BkSlashFill"     5  fillstyles $set
s" LtBkSlashFill"   6  fillstyles $set
s" HatchFill"       7  fillstyles $set
s" XHatchFill"      8  fillstyles $set
s" InterleaveFill"  9  fillstyles $set
s" WideDotFill"     10 fillstyles $set
s" CloseDotFill"    11 fillstyles $set

( The two text directions available )
2 array TextDirect

s" HorizDir"        0 textdirect $set
s" VertDir"         1 textdirect $set

( The Horizontal text justifications available )
3 array HorizJust

s" LeftText"        0 horizjust $set
s" CenterText"      1 horizjust $set
s" RightText"       2 horizjust $set

( The vertical text justifications available )
3 array VertJust

s" BottomText"      0 vertjust $set
s" CenterText"      1 vertjust $set
s" TopText"         2 vertjust $set


12 constant MaxFillStyles  ( patterns 0..11 )

variable MaxRadius
variable FillColor
variable EndAngle
variable Radius
variable Xasp
variable Yasp
variable RadiusStep
variable StepAngle
variable Color
variable Width
variable Height
variable Step
variable Style
variable Tmp

0 value MaxX
0 value MaxY
0 value CenterX
0 value CenterY
0 value XStep
0 value YStep
0 value X
0 value Y
0 value W
0 value H

variable GraphDriver  ( Graphics device driver )
variable GraphMode    ( Graphics mode value )
variable ErrorCode    ( Reports any graphics errors )
variable MaxColor     ( maximum color value available )
2variable OldExitProc ( Pointer;  Saves exit procedure address )

20 value MaxPoints    ( # points max )

create Points  MaxPoints 2* cells allot  ( polygon or points buffer )


( Adjust a value for the aspect ratio of the device )
: AdjAsp ( n -- n2 )  GetAspectRatio >r  m*  r> sm/rem nip ;


( Returns a Random non-zero color value within the legal range )
: RandColor  ( -- n )
  MaxColor @  Random 1+ ;


( Select the maximum color in the Palette for the drawing color )
: DefaultColors  ( -- )
  MaxColor @ SetColor ;


( Draw a border around the current view port )
: DrawBorder  ( -- )
  DefaultColors
  SolidLn 0 NormWidth SetLineStyle
  0 0 v.width v.height Rectangle ;


( Set the window to the entire screen )
: FullPort  ( -- )
  0 0 MaxX MaxY 1 SetViewPort ;


( Make a default window and view port for demos )
: MainWindow  ( c-addr u -- )
  DefaultColors                            ( Reset the colors )
  ClearDevice                              ( Clear the screen )
  DefaultFont HorizDir 1 SetTextStyle      ( Default text font )
  CenterText TopText SetTextJustify        ( Centre & Top justify text )
  FullPort                                 ( Full screen view port )
  MaxX 2/ 2  2swap  OutTextXY              ( Draw the header )
  ( Draw main window )
  0  s" M" TextHeight 4 +  MaxX  MaxY s" M" TextHeight 4 + -  1 SetViewPort
  DrawBorder                               ( Put a border around it )
  ( Move the edges in 1 pixel on all sides so border isn't in the view port )
  1  s" M" TextHeight 5 +  MaxX 1-  MaxY s" M" TextHeight 5 + -  1 SetViewPort
;


( Display a status line at the bottom of the screen )
: StatusLine  ( c-add u -- )
  FullPort
  DefaultColors
  DefaultFont HorizDir 1 SetTextStyle
  CenterText  TopText SetTextJustify
  SolidLn 0 NormWidth SetLineStyle
  EmptyFill 0 SetFillStyle
  0  MaxY  s" M" TextHeight 4 +  -  MaxX  MaxY  Bar   ( Erase old status line )
  0  MaxY  s" M" TextHeight 4 +  -  MaxX  MaxY  Rectangle
  MaxX 2/  MaxY  s" M" TextHeight 2+  -  2swap  OutTextXY
  ( Go back to the main window )
  1  s" M" TextHeight 5 +  MaxX 1-  MaxY s" M" TextHeight 5 + - 1 SetViewPort
;


( Wait for the user to abort the program or continue )
: WaitToGo  ( -- )
  DefaultColors
  s" Esc aborts or press a key..." StatusLine
   Key 27 = if ( Esc )
    CloseGraph  abort                 ( terminate program )
  else
    ClearDevice                       ( clear screen, go on with demo )
  then ;


( Write out a string and increment to next line )
: WriteOut ( adr u -- )
  X Y  2swap OutTextXY
  s" M" TextHeight  2+  Y +  to Y
;


( Display the status of all query functions after OpenGraph )
: ReportStatus
  10 to X  4 to Y

  s" Status report" MainWindow
  LeftText TopText SetTextJustify
  s" Graphics device    : "  GetDriverName s+  WriteOut
  s" Graphics mode      : "  GetGraphMode GetModeName s+  WriteOut
  s" Screen resolution  : (0, 0, "  GetMaxX Int2Str s+  s" , " s+
    GetMaxY Int2Str s+  s" )" s+  WriteOut
  s" Current view port  : ("  view.left Int2Str s+  s" , " s+
    view.top Int2Str s+  s" , " s+  view.right Int2Str s+  s" , " s+
    view.bottom Int2Str s+  s" )" s+  WriteOut
  s" Clipping           : "  view.clip if  s" ON"  else  s" OFF"  then s+
    WriteOut
  s" Current position   : ("
    GetX Int2Str s+  s" , " s+  GetY Int2Str s+  s" )" s+  WriteOut
\  s" Palette entries    : " Palette.Size Int2Str s+  WriteOut
  s" GetMaxColor        : " GetMaxColor Int2Str s+  WriteOut
  s" Current color      : " GetColor Int2Str s+  WriteOut
  s" Line style         : " line.style LineStyles $@ s+  WriteOut
  s" Line thickness     : " line.thickness Int2Str s+  WriteOut
  s" Current fill style : " fill.pattern FillStyles $@ s+  WriteOut
  s" Current fill color : " fill.color Int2Str s+  WriteOut
  s" Current font       : " text.font Fonts $@ s+  WriteOut
  s" Text direction     : " text.direction TextDirect $@ s+  WriteOut
  s" Character size     : " text.charsize Int2Str s+  WriteOut
  s" Horizontal justify : " text.horiz HorizJust $@ s+  WriteOut
  s" Vertical justify   : " text.vert VertJust $@ s+  WriteOut
  WaitToGo ;


: DrawBox  ( -- )
  SolidFill Color @ SetFillStyle
  Color @ SetColor
  X Y  over Width @ +  over Height @ +  Bar
  X Y  over Width @ +  over Height @ +  Rectangle
  GetColor  Color !
  Color @ 0= if
    MaxColor @  SetColor
    X Y  over Width @ +  over Height @ +  Rectangle
  then
  Color @ 1+  GetMaxColor 1+  mod  Color ! ;


( Display all of the colors available for the current driver and mode )
: ColorPlay
  s" Color demonstration" MainWindow

  0 Color !

  v.width 1+  46 /  2*  Width !
  v.height ( view.bottom view.left -) 1+  47 /  2*  Height !

  Width  @  3 / to X
  Height @  3 / to Y

  16 0 do
    16 0 do
      DrawBox
      Width @  2/  3 *  X + to X
    loop
    Width @  3 /  to X
    Height @  2 /  3 *  Y + to Y
  loop

  WaitToGo ;


15 constant XBars
10 constant YBars

create Pal  256 3 * allot

: SetDACBlock  ( Start Count adr )
  'DX !  cseg 'ES !  'CX !  'BX !
  $1012 'AX !  $10 Intcall ;

: ReadDACBlock ( Start Count adr )
  'DX !  cseg 'ES !  'CX !  'BX !
  $1017 'AX !  $10 Intcall ;

: getVGAPal  ( index -- R G B )
  3 * Pal +  dup >r  c@  r@ 1+ c@  r> 2 + c@ ;

( Demonstrate the use of the SetPalette command )
: PalettePlay
  GetMaxColor 16 < if
    s" SetPalette demonstration" MainWindow
    Pal GetPalette
  else
    s" SetRGBPalette demonstration" MainWindow
    0 256 Pal ReadDACBlock
  then
  s" Press any key..." StatusLine

  v.width  XBars /  Width !
  v.height YBars /  Height !
  0 to X  0 to Y

  0 ( Color )

  YBars 0 do
    XBars 0 do
      SolidFill over SetFillStyle
      X Y  Width @  X +  over Height @ +  Bar
      Width @ 1+  X +  to X
      1+ ( Color )  16 mod
    loop
    0 to X
    Height @ 1+  Y +  to Y
  loop
  drop

  begin
    GetMaxColor 16 < if
      GetMaxColor 1+ Random  65 Random SetPalette
    else
      16 Random  256 Random getVGAPal  SetRGBPalette
    then
    5 MS
    key?
  until

  GetMaxColor 16 < if
    Pal SetAllPalette
  else
    0 256 Pal SetDACBlock
  then

  WaitToGo ;

( Demonstrate the predefined line styles available )
: LineStylePlay
  ClearDevice
  DefaultColors
  s" Pre-defined line styles" MainWindow

  35 to X  10 to Y
  v.width  11 /  Step !

  LeftText TopText SetTextJustify
  X Y s" NormWidth" OutTextXY
  CenterText TopText SetTextJustify
  4 0 do
    i 0 NormWidth SetLineStyle
    X  20 Y +  X  View.Bottom 40 - Line
    X  View.Bottom 30 -  i Int2Str OutTextXY
    Step @  X + to X
  loop

  Step @ 2*  X + to X

  LeftText TopText SetTextJustify
  X Y s" ThickWidth" OutTextXY
  CenterText TopText SetTextJustify
  4 0 do
    i 0 ThickWidth SetLineStyle
    X  20 Y +  X  View.Bottom 40 - Line
    X  View.Bottom 30 -  i Int2Str  OutTextXY
    Step @  X + to X
  loop

  LeftText TopText SetTextJustify
  WaitToGo ;

( Demonstrate user defined line styles )
: UserLineStylePlay
  s" User defined line styles" MainWindow

  4 to X  10 to Y
  0 Style !  0 Tmp !

  begin
     X view.right 4 - <
  while
    Style @
    1 Tmp @ 16 mod lshift  ( assume symmetrical MOD )
    or Style !

    UserBitLn Style @ NormWidth SetLineStyle
    X Y  X v.height Y - Line
    5  X + to X
    1 Tmp +!
    Style @ $FFFF = if
      0 Tmp !
      0 Style !
    then
  repeat

  WaitToGo ;

: DrawBox1 ( -- )
  Style @  MaxColor @  SetFillStyle
  X Y  Width @ X +  Height @ Y + Bar
  X Y  Width @ X +  Height @ Y + Rectangle
  Width @ 2/ X +   Height @ 4 + Y +  Style @ Int2Str  OutTextXY
  1 Style +! ;

( Display all of the predefined fill styles available )
: FillStylePlay
  s" Pre-defined fill styles" MainWindow
  view.right  1+    13 /  dup to X  2* Width  !
  view.bottom 10 -  10 /  dup to Y  2* Height !

  0 Style !

  3 0 do
    4 0 do
      DrawBox1
      Width @  2/ 3 *  X + to X
    loop
    Width @  2/ to X
    Height @  2/ 3 *  Y + to Y
  loop


  LeftText TopText SetTextJustify
  WaitToGo ;

hex
create Patterns
  AA c, 55 c, AA c, 55 c, AA c, 55 c, AA c, 55 c,
  33 c, 33 c, CC c, CC c, 33 c, 33 c, CC c, CC c,
  F0 c, F0 c, F0 c, F0 c, F  c, F  c, F  c, F  c,
  0  c, 10 c, 28 c, 44 c, 28 c, 10 c, 0  c, 0  c,
  0  c, 70 c, 20 c, 27 c, 25 c, 27 c, 4  c, 4  c,
  0  c, 0  c, 0  c, 18 c, 18 c, 0  c, 0  c, 0  c,
  0  c, 0  c, 3C c, 3C c, 3C c, 3C c, 0  c, 0  c,
  0  c, 7E c, 7E c, 7E c, 7E c, 7E c, 7E c, 0  c,
  0  c, 0  c, 22 c, 8  c, 0  c, 22 c, 1C c, 0  c,
  FF c, 7E c, 3C c, 18 c, 18 c, 3C c, 7E c, FF c,
  0  c, 10 c, 10 c, 7C c, 10 c, 10 c, 0  c, 0  c,
  0  c, 42 c, 24 c, 18 c, 18 c, 24 c, 42 c, 0  c,
decimal

: DrawBox2  ( -- )
  Style @  8 *  Patterns +  MaxColor @ SetFillPattern
  X Y  Width @ X +  Height @ Y +  Bar
  X Y  Width @ X +  Height @ Y +  Rectangle
  1 Style +! ;

( Display some user defined fill patterns )
: FillPatternPlay
  s" User defined fill styles" MainWindow
  view.right  1+    13 /  dup to X  2* Width  !
  view.bottom 10 -  10 /  dup to Y  2* Height !

  0 Style !

  3 0 do

    4 0 do
      DrawBox2
      Width @ 2/ 3 *  X + to X
    loop

    Width  @ 2/ to X
    Height @ 2/ 3 *  Y + to Y
  loop

  LeftText TopText SetTextJustify
  WaitToGo ;

( Demonstrate text justifications and text sizing )
: TextPlay
  s" SetTextJustify / SetUserCharSize demo" MainWindow

  DefaultFont ( TriplexFont) VertDir 3 ( 4) SetTextStyle
  v.height 2- to Y
  CenterText BottomText SetTextJustify
  s" M" TextWidth 2* Y s" Vertical" OutTextXY

  DefaultFont ( TriplexFont) HorizDir 3 ( 4) SetTextStyle
  LeftText TopText SetTextJustify
  s" M" TextWidth 2* 2 s" Horizontal" OutTextXY

  CenterText CenterText SetTextJustify

  v.width 2/ to X
  s" H" TextHeight to Y

  5 1 do
    DefaultFont ( TriplexFont) HorizDir i SetTextStyle
    s" M" TextHeight to H
    s" M" TextWidth  to W
    H Y + to Y
    X Y s" Size " i Int2Str s+ OutTextXY
  loop

  H 2/ Y + to Y

\  CenterText TopText SetTextJustify
\  5 6 3 2 SetUserCharSize
\  DefaultFont ( TriplexFont) HorizDir UserCharSize SetTextStyle
\  v.width 2/ Y s" User defined size!" OutTextXY

  WaitToGo ;

( Demonstrate the use of RestoreCrtMode and SetGraphMode )
: CrtModePlay
  s" SetGraphMode / RestoreCrtMode demo" MainWindow
  CenterText CenterText SetTextJustify
  v.width 2/ v.height 2/ s" Now you are in graphics mode" OutTextXY
  s" Press any key for text mode..." StatusLine
  Key drop
  RestoreCrtmode
  s" Now you are in text mode." type cr
  s" Press any key to go back to graphics..." type
  Key drop
  GetGraphMode SetGraphMode
  s" SetGraphMode / RestoreCrtMode demo" MainWindow
  CenterText CenterText SetTextJustify
  v.width 2/ v.height 2/ s" Back in graphics mode..." OutTextXY
  WaitToGo ;

( Say goodbye and then exit the program )
: SayGoodbye
  s" " MainWindow
  DefaultFont ( TriplexFont) HorizDir 3 ( 4) SetTextStyle
  CenterText CenterText SetTextJustify
  v.width 2/ v.height 2/ s" That's all folks!" OutTextXY
  s" Press any key to quit..." StatusLine
  key drop ;

( Random filled ellipse demonstration )
: FillEllipsePlay
  s" FillEllipse demonstration" MainWindow
  s" Esc aborts or press a key..." StatusLine

  MaxY 10 / MaxRadius !
  SolidLn 0 NormWidth SetLineStyle
  begin
    RandColor FillColor !
    FillColor @ SetColor
    MaxFillStyles Random  FillColor @  SetFillStyle
    MaxX Random  MaxY Random
    MaxRadius @ Random
    MaxRadius @ Random
      FillEllipse
    Speed MS
    key?
  until
  WaitToGo ;

( Draw random sectors on the screen )
: SectorPlay
  s" Sector demonstration" MainWindow
  s" Esc aborts or press a key..." StatusLine

  MaxY 10 / MaxRadius !
  SolidLn 0 NormWidth SetLineStyle
  begin
    RandColor FillColor !
    FillColor @ SetColor
    MaxFillStyles Random  FillColor @  SetFillStyle
    360 Random EndAngle !
    MaxX Random  MaxY Random
    EndAngle @ Random  EndAngle @
    MaxRadius @ Random
    MaxRadius @ Random
      Sector
    Speed MS
    key?
  until
  WaitToGo ;


1962 constant InitSeed ( A seed for the random number generator )
1000 constant NumPts   ( The number of pixels plotted )

0 value XMax
0 value YMax

( Demonstrate the PutPixel and GetPixel commands )
: PutPixelPlay
  s" PutPixel / GetPixel demonstration" MainWindow
  s" Esc aborts or press a key..." StatusLine

  v.width  1- to XMax
  v.height 1- to YMax

  begin
    key? 0=
  while
    ( Plot random pixels )
    InitSeed SEED !
    0
    begin
      dup NumPts <
    while
      1+
      XMax Random 1+
      YMax Random 1+
      RandColor PutPixel
    repeat
    drop

    ( Erase pixels )
    InitSeed SEED !
    0
    begin
      dup NumPts <
    while
      1+
      XMax Random 1+
      YMax Random 1+
      2dup GetPixel ( Color )
      RandColor = if
        0 PutPixel
      else
        2drop
      then
    repeat
    drop
  repeat
  WaitToGo ;


20  constant r
100 constant StartX
50  constant StartY

0 value ulx
0 value uly
0 value lrx
0 value lry

2variable Saucer  ( pointer )

: MoveSaucer ( -- )
  r 2* Random  dup Step !
  1 and if ( odd )  Step @  negate  Step !  then
  Step @  X + to X

  r Random  dup Step !
  1 and if ( odd )  Step @  negate  Step !  then
  Step @  Y + to Y

  ( Make saucer bounce off viewport walls )
  X Width @ + 1-  view.right  > if
    v.width  Width @ -  1+  to X
  else
    X view.left < if  view.left to X  then
  then

  Y Height @ + 1-  view.bottom  > if
    v.height  Height @ -  1+  to Y
  else
    Y view.top < if  view.top to Y  then
  then ;


( Demonstrate the GetImage and PutImage commands )
: PutImagePlay
  ( PaintScreen )
  ClearDevice
  FullPort
  s" GetImage / PutImage Demonstration" MainWindow
  s" Esc aborts or press a key..." StatusLine

  ( DrawSaucer )
  StartX  StartY      0   360  r  r 3 / 2+  Ellipse
  StartX  StartY 4 -  190 350  r  r 3 /     Ellipse
  StartX 7 +   StartY 6 -   StartX 10 +  StartY 12 -  Line
  StartX 10 +  StartY 12 -  2  Circle
  StartX 7 -   StartY 6 -   StartX 10 -  StartY 12 -  Line
  StartX 10 -  StartY 12 -  2  Circle
  SolidFill MaxColor @  SetFillStyle
  StartX 1+  StartY 4 +  GetColor  FloodFill

  ( ReadSaucerImage )
  StartX  r 1+  -        to ulx
  StartY  14    -        to uly
  StartX  r 1+  +        to lrx
  StartY  r 3 /  3 +  +  to lry

  ulx uly lrx lry ImageSize
  4 rshift 1+ ( paragraphs )  GETMEM if ( error )
    drop
  else
    0 Saucer 2!
    ulx uly lrx lry  Saucer 2@  GetImage
    ulx uly  Saucer 2@  XORput PutImage  ( erase image )

    ( Plot some "stars" )
    1000 0 do
      MaxX Random  MaxY Random  RandColor PutPixel
    loop

    MaxX 2/ to X
    MaxY 2/ to Y

    ( Move the saucer around )
    begin
      X Y  Saucer 2@  XORput PutImage   ( draw image )
      70 MS
      X Y  Saucer 2@  XORput PutImage   ( erase image )
      lrx ulx - 1+  Width !             ( width/height )
      lry uly - 1+  Height !
      MoveSaucer
      key?
    until
    Saucer 2@ drop ( seg ) RELMEM drop
  then
  WaitToGo ;


( Draw random bars on the screen )
: RandBarPlay
  s" Random Bars" MainWindow
  s" Esc aborts or press a key..." StatusLine

  begin
    RandColor  dup SetColor
    CloseDotFill Random 1+  swap  SetFillStyle
    MaxX Random  MaxY Random
    MaxX Random  MaxY Random  0 TopOff Bar3D
    Speed MS
    key?
  until
  WaitToGo ;


( Draw random arcs on the screen )
: ArcPlay
  s" Arc / GetArcCoords demonstration" MainWindow
  s" Esc aborts or press a key..." StatusLine

  MaxY 10 / MaxRadius !
  begin
    RandColor SetColor
    360 Random EndAngle !
    SolidLn 0 NormWidth SetLineStyle
    MaxX Random  MaxY Random
    EndAngle @ Random  EndAngle @
    MaxRadius @ Random
      Arc
    Arc.X Arc.Y Arc.Xstart Arc.Ystart  Line
    Arc.X Arc.Y Arc.Xend Arc.Yend  Line
    Speed MS
    key?
  until
  WaitToGo ;


( Draw random circles on the screen )
: CirclePlay
  s" Circle demonstration" MainWindow
  s" Esc aborts or press a key..." StatusLine

  MaxY 10 / MaxRadius !
  SolidLn 0 NormWidth SetLineStyle
  begin
    RandColor SetColor
    MaxX Random  MaxY Random
    MaxRadius @ Random
      Circle
    Speed MS
    key?
  until
  WaitToGo ;


create CheckerBoard
  0 c, $10 c, $28 c, $44 c, $28 c, $10 c, 0 c, 0 c,


( Draw a Tesseract on the screen with relative move and
  line drawing commands, also create a polygon for filling )
: DrawTesseract
  12 to MaxPoints
  MaxX 9 /  to W
  MaxY 8 /  to H
  MaxX 2/  W  5 2 */mod  swap if 1+ then  -  to X
  MaxY 2/  H  3 *  -  to Y

  ( Border around viewport is outer part of polygon )
  0    0    [ Points 0  + ] literal 2!
  0    MaxX [ Points 4  + ] literal 2!
  MaxY MaxX [ Points 8  + ] literal 2!
  MaxY 0    [ Points 12 + ] literal 2!
  0    0    [ Points 16 + ] literal 2!

  X Y MoveTo

  ( Grab the whole in the polygon as we draw )
  0        H         MoveRel  GetY GetX [ Points 20 + ] literal 2!
  W        H negate  MoveRel  GetY GetX [ Points 24 + ] literal 2!
  W 4 *    0         MoveRel  GetY GetX [ Points 28 + ] literal 2!
  0        H 5 *     MoveRel  GetY GetX [ Points 32 + ] literal 2!
  W negate H         MoveRel  GetY GetX [ Points 36 + ] literal 2!
  W -4 *   0         MoveRel  GetY GetX [ Points 40 + ] literal 2!
  0        H -5 *    MoveRel  GetY GetX [ Points 44 + ] literal 2!

  ( Fill the polygon with a user defined fill pattern )
  CheckerBoard MaxColor @ SetFillPattern
  12 Points FillPoly

  W  H negate MoveRel
  0  H 5 *    LineRel  W 2*  0  LineRel  0 H -3 *   LineRel
  W  H negate LineRel  0  H 5 * LineRel  0 H -5 *   MoveRel
  W -2 *  0   LineRel  0  H 3 * LineRel  W negate H LineRel
  W  H negate MoveRel  W  0     LineRel  0 H -2 *   MoveRel
  W negate  0 LineRel

  ( Flood fill the center )
  MaxX 2/ MaxY 2/ MaxColor @ FloodFill ;


( Demonstrate MoveTo and LineTo commands )
: LineToPlay
  s" MoveTo, LineTo demonstration" MainWindow

  15 to MaxPoints

  v.width  2/ to CenterX
  v.height 2/ to CenterY

  CenterY Radius !
  begin
    Radius @ AdjAsp CenterY +
    v.height 20 -  <
  while
    1 Radius +!
  repeat

  360 MaxPoints / StepAngle !
  MaxPoints 0 do
    StepAngle @  I *
    CenterX  over  Radius @  Cos  +
    CenterY  rot   Radius @  Sin  AdjAsp  -
    I 2* cells  Points +  2!
  loop

  CenterX CenterY Radius @ Circle

  MaxPoints 0 do
    MaxPoints I do
      J  2* cells  Points +  2@  MoveTo
      I  2* cells  Points +  2@  LineTo
    loop
  loop

  WaitToGo ;


( Demonstrate MoveRel and LineRel commands )
: LineRelPlay
  s" LineRel / MoveRel demonstration" MainWindow
  s" Esc aborts or press a key..." StatusLine

  ( Move the viewport out 1 pixel from each end )
  view.left 1-  view.top 1- view.right 1+ view.bottom 1+ ClipOn  SetViewPort
  DrawTesseract
  WaitToGo ;


( Get the coordinates of text for pie slice labels )
: GetTextCoords ( AngleInDegrees Radius -- X Y )
  2dup Cos -rot  Sin ;


( Demonstrate  PieSlice and GetAspectRatio commands )
: PiePlay
  s" PieSlice / GetAspectRatio demonstration" MainWindow
  GetAspectRatio  Yasp !  Xasp !

  v.width  2/        to CenterX
  v.height 2/  20 +  to CenterY
  v.height 3 /       Radius !

  begin
    Radius @ AdjAsp  v.height 10 36 */  <
  while
    1 Radius +!
  repeat

  DefaultFont ( TriplexFont) HorizDir 2 ( 4) SetTextStyle
  CenterText TopText SetTextJustify
  CenterX 6 s" This is a pie chart!" OutTextXY

  DefaultFont ( TriplexFont) HorizDir 2 ( 3) SetTextStyle

  SolidFill RandColor SetFillStyle
  CenterX 10 +  CenterY 10 AdjAsp -  0 90  Radius @  PieSlice
  45  Radius @  GetTextCoords  to Y  to X
  LeftText BottomText SetTextJustify
  CenterX 10 + X + s" H" TextWidth +
    CenterY 10 Y + AdjAsp -
    s" 25 %" OutTextXY

  HatchFill RandColor SetFillStyle
  CenterX  CenterY  225 360  Radius @  PieSlice
  293  Radius @  GetTextCoords  to Y  to X
  LeftText TopText SetTextJustify
  CenterX X + s" H" TextWidth +
    CenterY Y AdjAsp -
    s" 37.5 %" OutTextXY

  InterleaveFill RandColor SetFillStyle
  CenterX 10 - CenterY  135 225  Radius @  PieSlice
  180  Radius @  GetTextCoords  to Y  to X
  RightText CenterText SetTextJustify
  CenterX 10 - X + s" H" TextWidth -
    CenterY Y AdjAsp -
    s" 25 %" OutTextXY

  WideDotFill RandColor SetFillStyle
  CenterX CenterY  90 135  Radius @  PieSlice
  112  Radius @  GetTextCoords  to Y  to X
  RightText BottomText SetTextJustify
  CenterX X + s" H" TextWidth -
    CenterY Y AdjAsp -
    s" 12.5 %" OutTextXY

  WaitToGo ;

0 value NumBars  ( The number of bars drawn )

create BarHeight2
  1 c, 3 c, 5 c, 2 c, 4 c,

create Styles
  1 c, 3 c, 10 c, 5 c, 9 c,

( Demonstrate Bar command )
: BarPlay
  s" Bar / Rectangle demonstration" MainWindow

  s" M" TextHeight  3 *  to H
  5 to NumBars

  CenterText TopText SetTextJustify
  DefaultFont ( TriplexFont) HorizDir 2 ( 4) SetTextStyle
  MaxX 2/ 6 s" These are 2D bars !" OutTextXY
  DefaultFont HorizDir 1 SetTextStyle

  view.left 50 +  view.top 40 ( 30) +  view.right 50 -  view.bottom 10 -
    ClipOn SetViewPort

  H dup dup  v.height H -  Line
  H  v.height H -  v.width H -  over  Line

  v.height  H 2* -  NumBars /  to YStep
  v.width   H 2* -  NumBars /  to XStep
  v.height  H    -             Tmp   !

  LeftText ( CenterText) CenterText SetTextJustify

  ( Draw Y axis with tick marks )
  NumBars 1+ 0 do
    H 2/  Tmp @  H  over Line
    0  Tmp @  I 1+ Int2Str OutTextXY
    Ystep negate  Tmp +!
  loop

  ( Draw X axis, bars, and tick marks )
  H Tmp !
  CenterText TopText SetTextJustify

  Numbars 1+ 0 do
    MaxColor @ SetColor
    Tmp @  v.height H -
    Tmp @  v.height 3 -  H 2/ - Line
    Tmp @  v.height H 2/ -
    I 1+ Int2Str OutTextXY

    I 1+ NumBars 1+ <> if
      RandColor
      I Styles + c@ over SetFillStyle
      SetColor

      Tmp @  v.height H - I BarHeight2 + c@  Ystep *  -
      Tmp @ Xstep +  v.height H - 1-  Bar

      Tmp @  v.height H - i BarHeight2 + c@  Ystep * -
      Tmp @ Xstep +  v.height H - 1-  Rectangle

      Xstep Tmp +!
    then
  loop
  WaitToGo ;

5 value YTicks   ( The number of tick marks on the Y axis )
variable BDepth

create BarHeight
  1 c, 3 c, 2 c, 5 c, 4 c, 2 c, 1 c,

( Demonstrate Bar3D command )
: Bar3DPlay
  s" Bar3D / Rectangle demonstration" MainWindow

  s" M" TextHeight  3 *  to H
  7 to NumBars

  CenterText TopText SetTextJustify
  Defaultfont ( TriplexFont) HorizDir 2 ( 4) SetTextStyle
  MaxX 2/  6  s" These are 3D bars !"  OutTextXY

  DefaultFont HorizDir 1 SetTextStyle

  view.left 50 +  view.top 40 +  view.right 50 -  view.bottom 10 -
    ClipOn SetViewPort

  H dup dup  v.height H -  Line
  H  v.height H -  v.width H -  over  Line

  v.height H 2* -  YTicks  /  to YStep
  v.width  H 2* -  NumBars /  to XStep
  v.height H    -             Tmp !

  LeftText CenterText SetTextJustify

  ( Draw the Y axis and ticks marks )
  Yticks 1+ 0 do
    H 2/ Tmp @  H  over Line
    0  Tmp @  I Int2Str OutTextXY
    Ystep negate  Tmp +!
  loop

  Xstep 4 /  BDepth !  ( Calculate depth of bar )

  ( Draw X axis, bars, and tick marks )
  CenterText TopText SetTextJustify
  H Tmp !

  Numbars 1+ 0 do
    MaxColor @ SetColor
    Tmp @  v.height H -
    Tmp @  v.height 3 -  H 2/ - Line
    Tmp @  v.height  H 2/ -
    I Int2Str OutTextXY

    I 1+ NumBars 1+ <> if
      RandColor
      I 1+ over SetFillStyle
      SetColor
      Tmp @
      v.height H -  I BarHeight + c@  Ystep *  -
      Tmp @  Xstep +  Bdepth @ -
      v.height H - 1-
        BDepth @  TopOn  Bar3D

      Xstep Tmp +!
    then
  loop
  WaitToGo ;

( Draw random polygons with random fill styles on the screen )
: PolyPlay
  s" FillPoly demonstration" MainWindow
  s" Esc aborts or press a key..." StatusLine

  5 to MaxPoints
  begin
    RandColor dup SetColor
    CloseDotFill Random 1+  swap SetFillStyle
    MaxPoints 0 do
      MaxY Random  MaxX Random
      I 2* cells Points +  2!
    loop
    MaxPoints Points FillPoly
    Speed MS
    key?
  until
  WaitToGo ;

variable Left
variable Top
variable Right
variable Bottom

( Demonstrate the SetWriteMode procedure for XOR lines )
: WriteModePlay  ( -- )
  s" SetWriteMode demonstration" MainWindow
  s" Esc aborts or press a key" StatusLine

  0 Left !
  0 Top !
  v.width Right !
  v.height Bottom !

  Bottom @  50 /  Step !
  GetMaxColor SetColor
  Left @ Top @ Right @ Bottom @ Line
  Left @ Bottom @ Right @ Top @ Line
  XORPut SetWriteMode                       ( Set XOR write mode )

  begin
    Left @ Top @ Right @ Bottom @ Line      ( Draw XOR lines )
    Left @ Bottom @ Right @ Top @ Line
    Left @ Top @ Right @ Bottom @ Rectangle ( Draw XOR rectangle )
    50 MS                                   ( Wait )
    Left @ Top @ Right @ Bottom @ Line      ( Erase lines )
    Left @ Bottom @ Right @ Top @ Line
    Left @ Top @ Right @ Bottom @ Rectangle ( Erase rectangle )

    Left @ Step @ +  Right  @ <
    Top  @ Step @ +  Bottom @ <  and if
      Step @                                ( Shrink rectangle )
      dup Left  +!  dup Top +!
      negate
      dup Right +!  Bottom +!
    else
      RandColor SetColor                  ( New color )
      0 Left !                            ( Original large rectangle )
      0 Top !
      v.width Right !
      v.height Bottom !
    then
    key?
  until
  CopyPut SetWriteMode                      ( back to overwrite mode )
  WaitToGo ;


( Demonstrate  SetAspectRatio command )
: AspectRatioPlay
  s" SetAspectRatio demonstration" MainWindow
  s" Esc aborts or press a key..." StatusLine

  v.width   2/  to CenterX
  v.height  2/  to CenterY
  v.height  5 / 3 * Radius !

  Radius @ 30 / RadiusStep !

  CenterX  CenterY  Radius @ Circle

  GetAspectRatio  Yasp !  Xasp !

  31 1 do
    Xasp @  Yasp @  I GetMaxX * +  SetAspectRatio  ( Increase Y aspect factor )
    CenterX CenterY Radius @ Circle
    RadiusStep @  negate  Radius +!             ( Shrink radius )
  loop

  RadiusStep @ 30 * Radius +!

  31 1 do
    Xasp @  I GetMaxX * +  Yasp @  SetAspectRatio  ( Increase X aspect factor )
    Radius @ RadiusStep @ > if
      RadiusStep @  negate  Radius +!          ( Shrink radius )
    then
    CenterX CenterY Radius @ Circle
  loop

  Xasp @ Yasp @ SetAspectRatio                 ( back to original aspect )
  WaitToGo ;


: ?error  ( -- )
  GraphResult ?dup if  GraphErrorMsg cr type  abort  then ;


( Initialize graphics and report any errors that may occur )
: Initialize
\  s" CGA" opengraph ?error  0 setgraphmode
\  s" EGAVGA" opengraph ?error  2 setgraphmode ( VGA 640x480 16 )
\  s" EGAVGA" opengraph ?error  1 setgraphmode ( EGA 640x350 16 )
\  s" VGA256" opengraph ?error  0 setgraphmode ( VGA/MCGA 320x200 )
\  s" SVGA" opengraph ?error  0 setgraphmode ( 320x200 256 )
  s" SVGA" opengraph ?error  1 setgraphmode ( Autodetect )
\  s" SVGA" opengraph ?error  40 setgraphmode ( VESA 640x480 256 )
\  s" SVGA" opengraph ?error  41 setgraphmode ( VESA 800x600 256 )
\  s" SVGA" opengraph ?error  42 setgraphmode ( VESA 1024x768 256 )
\  s" SVGA" opengraph ?error  43 setgraphmode ( VESA 1280x1024 256 )

  GetMaxX to MaxX
  GetMaxY to MaxY
  Randomize
  GetMaxColor  15 min  MaxColor !  ( Limit max drawing color )
  DefaultColors ;


: demo ( program body )
  Initialize
  Randomize
  ReportStatus
  AspectRatioPlay
  FillEllipsePlay
  SectorPlay
  WriteModePlay
  ColorPlay
  PalettePlay
  PutPixelPlay
  PutImagePlay
  RandBarPlay
  BarPlay
  Bar3DPlay
  ArcPlay
  CirclePlay
  PiePlay
  LineToPlay
  LineRelPlay
  LineStylePlay
  UserLineStylePlay
\  TextDump
  TextPlay
  CrtModePlay
  FillStylePlay
  FillPatternPlay
  PolyPlay
  SayGoodbye
  CloseGraph ;


cr .( Save to disk? )  y/n
[if]
  turnkey demo BGIDEMO2
[then]

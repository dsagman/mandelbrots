\ This version translated to Forth
\
\ Compile with DX-Forth 3.91 or later:
\
\   FORTH.EXE - INCLUDE PEDE BYE
\
\ Changes at: 2010-10-22
\ - Fixed mouse detect routine
\ - Fixed killplayer sound
\ - Forgot to init random number gen
\
\ -----------------------------------------------
\ Originally programmed in XPL0 by ...
\
\ PEDE.XPL       20-Nov-2003
\ Centipede Arcade Game
\ by Richard Ottosen, Bill Bailey and Loren Blaney

\ Revision History:
\ 04-Nov-1981: Original ran on Apple II in text mode
\ 20-Nov-2003: Added graphics and modified for PC, LB.

empty  forth definitions  decimal
application

1 fload XPLGRAPH  \ XPL0 graphics
1 fload XRAND     \ XPL0 random number gen

\ Define functions we don't have

: <=  > not ;
: >=  < not ;
: 0<=  0> not ;
: 0>=  0< not ;

warning off

\ character array
: CARRAY ( n "name" )  create  allot ;

\ character array
: 2CARRAY
  create ( n size )  dup , *  allot
  does> dup >r @ rot * + r> cell+ + ;
\  ;code  bx pop  cx pop  ax pop  0 [bx] mul
\  cx ax add  2 # bx add  bx ax add  ax push
\  next  end-code

\ integer array
: ARRAY ( n "name" )
  create cells  allot
  does> swap cells + ;

warning on

\ Fetch array char
code C[]  ( index base -- char )
  bx pop  ax pop  ax bx add  0 [bx] al mov
  ah ah sub  ax push  next  end-code

\ Store array char
code C[]!  ( char index base -- )
  bx pop  ax pop  ax bx add  ax pop
  al 0 [bx] mov  next  end-code

system

\ Enumerate constants
: ENUM  ( n "name" -- n+1 ) dup constant 1+ ;

application

\ CASE additions
: |OR| ( n1 n2 n3 -- n1 n2|n3 )
  2 pick over = if swap then drop ;

\ code |OR| ( n1 n2 n3 -- n1 n2|n3 )
\  ax pop  sp bx mov  ax 2 [bx] cmp  1 $ jnz
\  bx pop  ax push  1 $: next  end-code

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


\ The 320x200 graphic screen (mode $13) is is divided into 8x8-pixel cells,
\ giving a column and line Width and Height of 40x25. All graphic objects
\ (sprites) are mapped into one (or two) of these 8x8 cells. A 40x24 play
\ field array (Field) represents all but the bottom line of the screen.

40 constant Width       \ screen dimensions in 8x8 pixel cells
25 constant Height
12 constant Length      \ initial number of segments in centipede
\ Warning: Width and Length can't be changed unless PlayRound is changed
Length 1- constant Tail \ index to centipede's last segment
30 constant HeadTime    \ delay for injecting heads near bottom
Width Height 24 */ constant MushIni  \ initial number of mushrooms
3  constant PlayIni     \ initial number of players
9  constant SpeedIni    \ initial speed of game (60ths of a second)
5  constant SpeedMax    \ limit maximum speed after 40000 points
Height 12 - constant SpiLimIni  \ initial spider limit (line)

Width 1-    constant Right    \ right-most (8-pixel wide) column of screen
Width 2/    constant Center   \ center column of screen
Height 1-   constant Bottom   \ bottom-most line number of screen (for scores)
Bottom 1-   constant BotLimit \ lower limit of all objects on play field
BotLimit 4 - constant TopLimit \ upper limit of player & upward moving centipede

0
enum Blank   \ objects that go into play field
enum Head
enum Segment
enum Player
enum Shell
enum Mush
enum Mush3
enum Mush2
enum Mush1
enum SpiderL
enum SpiderR
enum Flea
enum Explo
drop

$1B constant Esc   \ Esc key exits program

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

variable Armed       \ flag: player is armed with shell
variable Bitten      \ flag: something bit the player (he's dead)
variable FleaDrop    \ flag: flea is dropping (watch out!)
variable FleaMad     \ flag: flea is mad cuz it's been shot once
0 value  FleaX       \ flea's field coordinates
0 value  FleaY
variable FleaWas     \ what the flea moved on top of (restores mushes)
variable FullMoon    \ timer for injecting heads near bottom
variable II          \ scratch for Main
variable Players     \ total number of players remaining
0 value  PlayX       \ player's field coordinates
0 value  PlayY
variable ScoreL      \ current total score (low part)
variable ScoreH      \ high-order portion of score (multiples of 10000)
variable HitBottom   \ flag: centipede has reached BotLimit
variable HiScoreL    \ highest score in game series (low part)
variable HiScoreH    \ high order portion (in 10000's)
variable SegCnt      \ current number of live segments (incl. heads)
0 value  ShellX      \ shell's field coordinates
0 value  ShellY
variable SpiBias     \ pushes spider right or left (+/-1)
variable SpiLimit    \ upper limit of spider (line)
0 value  SpiX        \ spider's field coordinates (left side)
0 value  SpiY
variable SpiXDir     \ direction spider is currently moving
variable SpiYDir
variable Vol         \ flag: sound volume is on
variable Wave        \ number of wave being played (starts at 0)

\ seg
$A000 value Screen   \ 320x200 video graphic screen ($A000)

\ char
Width Height 1- 2carray Field  \ the play field

\ int
Length array Seg      \ centipede segment type: Head, Segment, or Blank
Length array SegX     \ segment's (or head's) field coordinates
Length array SegY
Length array SegXDir  \ X direction of a segment (left=-1, right=+1)
Length array SegYDir  \ Y direction of a segment (up=-1, down=+1)

\ sprites (8x8 pixel graphic images):
\ char
  8 8 * 2+ carray SpBlank  \ first 2 bytes hold width and height in pixels

8 8 8 * 2+ 2carray SpHead  \ centipede's head (array of 8 for leg positions)
8 8 8 * 2+ 2carray SpSeg

  8 8 * 2+ carray SpPlay
  8 8 * 2+ carray SpShell
  8 8 * 2+ carray SpMush
  8 8 * 2+ carray SpMush3
  8 8 * 2+ carray SpMush2
  8 8 * 2+ carray SpMush1
  8 8 * 2+ carray SpSpiL0
  8 8 * 2+ carray SpSpiR0
  8 8 * 2+ carray SpSpiL1
  8 8 * 2+ carray SpSpiR1
  8 8 * 2+ carray SpFlea0
  8 8 * 2+ carray SpFlea1
  8 8 * 2+ carray SpExplo0
  8 8 * 2+ carray SpExplo1

\ temps
0 value X
0 value Y
0 value X0
0 value Y0
0 value X1
0 value Y1

\ =============================== MOUSE ROUTINES ================================

: OpenMouse ( -- flag )         \ initializes mouse; returns 'false' if it fails
                                \ pointer is set to center of screen but is hidden
  $3533 'AX !  $21 intcall      \ make sure mouse vector ($33) points to something
  'BX @  'ES @  or 0= if  false exit  then
  $0000 'AX !  $33 intcall  'AX @  \ reset mouse; return 'false' if failure
;

\ For video modes $0-$E and $13 the maximum coordinates are 639x199, minus
\ the size of the pointer. For modes $F-$12 the coordinates are the same as
\ the pixels. For 80-column text modes divide the mouse coordinates by 8 to
\ get the character cursor position.
\ 0 = X coordinate; 1 = Y coordinate
: GetMousePosition ( n -- pos )  \ return position of specified mouse coordinate
  $0003 'AX !  $33 intcall
  if  'DX  else  'CX  then @
;

: GetMouseButton ( -- flag )    \ returns non zero if either mouse button is down
                                \ also checks for keyboard commands
  key? if                       \ Esc key aborts program
        key upcase  case
        [char] S of  Vol @  0=  Vol !  endof   \ toggle sound on/off
             Esc of
                     3 SetVid           \ restore normal text mode
                     $36 $43 pc!        \ restore normal timer mode (3)
                     $FF $40 pc!        \ set to maximum count
                     $FF $40 pc!        \ (low byte first)
                     abort
                 endof
        endcase
  then
  $0003 'AX !  $33 intcall  'BX @  $03 and
;

: MoveMouse ( X Y )             \ move mouse pointer to X,Y
  'DX !  'CX !
  $0004 'AX !  0 'BX !  $33 intcall
;

\ ===============================================================================

: Delay ( n )                   \ delay N sixtieths of a second
  0 max  0 ?do                  \ (negative N does 0 delay)
        begin  $3DA pc@  $08 and 0= until       \ wait for no vertical retrace
        begin  $3DA pc@  $08 and    until       \ wait for vertical retrace
  loop
;

: GetTime ( -- timer )          \ read system timer's 8253 counter
                                \ each count is 838 ns (= 1 / 1.19E6 Hz)
  0 $43 pc!     \ latch counter 0
  $40 pc@  $40 pc@  8 lshift +  invert ;


: Noise ( Cy Per )              \ emit a sound on the beeper speaker
                                \ number of cycles, period in 10 ns intervals
  \ Each count is 838 ns. Multiplying by 12 gives the period in 10 ns intervals.
  12 * ( Cnt )
  Vol @ if
        $61 pc@  $03 or  $61 pc!                \ enable speaker and timer
        $B6 $43 pc!                             \ set channel 2 for mode 3
        dup $42 pc!
        dup  8 rshift  $42 pc!
  then
  \ delay approximately the same as the original Apple II Sound intrinsic
  swap  ( Cnt Cy )
  0 ?do
        GetTime >r
        begin  GetTime r@ -  over > until
        r> drop
  loop
  ( Cnt ) drop
  $61 pc@  $03 invert  and  $61 pc!             \ turn off speaker
;

\ ===============================================================================

: IntoutDbl ( High Low -- )   \ display double precision integer
  >r  10000 um*  r> m+  d. ;


: CycleColors ( )             \ cycle 32 shades of 7 colors
  32 0 do                     \ for 32 shades...
        i 32 + $3C7 pc!       \ save first color
        $3C9 pc@  \ R0
        $3C9 pc@  \ G0
        $3C9 pc@  \ B0

        7 1 do                \ shift 6 colors down
                i 1+ 32 * j +  $3C7 pc!
                $3C9 pc@  \ R
                $3C9 pc@  \ G
                $3C9 pc@  \ B

                swap rot  ( B G R )

                i 32 * j +  $3C8 pc!
                $3C9 pc!
                $3C9 pc!
                $3C9 pc!
        loop

        swap rot  ( B G R )

        7 32 * i +  $3C8 pc!                    \ set last color to first color
        $3C9 pc!
        $3C9 pc!
        $3C9 pc!
  loop ;


0 value Sp              \ address of sprite data
0 value W
0 value H
0 value Y320
variable Mirror         \ flag: mirror image: reverse left and right

: DrawSprite ( X Y Sp )  \ draw a sprite onto the 320x200 graphic screen
  to Sp
  to Y0
  to X0

  0 Sp c[] to W   \ get width and height (in pixels)
  1 Sp c[] to H

  2 ( K )

  Y0 H + Y0 do
          i 320 * to Y320
          Mirror @ if
              X0  X0 W + 1- do
                  dup Sp c[]  Screen Y320 i + c!l
                  1+ ( K)
              -1 +loop
          else
              X0 W +  X0 do
                  dup Sp c[]  Screen Y320 i + c!l
                  1+ ( K)
              loop
          then
  loop
  ( K ) drop
;


: DrawObj ( X Y Obj Ex ) \ draw object given Field coordinates
                         \ object to draw
                         \ extra modifier (segment direction, etc.)
  0 Mirror !
  swap  ( X Y Ex Obj )
  case
    Head     of  dup Mirror !  8 Ran 0 SpHead  endof
    Segment  of  dup Mirror !  8 Ran 0 SpSeg   endof
    Player   of  SpPlay   endof
    Shell    of  SpShell  endof
    Mush     of  SpMush   endof
    Mush3    of  SpMush3  endof
    Mush2    of  SpMush2  endof
    Mush1    of  SpMush1  endof
    SpiderL  of  dup ( Ex) if  SpSpiL0  else  SpSpiL1  then  endof
    SpiderR  of  dup ( Ex) if  SpSpiR0  else  SpSpiR1  then  endof
    Flea     of  over ( Y) 1 and if  SpFlea0  else  SpFlea1  then
                 over Mirror !  endof
    Explo    of  2 Ran if  SpExplo0  else  SpExplo1  then  endof
      SpBlank swap
  endcase
  ( X Y Ex Sp )
  >r drop
  3 lshift >r
  3 lshift r>
  r>
  DrawSprite
;


\ -------------------------------------------------------------------------------

: ShowPlayers ( )               \ show the waiting players
  12 1+ 2 do
        i 1+
        Bottom
        i Players @ <= if  Player  else  Blank  then
        0
        DrawObj
  loop
;


: SetUp ( X Y Obj Ex )   \ set object into Field array and display it
  2over ( x y )
  swap 0 Right 1+  within
  swap 0 Height    within
  and if                 \ X,Y coordinate is on the screen
        ( X Y Obj Ex )
        2over Field ( X Y Obj Ex adr)  2 pick swap c!
        DrawObj
  else  2drop 2drop  then
;

\ -------------------------------------------------------------------------------

: StartSpider     \ start the spider off the screen
  2 Ran  2* 1-    \ randomly pick left or right direction of motion
  dup SpiBias !   \ +1 or -1
  dup 0< if  Width 2/ Right +  else  Width 2/ negate  then  to SpiX
  SpiXDir !
;

\ -------------------------------------------------------------------------------

: BumpScore ( n )      \ increment score by Points and display it
  ScoreL +!
  ScoreL @ 10000 >= if
        1      ScoreH +!
        -10000 ScoreL +!
        1 Players +!
        ShowPlayers
        2 Delay     \ pause between last score's sound and new player sound
        1 1+ 0 do
          25 191 Noise  25 143 Noise
        loop
  then
  Width 18 - Bottom at-xy  Yellow Attrib c!   ScoreH @ ScoreL @ IntoutDbl
;

\ -------------------------------------------------------------------------------

: FlashNum ( X Y N )      \ flash number of points (N) on screen
  >r
  >r  0 max  Right 2- min  r>             \ don't go off edge (spider)
  2dup at-xy  White Attrib c!  r> .

  151 100 do 3 i Ran Noise loop  6 delay  \ make splat sound

  >r dup r@ Blank 0 SetUp  \ remove anything the score may have overwritten
  dup 1+ r@ Blank 0 SetUp
      2+ r> Blank 0 SetUp
;

0 value JJ

: ScoreSeg               \ hit a segment or head
  \ find the hit segment (or head):
  Tail 1+ 0 do
    i to JJ
    ShellX i SegX @ =
    ShellY i SegY @ = and
    i Seg @  Blank <> and  if  leave  then
  loop

  jj SegX @  jj SegY @  Blank 0 SetUp              \ remove it

  jj Seg @  Head = if
        jj SegX @  jj SegXDir @ +  jj SegY @  Mush 0 SetUp
        \ (make it a mushroom shifted over one position)
  else  jj SegX @  jj SegY @  Mush 0 SetUp  then

  Blank  jj Seg !

  \ grow a new head at the next segment:
  jj Tail <  jj 1+ Seg @ Segment =  and if  Head  jj 1+ Seg !  then

  -1 SegCnt +!
;

variable Points

: ScoreHit ( )                 \ bump score if shell hit something
  0 Points !                   \ default points
  ShellX ShellY Field c@  case
    Mush    of
              51 2 do  2 i Ran Noise  loop
              ShellX ShellY Mush3 0 SetUp
            endof
    Mush3   of
              51 2 do  2 i Ran Noise  loop
              ShellX ShellY Mush2 0 SetUp
            endof
    Mush2   of
              51 2 do  2 i Ran Noise  loop
              ShellX ShellY Mush1 0 SetUp
            endof
    Mush1   of
              1 Points !
              51 2 do  2 i Ran Noise  loop
              ShellX ShellY Blank 0 SetUp
            endof
    Segment of
              10 Points !
              101 50 do  3 i Ran Noise  loop
              ScoreSeg
            endof
    Head    of
              100 Points !
              101 50 do  3 i Ran Noise  loop
              ScoreSeg
            endof
    SpiderL
    SpiderR |or|
            of
              PlayY SpiY - 1+  1 rshift  case
                1 of  900  endof
                2 of  600  endof
                      300 swap
              endcase  Points !
              SpiX SpiY Points @ FlashNum
              ShellX 1- ShellY Blank 0 SetUp   \ remove dead spider
              ShellX    ShellY Blank 0 SetUp
              ShellX 1+ ShellY Blank 0 SetUp
              StartSpider
            endof
    Flea    of
              FleaMad @ if
                      200 Points !
                      150 1+ 100 do  3 i Ran Noise  loop
                      ShellX ShellY Blank 0 SetUp
                      false FleaDrop !
              else
                      true FleaMad !
              then
            endof
  endcase
  Points @ BumpScore
;

\ -------------------------------------------------------------------------------

: KillPlayer            \ something bit the player (i.e. you're dead)
  8 1+ 0 do             \ you're dead, player (awful noise)
                        \ make sure player, and possibly spider is gone
        PlayX 1- PlayY Explo 0 SetUp
        PlayX    PlayY Explo 0 SetUp
        PlayX 1+ PlayY Explo 0 SetUp
        10 1+ 0 do  1 j 150 * Ran Noise  loop
  loop

  PlayX 1- PlayY Blank 0 SetUp     \ remove dead player from field
  PlayX    PlayY Blank 0 SetUp
  PlayX 1+ PlayY Blank 0 SetUp
  -1 Players +!                    \ one less player

  \ restore shot-up mushrooms:
  Right 1+ 0 do
    BotLimit 1+ 0 do
      j i Field c@  case
        Mush1
        Mush2 |or|
        Mush3 |or|
              of
                5 BumpScore
                j i  Mush 0 SetUp
                4 2 do  2 i Ran Noise  loop
                12 Delay
              endof
      endcase
    loop
  loop

  40 Delay                      \ pause for effect
;

\ -------------------------------------------------------------------------------

: MoveFlea                      \ move the flea
  Wave @ 0= if exit then        \ (give the guy a break to start with)

  FleaDrop @ if
        FleaY BotLimit < if
                FleaWas @  Blank = if       \ leave mushrooms in wake
                    FleaX FleaY  Height 6 / Ran if Blank else Mush then  0 SetUp
                    \ replace what the flea hopped on except if it is a moving object
                else
                          FleaWas @  case
                            Head
                            Segment |or|
                            Player  |or|
                            Shell   |or|
                            SpiderL |or|
                            SpiderR |or|
                                    of
                                      FleaX FleaY Blank 0 SetUp
                                    endof
                            FleaX FleaY FleaWas @ 0 SetUp
                          endcase
                then
                FleaY 1+ to FleaY
                FleaX FleaY Field c@  FleaWas !  \ save what the flea is on
                FleaX FleaY  Flea  FleaX Center <  SetUp

                FleaWas @  case
                    Player of  true Bitten !  endof
                    Shell  of  ScoreHit  true Armed !  endof
                endcase

                FleaMad @ if
                        5 FleaY 3 * 20 + Noise
                else
                        2 FleaY 30 * 200 + Noise
                then
        else
                false FleaDrop !           \ hit bottom
                FleaX FleaY Blank 0 SetUp  \ eradicate flea
        then
  else
        \ count the objects (mushrooms) on the bottom 5 rows
        0
        BotLimit 1+ TopLimit do
            Right 1+ 0 do
                i j Field c@  Blank <> if  1+  then
            loop
        loop

        \ if the objects (mushrooms) are less than threshold then drop the flea
        ( n)  Wave @ 2/ 5 +  < if
                true  FleaDrop !
                false FleaMad !
                Width Ran to FleaX  0 to FleaY
                FleaX FleaY Field c@  FleaWas !
        then
  then
;

\ -------------------------------------------------------------------------------

: MoveSpider             \ bounce the spider around
  SpiX to X   SpiY to Y

  X 0<=  X Right >=  or if                     \ spider enters at the top line
        SpiLimit @ to Y  SpiBias @ SpiXDir !  1 SpiYDir !
  then
                                               \ 10% of the time change horz dir
  10 Ran 0= if  3 Ran 1- SpiBias @ +  SpiXDir !  then

  SpiXDir @ 0< if
    SpiX 1- to X                               \ 1/3 of time move horizontally
  else
    SpiXDir @ 0> if  SpiX 1+ to X  then        \ 2 1 0   1 0-1   0-1-2   2 1 0
  then

  10 Ran 0= if  5 Ran 2 -  SpiYDir !  then     \ 10% of the time change vert dir

  SpiYDir @ 0<= if
        Y 1- to Y                              \ SpiYDir = -2, -1, 0, 1, or 2
  else
        SpiYDir @ 0> if  Y 1+ to Y  then
  then

  Y BotLimit > if
        BotLimit 1- to Y   SpiYDir @ negate SpiYDir !
  else
        Y SpiLimit @ <  if
          SpiLimit @ 1+ to Y  1 SpiYDir !
        then
  then

  \ erase what the spider was on
  \ (spider eats mushrooms; moving objects restore themselves)
  SpiX    SpiY  Blank 0 SetUp
  SpiX 1+ SpiY  Blank 0 SetUp

  X to SpiX  Y to SpiY                          \ actually move spider

  SpiX    SpiY SpiderL SpiYDir @ 0<=  SetUp
  SpiX 1+ SpiY SpiderR SpiYDir @ 0<=  SetUp

  SpiX 1+ 0>=  SpiX Right <=  and if
        2  SpiY SpiLimit @ - 10 *  100 +  Noise
  then

  SpiY PlayY = if
    SpiX PlayX =  SpiX 1+ PlayX =  or if  true Bitten !  then
  then

  \ if spider went 1/2 way off the screen then reverse its direction
  SpiX  Right Width 2/ +  > if
        -1 SpiBias !
  else
        SpiX  Width 2/ negate  <  if  1 SpiBias !  then
  then
;


\ -------------------------------------------------------------------------------

0 value Zombie

: InjectHead             \ inject a new head at bottom to prevent boredom
  FullMoon @ HeadTime > if             \ the zombies emerge
    \ if a head reached the bottom (and is going back up) then inject a head.
    Tail 0 do
        i SegYDir @  0<
        i Seg @  Blank <>  and if  true HitBottom !  then
    loop

    -1 to Zombie                        \ start with no dead bodies

    HitBottom @ if
        Tail 0 do                       \ find a dead segment to revive
            i Seg @ Blank = if  i to Zombie  then
        loop
    then

    Zombie 0>= if                       \ we found a live one (sort of)
        Head Zombie Seg !
        2 Ran if  1  else  -1  then  Zombie SegXDir !
        1 Zombie SegYDir !
        Zombie SegXDir @  1 =  if  0  else  Right  then  Zombie SegX !
        TopLimit 1-  Zombie SegY !
        1 SegCnt +!                     \ the zombie flesh lives...
    then

    0 FullMoon !                        \ now for a period of darkness
  else
    1 FullMoon +!
  then
;

\ -------------------------------------------------------------------------------

: Turn ( i )          \ turn the segment down (or up) and around
  \ move the segment down (or up) one row and reverse horizontal direction
  Y0 over SegYDir @ +  to Y1                 \ make tenative vertical move
  Y1 BotLimit > if
    -1 over SegYDir !                        \ if too far then reverse dir
  else
    Y1 TopLimit < if  1 over SegYDir !  then
  then
  Y0 over SegYDir @ +  over SegY !           \ make actual vertical move
  ( i ) SegXDir  dup @ negate swap !
;

: MoveCent               \ move centipede
  Tail 1+ 0 do
    i Seg @  Blank <> if                        \ don't move dead segments
        i SegX @ to X0   i SegY @ to Y0         \ get initial position
        X0 i SegXDir @ +  to X1                 \ make tenative horizontal move

        X1 0< if                                \ if screen limit then turn
          i Turn
        else
          X1 Right > if
            i Turn
          else
            X1 Y0 Field c@  case                \ bounce segment off mushrooms
              Blank
              Player   |or|
              Shell    |or|
              SpiderL  |or|
              SpiderR  |or|
              Flea     |or|
                of  X1 i SegX !  endof          \ and other segments
                i Turn
            endcase
          then
        then
        X0 Y0 Blank 0 SetUp                     \ remove segment from old location
        i SegX @  i SegY @  i Seg @  i SegXDir @ 0< SetUp  \ & display it in new loc

        i SegX @  PlayX =   i SegY @  PlayY =  and if
          true Bitten !
        then
    then
  loop
;

\ -------------------------------------------------------------------------------

: MoveShell ( )               \ move the shell if it has been fired
  Armed @ if
        GetMouseButton if                       \ fire!
                PlayX to ShellX   PlayY 1- to ShellY
                false Armed !
                ShellX ShellY Field c@  Blank <> if
                        ScoreHit  true Armed !
                else
                        ShellX ShellY Shell 0 SetUp
                then
        then
  else
                                                \ shell is in the air
        ScoreHit                                \ did something move into shell?
        ShellX ShellY Blank 0 SetUp             \ remove shell from old location
        ShellY 1 < if
                true Armed !                    \ off top of screen--missed
        else
                ShellY 1- to ShellY             \ move shell up
                ShellX ShellY Field c@  Blank <> if    \ hit something
                        ScoreHit   true Armed !
                else
                        ShellX ShellY Shell 0 SetUp
                then
        then
  then
;

\ -------------------------------------------------------------------------------

0 value S

: MovePlayer                                \ move the player
  Bitten @ if exit then                     \ don't move bitten player

  \ make tenative move of one character cell toward mouse pointer:
  0 GetMousePosition  Width 640 */  ( MX)   \ (0 thru Width-1)

  PlayX ( x )                               \ make tenative move toward mouse
  over PlayX >  PlayX Right <  and if  1+  then
  swap PlayX <  PlayX 0>       and if  1-  then  to X

  1 GetMousePosition  5 200 */  TopLimit +  ( MY)   \ (0 thru 4)

  PlayY ( y )                               \ BotLimit-TopLimit+1 = 5
  over PlayY >  PlayY BotLimit <  and if  1+  then
  swap PlayY <  PlayY TopLimit >  and if  1-  then  to Y

  X Y Field c@ to S                         \ get contents of target location

  S Head =  S Segment = or  S SpiderL = or  S SpiderR = or  S Flea = or
  if  true Bitten !  then

  S Mush <>  S Mush1 <> and  S Mush2 <> and  S Mush3 <> and if
        \ don't move over mushrooms
        PlayX PlayY Blank 0 SetUp       \ remove player from old position
        X  Y  Player 0 SetUp            \ display player in new position
        X to PlayX  Y to PlayY          \ save player's coordinates
  else
        PlayX 16 *  PlayY TopLimit - 40 *  MoveMouse
  \ move mouse position to X,Y to remove springiness (assumes Bottom = Height-1)
  then
;

\ -------------------------------------------------------------------------------

\ initialize centipede segment arrays:     Table(ModWave, Segment)
\ (assumes Length = 12 and Width = 40)
\               Segment (incl. head) -->                      ModWave

create (SegXTbl)
  28 , 29 , 30 , 31 , 32 , 33 , 34 , 35 , 36 , 37 , 38 , 39 ,
  27 , 10 ,  9 ,  8 ,  7 ,  6 ,  5 ,  4 ,  3 ,  2 ,  1 ,  0 ,
  10 , 18 , 30 , 31 , 32 , 33 , 34 , 35 , 36 , 37 , 38 , 39 ,
  35 , 24 , 12 ,  8 ,  7 ,  6 ,  5 ,  4 ,  3 ,  2 ,  1 ,  0 ,
   8 , 17 , 24 , 29 , 32 , 33 , 34 , 35 , 36 , 37 , 38 , 39 ,
  34 , 27 , 20 , 14 ,  9 ,  6 ,  5 ,  4 ,  3 ,  2 ,  1 ,  0 ,
   5 , 12 , 19 , 24 , 27 , 32 , 34 , 35 , 36 , 37 , 38 , 39 ,
  34 , 28 , 23 , 18 , 15 , 10 ,  7 ,  4 ,  3 ,  2 ,  1 ,  0 ,
   0 ,  5 , 10 , 15 , 20 , 24 , 28 , 32 , 36 , 37 , 38 , 39 ,
  37 , 32 , 27 , 23 , 19 , 15 , 11 ,  8 ,  5 ,  2 ,  1 ,  0 ,
   0 ,  4 ,  8 , 11 , 14 , 17 , 22 , 27 , 30 , 34 , 38 , 39 ,
  39 , 34 , 30 , 27 , 24 , 20 , 18 , 14 , 10 ,  7 ,  3 ,  0 ,

: SegXTbl ( ModWave index -- n )
  swap 12 * + cells (SegXTbl) + @ ;

create (SegXDirTbl)
  -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 ,
  -1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,
  -1 ,  1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 ,
  -1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,
   1 , -1 , -1 ,  1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 ,
   1 ,  1 , -1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,  1 ,
   1 , -1 ,  1 , -1 ,  1 , -1 , -1 , -1 , -1 , -1 , -1 , -1 ,
   1 , -1 , -1 ,  1 ,  1 ,  1 , -1 , -1 ,  1 ,  1 ,  1 ,  1 ,
   1 ,  1 ,  1 , -1 , -1 , -1 ,  1 , -1 , -1 , -1 , -1 , -1 ,
   1 ,  1 ,  1 ,  1 , -1 ,  1 ,  1 , -1 , -1 ,  1 ,  1 ,  1 ,
   1 ,  1 , -1 , -1 , -1 ,  1 ,  1 ,  1 , -1 ,  1 , -1 , -1 ,
  -1 , -1 , -1 , -1 , -1 , -1 , -1 ,  1 ,  1 ,  1 ,  1 ,  1 ,

: SegXDirTbl ( ModWave index -- n )
  swap 12 * + cells (SegXDirTbl) + @ ;

\ ModWave   wave number, modulo 12 (0..11)

: LoopUntilDead                   \ loop until centipede is dead
  begin
          SpiLimIni ScoreH @ +  TopLimit min  SpiLimit !

                                  \ speed up game as score increases
          SpeedIni ScoreH @ -  SpeedMax max  II !

          II @ 1+  0 do
                                  \ this loop is run 60 times per second
                  1 Delay         \ it's the surrounding loop that varies
                  MovePlayer      \ in speed according to ScoreH
                  MoveShell

                  Bitten @ if  KillPlayer  unloop exit  then

                  SegCnt @ 0<= if
                           1 Wave +!  CycleColors  unloop exit
                  then

                  i II @ 2/ = if
                          SegCnt  @ 1 = if  MoveCent    then
                          FleaMad @     if  MoveFlea    then
                          ScoreH  @     if  MoveSpider  then
                  then
          loop

          MoveCent
          InjectHead
          MoveSpider
          MoveFlea
  again
;

: PlayRound              \ play one round (until player is bitten & dies)
                         \ makes some things happen faster than others
  ShowPlayers                                   \ show remaining players

  Center to PlayX  BotLimit to PlayY            \ set up player
  PlayX 16 *  PlayY TopLimit -  40 *  MoveMouse
  \ move mouse position to remove springiness (assumes Bottom = Height-1)

  PlayX PlayY Player 0 SetUp
  false Bitten !
  true Armed !

  StartSpider
  SpiLimIni SpiLimit !

  false FleaDrop !                              \ don't drop flea yet

  begin                                         \ repeat until player is bitten
        0 Bottom at-xy  Yellow Attrib c!  Wave @ 1+ .

        \ hatch centipede
        Wave @  12 mod  ( ModWave )
        Tail 1+ 0 do
                dup i SegXTbl     i SegX !
                            0     i SegY !      \ top row
                dup i SegXDirTbl  i SegXDir !
                            1     i SegYDir !   \ move downward
                i over  <= if  Head  else  Segment  then  i Seg !
        loop drop

        Tail 1+ 0 do
                i SegX @  i SegY @  i Seg @  i SegXDir @ 0<  SetUp
        loop

        Length SegCnt !
        false HitBottom !
        0 FullMoon !

        LoopUntilDead

  Bitten @ until

  \ clean up the carnage:
  Tail 1+ 0 do                                  \ remove centipede
    i Seg @ Blank <> if
        i SegX @  i SegY @  Blank 0 SetUp
    then
  loop

  Armed @ not if                                \ remove shell from flight
          ShellX ShellY Blank 0 SetUp
  then

  FleaDrop @ if                                 \ remove flea
          FleaX FleaY Blank 0 SetUp
  then

  SpiX    SpiY Blank 0 SetUp                    \ remove spider
  SpiX 1+ SpiY Blank 0 SetUp

  PlayX PlayY Blank 0 SetUp                     \ remove player
;

\ -------------------------------------------------------------------------------

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
  s" PEDE.BMP" r/w open-file if ( err)
        3 SetVid
           ." PEDE.BMP file not found."
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
  8 0 do  8 i *  0 8 8  i 0 SpSeg  LoadSp  loop
  8 0 do  8 i *  8 8 8  i 0 SpHead LoadSp  loop

  32 24 8 8 SpBlank  LoadSp
   0 16 8 8 SpPlay   LoadSp
   8 16 8 8 SpShell  LoadSp
   0 24 8 8 SpMush   LoadSp
   8 24 8 8 SpMush3  LoadSp
  16 24 8 8 SpMush2  LoadSp
  24 24 8 8 SpMush1  LoadSp
   0 32 8 8 SpSpiL0  LoadSp
   8 32 8 8 SpSpiR0  LoadSp
  16 32 8 8 SpSpiL1  LoadSp
  24 32 8 8 SpSpiR1  LoadSp
   0 40 8 8 SpFlea0  LoadSp
   8 40 8 8 SpFlea1  LoadSp
   0 48 8 8 SpExplo0 LoadSp
   8 48 8 8 SpExplo1 LoadSp
;

\ -------------------------------------------------------------------------------

: PlayGame               \ play one game (until all players die)
  LoadSprites            \ load sprites and set up color registers

  \ show introductory screen:
  Clear
  Center 15 - to X   Height 2/ 9 - to Y
  Yellow Attrib c!
  Center 16 -  Y 8  + at-xy  ."  New player every 10000 points "
  LRed Attrib c!
  Center 16 -  Y 11 + at-xy  ."      Hit Esc to exit game      "
  LCyan Attrib c!
  Center 16 -  Y 13 + at-xy  ."      S key controls sound      "
  LGreen Attrib c!
  Center 16 -  Y 15 + at-xy  ."      Click mouse to start      "

  \ show results of previous game:
  5          Bottom 1- at-xy  White  Attrib c!  ." Wave"
  5          Bottom    at-xy  Yellow Attrib c!  Wave @ 1+ .
  Width 23 - Bottom 1- at-xy  White  Attrib c!  ." Score "
  Width 23 - Bottom    at-xy  Yellow Attrib c!  ScoreH @ ScoreL @ IntoutDbl
  Width 10 - Bottom 1- at-xy  White  Attrib c!  ." High "
  Width 10 - Bottom    at-xy  Yellow Attrib c!  HiScoreH @ HiScoreL @ IntoutDbl

  begin                   \ wiggle the cute little centipede feet

        12 1+  0 do  X i +  Y  Segment 0 DrawObj  loop
        X 13 +  Y Head 0 DrawObj
        X 15 +  Y Head 1 DrawObj
        28 1+ 16 do  X i +  Y  Segment 1 DrawObj  loop

        X       Y 1+  Segment 0 DrawObj
        X 28 +  Y 1+  Segment 1 DrawObj
        X       Y 2+  Segment 0 DrawObj

        X 1+    Y 2+ at-xy  BWhite Attrib c!
        ."   P E D E I C I D E   1.0  "

        X 28 +  Y 2+  Segment 1 DrawObj
        X       Y 3 + Segment 0 DrawObj
        X 28 +  Y 3 + Segment 1 DrawObj

        13 1+  0 do  X i +  Y 4 + Segment 0 DrawObj  loop
        28 1+ 14 do  X i +  Y 4 + Segment 1 DrawObj  loop

        0 ( exit flag)

        9 1+ 0 do
                1 Delay
                GetMouseButton if invert leave then  \ click mouse...
        loop
  until

  \ unveil screen full of mushooms:
  BotLimit 0 do
    Width 0 do
        i j  Width BotLimit * Ran  MushIni > if Blank else Mush then 0 SetUp
    loop
    2 Delay
  loop

  Width 0 do
    i BotLimit Blank 0 SetUp
  loop

  0 Wave !
  0 ScoreL !  0 ScoreH !
  PlayIni Players !

  ShowPlayers                                  \ show the waiting players

  \ show the score:
  Width 24 - Bottom at-xy  White Attrib c!  ." Score "
  Yellow Attrib c!  ScoreH @ ScoreL @ IntoutDbl
  Width 11 - Bottom at-xy  White Attrib c!  ." High "
  Yellow Attrib c!  HiScoreH @ HiScoreL @ IntoutDbl

  begin  Players @ 0>  while  PlayRound  repeat

  ScoreH @ HiScoreH @ >
  ScoreH @ HiScoreH @ =   ScoreL @ HiScoreL @ >  and
  or if
    ScoreL @ HiScoreL !  ScoreH @  HiScoreH !
  then

  12 1+ 1 do 9 19 i * 227 + Noise loop  \ depressing sound--you lose!
  60 Delay

  begin  GetMouseButton not  until      \ wait until buttons are released
;

\ ===============================================================================

\ Main
: Main
  -1 Ran drop			\ randomize
  OpenMouse not abort" This program requires a mouse."

\  $A000 to Screen
  $13 SetVid                    \ 40x25 text mode

\ The system timer (timer 0) is normally set to mode 3, as defined by IBM.
\ Some BIOSes, Win3.1 and WinXP have a bug that instead sets this timer to
\ mode 2. This does not change the interrupt rate, but it does change the
\ rate that the internal counter decrements. Mode 3 decrements by 2, and
\ mode 2 decrements by 1. Since the internal counter is read by this code,
\ it is essential that the rate be correct. Of course WinXP (in its infinite
\ wisdom) does not allow reprogramming the mode, so the non-standard (but
\ more logical) mode 2 is used here.

  $34 $43 pc!   \ timer 0 mode 2
  $FF $40 pc!   \ set 16-bit countdown timer to maximum count
  $FF $40 pc!   \ (low byte first)

  true Vol !
  0 Wave !                      \ (PlayGame shows these initial values)
  0 ScoreL !  0 ScoreH !
  0 HiScoreL !  0 HiScoreH !

  begin
    PlayGame                    \ (Esc key exits program)
  again
;


CR .( Save to disk? ) y/n
[if]  turnkey Main PEDE  [then]


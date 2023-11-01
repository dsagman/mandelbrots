\ PI.F
\
\ Revised 2015-02-09  es
\
\ Compute Pi to an arbitrary precision. Uses Machin's
\ formula:  pi/4 = 4 arctan(1/5) - arctan(1/239)
\
\ Compile with 16-bit DX-Forth: FORTH - INCLUDE PI.F BYE
\
\ This 16-bit implementation allows up to 45,808 digits
\ to be computed before arithmetic overflow occurs.
\
\ The code can be used on 32-bit targets with appropriate
\ changes:
\
\   16-bit             32-bit
\
\   10000 Multiply     100000000 Multiply
\   <# # # # # #>      <# # # # # # # # # #>
\   4 +loop            8 +loop
\   525 um/mod         1050 um/mod
\                      remove 'digits > 45808' warning
\
\ Acknowledgements:
\
\   Roy Williams, Feb 1994
\   J. W. Stumpel, May 1991
\   E. Ford, Aug 2009
\   R. Bishop, Aug 1978
\
\ This code is PUBLIC DOMAIN. Use at your own risk.

empty forth definitions decimal application

1 constant Save  \ generate turnkey

0 value power  ( adr)
0 value term   ( adr)
0 value result ( adr)
0 value size   ( n)

variable carry

: Add ( -- )
  0 carry !
  result   0 size 1- do
    i cells over + ( res) dup @ 0
    i cells term + @ 0  d+  carry @ m+
    ( hi) carry !  ( lo) swap ( res) !
  -1 +loop  drop ;

: Subtract ( -- )
  0 carry !
  result   0 size 1- do
    i cells over + ( res) dup @ 0
    i cells term + @ 0  d-  carry @ m+
    ( hi) carry !  ( lo) swap ( res) !
  -1 +loop  drop ;

0 value factor

\ scan forward for cell containing non-zero
: +index ( adr -- adr index )
  -1 begin 1+ dup size - while 2dup cells + @ until then ;

: Divide ( adr factor -- )
  to factor   0 carry !  +index
  ( adr index )  size swap ?do
    i cells over + ( res)
    dup @  carry @  factor  um/mod
    ( quot) rot ( res) !  ( rem) carry !
  loop  drop ;

\ scan backward for cell containing non-zero
: -index ( adr -- adr index )
  size begin 1- dup while 2dup cells + @ until then ;

: Multiply ( adr factor -- )
  to factor   0 carry !  -index
  ( adr index )  0 swap do
    i cells over + ( res)
    dup @  factor  um*  carry @ m+
    ( hi) carry !  ( lo) swap ( res) !
  -1 +loop  drop ;

: Copy ( -- )
  power term size cells cmove ;

\ : Zero? ( result -- f )
\  +index nip size = ;

: Zero? ( result -- f )
  size cells 0 skip nip 0= ;

0 value pass
variable exp
variable sign

: Divisor ( -- n )
  pass 1 = if  5  else  239  then ;

: Initialize ( -- )
  power size cells erase
  term  size cells erase
  pass 1 = if  result size cells erase  then
  16  pass dup * / power !
  power  divisor  Divide
  1 exp !  pass 1- sign ! ;

0 value ndigit

: CalcPi ( -- )
  ndigit 45800 u> if
    ." Warning: digits > 45808 will be in error " cr
  then

  2 1+ 1 do
    i to pass
    Initialize
    begin
      Copy
      term  exp @ Divide
      sign @  dup if  Subtract  else  Add  then
      0= sign !  2 exp +!
      power  divisor dup *  Divide
      power zero?
    until
  loop ;

variable out
: cr  cr  0 out ! ;
: #  #  1 out +! ;

: Print ( -- )
  result  dup @ 0 .r  [char] . emit  cr
  ndigit 0 ?do
    0 over !
    dup 10000 Multiply
    dup @  0 <# # # # # #> type
    out @ 63 > if cr then
    4 +loop
  drop  cr ;

: Number ( adr len -- n )
  0 0 2swap >number 2drop drop ;

save [if]

: GetNumber ( -- n )
  cmdtail number dup 0= abort" Usage: PI #digits" ;

[else]

: GetNumber ( -- n )
  cr ." How many digits do you want? "
  pad dup 20 accept number dup 0= abort" Invalid" cr ;

[then]

: main ( -- )
  dos-io ( allow output redirect )
  getnumber  dup to ndigit

  \ array size = ceil(ndigit / log10(2^16))
  109 um* 525 um/mod swap ( rem) if  1+  then
  ( extra for accurate last digits)
  2 +  to size

  \ create arrays
  here to power   size cells allot
  here to term    size cells allot
  here to result  size cells allot

  calcpi
  print ;

save [if]

  turnkey main pi

[else]

  cr .( Type MAIN to begin ) cr

[then]

\ end

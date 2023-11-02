REM For quick basic
DEFINT A-B, K, M-N

SCREEN 9: CLS
s = TIMER
PRINT "start =", s

a = 640: b = 350
bk = 100
rmin = -.74612: rmax = -.74427
imin = .11196: imax = .11339
dp = (rmax - rmin) / (a - 1)
dq = (imax - imin) / (b - 1)
m = 200
FOR y = 0 TO b - 1
  FOR x = 0 TO a - 1
    cr = rmin + (x * dp)
    ci = imin + (y * dq)
    k = 0: xr = 0: xi = 0
    DO
        rk = xr * xr - xi * xi + cr
        ik = 2 * xr * xi + ci
        xr = rk: xi = ik
        k = k + 1
    LOOP UNTIL k = m OR xr * xr + xi * xi > 4
    PSET (x, y), k MOD 8
  NEXT x
NEXT y

e = TIMER
PRINT "end =", e
PRINT "total =", e - s


                      


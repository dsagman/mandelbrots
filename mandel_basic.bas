Dim As Double Start
Start = Timer

Dim As Integer M, K, X, Y
Dim As Double CR, CI, XR, XI, RK, IK
Dim As Double P0, Q0, DP, DQ, XK, YK
Const ZOOM As Double = 2000.0

Const CDepth As UInteger = 8
Const Colors As UInteger = 8192

Const RMIN = -0.74612
Const RMAX = -0.74427
Const IMIN = 0.11196
Const IMAX = 0.11339
' Const RMIN = -2.25
' Const RMAX = .75
' Const IMIN = -1.5
' Const IMAX = 1.5
Const W  = 640
Const H  = 350

M = 1000
ScreenRes W, H, CDepth
open cons for output as #1 
WindowTitle "Mandelbrot Set"

DP = (RMAX - RMIN) / W
DQ = (IMAX - IMIN) / H
For Y As UInteger = 0 to H-1
    For X as UInteger = 0 to W-1
        CR = RMIN+X*DP
        CI = IMIN+Y*DQ
        K=0: XR=0: XI=0
        Do
            RK=XR*XR-XI*XI+CR
            IK=2*XR*XI+CI
            XR=RK: XI=IK
            K=K+1
        Loop Until K=M Or XR*XR+XI*XI>4
        PSet (X,Y), K mod Colors
    Next X
Next Y
Print #1, "Total time ="; Timer - Start
Sleep
End

' using Pmap causes some weird vertical lines
' Window Screen (RMIN, IMIN)-(RMAX, IMAX)
' For Y = 0 to H-1
'     For X = 0 to W-1
'         CR = Pmap(X,2)
'         CI = Pmap(Y,3)
'         K=0: XR=0: XI=0
'         Do
'             RK=XR*XR-XI*XI+CR
'             IK=2*XR*XI+CI
'             XR=RK: XI=IK
'             K=K+1
'         Loop Until K=M Or XR*XR+XI*XI>1000
'         PSet (CR,CI), K mod Colors
'     Next X
' Next Y

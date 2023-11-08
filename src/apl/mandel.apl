⍝ Define the size of the image and other constants
a ← 640 ⋄ b ← 350
rmin ← ¯0.74612 ⋄ rmax ← ¯0.74427
imin ← 0.11196 ⋄ imax ← 0.11339
m ← 200
bk ← 100

⍝ Calculate the increments
dp ← (rmax - rmin) ÷ (a - 1)
dq ← (imax - imin) ÷ (b - 1)

⍝ Generate complex numbers for each point in the image
cr ← rmin + (⍳a-1) × dp
ci ← imin + (⍳b-1) × dq
C ← cr∘.+ci×0J1

⍝ Mandelbrot iteration
Mandelbrot ← {
    k ← 0 ⋄ z ← 0
    {k < m} ⍣ (⍺⍺) {(k←k+1) ⋄ (z ← (z×z) + ⍵) ⋄ (z ∘.× z) ≤ 4}¨ ⍵
    k
}

⍝ Apply the Mandelbrot function to each element of the complex array
Start ← ⎕AI[3] ⍝ Get the start time
P ← Mandelbrot C
End ← ⎕AI[3] ⍝ Get the end time

⍝ Print the timing information
'Start = ',⍕Start
'End = ',⍕End
'Total = ',⍕End-Start

⍝ Display the result - for this we would need a graphical representation,
⍝ which is not directly supported in the APL console.
⍝ In a real application, we would render this into a graphical window.


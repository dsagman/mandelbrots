-- Adapted from https://github.com/alexbooth/fraskell/blob/master/fract.hs

import Codec.Picture
import Codec.Picture.Types
import System.Environment

main :: IO ()
main = do
    putStrLn "Beginning rendering of image."
    savePngImage "haskell.png" generateFractal
    putStrLn "Completed"

width :: Int
width = 640

height :: Int
height = 350

rmin = -0.74612
rmax = -0.74427
imin = 0.11196
imax = 0.11339

-- rmin = -2.5
-- rmax = 1.0
-- imin = -1.0
-- imax = 1.0

generateFractal :: DynamicImage
generateFractal = ImageRGB8 $ generateImage mandelbrot width height

iters :: Int
iters = 200

mandelbrot :: Int -> Int -> PixelRGB8
-- mandelbrot x0 y0 = getColor 0 0 0
mandelbrot x0 y0 = getColor (scaleX x0) (scaleY y0) 0
    where getColor :: Float -> Float -> Int -> PixelRGB8
          getColor x y i 
            | i >= iters = PixelRGB8 0 0 0
            | x*x + y*y < 2*2 = getColor (x*x - y*y + scaleX x0) (2*x*y + scaleY y0) (i+1)
            | otherwise = calcColor i 
            
            
            


-- https://iquilezles.org/articles/palettes/
-- color(t) = a + b ⋅ cos[ 2π(c⋅t+d)]
calcColor :: Int -> PixelRGB8
calcColor i = 
     let t = fromIntegral i / fromIntegral iters
         (a1, a2, a3) = (0.5, 0.5, 0.5)
         (b1, b2, b3) = (0.5, 0.5, 0.5)
         (c1, c2, c3) = (2.5, 2.5, 2.5)
         (d1, d2, d3) = (0.0, 0.33, 0.67)
         r = round (255 * (a1 + b1 * cos (2 * pi * (c1 * t + d1))))
         g = round (255 * (a2 + b2 * cos (2 * pi * (c2 * t + d2))))
         b = round (255 * (a3 + b3 * cos (2 * pi * (c3 * t + d3))))
    in PixelRGB8 r g b
         

scaleX :: Integral a => a -> Float
scaleX x = rmin + fromIntegral x * (rmax - rmin) / fromIntegral width 

scaleY :: Integral a => a -> Float
scaleY y = imin + fromIntegral y * (imax - imin) / fromIntegral height

import matplotlib.pyplot as plt
import numpy as np
import time

def calculate_color(iteration, max_iter):
    """
    Calculate the color based on the number of iterations.
    Colors are represented as triples containing the RGB values.
    """
    if iteration < max_iter:
        r = iteration % 256
        g = (iteration * iteration) % 256  # Squaring iteration can lead to interesting color patterns
        b = (iteration * 2) % 256
    else:
        r, g, b = 0, 0, 0  # Black color
    
    return (r, g, b)

# Set up the dimensions and scale of the plot
a, b = 640, 350
rmin, rmax = -0.74612, -0.74427
imin, imax = 0.11196, 0.11339
dp = (rmax - rmin) / (a - 1)
dq = (imax - imin) / (b - 1)

# Maximum number of iterations for Mandelbrot "escaping"
m = 200

# Start the timer
s = time.time()
print("start =", s)

# Create an image with RGB color model
mandelbrot_image = np.zeros((b, a, 3), dtype=int)

for y in range(b):
    for x in range(a):
        cr = rmin + (x * dp)
        ci = imin + (y * dq)
        k = 0
        xr, xi = 0.0, 0.0

        while k < m and (xr * xr + xi * xi) <= 4:
            xr, xi = xr * xr - xi * xi + cr, 2 * xr * xi + ci
            k += 1
        
        # Calculate the color based on iterations
        mandelbrot_image[y, x] = calculate_color(k, m)

# End timer
e = time.time()
print("end =", e)
print("total =", e - s)

# Displaying the Mandelbrot set
plt.imshow(mandelbrot_image)
plt.axis('off')  # Turn off the axis
plt.show()


import numpy as np
import matplotlib.pyplot as plt
from multiprocessing import Pool, cpu_count
import time
from functools import partial

def calculate_color(iteration, max_iter):
    if iteration < max_iter:
        return iteration % 256, (iteration * iteration) % 256, (iteration * 2) % 256
    else:
        return 0, 0, 0  # Black color

def mandelbrot_calc_row(y, width, height, rmin, rmax, imin, imax, max_iter):
    row = np.zeros((width, 3), dtype=int)
    imaginary = imin + (y * (imax - imin) / (height - 1))

    for x in range(width):
        real = rmin + (x * (rmax - rmin) / (width - 1))
        c = complex(real, imaginary)
        z = 0j
        for n in range(max_iter):
            z = z * z + c
            if abs(z) > 2:
                row[x] = calculate_color(n, max_iter)
                break

    return row

def mandelbrot_set(width, height, rmin, rmax, imin, imax, max_iter):
    pool = Pool(processes=cpu_count())  # Create a pool of processes. By default, one is created for each CPU in your machine.
    partial_calc_row = partial(mandelbrot_calc_row, width=width, height=height, rmin=rmin, rmax=rmax, imin=imin, imax=imax, max_iter=max_iter)

    # Distribute the calculation across the process pool, and concatenate the results as they come in
    mandelbrot_image = np.array(pool.map(partial_calc_row, range(height)))
    pool.close()
    pool.join()
    return mandelbrot_image

if __name__ == "__main__":
    # Image size (pixels)
    WIDTH = 640
    HEIGHT = 350

    # Plot window
    RE_START = -0.74612
    RE_END = -0.74427
    IM_START = 0.11196
    IM_END = 0.11339

    # Maximum number of iterations
    MAX_ITER = 200

    # Start timer
    start_time = time.time()
    print("Starting computations")

    # Calculate and plot the Mandelbrot set
    mandelbrot_image = mandelbrot_set(WIDTH, HEIGHT, RE_START, RE_END, IM_START, IM_END, MAX_ITER)
    end_time = time.time()
    
    # Print computation time
    print("Computation time: ", end_time - start_time, "seconds")

    # Show the generated image
    plt.imshow(mandelbrot_image)
    plt.axis('off')
    plt.show()


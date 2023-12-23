from PIL import Image
import time

def calculate_color(iteration, max_iter):
    if iteration < max_iter:
        return (iteration % 256, (iteration * iteration) % 256, (iteration * 2) % 256)
    else:
        return (0, 0, 0)  # Black color

def mandelbrot_calc_set(width, height, rmin, rmax, imin, imax, max_iter):
    mandelbrot_set = []
    for y in range(height):
        row = []
        for x in range(width):
            z = complex(0, 0)
            c = complex(rmin + (x / width) * (rmax - rmin), imin + (y / height) * (imax - imin))
            iteration = 0

            while abs(z) < 2 and iteration < max_iter:
                z = z * z + c
                iteration += 1

            color = calculate_color(iteration, max_iter)
            row.append(color)
        mandelbrot_set.append(row)
    return mandelbrot_set

def main():
    # Image size
    WIDTH = 640
    HEIGHT = 350

    # Bounds for the Mandelbrot set
    RE_START = -0.74612
    RE_END = -0.74427
    IM_START = 0.11196
    IM_END = 0.11339

    # Max iterations
    MAX_ITER = 10000

    print("Starting calculations...")
    start_time = time.time()

    # Generate Mandelbrot set
    mandel_set = mandelbrot_calc_set(WIDTH, HEIGHT, RE_START, RE_END, IM_START, IM_END, MAX_ITER)

    # Create an image from the generated set
    img = Image.new('RGB', (WIDTH, HEIGHT))
    pixels = img.load()

    for y, row in enumerate(mandel_set):
        for x, color in enumerate(row):
            pixels[x, y] = color

    end_time = time.time()
    print(f"Image saved as 'mandelbrot_pypy.png' (Calculation time: {end_time - start_time:.2f} seconds)")
    
    img.save('mandelbrot_pypy.png')


if __name__ == "__main__":
    main()

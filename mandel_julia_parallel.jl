using Plots
using Colors  # Needed for the color conversions
using Dates   # Needed for the timing

# Function to calculate color based on the number of iterations
function calculate_color(iteration, max_iter)
    if iteration == max_iter
        return RGB(0, 0, 0)  # Black color for points inside the Mandelbrot set
    else
        # Generate color based on the number of iterations. This is a simple gradient; customize as needed.
        return RGB(0.5 + 0.5*cos(3.32 + iteration*0.15), 0.5 + 0.5*cos(0.8 + iteration*0.8), 0.5 + 0.5*cos(4.5 + iteration*0.1))
    end
end

function mandelbrot_set(width, height, rmin, rmax, imin, imax, max_iter)
    img = zeros(height, width)  # Array to store pixel intensity

    # The @threads macro indicates Julia should run the loop in parallel
    Threads.@threads for y in 1:height
        for x in 1:width
            z = 0
            c = complex(rmin + (x / width) * (rmax - rmin), imin + (y / height) * (imax - imin))
            iteration = 0

            while abs(z) < 2 && iteration < max_iter
                z = z^2 + c
                iteration += 1
            end

            # Normalize the iteration count to range from 0 to 1
            img[y, x] = iteration == max_iter ? 0 : iteration / max_iter  # This will be used as intensity for the heatmap
        end
    end

    return img
end

# Main function to execute
function main()
    # Image size and parameters
    width = 640
    height = 350
    rmin = -.74612
    rmax = -.74427
    imin = .11196
    imax = .11339
    # rmin = -2.0
    # rmax = 1.0
    # imin = -1.0
    # imax = 1.0
    max_iter = 200

    # Record the start time
    start_time = time()  # Using time() to get the current time in seconds

    # Generate the Mandelbrot set
    println("Calculating the Mandelbrot set...")
    img = mandelbrot_set(width, height, rmin, rmax, imin, imax, max_iter)

    # Calculate and print the elapsed time
    elapsed_time = time() - start_time
    println("Calculation completed in: ", elapsed_time, " seconds.")

    # Create a heatmap from the img matrix and display it
    # Note: we are using the heatmap function here to display the image matrix directly
    mandelbrot_plot = heatmap(img, color=:inferno, cbar=false, axis=false)  # using the heatmap function for image data

    println("Displaying the image...")
    display(mandelbrot_plot)

    # If you want to keep the script from exiting
    println("Press Enter to exit...")
    readline()  # This will wait for the user input before the script terminates
end

# Execute the main function
main()
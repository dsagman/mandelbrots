extern crate minifb;
extern crate rayon;

use minifb::{Key, Window, WindowOptions};
use std::time::Instant;
use rayon::prelude::*;

const WIDTH: usize = 640;
const HEIGHT: usize = 350;
const MAX_ITER: u32 = 200;

/// Calculate color based on the number of iterations.
/// Returns a tuple (r, g, b).
fn calculate_color(iteration: u32) -> (u32, u32, u32) {
    if iteration < 256 {
        // Simple coloring based on iteration count
        let r = iteration % 256;
        let g = (iteration * iteration) % 256; // Squaring iteration can lead to interesting color patterns
        let b = (iteration * 2) % 256;
        (r, g, b)
    } else {
        (0, 0, 0) // Black color
    }
}

fn main() {
    let mut buffer: Vec<u32> = vec![0; WIDTH * HEIGHT];

    let mut window = Window::new(
        "Mandelbrot Set",
        WIDTH,
        HEIGHT,
        WindowOptions::default(),
    )
    .unwrap_or_else(|e| {
        panic!("{}", e);
    });

    println!("Mandelbrot Set");

    let start = Instant::now();

    // Mandelbrot set parameters
    let (rmin, rmax, imin, imax) = (-0.74612, -0.74427, 0.11196, 0.11339);
    let (w, h) = (WIDTH, HEIGHT);
    let (zoom_x, zoom_y) = ((rmax - rmin) / w as f64, (imax - imin) / h as f64);

    buffer.par_chunks_mut(WIDTH).enumerate().for_each(|(y, row)| {
        for x in 0..WIDTH {
            let cr = rmin + x as f64 * zoom_x;
            let ci = imin + y as f64 * zoom_y;
            let (mut zr, mut zi, mut n) = (0.0, 0.0, 0u32);
            while zr * zr + zi * zi <= 4.0 && n < MAX_ITER {
                let new_zr = zr * zr - zi * zi + cr;
                zi = 2.0 * zr * zi + ci;
                zr = new_zr;
                n += 1;
            }

            let (r, g, b) = calculate_color(n);
            let color = ((r as u32) << 16) | ((g as u32) << 8) | b as u32;
            row[x] = color; // Set the color of the current pixel in the chunk
        }
    });
    //    for y in 0..h {
    //     for x in 0..w {
    //         let cr = rmin + x as f64 * zoom_x;
    //         let ci = imin + y as f64 * zoom_y;
    //         let (mut zr, mut zi, mut n) = (0.0, 0.0, 0u32);
    //         while zr * zr + zi * zi <= 4.0 && n < MAX_ITER {
    //             let new_zr = zr * zr - zi * zi + cr;
    //             zi = 2.0 * zr * zi + ci;
    //             zr = new_zr;
    //             n += 1;
    //         }

    //         // Create a color based on the number of iterations
    //         // let color = if n < 256 { n * 0x01010101 } else { 0 };
    //         // buffer[y * w + x] = color as u32;
    //         let (r, g, b) = calculate_color(n);
    //         // Pack the RGB values into a single u32
    //         let color = ((r << 16) & 0xFF0000) | ((g << 8) & 0x00FF00) | (b & 0x0000FF);
    //         buffer[y * w + x] = color;
    //     }
    // }
    println!("Total time = {:?}", start.elapsed());
 
    // Update the window content
    while window.is_open() && !window.is_key_down(Key::Escape) {
        window
            .update_with_buffer(&buffer, WIDTH, HEIGHT)
            .unwrap();
    }

}


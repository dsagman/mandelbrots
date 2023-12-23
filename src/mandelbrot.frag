#version 330 core

out vec4 fragColor;
uniform float width;
uniform float height;
uniform float rmin;
uniform float rmax;
uniform float imin;
uniform float imax;
uniform int max_iter;

void main() {
    float x = gl_FragCoord.x;
    float y = gl_FragCoord.y;

    float re = rmin + (x / width) * (rmax - rmin);
    float im = imin + (y / height) * (imax - imin);
    float cx = re;
    float cy = im;
    int iteration = 0;

    while (re*re + im*im < 4.0 && iteration < max_iter) {
        float newRe = re*re - im*im + cx;
        float newIm = 2.0*re*im + cy;
        re = newRe;
        im = newIm;
        iteration++;
    }

    // vec3 color = iteration < max_iter ? vec3(float(iteration) / 256.0, 0.0, 0.0) : vec3(0.0, 0.0, 0.0);
    vec3 color;
    if (iteration < max_iter) {
        color = vec3(float(iteration % 256) / 255.0, 
                     float((iteration * iteration) % 256) / 255.0, 
                     float((iteration * 2) % 256) / 255.0);
    } else {
        color = vec3(0.0, 0.0, 0.0); // Black color for points inside the Mandelbrot set
    }
    
    fragColor = vec4(color, 1.0);
}





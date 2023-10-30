#include <SDL2/SDL.h>
#include <stdio.h>
#include <time.h>

// #define ZOOM 2000.0
#define Colors 8192

#define RMIN -0.74612
#define RMAX -0.74427
#define IMIN 0.11196
#define IMAX 0.11339
#define W 640
#define H 350
#define MAX_ITER 200

void calculateColor(int iteration, int *r, int *g, int *b) {
    // Simple coloring based on iteration count
    if (iteration < MAX_ITER) {
        *r = iteration % 256;
        *g = (iteration * iteration) % 256; // Squaring iteration can lead to interesting color patterns
        *b = (iteration * 2) % 256;
    } else {
        *r = 0; *g = 0; *b = 0; // Black color
    }
}

int main(int argc, char *argv[]) {

    clock_t start, end;
    double cpu_time_used;

    start = clock();

    SDL_Window *window = NULL;
    SDL_Renderer *renderer = NULL;
    window = SDL_CreateWindow("Mandelbrot Set", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, W, H, SDL_WINDOW_SHOWN); 
    renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
    
    SDL_SetRenderDrawColor(renderer, 0xFF, 0xFF, 0xFF, 0xFF);
    SDL_RenderClear(renderer);

    double CR, CI, XR, XI, RK, IK;
    double DP = (RMAX - RMIN) / W;
    double DQ = (IMAX - IMIN) / H;

    for (int Y = 0; Y < H; Y++) {
        for (int X = 0; X < W; X++) {
            CR = RMIN + X * DP;
            CI = IMIN + Y * DQ;
            int K = 0;
            XR = 0;
            XI = 0;

            do {
                RK = XR * XR - XI * XI + CR;
                IK = 2 * XR * XI + CI;
                XR = RK;
                XI = IK;
                K = K + 1;
            } while (K < MAX_ITER && XR * XR + XI * XI <= 4.0);

            // int color = K % Colors;
            int r, g, b;
            calculateColor(K, &r, &g, &b);
            SDL_SetRenderDrawColor(renderer, r, g, b, SDL_ALPHA_OPAQUE);
            SDL_RenderDrawPoint(renderer, X, Y);
        }
    }

    SDL_RenderPresent(renderer);

    end = clock();
    cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;

    printf("Total time = %f\n", cpu_time_used);

    SDL_Event e;
    int quit = 0;
    while (!quit) {
        while (SDL_PollEvent(&e)) {
            if (e.type == SDL_QUIT) {
                quit = 1;
            }
        }
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();

    return 0;
}

// cruft from chatgpt
// if (SDL_Init(SDL_INIT_VIDEO) < 0) {
//         printf("SDL could not initialize! SDL_Error: %s\n", SDL_GetError());
//         return 1;
//     }

//     window = SDL_CreateWindow("Mandelbrot Set", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, W, H, SDL_WINDOW_SHOWN);
//     if (window == NULL) {
//         printf("Window could not be created! SDL_Error: %s\n", SDL_GetError());
//         return 1;
//     }

//     renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);
//     if (renderer == NULL) {
//         printf("Renderer could not be created! SDL Error: %s\n", SDL_GetError());
//         return 1;
//     }
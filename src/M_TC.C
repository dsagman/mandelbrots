/* For Borland Turbo C*/
#include <graphics.h>
#include <dos.h>
#include <conio.h>
#include <stdio.h>
#include <math.h>

void main() {
    /* Declarations must come before any statements */
    int gd = EGA, gm = EGAHI; 
    int x, y, k, m, a, b, color;
    float rmin, rmax, imin, imax, dp, dq, cr, ci, xr, xi, rk, ik;
    unsigned long start, end;
    struct time t;

    /* Initialize graphics mode */
    initgraph(&gd, &gm, "c:\\TC");  /* No need for path in EGA mode */
    if (graphresult() != grOk) {
        printf("Graphics initialization failed.");
        getch();  /* Wait for a key press before closing */
        return;
    }

    /* Clear screen and get start time */
    cleardevice();
    gettime(&t);
    start = ((unsigned long)t.ti_hour * 3600) + (t.ti_min * 60) + t.ti_sec;  /* Convert to total seconds */
    printf("start = %lu\n", start);

    /* Set parameters */
    a = 640; b = 350;  /* Adjust according to your EGA resolution */
    rmin = -.74612f; rmax = -.74427f;
    imin = .11196f; imax = .11339f;
    dp = (rmax - rmin) / (float)(a - 1);
    dq = (imax - imin) / (float)(b - 1);
    m = 200;

    /* Main loop to plot points */
    for (y = 0; y < b; y++) {
        for (x = 0; x < a; x++) {
            cr = rmin + (float)x * dp;
            ci = imin + (float)y * dq;
            k = 0; xr = 0.0f; xi = 0.0f;
            do {
                rk = xr * xr - xi * xi + cr;
                ik = 2 * xr * xi + ci;
                xr = rk; xi = ik;
                k++;
            } while (k < m && (xr * xr + xi * xi) <= 4.0f);

            color = k % 16;  /* EGA supports 16 colors */
            putpixel(x, y, color);
        }
    }

    /* Calculate and print the time taken */
    gettime(&t);
    end = ((unsigned long)t.ti_hour * 3600) + (t.ti_min * 60) + t.ti_sec;  /* Convert to total seconds */
    printf("end = %lu\n", end);
    printf("total = %lu\n", end - start);

    /* Wait for a keypress and then close the graphics window */
    getch();
    closegraph();

}


program Mandelbrot;
{For Turbo Pascal}

uses Graph, Crt;

var
  gd, gm: Integer;
  s, e: LongInt;
  a, b, bk, m, x, y, k: Integer;
  rmin, rmax, imin, imax, dp, dq, cr, ci, xr, xi, rk, ik: Real;
  msg: string;

begin
  { Initialize graphics mode }
  { Set graphics driver and mode manually }
  gd := EGA;  { EGA graphics driver }
  gm := EGAHi; { EGA high-resolution mode (640x350) }
  InitGraph(gd, gm, 'C:\TP\BGI'); { You might need to set the correct path for the BGI driver }

  s := MemL[Seg0040:$006C]; { Get the system timer }

  Writeln('start = ', s);

  a := 640;
  b := 350;
  bk := 100;
  rmin := -0.74612;
  rmax := -0.74427;
  imin := 0.11196;
  imax := 0.11339;
  dp := (rmax - rmin) / (a - 1);
  dq := (imax - imin) / (b - 1);
  m := 200;

  for y := 0 to b - 1 do
  begin
    for x := 0 to a - 1 do
    begin
      cr := rmin + (x * dp);
      ci := imin + (y * dq);
      k := 0;
      xr := 0;
      xi := 0;

      repeat
        rk := xr * xr - xi * xi + cr;
        ik := 2 * xr * xi + ci;
        xr := rk;
        xi := ik;
        k := k + 1;
      until (k = m) or (xr * xr + xi * xi > 4);

      PutPixel(x, y, k mod 8);
    end;
  end;

  e := MemL[Seg0040:$006C]; { Get the system timer again }

  { Format and display the timing information in graphics mode }
  Str((e - s), msg); { Convert the time difference to a string }
  msg := 'Total time: ' + msg + ' ticks';
  SetColor(White); { Choose the text color }
  OutTextXY(10, 10, msg); { Display the message in the graphics window }

  { Wait for a key press in graphics mode }
  ReadKey;

  { After a key is pressed, close the graphics mode }
  CloseGraph;
end.

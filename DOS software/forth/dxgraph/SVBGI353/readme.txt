SVGA BGI Driver 3.53

Changes from original version 3.51A
-----------------------------------
v3.52
- Floodfill now works with C small/medium memory model targets (*).
- Out of flood memory is detectable by GraphResult.
- Corrected a problem which causes certain VESA cards to display
  improperly (e.g. Matrox Millenium)

  (*) Crashes may still occur in these targets once flood memory
  becomes exhausted.  This is due to a bug in the Borland graphics
  library.  The bug affects all BGI drivers including this one.

v3.53
- For compatibility with the EGAVGA.BGI driver and software, RGB
  palette values must now lie in the range 0..63 and not 0..255 as
  before.

  NOTE: Software written for previous versions of this driver which
  use SetRGBPalette will need to be modified and recompiled before
  using the new driver.  E.g. To modify the PCXVIEW program included
  in the original SVGA distribution, change the line containing the
  statement:
     SetRGBPalette (I, Red, Green, Blue)
  to:
     SetRGBPalette (I, Red Shr 2, Green Shr 2, Blue Shr 2)


Driver modes
------------
  0    320*200 VGA/MCGA
  1    Autodetect
  2    640*400 Autodetect
  3    640*480 Autodetect
  4    800*600 Autodetect
  5    1024*768 Autodetect
  6    1280*1024 Autodetect
  7    640*350 ET3000
  8    640*480 ET3000
  9    800*600 ET3000
  10   640*350 ET4000
  11   640*400 ET4000
  12   640*480 ET4000
  13   800*600 ET4000
  14   1024*768 ET4000
  15   640*400 Trident 8900
  16   640*480 Trident 8900
  17   800*600 Trident 8900
  18   1024*768 Trident 8900
  19   640*400 Video7
  20   640*480 Video7
  21   800*600 Video7
  22   640*400 ATI VGA Wonder
  23   640*480 ATI VGA Wonder
  24   800*600 ATI VGA Wonder
  25   1024*768 ATI VGA Wonder
  26   640*400 Paradise
  27   640*480 Paradise
  28   800*600 Paradise
  29   640*350 Everex
  30   640*400 Everex
  31   640*480 Everex
  32   800*600 Everex
  33   640*400 Oak
  34   800*600 Oak
  35   640*480 S3
  36   800*600 S3
  37   1024*768 S3
  38   1280*1024 S3
  39   640*400 VESA
  40   640*480 VESA
  41   800*600 VESA
  42   1024*768 VESA
  43   1280*1024 VESA

Note: All modes are 256 color.


Disclaimer and copying
----------------------
This is an unofficial update and was made by a third party author.
The software is supplied "as is".  No responsibility is taken for
omissions, errors or consequential damage.  Use is strictly "at
your own risk".

Copying or alteration of these files is subject to the conditions
set out by the original author.  Please refer to the enclosed file
"copying.txt" for details.


Further Information
-------------------
The original SVGA BGI driver distribution including documentation
(in German) may be found at:

  http://www.von-bassewitz.de/uz/bgi.html


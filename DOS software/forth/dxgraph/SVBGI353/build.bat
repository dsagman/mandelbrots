rem Make BGI drivers
@echo off
tasm /t /m5 /DVer3=1 /DP80286=0 /DP80386=0 svga
tlink /s svga
exetobin svga.exe svga.bin
bh3 svga SVGA.BP7 svga.map SVGA
copy svga.bgi SVGA.BP7 /y

tasm /t /m5 /DVer3=1 /DP80286=0 /DP80386=1 svga, svga386
tlink /s svga386
exetobin svga386.exe svga386.bin
bh3 svga386 SVGA386.BP7 svga386.map SVGA
copy svga386.bgi SVGA386.BP7 /y

tasm /t /m5 /DVer3=0 /DP80286=0 /DP80386=0 svga
tlink /s svga
exetobin svga.exe svga.bin
bh2 svga SVGA.BGI SVGA

tasm /t /m5 /DVer3=0 /DP80286=0 /DP80386=1 svga, svga386
tlink /s svga386
exetobin svga386.exe svga386.bin
bh2 svga386 SVGA386.BGI SVGA

del svga*.obj
del svga*.exe
del svga*.map
del svga*.bin
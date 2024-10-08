if exist test.gb del test.gb
if exist main.o del main.o
if exist linkfile del linkfile
if exist test.sym del test.sym

"C:\Program Files\WLA-DX\wla-gb.exe" -o main.o main.s

echo [objects]>linkfile
echo main.o>>linkfile

"C:\Program Files\WLA-DX\wlalink.exe" -v -s linkfile test.gb

del main.o

"C:\Program Files\bgb\bgb.exe" test.gb -nowarn
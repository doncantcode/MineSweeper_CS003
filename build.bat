@echo off
REM ===================================================================
REM  Build Minesweeper (NASM / DOS .COM)
REM
REM  Usage:  build.bat            build main.com in this folder
REM          build.bat -run       build, then launch it in DOSBox
REM
REM  nasm.exe is looked up on PATH first, then in the common
REM  C:\Users\<user>\nasm\nasm-<ver>\ location.
REM ===================================================================
setlocal

cd /d "%~dp0"

set "NASM="
where nasm >nul 2>nul && set "NASM=nasm"
if not defined NASM (
    for /d %%D in ("%USERPROFILE%\nasm\nasm-*") do (
        if exist "%%D\nasm.exe" set "NASM=%%D\nasm.exe"
    )
)
if not defined NASM (
    echo ERROR: nasm.exe not found on PATH or under %USERPROFILE%\nasm\
    echo        Download it from https://www.nasm.us/pub/nasm/releasebuilds/
    exit /b 1
)

echo Building main.com with "%NASM%" ...
"%NASM%" -f bin main.asm -o main.com -l main.lst
if errorlevel 1 (
    echo BUILD FAILED
    exit /b 1
)

echo Build OK: main.com
if /i "%~1"=="-run" (
    where dosbox >nul 2>nul || (
        echo ERROR: dosbox not found on PATH
        exit /b 1
    )
    dosbox -c "mount c ." -c "c:" -c "main.com"
)
endlocal

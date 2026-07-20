@echo off
setlocal

set ARGS=

:loop
if "%~1"=="" goto done

if "%~1"=="--target=x86_64-pc-windows-msvc" (
    set ARGS=%ARGS% --target=x86_64-windows-gnu
) else (
    set ARGS=%ARGS% %1
)

shift
goto loop

:done

zig cc %ARGS%
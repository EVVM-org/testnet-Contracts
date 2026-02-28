@echo off
setlocal enabledelayedexpansion

:: Get the directory where the script is located
set "SCRIPT_DIR=%~dp0"

:: Detect architecture
set "ARCH="
for /f "tokens=2 delims==" %%A in ('wmic os get osarchitecture /value 2^>nul') do (
    set "ARCH=%%A"
)

:: Remove any trailing spaces/carriage returns
set "ARCH=%ARCH: =%"

:: Determine the executable
if "%ARCH%"=="64-bit" (
    set "EXECUTABLE=%SCRIPT_DIR%.executables\evvm-windows-x64.exe"
) else if "%ARCH%"=="32-bit" (
    echo Unsupported architecture: 32-bit Windows is not supported.
    exit /b 1
) else (
    echo Unable to detect architecture. Defaulting to x64.
    set "EXECUTABLE=%SCRIPT_DIR%.executables\evvm-windows-x64.exe"
)

:: Execute the binary
if exist "%EXECUTABLE%" (
    "%EXECUTABLE%" %*
    set "status=%ERRORLEVEL%"
    if not "%status%"=="0" (
        echo.
        echo Warning: native CLI executable returned error %status%.
        echo This may mean the file is corrupted or built for the wrong platform.
        where bun >nul 2>&1
        if not errorlevel 1 (
            echo Attempting Bun fallback...
            bun run cli/index.ts %*
            exit /b %ERRORLEVEL%
        ) else (
            echo Bun not found; please install Bun or rebuild the binaries on Windows.
        )
        exit /b %status%
    )
) else (
    echo Executable not found: %EXECUTABLE%
    echo Please ensure the executable exists in the .executables folder.
    exit /b 1
)
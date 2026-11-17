@echo off
setlocal EnableExtensions

rem Organizer post-cook packaging
rem Run this file from anywhere; all paths are relative to this script's folder.

set "ROOT=%~dp0"
set "COOKED=C:\Users\%USERNAME%\Documents\Unreal Projects\Modding\parcel\Saved\Cooked\Windows\parcel\content"
set "BPMOD=%ROOT%BPMod"
set "REDUNDANT=%ROOT%good redundant"
set "RELEASE=%ROOT%Releases"

echo.
echo ==========================================
echo        ORGANIZER PACKING
echo ==========================================
echo.

rem Confirm the cooked content directory exists.
if not exist "%COOKED%\" (
    echo ERROR: Cooked content directory was not found:
    echo "%COOKED%"
    exit /b 1
)

rem Ensure destination directories exist.
if not exist "%BPMOD%\" mkdir "%BPMOD%"
if errorlevel 1 (
    echo ERROR: Could not create BPMod.
    exit /b 1
)

if not exist "%REDUNDANT%\" mkdir "%REDUNDANT%"
if errorlevel 1 (
    echo ERROR: Could not create good redundant.
    exit /b 1
)

if not exist "%RELEASE%\" mkdir "%RELEASE%"
if errorlevel 1 (
    echo ERROR: Could not create release.
    exit /b 1
)

echo [1/4] Copying cooked content into BPMod...
robocopy "%COOKED%" "%BPMOD%" /E
set "ROBOCOPY_RESULT=%ERRORLEVEL%"
if %ROBOCOPY_RESULT% GEQ 8 (
    echo ERROR: Robocopy failed with exit code %ROBOCOPY_RESULT%.
    exit /b %ROBOCOPY_RESULT%
)

echo.
echo [2/4] Moving existing root-level pak/utoc/ucas files to good redundant...

for %%E in (pak utoc ucas) do (
    for %%F in ("%ROOT%*.%%E") do (
        if exist "%%~fF" (
            echo Moving %%~nxF
            move /Y "%%~fF" "%REDUNDANT%\" >nul
            if errorlevel 1 (
                echo ERROR: Could not move %%~nxF to good redundant.
                exit /b 1
            )
        )
    )
)

echo.
echo [3/4] Running retoc...
pushd "%ROOT%"
retoc to-zen --version UE5_7 "%BPMOD%" "%ROOT%Organizer.utoc"
set "RETOC_RESULT=%ERRORLEVEL%"
popd

if not "%RETOC_RESULT%"=="0" (
    echo ERROR: retoc failed with exit code %RETOC_RESULT%.
    exit /b %RETOC_RESULT%
)

echo.
echo [4/4] Moving generated Organizer files into release...

set "MOVED=0"
for %%E in (pak utoc ucas) do (
    if exist "%ROOT%Organizer.%%E" (
        move /Y "%ROOT%Organizer.%%E" "%RELEASE%\" >nul
        if errorlevel 1 (
            echo ERROR: Could not move Organizer.%%E into release.
            exit /b 1
        )
        set "MOVED=1"
        echo Moved Organizer.%%E
    )
)

if "%MOVED%"=="0" (
    echo ERROR: retoc completed, but no Organizer.pak, Organizer.utoc, or Organizer.ucas
    echo files were found in the Organizer root.
    echo Check retoc's output location and filename.
    exit /b 1
)

echo.
echo ==========================================
echo        PACKING COMPLETE
echo ==========================================
echo Output: "%RELEASE%"
echo.
exit /b 0

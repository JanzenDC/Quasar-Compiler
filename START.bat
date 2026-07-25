@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Quasar Capacitor Builder
cd /d "%~dp0"

REM Safe ANSI colors (Windows 10+)
set "ESC="
for /f %%A in ('powershell -NoProfile -Command "[char]27" 2^>nul') do set "ESC=%%A"
if defined ESC (
  set "CY=%ESC%[96m"
  set "MG=%ESC%[95m"
  set "GR=%ESC%[92m"
  set "YL=%ESC%[93m"
  set "DIM=%ESC%[90m"
  set "BD=%ESC%[1m"
  set "RST=%ESC%[0m"
) else (
  set "CY="
  set "MG="
  set "GR="
  set "YL="
  set "DIM="
  set "BD="
  set "RST="
)

:menu
cls
call :banner
echo.
echo   %BD%What would you like to do?%RST%
echo.
echo     %CY%1%RST%  Build Android APK          %DIM%(recommended)%RST%
echo     %CY%2%RST%  Check your PC setup        %DIM%(Node, Java, Android SDK)%RST%
echo     %CY%3%RST%  How to use this builder
echo     %CY%4%RST%  Open README
echo     %CY%0%RST%  Exit
echo.
set "CHOICE="
set /p "CHOICE=  Choose [1]: "
if "%CHOICE%"=="" set "CHOICE=1"

if "%CHOICE%"=="1" goto :build
if "%CHOICE%"=="2" goto :doctor
if "%CHOICE%"=="3" goto :howto
if "%CHOICE%"=="4" goto :readme
if "%CHOICE%"=="0" goto :bye
if /I "%CHOICE%"=="exit" goto :bye
echo.
echo   Invalid choice. Try again.
timeout /t 2 >nul
goto :menu

:build
cls
call build-capacitor-android.bat
echo.
echo   Returning to menu...
timeout /t 2 >nul
goto :menu

:doctor
cls
call check-setup.bat --no-pause
echo.
pause
goto :menu

:howto
cls
call :banner
echo.
echo   %BD%Quick start%RST%
echo.
echo   %GR%1.%RST% Make sure your Quasar app already has Capacitor Android:
echo        cd your-project
echo        npx quasar mode add capacitor
echo.
echo   %GR%2.%RST% From this menu, choose %CY%1%RST% ^(Build Android APK^).
echo.
echo   %GR%3.%RST% Paste your project folder path when asked.
echo        Tip: drag the project folder into the window.
echo.
echo   %GR%4.%RST% Choose %CY%debug%RST% to get an APK you can install on a phone.
echo.
echo   %BD%Or from Command Prompt / PowerShell:%RST%
echo.
echo     START.bat
echo     build-capacitor-android.bat "C:\path\to\project" debug
echo     check-setup.bat
echo.
echo   Full details: README.md
echo.
pause
goto :menu

:readme
if exist "%~dp0README.md" (
  start "" "%~dp0README.md"
) else (
  echo   README.md not found.
  timeout /t 2 >nul
)
goto :menu

:bye
echo.
echo   Goodbye.
timeout /t 1 >nul
endlocal
exit /b 0

:banner
if exist "%~dp0build-capacitor-android-banner.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-capacitor-android-banner.ps1"
) else (
  echo.
  echo   CAPACITOR BUILDER
  echo   Powered by Nexus IT Solutions Inc.
  echo.
)
exit /b 0

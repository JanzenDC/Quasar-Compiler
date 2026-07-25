@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Quasar Capacitor Builder - Setup Check
cd /d "%~dp0"

set "ESC="
for /f %%A in ('powershell -NoProfile -Command "[char]27" 2^>nul') do set "ESC=%%A"
if defined ESC (
  set "OK=%ESC%[92m  [OK]%ESC%[0m "
  set "MISS=%ESC%[91m  [MISSING]%ESC%[0m "
  set "WARN=%ESC%[93m  [WARN]%ESC%[0m "
  set "DIM=%ESC%[90m"
  set "BD=%ESC%[1m"
  set "RST=%ESC%[0m"
) else (
  set "OK=  [OK] "
  set "MISS=  [MISSING] "
  set "WARN=  [WARN] "
  set "DIM="
  set "BD="
  set "RST="
)

set "FAIL=0"
set "SOFT=0"

echo.
echo   %BD%Checking your PC for Android APK builds...%RST%
echo   %DIM%This does not build an app - it only checks tools.%RST%
echo.

REM ---- Node.js ----
where node >nul 2>&1
if errorlevel 1 (
  echo %MISS%Node.js
  echo           Install from https://nodejs.org ^(LTS recommended^)
  set "FAIL=1"
) else (
  for /f "tokens=*" %%V in ('node -v 2^>nul') do set "NODE_VER=%%V"
  echo %OK%Node.js  %DIM%!NODE_VER!%RST%
)

REM ---- npm ----
where npm >nul 2>&1
if errorlevel 1 (
  echo %MISS%npm
  echo           Reinstall Node.js ^(npm is included^)
  set "FAIL=1"
) else (
  for /f "tokens=*" %%V in ('npm -v 2^>nul') do set "NPM_VER=%%V"
  echo %OK%npm      %DIM%v!NPM_VER!%RST%
)

REM ---- Java / JDK ----
where java >nul 2>&1
if errorlevel 1 (
  echo %MISS%Java ^(JDK^)
  echo           Install JDK 17+ and add it to PATH
  echo           https://adoptium.net/
  set "FAIL=1"
) else (
  set "JAVA_VER="
  for /f "tokens=3" %%V in ('java -version 2^>^&1 ^| findstr /i "version"') do if not defined JAVA_VER set "JAVA_VER=%%~V"
  echo %OK%Java     %DIM%!JAVA_VER!%RST%
)

REM ---- ANDROID_HOME / ANDROID_SDK_ROOT ----
set "SDK="
if defined ANDROID_HOME set "SDK=%ANDROID_HOME%"
if defined ANDROID_SDK_ROOT set "SDK=%ANDROID_SDK_ROOT%"

if not defined SDK (
  REM Common Windows default locations
  if exist "%LOCALAPPDATA%\Android\Sdk" set "SDK=%LOCALAPPDATA%\Android\Sdk"
  if exist "%USERPROFILE%\AppData\Local\Android\Sdk" set "SDK=%USERPROFILE%\AppData\Local\Android\Sdk"
)

if not defined SDK (
  echo %WARN%Android SDK path not found
  echo           Install Android Studio once ^(for the SDK^), or set ANDROID_HOME
  echo           Typical path: %%LOCALAPPDATA%%\Android\Sdk
  set "SOFT=1"
) else (
  if exist "%SDK%\platform-tools" (
    echo %OK%Android SDK  %DIM%%SDK%%RST%
  ) else (
    echo %WARN%ANDROID_HOME points here but looks incomplete:
    echo           %SDK%
    set "SOFT=1"
  )
)

REM ---- adb (optional, for install-to-phone) ----
where adb >nul 2>&1
if errorlevel 1 (
  if defined SDK (
    if exist "%SDK%\platform-tools\adb.exe" (
      echo %OK%adb       %DIM%found in SDK platform-tools%RST%
    ) else (
      echo %WARN%adb not in PATH
      echo           Optional: add %%ANDROID_HOME%%\platform-tools to PATH
      set "SOFT=1"
    )
  ) else (
    echo %WARN%adb not found ^(optional - used to install APK to a phone^)
    set "SOFT=1"
  )
) else (
  echo %OK%adb       %DIM%available in PATH%RST%
)

REM ---- Builder files ----
echo.
echo   %BD%Builder files in this folder%RST%
if exist "%~dp0build-capacitor-android.bat" (
  echo %OK%build-capacitor-android.bat
) else (
  echo %MISS%build-capacitor-android.bat
  set "FAIL=1"
)
if exist "%~dp0START.bat" (
  echo %OK%START.bat
) else (
  echo %WARN%START.bat
  set "SOFT=1"
)
if exist "%~dp0README.md" (
  echo %OK%README.md
) else (
  echo %WARN%README.md
  set "SOFT=1"
)

echo.
echo   ----------------------------------------
set "EXIT_CODE=0"
if "%FAIL%"=="1" (
  echo   %BD%Result: NOT READY%RST%
  echo   Fix the MISSING items above, then run this check again.
  echo.
  echo   Minimum needed:
  echo     - Node.js LTS + npm
  echo     - JDK 17 or newer
  echo     - Android SDK ^(install Android Studio once^)
  set "EXIT_CODE=1"
) else if "%SOFT%"=="1" (
  echo   %BD%Result: READY with warnings%RST%
  echo   You can try building. Warnings are optional or nice-to-have.
) else (
  echo   %BD%Result: READY%RST%
  echo   Your PC looks good. Open START.bat and choose Build Android APK.
)

REM Keep window open when double-clicked. START.bat passes --no-pause.
if /I not "%~1"=="--no-pause" (
  echo.
  pause
)
endlocal & exit /b %EXIT_CODE%

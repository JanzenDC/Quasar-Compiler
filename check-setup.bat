@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Capacitor Builder - Setup Check
cd /d "%~dp0"

set "ESC="
for /f %%A in ('powershell -NoProfile -Command "[char]27" 2^>nul') do set "ESC=%%A"
if defined ESC (
  set "OK=%ESC%[92m  [OK]%ESC%[0m "
  set "MISS=%ESC%[91m  [MISSING]%ESC%[0m "
  set "WARN=%ESC%[93m  [WARN]%ESC%[0m "
  set "DIM=%ESC%[90m"
  set "BD=%ESC%[1m"
  set "CY=%ESC%[96m"
  set "RST=%ESC%[0m"
) else (
  set "OK=  [OK] "
  set "MISS=  [MISSING] "
  set "WARN=  [WARN] "
  set "DIM="
  set "BD="
  set "CY="
  set "RST="
)

set "FAIL=0"
set "SOFT=0"
set "NEED_NODE=0"
set "NEED_JAVA=0"
set "NEED_SDK=0"

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
  set "NEED_NODE=1"
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
  set "NEED_NODE=1"
) else (
  for /f "tokens=*" %%V in ('npm -v 2^>nul') do set "NPM_VER=%%V"
  echo %OK%npm      %DIM%v!NPM_VER!%RST%
)

REM ---- Java / JDK ----
where java >nul 2>&1
if errorlevel 1 (
  echo %MISS%Java ^(JDK^)
  echo           Need JDK 17+ on PATH
  echo           %DIM%You can download it from this check - see below%RST%
  set "FAIL=1"
  set "NEED_JAVA=1"
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
  if exist "%LOCALAPPDATA%\Android\Sdk" set "SDK=%LOCALAPPDATA%\Android\Sdk"
  if exist "%USERPROFILE%\AppData\Local\Android\Sdk" set "SDK=%USERPROFILE%\AppData\Local\Android\Sdk"
)

if not defined SDK (
  echo %WARN%Android SDK path not found
  echo           Install Android Studio once ^(for the SDK^), or set ANDROID_HOME
  echo           Typical path: %%LOCALAPPDATA%%\Android\Sdk
  set "SOFT=1"
  set "NEED_SDK=1"
) else (
  if exist "%SDK%\platform-tools" (
    echo %OK%Android SDK  %DIM%%SDK%%RST%
  ) else (
    echo %WARN%ANDROID_HOME points here but looks incomplete:
    echo           %SDK%
    set "SOFT=1"
    set "NEED_SDK=1"
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
  goto :offer_download
)

if "%SOFT%"=="1" (
  echo   %BD%Result: READY with warnings%RST%
  echo   You can try building. Warnings are optional or nice-to-have.
  if "%NEED_SDK%"=="1" goto :offer_download
  goto :finish
)

echo   %BD%Result: READY%RST%
echo   Your PC looks good. Open START.bat and choose Build Android APK.
goto :finish

:offer_download
echo.
echo   %BD%Download missing tools now?%RST%
echo.
if "%NEED_JAVA%"=="1" echo     %CY%J%RST%  Download / install JDK 21 ^(Temurin^)
if "%NEED_NODE%"=="1" echo     %CY%N%RST%  Download / install Node.js LTS
if "%NEED_SDK%"=="1"  echo     %CY%A%RST%  Open Android Studio download page
echo     %CY%0%RST%  Skip - do it later
echo.
set "DL="
set /p "DL=  Choose: "
if "%DL%"=="" set "DL=0"

if /I "%DL%"=="J" goto :dl_java
if /I "%DL%"=="N" goto :dl_node
if /I "%DL%"=="A" goto :dl_android
if "%DL%"=="0" goto :finish
goto :finish

:dl_java
echo.
echo   Installing JDK 21...
where winget >nul 2>&1
if not errorlevel 1 (
  echo   Using winget ^(Eclipse Temurin 21^)...
  echo   Accept prompts if Windows asks for permission.
  echo.
  winget install -e --id EclipseAdoptium.Temurin.21.JDK --accept-package-agreements --accept-source-agreements
  if errorlevel 1 (
    echo.
    echo   winget install failed. Opening download page in your browser...
    start "" "https://adoptium.net/temurin/releases/?version=21&os=windows&arch=x64&package=jdk"
  ) else (
    echo.
    echo   %OK%JDK install finished.
    echo   Close this window, open a NEW Command Prompt, then run check-setup again.
  )
) else (
  echo   winget not found. Opening Temurin JDK 21 download page...
  start "" "https://adoptium.net/temurin/releases/?version=21&os=windows&arch=x64&package=jdk"
  echo   Download the .msi, install it, then reopen this check.
)
goto :finish

:dl_node
echo.
echo   Installing Node.js LTS...
where winget >nul 2>&1
if not errorlevel 1 (
  echo   Using winget...
  echo.
  winget install -e --id OpenJS.NodeJS.LTS --accept-package-agreements --accept-source-agreements
  if errorlevel 1 (
    echo.
    echo   winget install failed. Opening download page...
    start "" "https://nodejs.org/en/download"
  ) else (
    echo.
    echo   %OK%Node.js install finished.
    echo   Close this window, open a NEW Command Prompt, then run check-setup again.
  )
) else (
  echo   winget not found. Opening Node.js download page...
  start "" "https://nodejs.org/en/download"
  echo   Download the LTS installer, install it, then reopen this check.
)
goto :finish

:dl_android
echo.
echo   Opening Android Studio download page...
start "" "https://developer.android.com/studio"
echo   Install Android Studio once ^(for the SDK^), then run this check again.
goto :finish

:finish
REM Keep window open when double-clicked. START.bat passes --no-pause.
if /I not "%~1"=="--no-pause" (
  echo.
  pause
)
endlocal & exit /b %EXIT_CODE%

@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Quasar Capacitor - Android APK Builder
cd /d "%~dp0"

REM ============================================================
REM  Quasar / Capacitor Android APK builder
REM  Double-click START.bat, or run this file directly.
REM  Usage: build-capacitor-android.bat [project-path] [debug|release]
REM         build-capacitor-android.bat /?   help
REM ============================================================

REM Safe ANSI escape (Windows 10+). Falls back to no color.
set "ESC="
for /f %%A in ('powershell -NoProfile -Command "[char]27" 2^>nul') do set "ESC=%%A"
if not defined ESC (
  set "C1="
  set "C2="
  set "C3="
  set "C4="
  set "C5="
  set "C6="
  set "GR="
  set "YL="
  set "DIM="
  set "BD="
  set "RST="
) else (
  set "C1=%ESC%[96m"
  set "C2=%ESC%[94m"
  set "C3=%ESC%[95m"
  set "C4=%ESC%[35m"
  set "C5=%ESC%[91m"
  set "C6=%ESC%[31m"
  set "GR=%ESC%[92m"
  set "YL=%ESC%[93m"
  set "DIM=%ESC%[90m"
  set "BD=%ESC%[1m"
  set "RST=%ESC%[0m"
)

set "MODE=debug"
set "PROJECT_DIR="
set "BANNER_SHOWN=0"
set "MODE_SET=0"
set "APP_NAME=app"

REM ---- Help ----
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="help" goto :show_help

if "%~1"=="" goto :ask_path

if exist "%~1" (
  set "PROJECT_DIR=%~f1"
  if /I "%~2"=="debug" (
    set "MODE=debug"
    set "MODE_SET=1"
    goto :after_path
  )
  if /I "%~2"=="release" (
    set "MODE=release"
    set "MODE_SET=1"
    goto :after_path
  )
  if "%~2"=="" goto :after_path
  echo ERROR: Unknown mode "%~2" ^(use debug or release^)
  echo Run with /? for help.
  pause
  exit /b 1
)

echo ERROR: Folder not found:
echo   %~1
pause
exit /b 1

:ask_path
call :show_banner
echo.
echo   %BD%Step 1 - Choose your Quasar project%RST%
echo.
echo   Paste the folder path, or drag the project folder into this window.
echo.
echo   %DIM%Example:%RST% C:\xampp\htdocs\iwd_attendance
echo.
set /p "PROJECT_DIR=  Project path: "

call :clean_path
if not defined PROJECT_DIR (
  echo.
  echo   ERROR: No path entered.
  pause
  exit /b 1
)

dir /b /ad "%PROJECT_DIR%" >nul 2>&1
if errorlevel 1 (
  echo.
  echo   ERROR: Folder not found:
  echo     [%PROJECT_DIR%]
  echo.
  echo   Tip: drag the project folder into this window, then press Enter.
  pause
  exit /b 1
)

for %%I in ("%PROJECT_DIR%") do set "PROJECT_DIR=%%~fI"

:after_path
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

for %%I in ("%PROJECT_DIR%") do set "APP_NAME=%%~nxI"

echo.
echo   Scanning project for Capacitor Android...
echo   %DIM%%PROJECT_DIR%%RST%
echo.
call :scan_capacitor
if errorlevel 1 (
  echo.
  echo   Capacitor scan FAILED - fix the items above, then try again.
  echo.
  echo   To add Capacitor to a Quasar app:
  echo     cd "%PROJECT_DIR%"
  echo     npx quasar mode add capacitor
  echo.
  echo   See README.md for full setup steps.
  pause
  exit /b 1
)

echo.
echo   %GR%Capacitor scan OK - Android ready.%RST%
if "%MODE_SET%"=="1" goto :have_path

:ask_mode
echo.
echo   %BD%Step 2 - Build mode%RST%
echo.
echo     %C1%1%RST%  debug    %DIM%Installable on phone - recommended for testing%RST%
echo     %C1%2%RST%  release  %DIM%Needs signing before it will install%RST%
echo.
set /p "MODE_CHOICE=  Choose [1/2] default 1: "
if "%MODE_CHOICE%"=="" set "MODE_CHOICE=1"
if "%MODE_CHOICE%"=="1" set "MODE=debug"
if "%MODE_CHOICE%"=="2" set "MODE=release"
if /I "%MODE_CHOICE%"=="debug" set "MODE=debug"
if /I "%MODE_CHOICE%"=="release" set "MODE=release"
if /I "%MODE%"=="debug" goto :have_path
if /I "%MODE%"=="release" goto :have_path
echo   Invalid choice. Using debug.
set "MODE=debug"

:have_path
call :show_banner
echo.
echo   %DIM%Project:%RST%  %PROJECT_DIR%
echo   %DIM%App:    %RST%  %APP_NAME%
echo   %DIM%Mode:   %RST%  %MODE%
echo.

where node >nul 2>&1
if errorlevel 1 (
  echo   ERROR: Node.js not found in PATH.
  echo   Install from https://nodejs.org then try again.
  echo   Or run check-setup.bat to see what is missing.
  pause
  exit /b 1
)

where npm >nul 2>&1
if errorlevel 1 (
  echo   ERROR: npm not found in PATH.
  echo   Reinstall Node.js ^(includes npm^) then try again.
  pause
  exit /b 1
)

where java >nul 2>&1
if errorlevel 1 (
  echo   %YL%WARNING: Java not found in PATH. Gradle may fail if JDK is missing.%RST%
  echo   Run check-setup.bat for details.
  echo.
)

pushd "%PROJECT_DIR%"
if errorlevel 1 (
  echo   ERROR: Cannot open project folder.
  pause
  exit /b 1
)

echo   %BD%[0/3]%RST% Checking npm dependencies...

call :ensure_npm "%PROJECT_DIR%" "project root"
if errorlevel 1 (
  popd
  pause
  exit /b 1
)

if exist "%PROJECT_DIR%\src-capacitor\package.json" (
  call :ensure_npm "%PROJECT_DIR%\src-capacitor" "src-capacitor"
  if errorlevel 1 (
    popd
    pause
    exit /b 1
  )
)

echo.
echo   %BD%[1/3]%RST% Building web assets ^(quasar --skip-pkg^)...
call npx quasar build -m capacitor -T android --skip-pkg
if errorlevel 1 (
  popd
  echo.
  echo   Web build FAILED.
  echo   Check Quasar errors above. Common fix: npm install in the project.
  pause
  exit /b 1
)

echo.
echo   %BD%[2/3]%RST% Syncing Capacitor Android...
pushd "%PROJECT_DIR%\src-capacitor"
call npx cap sync android
if errorlevel 1 (
  popd
  popd
  echo.
  echo   Capacitor sync FAILED.
  pause
  exit /b 1
)
popd

echo.
echo   %BD%[3/3]%RST% Building %MODE% APK with Gradle...
pushd "%PROJECT_DIR%\src-capacitor\android"
if /I "%MODE%"=="debug" (
  call gradlew.bat assembleDebug
) else (
  call gradlew.bat assembleRelease
)
set "GRADLE_EXIT=!ERRORLEVEL!"
popd
popd

if not "!GRADLE_EXIT!"=="0" (
  echo.
  echo   Gradle build FAILED.
  echo   Often missing JDK or Android SDK - run check-setup.bat
  pause
  exit /b 1
)

set "APK_DEBUG=%PROJECT_DIR%\src-capacitor\android\app\build\outputs\apk\debug\app-debug.apk"
set "APK_RELEASE=%PROJECT_DIR%\src-capacitor\android\app\build\outputs\apk\release\app-release-unsigned.apk"
set "APK_RELEASE_SIGNED=%PROJECT_DIR%\src-capacitor\android\app\build\outputs\apk\release\app-release.apk"
set "APK_TO_OPEN="
set "APK_KIND="

echo.
echo   ========================================
echo   %GR%Build finished successfully%RST%
echo   ========================================

if /I "%MODE%"=="debug" (
  if exist "!APK_DEBUG!" (
    echo.
    echo   Installable APK:
    echo     !APK_DEBUG!
    set "APK_TO_OPEN=!APK_DEBUG!"
    set "APK_KIND=debug"
  ) else (
    echo   ERROR: app-debug.apk not found.
  )
) else (
  if exist "!APK_RELEASE_SIGNED!" (
    echo.
    echo   Release APK:
    echo     !APK_RELEASE_SIGNED!
    set "APK_TO_OPEN=!APK_RELEASE_SIGNED!"
    set "APK_KIND=release"
  ) else if exist "!APK_RELEASE!" (
    echo.
    echo   Release APK ^(%YL%UNSIGNED - will NOT install on phone%RST%^):
    echo     !APK_RELEASE!
    echo.
    echo   Use debug mode for sideloading, or sign this APK / add a keystore.
    set "APK_TO_OPEN=!APK_RELEASE!"
    set "APK_KIND=unsigned"
  ) else (
    echo   ERROR: release APK not found.
  )
)

if not defined APK_TO_OPEN (
  echo.
  pause
  endlocal
  exit /b 1
)

:post_build
echo.
echo   %BD%What next?%RST%
echo.
echo     %C1%1%RST%  Open APK folder in Explorer
echo     %C1%2%RST%  Copy APK to Desktop\QuasarBuilds
echo     %C1%3%RST%  Install on connected phone ^(adb^)
echo     %C1%0%RST%  Done
echo.
set "NEXT="
set /p "NEXT=  Choose [1]: "
if "%NEXT%"=="" set "NEXT=1"

if "%NEXT%"=="1" goto :open_explorer
if "%NEXT%"=="2" goto :copy_desktop
if "%NEXT%"=="3" goto :adb_install
if "%NEXT%"=="0" goto :done
goto :post_build

:open_explorer
if exist "!APK_TO_OPEN!" (
  echo.
  echo   Opening APK location...
  start "" explorer /select,"!APK_TO_OPEN!"
) else (
  echo   APK file not found.
)
goto :post_build

:copy_desktop
set "OUT_DIR=%USERPROFILE%\Desktop\QuasarBuilds"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"
set "T=%TIME::=%"
set "T=%T: =0%"
set "T=%T:~0,6%"
set "OUT_NAME=%APP_NAME%-%MODE%-%T%.apk"
set "OUT_FILE=%OUT_DIR%\%OUT_NAME%"
copy /Y "!APK_TO_OPEN!" "!OUT_FILE!" >nul
if errorlevel 1 (
  echo.
  echo   Copy FAILED.
) else (
  echo.
  echo   %GR%Copied to:%RST%
  echo     !OUT_FILE!
  start "" explorer /select,"!OUT_FILE!"
)
goto :post_build

:adb_install
set "ADB_EXE="
where adb >nul 2>&1
if not errorlevel 1 set "ADB_EXE=adb"
if not defined ADB_EXE (
  if defined ANDROID_HOME if exist "%ANDROID_HOME%\platform-tools\adb.exe" set "ADB_EXE=%ANDROID_HOME%\platform-tools\adb.exe"
)
if not defined ADB_EXE (
  if defined ANDROID_SDK_ROOT if exist "%ANDROID_SDK_ROOT%\platform-tools\adb.exe" set "ADB_EXE=%ANDROID_SDK_ROOT%\platform-tools\adb.exe"
)
if not defined ADB_EXE (
  if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" set "ADB_EXE=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
)

if not defined ADB_EXE (
  echo.
  echo   adb not found. Enable USB debugging on your phone, install platform-tools,
  echo   or add Android SDK platform-tools to PATH. See README.md.
  goto :post_build
)

if /I "%APK_KIND%"=="unsigned" (
  echo.
  echo   Cannot install an unsigned release APK. Build debug instead.
  goto :post_build
)

echo.
echo   Installing via adb ^(phone must be connected with USB debugging^)...
"!ADB_EXE!" devices
"!ADB_EXE!" install -r "!APK_TO_OPEN!"
if errorlevel 1 (
  echo.
  echo   Install FAILED. Is the phone connected? Is USB debugging on?
) else (
  echo.
  echo   %GR%Installed on device.%RST%
)
goto :post_build

:done
echo.
echo   Done. You can close this window.
pause
endlocal
exit /b 0

REM ------------------------------------------------------------
REM Help
REM ------------------------------------------------------------
:show_help
echo.
echo   Quasar Capacitor Android APK Builder
echo.
echo   USAGE
echo     START.bat
echo     build-capacitor-android.bat
echo     build-capacitor-android.bat "C:\path\to\quasar-project"
echo     build-capacitor-android.bat "C:\path\to\quasar-project" debug
echo     build-capacitor-android.bat "C:\path\to\quasar-project" release
echo     build-capacitor-android.bat /?
echo.
echo   MODES
echo     debug    Installable APK for testing ^(default^)
echo     release  Production APK ^(needs signing to install^)
echo.
echo   ALSO
echo     check-setup.bat   Verify Node, Java, Android SDK
echo     README.md         Full guide
echo.
exit /b 0

REM ------------------------------------------------------------
REM scan_capacitor - verify Quasar Capacitor Android is present
REM ------------------------------------------------------------
:scan_capacitor
set "SCAN_FAIL=0"
set "OK=  [OK] "
set "MISS=  [MISSING] "

if exist "%PROJECT_DIR%\package.json" (
  echo %OK%package.json
) else (
  echo %MISS%package.json ^(not a Node/Quasar project root^)
  set "SCAN_FAIL=1"
)

if exist "%PROJECT_DIR%\quasar.config.js" (
  echo %OK%quasar.config.js
) else if exist "%PROJECT_DIR%\quasar.config.ts" (
  echo %OK%quasar.config.ts
) else if exist "%PROJECT_DIR%\quasar.config.cjs" (
  echo %OK%quasar.config.cjs
) else (
  echo %MISS%quasar.config.js/ts ^(Quasar config^)
  set "SCAN_FAIL=1"
)

if exist "%PROJECT_DIR%\src-capacitor\" (
  echo %OK%src-capacitor\
) else (
  echo %MISS%src-capacitor\ ^(Capacitor mode not added^)
  set "SCAN_FAIL=1"
)

set "CAP_CFG=0"
if exist "%PROJECT_DIR%\src-capacitor\capacitor.config.js" set "CAP_CFG=1"
if exist "%PROJECT_DIR%\src-capacitor\capacitor.config.ts" set "CAP_CFG=1"
if exist "%PROJECT_DIR%\src-capacitor\capacitor.config.json" set "CAP_CFG=1"
if "%CAP_CFG%"=="1" (
  echo %OK%capacitor.config
) else (
  echo %MISS%capacitor.config.js/ts/json
  set "SCAN_FAIL=1"
)

if exist "%PROJECT_DIR%\src-capacitor\package.json" (
  echo %OK%src-capacitor\package.json
  findstr /I /C:"@capacitor/android" "%PROJECT_DIR%\src-capacitor\package.json" >nul 2>&1
  if errorlevel 1 (
    echo %MISS%@capacitor/android in src-capacitor\package.json
    set "SCAN_FAIL=1"
  ) else (
    echo %OK%@capacitor/android dependency
  )
  findstr /I /C:"@capacitor/cli" "%PROJECT_DIR%\src-capacitor\package.json" >nul 2>&1
  if errorlevel 1 (
    findstr /I /C:"@capacitor/core" "%PROJECT_DIR%\src-capacitor\package.json" >nul 2>&1
    if errorlevel 1 (
      echo %MISS%@capacitor/cli or @capacitor/core in package.json
      set "SCAN_FAIL=1"
    ) else (
      echo %OK%@capacitor/core dependency
    )
  ) else (
    echo %OK%@capacitor/cli dependency
  )
) else (
  echo %MISS%src-capacitor\package.json
  set "SCAN_FAIL=1"
)

if exist "%PROJECT_DIR%\src-capacitor\android\" (
  echo %OK%src-capacitor\android\
) else (
  echo %MISS%src-capacitor\android\ ^(Android platform missing^)
  set "SCAN_FAIL=1"
)

if exist "%PROJECT_DIR%\src-capacitor\android\gradlew.bat" (
  echo %OK%android\gradlew.bat
) else (
  echo %MISS%android\gradlew.bat
  set "SCAN_FAIL=1"
)

if exist "%PROJECT_DIR%\src-capacitor\android\app\build.gradle" (
  echo %OK%android\app\build.gradle
) else if exist "%PROJECT_DIR%\src-capacitor\android\app\build.gradle.kts" (
  echo %OK%android\app\build.gradle.kts
) else (
  echo %MISS%android\app\build.gradle
  set "SCAN_FAIL=1"
)

if "%SCAN_FAIL%"=="1" exit /b 1
exit /b 0

REM ------------------------------------------------------------
REM clean_path - strip quotes, spaces, trailing slash from PROJECT_DIR
REM ------------------------------------------------------------
:clean_path
if not defined PROJECT_DIR exit /b 0

REM Remove surrounding quotes
set "PROJECT_DIR=%PROJECT_DIR:"=%"

REM Collapse accidental leading spaces (keeps spaces inside path)
for /f "tokens=*" %%A in ("%PROJECT_DIR%") do set "PROJECT_DIR=%%A"

:clean_path_trim
if not defined PROJECT_DIR exit /b 0
if "%PROJECT_DIR:~-1%"==" " (
  set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
  goto :clean_path_trim
)
if "%PROJECT_DIR:~-1%"=="\" (
  set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
  goto :clean_path_trim
)
if "%PROJECT_DIR:~-1%"=="/" (
  set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
  goto :clean_path_trim
)
exit /b 0

:show_banner
if "%BANNER_SHOWN%"=="1" exit /b 0
set "BANNER_SHOWN=1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-capacitor-android-banner.ps1"
exit /b 0

:ensure_npm
set "NPM_DIR=%~1"
set "NPM_LABEL=%~2"

if not exist "%NPM_DIR%\package.json" exit /b 0

set "NEED_INSTALL=0"
if not exist "%NPM_DIR%\node_modules\" set "NEED_INSTALL=1"
if exist "%NPM_DIR%\node_modules\" (
  dir /b "%NPM_DIR%\node_modules" >nul 2>&1
  if errorlevel 1 set "NEED_INSTALL=1"
)

if /I "%NPM_LABEL%"=="project root" (
  if not exist "%NPM_DIR%\node_modules\@quasar\app-vite" set "NEED_INSTALL=1"
)

if "%NEED_INSTALL%"=="0" (
  echo     OK - %NPM_LABEL% dependencies found
  exit /b 0
)

echo     MISSING - installing npm packages for %NPM_LABEL%...
echo     Folder: %NPM_DIR%
pushd "%NPM_DIR%"
call npm install
set "NPM_EXIT=!ERRORLEVEL!"
popd

if not "!NPM_EXIT!"=="0" (
  echo   ERROR: npm install failed in %NPM_LABEL%.
  exit /b 1
)

echo     Done - %NPM_LABEL% dependencies installed
exit /b 0

# Quasar Capacitor Builder

Build an **installable Android APK** from any Quasar + Capacitor project — **without opening Android Studio**.

Double-click **`START.bat`** to begin.

---

## What this is

A small Windows toolkit that runs the normal Quasar → Capacitor → Gradle pipeline for you:

1. Installs missing npm dependencies  
2. Builds the web app for Capacitor Android  
3. Syncs native Android files  
4. Assembles a debug or release APK  
5. Lets you open the APK, copy it to your Desktop, or install it on a phone  

It works on **any** Quasar project that already has Capacitor Android mode. This folder is only the builder — your app lives elsewhere (for example `C:\xampp\htdocs\my-app`).

---

## Requirements (your PC)

| Tool | Why | Where |
|------|-----|--------|
| **Node.js LTS** + npm | Quasar / Capacitor CLI | https://nodejs.org |
| **JDK 17+** | Gradle Android builds | https://adoptium.net |
| **Android SDK** | Native APK build | Install [Android Studio](https://developer.android.com/studio) once (you only need the SDK) |

Optional:

- **adb** (comes with Android SDK `platform-tools`) — install the APK straight to a USB-connected phone  
- USB debugging enabled on the phone  

Run a quick check anytime:

```bat
check-setup.bat
```

Or choose **Check your PC setup** from `START.bat`.

---

## Prepare your Quasar app (once per project)

Your app must already have Capacitor Android. From the project folder:

```bat
cd C:\path\to\your-quasar-app
npm install
npx quasar mode add capacitor
```

When Quasar asks, pick **Android**. You should end up with:

```
your-app/
  package.json
  quasar.config.js   (or .ts / .cjs)
  src-capacitor/
    capacitor.config.*
    package.json
    android/
      gradlew.bat
      app/build.gradle
```

The builder scans for these before building. If something is missing, it lists exactly what to fix.

---

## How to use

### Option A — Friendly menu (recommended)

1. Open the **Quasar Compiler** folder  
2. Double-click **`START.bat`**  
3. Choose **1 — Build Android APK**  
4. Paste your project path (or drag the folder into the window)  
5. Choose **debug** (recommended) or **release**  
6. Wait for the build to finish  
7. Pick what to do next:
   - Open the APK in Explorer  
   - Copy it to `Desktop\QuasarBuilds`  
   - Install on a connected phone via adb  

### Option B — Run the builder directly

Double-click `build-capacitor-android.bat` and follow the prompts.

### Option C — Command line

```bat
build-capacitor-android.bat "C:\xampp\htdocs\my-app" debug
build-capacitor-android.bat "C:\xampp\htdocs\my-app" release
build-capacitor-android.bat /?
```

---

## Debug vs release

| Mode | Result | Install on phone? |
|------|--------|-------------------|
| **debug** (default) | `app-debug.apk` | Yes — best for testing |
| **release** | `app-release.apk` or unsigned | Only if signed |

Unsigned release APKs **will not install**. Use **debug** for sideloading, or configure a keystore in the Android project for signed releases.

---

## Where the APK is saved

After a successful build:

**Debug**

```
your-app\src-capacitor\android\app\build\outputs\apk\debug\app-debug.apk
```

**Release**

```
your-app\src-capacitor\android\app\build\outputs\apk\release\app-release.apk
```

or

```
...\app-release-unsigned.apk
```

If you use **Copy APK to Desktop**, files go to:

```
%USERPROFILE%\Desktop\QuasarBuilds\
```

---

## What the builder runs (behind the scenes)

```text
npm install                    (if needed, root + src-capacitor)
npx quasar build -m capacitor -T android --skip-pkg
npx cap sync android
gradlew.bat assembleDebug   or   assembleRelease
```

`--skip-pkg` avoids Quasar’s packaged release step so Gradle produces a normal APK you can install (debug) or sign yourself (release).

---

## Files in this folder

| File | Purpose |
|------|---------|
| **`START.bat`** | Main menu — start here |
| **`build-capacitor-android.bat`** | Builds the APK |
| **`check-setup.bat`** | Checks Node, Java, Android SDK |
| `build-capacitor-android-banner.ps1` / `.txt` | Colored banner |
| **`README.md`** | This guide |

---

## Install APK on a phone

### From the builder

After a successful **debug** build, choose **Install on connected phone (adb)**.

### Manually

1. On the phone: **Settings → Developer options → USB debugging** ON  
2. Connect USB and allow the computer  
3. Copy the APK to the phone and open it, **or**:

```bat
adb install -r "C:\path\to\app-debug.apk"
```

---

## Troubleshooting

| Problem | What to try |
|---------|-------------|
| `Node.js not found` | Install Node LTS and reopen the terminal / builder |
| `Java not found` / Gradle fails | Install JDK 17+, ensure `java` works in a new Command Prompt |
| Capacitor scan FAILED | Run `npx quasar mode add capacitor` in the app; ensure `src-capacitor\android` exists |
| Web build FAILED | Run `npm install` in the project root, then try again |
| Gradle FAILED | Run `check-setup.bat`; open Android Studio once so the SDK / licenses are installed |
| Unsigned APK won’t install | Build **debug** instead, or sign the release APK |
| `adb` install fails | Enable USB debugging; accept the RSA prompt; try another cable/port |
| Path with spaces | Quoting is fine: `"C:\My Projects\app"` — or drag the folder into the window |

---

## Example workflow

```bat
REM 1) One-time: check this PC
check-setup.bat

REM 2) Build a project (interactive menu)
START.bat

REM 3) Or one-shot from CLI
build-capacitor-android.bat "C:\xampp\htdocs\iwd_attendance" debug
```

Then install `app-debug.apk` on your phone and test.

---

## Notes

- **Windows only** (batch + `gradlew.bat`)  
- **Android only** (not iOS)  
- Does not replace Quasar CLI — it automates the Capacitor Android APK path  
- Safe to keep next to your XAMPP `htdocs` projects and reuse for every Quasar + Capacitor app  

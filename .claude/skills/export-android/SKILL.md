# Skill: Export Android Debug APK

Use this skill to build and export a debug APK for side-loading onto an Android device
for testing.

## Steps

### 1. Verify Java 17 is installed

```bash
java -version 2>&1
```

The output must show `version "17"` (or higher, though 17 is recommended for Godot
4.3). If Java is not installed or the wrong version is active:

- On Ubuntu/Debian: `sudo apt-get install -y openjdk-17-jdk`
- On macOS: `brew install openjdk@17`
- Set `JAVA_HOME` to the JDK 17 installation if multiple versions are present:
  `export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))`

Do not proceed until `java -version` reports version 17.

### 2. Ensure Godot 4.3 headless binary is available

Check if `./bin/godot` exists and is executable:

```bash
test -x ./bin/godot && echo "Godot present" || echo "Godot missing"
```

If missing, install it:

```bash
./tools/install_godot_linux.sh
```

Verify the version after installation:

```bash
./bin/godot --version
```

The output must start with `4.3`.

### 3. Ensure Android SDK is set up

Check for `ANDROID_HOME` and a working `sdkmanager`:

```bash
echo "ANDROID_HOME=${ANDROID_HOME:-NOT SET}"
test -d "${ANDROID_HOME:-/usr/lib/android-sdk}/build-tools" \
    && echo "Build tools present" || echo "SDK missing"
```

If the SDK is not set up:

```bash
./tools/install_android_sdk.sh
```

This installs build-tools 34.0.0, platform-tools, android-34, and the Godot Android
export templates.

### 4. Export the debug APK

```bash
mkdir -p build/android
./bin/godot --headless --export-debug "Android" \
    build/android/BubbleReefRush-debug.apk
```

If Godot reports `No export preset found for "Android"`, open the Godot editor, go to
**Project → Export**, add an Android preset named exactly `Android`, configure the
package name and keystore (debug keystore is fine for testing), and re-run.

### 5. Report APK size and location

After a successful export:

```bash
ls -lh build/android/BubbleReefRush-debug.apk
```

Report the file size and full path.

**To install on a test device:**

1. Enable Developer Mode on the Android device:
   Settings → About Phone → tap "Build Number" seven times.
2. Enable USB Debugging:
   Settings → Developer Options → USB Debugging → On.
3. Connect the device via USB and confirm the ADB prompt on the device.
4. Install the APK:
   ```bash
   adb install -r build/android/BubbleReefRush-debug.apk
   ```
5. Launch the app from the device's app drawer and verify it boots to the main menu.

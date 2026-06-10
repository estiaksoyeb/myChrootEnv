# Building Android Apps on an Android Phone with Gradle (AGP 8.x)

> **IMPORTANT:** This documentation is specifically for **proot** and **chroot** environments (e.g., Ubuntu, Debian, or Kali inside Termux/AndroidIDE). If you are using **native Termux**, many of these issues are handled by the `tur-repo` or standard package managers.

> How `android-sdk-custom` finally made it work.

For a long time, building modern Android apps (AGP 8.x) directly on an Android phone using the Gradle CLI felt impossible. The build would always fail with errors like:

- `Syntax error: word unexpected`
- `Exec format error`
- `AAPT2 Daemon startup failed`

This happened even inside Termux, Ubuntu sandbox, or AndroidIDE terminals. The reason turned out to be **binary architecture mismatch**, not Gradle or Kotlin.

This article documents the exact, hardened setup that finally produces a real, installable APK on an ARM64 Android device — without Android Studio or ACS — and explains why it works.

---

## Table of Contents

1. [The Real Problem](#the-real-problem)
2. [Installing and Configuring OpenJDK](#installing-and-configuring-openjdk)
3. [The Missing Piece: android-sdk-custom](#the-missing-piece-android-sdk-custom)
4. [Installing android-sdk-custom](#installing-android-sdk-custom)
5. [Pointing the Environment to the Custom SDK](#pointing-the-environment-to-the-custom-sdk)
6. [The Critical Discovery: AAPT2 Version Matters](#the-critical-discovery-aapt2-version-matters)
7. [Forcing Gradle to use the ARM64 AAPT2](#forcing-gradle-to-use-the-arm64-aapt2)
8. [compileSdk vs buildToolsVersion](#compile-sdk-vs-build-tools-version)
9. [One-time Cleanup](#one-time-cleanup)
10. [Building the App (Daemon vs No-Daemon)](#building-the-app-daemon-vs-no-daemon)
11. [Installing the APK](#installing-the-apk)
12. [NDK Setup for Native Code](./NDK%20Setup.md)
13. [Flutter Setup](./Flutter%20Setup.md)
14. [Why This Finally Works](#why-this-finally-works)
15. [Hard Rules for Future Setups](#hard-rules-for-future-setups)

---

## The Real Problem

Android Gradle Plugin (AGP 8.x) downloads AAPT2 binaries compiled for `x86_64` Linux from Maven. Android phones are **ARM64**, and even inside Linux environments on Android, those x86 binaries cannot execute.

When Gradle tries to run them, the shell interprets the ELF file as text, causing errors like:
> `Syntax error: Unterminated quoted string`

As long as Gradle keeps using those x86 AAPT2 binaries, CLI builds on a phone will fail.

---

## Installing and Configuring OpenJDK

Gradle requires a Java Development Kit (JDK) to compile and build Android applications. Depending on your environment (native Termux or a proot/chroot environment), the installation and path setup differ slightly.

### 1. Installation

#### Inside chroot / proot Environments (Ubuntu, Debian, Kali)
Update the package lists and install the OpenJDK package:
```bash
apt update
apt install openjdk-17-jdk
```

#### Inside Native Termux
Update repositories and install the package:
```bash
pkg update
pkg install openjdk-17
```

---

### 2. Finding the Installation Path

To set the `JAVA_HOME` environment variable, you need to find the directory where the JDK is installed.

Run the following helper command, which automatically resolves symlinks to locate the JDK root directory:
```bash
dirname $(dirname $(readlink -f $(which javac)))
```

**Common Paths:**
* **chroot/proot (Debian/Ubuntu/Kali):** `/usr/lib/jvm/java-17-openjdk-arm64` (or similar, depending on the Java version)
* **Native Termux:** `/data/data/com.termux/files/usr/opt/openjdk`

---

### 3. Exporting `JAVA_HOME`

To make the environment variable persistent across terminal sessions, add it to your shell configuration file (usually `~/.bashrc` or `~/.profile`).

1. Open your shell configuration file:
   ```bash
   nano ~/.bashrc
   ```

2. Add the following lines at the bottom (replace `/usr/lib/jvm/java-17-openjdk-arm64` with the path returned by the command in step 2):
   ```bash
   export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64
   export PATH=$JAVA_HOME/bin:$PATH
   ```

3. Reload the shell configuration:
   ```bash
   source ~/.bashrc
   ```

**Verification:**
Verify that Java is configured properly by running:
```bash
echo $JAVA_HOME
java -version
```

---

## The Missing Piece: `android-sdk-custom`

The breakthrough came from the project: [HomuHomu833/android-sdk-custom](https://github.com/HomuHomu833/android-sdk-custom)

This repository provides a custom-built Android SDK where native tools (including `aapt2`) are rebuilt using **Zig + musl**, making them:
- **ARM64-compatible**
- Runnable on Android kernels
- Independent of glibc
- Drop-in replacements for Google’s SDK tools

In short: **AAPT2 finally runs on the phone.**

---

## Installing `android-sdk-custom`

Instead of overwriting any existing SDK, the custom SDK is installed in parallel.

1. **Download the ARM64 SDK archive:**
   ```bash
   wget https://github.com/HomuHomu833/android-sdk-custom/releases/download/36.0.0/android-sdk-aarch64-linux-musl.tar.xz
   ```

2. **Extract it:**
   ```bash
   mkdir -p /opt/android-sdk-custom
   cd /opt/android-sdk-custom
   tar -xf android-sdk-aarch64-linux-musl.tar.xz
   ```

After extraction, the SDK lives at: `/opt/android-sdk-custom/android-sdk`

**Expected structure:**
```text
android-sdk/
├── build-tools/
├── cmdline-tools/
├── platform-tools/
└── licenses/
```

---

## Pointing the Environment to the Custom SDK

Before building anything, the shell must use this SDK instead of any system- or IDE-managed one.

```bash
export ANDROID_SDK_ROOT=/opt/android-sdk-custom/android-sdk
export ANDROID_HOME=/opt/android-sdk-custom/android-sdk
export PATH=$ANDROID_SDK_ROOT/platform-tools:$PATH
```

**Verification:**
```bash
adb version
```
If `adb` runs and reports ARM64, the SDK path is correct.

---

## The Critical Discovery: AAPT2 Version Matters

Inside the custom SDK, multiple `aapt2` binaries may exist. In practice:
- **35.0.0** → x86 (cannot execute on phone)
- **36.1.0** → ARM64 (works correctly)

**Proof:**
```bash
/opt/android-sdk-custom/android-sdk/build-tools/36.1.0/aapt2 version
```
This must print a version number. If it prints `Exec format error`, that binary is unusable.

---

## Forcing Gradle to use the ARM64 AAPT2 (Best Practice)

The most effective way to handle the AAPT2 override is to set it **globally** on your phone. This ensures that every project you build on your device works correctly without breaking the project's portability for desktop environments.

1. **Create or edit the global Gradle properties file:**
   ```bash
   mkdir -p ~/.gradle
   nano ~/.gradle/gradle.properties
   ```

2. **Add the following line:**
   ```properties
   # Global override for ARM64 Android devices
   android.aapt2FromMavenOverride=/opt/android-sdk-custom/android-sdk/build-tools/36.1.0/aapt2
   ```

3. **In your project's `gradle.properties`,** only include settings that improve stability:
   ```properties
   # Reduce instability on Android devices
   org.gradle.caching=false
   org.gradle.parallel=false
   org.gradle.configureondemand=false
   ```

This approach allows the project to build seamlessly on both your phone (using the global override) and your desktop (using standard Maven binaries).

---

## <a name="compile-sdk-vs-build-tools-version"></a>compileSdk vs buildToolsVersion

A key lesson learned:
- `compileSdk` does **NOT** need to match `build-tools`.
- `compileSdk 35` works perfectly with `build-tools 36.1.0`.

**Example (valid and recommended):**
```kotlin
android {
    compileSdk = 35
    buildToolsVersion = "36.1.0"
}
```
- `compileSdk` controls API availability.
- `buildToolsVersion` controls native tools like AAPT2.

---

## One-time Cleanup

Previous failed attempts leave broken x86 AAPT2 artifacts in Gradle’s cache. This step is mandatory the first time.

```bash
./gradlew --stop
rm -rf ~/.gradle/caches
```

---

## Building the App (Daemon vs No-Daemon)

On Android devices, Gradle daemon behavior matters a lot.

**Recommended build command:**
```bash
./gradlew assembleDebug
```

**Why:**
- The Gradle JVM exits after the build.
- RAM is released immediately.
- No background processes remain.

To enforce no-daemon globally, you can add to `~/.gradle/gradle.properties`:
```properties
org.gradle.daemon=false
```

**Optional (to prevent Kotlin daemon too):**
```properties
kotlin.compiler.execution.strategy=in-process
```

---

## Installing the APK

Building does not install the app.

```bash
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

If changes don’t appear immediately:
```bash
adb shell am force-stop com.your.package.name
adb shell monkey -p com.your.package.name 1
```

---

## Why This Finally Works

The working combination is:
1. **android-sdk-custom** providing ARM64-native tools.
2. **build-tools 36.1.0** with a working ARM64 `aapt2`.
3. **Explicit AAPT2 override** in `gradle.properties`.
4. **Clean Gradle caches** removing poisoned x86 artifacts.
5. **Daemon-free builds** to avoid memory leaks on phones.

Missing any one of these causes the build to fail.

---

## Hard Rules for Future Setups

- Never use `build-tools 35.x` aapt2 on a phone.
- Never rely on Gradle auto-selecting tools on Android.
- Always pin `android.aapt2FromMavenOverride`.
- Always clear caches after SDK changes.
- Build and install are separate steps.
- Prefer daemon-free builds on phones.

---

## Final Result

With this setup, you get:
- Full CLI-based Android builds on an Android phone.
- AGP 8.x compatibility.
- ARM64-native toolchain.
- No Android Studio or ACS dependency.
- Predictable memory usage.

This turns Android-on-Android development from a fragile hack into a repeatable, hardened workflow.

---

**Reference project:** [HomuHomu833/android-sdk-custom](https://github.com/HomuHomu833/android-sdk-custom)

# Flutter Setup on Android (ARM64)

> **IMPORTANT:** This guide is designed for **proot** and **chroot** environments (like Ubuntu on Android). It documents how to integrate the Flutter SDK with the `android-sdk-custom` toolchain on ARM64 hardware.

> How to fix "Android sdkmanager not found" and Dart version mismatches.

While Flutter is generally platform-agnostic, running it inside a Linux container on an Android phone requires specific adjustments to ensure it communicates correctly with the ARM64-native Android SDK.

---

## 1. Installation of Flutter SDK

### Prerequisites (Debian/Ubuntu)
Install essential tools and add the official Google Dart repository to your system:

```bash
apt update
apt install -y git unzip curl wget gnupg apt-transport-https

# Add Dart repository
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/dart.gpg
echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=arm64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | tee /etc/apt/sources.list.d/dart_stable.list

apt update
apt install -y dart
```

### Cloning Flutter
Use a shallow clone to save space and time on mobile devices:

```bash
git clone https://github.com/flutter/flutter.git -b stable --depth 1 ~/flutter
```

### Add to PATH
Flutter must be added to your shell configuration (e.g., `~/.zshrc` or `~/.bashrc`). It is critical to put it **at the front** of the PATH to ensure Flutter's bundled Dart is used instead of the system-wide Dart for Flutter-specific tasks.

    ```bash
    export PATH="$HOME/flutter/bin:$PATH"
    ```

---

## 2. The Critical Fix: `cmdline-tools` Structure

The `android-sdk-custom` provides the Command Line Tools, but they are often placed directly in the `cmdline-tools/` directory. Modern Flutter versions (and the `sdkmanager` itself) expect a versioned sub-folder (usually `latest/`). Without this, `flutter doctor` will report:
> `Android sdkmanager not found. Update to the latest Android SDK.`

### How to fix:
Reorganize the directory structure manually:

```bash
cd /opt/android-sdk-custom/android-sdk/cmdline-tools
mkdir latest
mv bin lib source.properties NOTICE.txt latest/
```

After this, the structure should look like:
`cmdline-tools/latest/bin/sdkmanager`

---

## 3. Accepting Android Licenses

Once the structure is fixed, you must accept the licenses. Use the `yes` pipe to automate the process:

```bash
yes | flutter doctor --android-licenses
```

---

## 4. Resolving Dart Path Warnings

If `flutter doctor` warns that `dart` resolves to a system path (e.g., `/usr/bin/dart`), ensure your `PATH` priority is correct. Your shell config should look like this:

```bash
# Correct PATH priority
export PATH="$HOME/flutter/bin:$ANDROID_HOME/platform-tools:$PATH"
```

Verify with:
```bash
which dart
# Should return: /root/flutter/bin/dart
```

---

## 5. Building and Running

### The Root Warning
When running Flutter as `root` (common in chroot environments), you will see:
> `Woah! You appear to be trying to run flutter as root.`

This is a safety warning and can be ignored for development inside a sandboxed environment.

### Target Device
Since you are developing on the device itself, ensure `adb` is connected to the local port (usually `localhost:5555`) so Flutter can see the phone as a deployment target.

```bash
flutter devices
# Should list your local device (e.g., innova30)
```

### Running your first app:
```bash
flutter create my_app
cd my_app
flutter run
```

---

## 6. Why This Works
1.  **AAPT2 Compatibility:** Because we configured the **Global AAPT2 Override** in `~/.gradle/gradle.properties` (see [Build with Termux.md](./Build%20with%20Termux.md)), Flutter's Gradle builds will correctly use the ARM64-native `aapt2` binary instead of failing with a `Syntax error`.
2.  **Native Tooling:** Flutter uses the existing `ANDROID_HOME` environment, leveraging the `android-sdk-custom` for all heavy lifting during the APK build process.

---

Next Step: Refer to [Build with Termux.md](./Build%20with%20Termux.md) for general SDK and Environment setup.

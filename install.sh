#!/usr/bin/env bash
set -e

# ===== CONFIG =====
SDK_VER="36.0.0"
AAPT_VER="36.1.0"
SDK_BASE="/opt/android-sdk-custom"
SDK_ROOT="$SDK_BASE/android-sdk"
SDK_URL="https://github.com/HomuHomu833/android-sdk-custom/releases/download/${SDK_VER}/android-sdk-aarch64-linux-musl.tar.xz"

# ===== INSTALL OPENJDK =====
echo "Checking for OpenJDK..."
if ! command -v javac &> /dev/null; then
  echo "OpenJDK (javac) not found. Attempting to install..."
  if command -v apt-get &> /dev/null; then
    echo "Detected apt-get package manager."
    apt-get update
    apt-get install -y openjdk-17-jdk
  elif command -v pkg &> /dev/null; then
    echo "Detected Termux pkg package manager."
    pkg update
    pkg install -y openjdk-17
  else
    echo "❌ Neither apt-get nor pkg package manager found. Please install OpenJDK 17 manually."
    exit 1
  fi
else
  echo "✅ OpenJDK is already installed."
fi

# ===== CONFIGURE JAVA_HOME =====
JAVA_PATH=$(dirname $(dirname $(readlink -f $(which javac))))
echo "Found JDK path at: $JAVA_PATH"

SHELL_RC=""
if [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
elif [ -f "$HOME/.profile" ]; then
  SHELL_RC="$HOME/.profile"
fi

if [ -n "$SHELL_RC" ]; then
  if ! grep -q "JAVA_HOME" "$SHELL_RC"; then
    echo "Configuring JAVA_HOME in $SHELL_RC..."
    echo "" >> "$SHELL_RC"
    echo "# OpenJDK configuration" >> "$SHELL_RC"
    echo "export JAVA_HOME=$JAVA_PATH" >> "$SHELL_RC"
    echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> "$SHELL_RC"
  else
    echo "JAVA_HOME is already configured in $SHELL_RC."
  fi
fi

# Export for the current script session as well
export JAVA_HOME="$JAVA_PATH"
export PATH="$JAVA_HOME/bin:$PATH"

# ===== INSTALL ANDROID SDK (ARM64) =====
mkdir -p "$SDK_BASE"
(
  cd "$SDK_BASE"
  if [ ! -d "$SDK_ROOT" ]; then
    wget -q --show-progress "$SDK_URL"
    tar -xf android-sdk-aarch64-linux-musl.tar.xz
  fi
)

# ===== ENVIRONMENT =====
export ANDROID_SDK_ROOT="$SDK_ROOT"
export ANDROID_HOME="$SDK_ROOT"
export PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"

# ===== VERIFY ADB =====
adb version

# ===== VERIFY AAPT2 (ARM64 REQUIRED) =====
"$ANDROID_SDK_ROOT/build-tools/$AAPT_VER/aapt2" version

# ===== FORCE GRADLE TO USE ARM64 AAPT2 =====
mkdir -p ~/.gradle
GRADLE_PROP="$HOME/.gradle/gradle.properties"

grep -q "android.aapt2FromMavenOverride" "$GRADLE_PROP" 2>/dev/null || \
echo "android.aapt2FromMavenOverride=$ANDROID_SDK_ROOT/build-tools/$AAPT_VER/aapt2" >> "$GRADLE_PROP"

# ===== RECOMMENDED STABILITY FLAGS (PHONE BUILDS) =====
grep -q "org.gradle.daemon" "$GRADLE_PROP" 2>/dev/null || cat >> "$GRADLE_PROP" <<EOF

org.gradle.daemon=false
org.gradle.parallel=false
org.gradle.caching=false
kotlin.compiler.execution.strategy=in-process
EOF

# ===== CLEAN POISONED CACHES (RUN ONCE) =====
./gradlew --stop 2>/dev/null || true
rm -rf ~/.gradle/caches

echo "✅ ARM64 Android SDK installed"
echo "✅ ARM64 AAPT2 forced globally"
echo "✅ Ready to build with: ./gradlew assembleDebug"

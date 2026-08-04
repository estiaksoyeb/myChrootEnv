#!/usr/bin/env bash
set -e

# ===== CONFIG =====
SDK_VER="36.0.0"
AAPT_VER="36.1.0"
SDK_BASE="/opt/android-sdk-custom"

# Fallback to home directory if /opt is not writable and does not exist
if [ ! -d "$SDK_BASE" ] && [ ! -w "/opt" ] 2>/dev/null; then
  echo "⚠️ /opt is not writable. Installing SDK to $HOME/android-sdk-custom instead."
  SDK_BASE="$HOME/android-sdk-custom"
fi
SDK_ROOT="$SDK_BASE/android-sdk"
SDK_URL="https://github.com/HomuHomu833/android-sdk-custom/releases/download/${SDK_VER}/android-sdk-aarch64-linux-musl.tar.xz"

# ===== CHECK SYSTEM UTILITIES =====
echo "Checking required system utilities..."
for cmd in wget tar; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Installing missing dependency: $cmd..."
    if command -v apt-get &>/dev/null; then
      apt-get update && apt-get install -y "$cmd"
    elif command -v pkg &>/dev/null; then
      pkg update && pkg install -y "$cmd"
    else
      echo "❌ System utility '$cmd' is missing and no package manager is available to install it. Please install it manually."
      exit 1
    fi
  fi
done

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

# ===== INSTALL ANDROID SDK (ARM64) =====
mkdir -p "$SDK_BASE"
(
  cd "$SDK_BASE"
  if [ ! -d "$SDK_ROOT" ]; then
    echo "Downloading custom Android SDK..."
    wget -q --show-progress "$SDK_URL"
    echo "Extracting SDK..."
    tar -xf android-sdk-aarch64-linux-musl.tar.xz
    echo "Cleaning up archive to save space..."
    rm -f android-sdk-aarch64-linux-musl.tar.xz
  fi
)

# ===== CONFIGURE ENVIRONMENT VARIABLES =====
SHELL_RC=""
if [ -f "$HOME/.bashrc" ]; then
  SHELL_RC="$HOME/.bashrc"
elif [ -f "$HOME/.profile" ]; then
  SHELL_RC="$HOME/.profile"
fi

if [ -n "$SHELL_RC" ]; then
  if ! grep -q "android-sdk-custom" "$SHELL_RC"; then
    echo "Configuring environment variables in $SHELL_RC..."
    cat >> "$SHELL_RC" <<EOF

# ===== android-sdk-custom Environment =====
export JAVA_HOME=$JAVA_PATH
export ANDROID_HOME=$SDK_ROOT
export ANDROID_SDK_ROOT=$SDK_ROOT
export PATH=\$JAVA_HOME/bin:\$ANDROID_SDK_ROOT/platform-tools:\$PATH
# ==========================================
EOF
    echo "✅ Environment configured. Run 'source $SHELL_RC' to apply."
  else
    echo "✅ Environment variables already configured in $SHELL_RC."
  fi
fi

# Export for the current script session as well
export JAVA_HOME="$JAVA_PATH"
export ANDROID_HOME="$SDK_ROOT"
export ANDROID_SDK_ROOT="$SDK_ROOT"
export PATH="$JAVA_HOME/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

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
if [ -f "./gradlew" ]; then
  echo "Stopping active Gradle daemons..."
  ./gradlew --stop 2>/dev/null || true
fi
echo "Cleaning only poisoned AAPT2 cache entries..."
find "$HOME/.gradle/caches" -name "*aapt2*" -exec rm -rf {} + 2>/dev/null || true

echo "✅ ARM64 Android SDK installed"
echo "✅ ARM64 AAPT2 forced globally"
echo "✅ Ready to build with: ./gradlew assembleDebug"

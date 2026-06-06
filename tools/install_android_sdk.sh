#!/usr/bin/env bash
# Set up Android SDK and Godot 4.3 Android export templates on Ubuntu CI.
set -euo pipefail

GODOT_VERSION="4.3"
GODOT_RELEASE="stable"
GODOT_TAG="${GODOT_VERSION}-${GODOT_RELEASE}"
ANDROID_BUILD_TOOLS_VERSION="34.0.0"
ANDROID_PLATFORM="android-34"

# ---------------------------------------------------------------------------
# Helper: check if a command exists
# ---------------------------------------------------------------------------
command_exists() { command -v "$1" &>/dev/null; }

# ---------------------------------------------------------------------------
# 1. Install system packages
# ---------------------------------------------------------------------------
echo "=== Installing system packages ==="
PACKAGES_NEEDED=()

if ! command_exists java; then
    PACKAGES_NEEDED+=(openjdk-17-jdk)
fi

# android-sdk-build-tools pulls in a minimal SDK and sdkmanager stub on Ubuntu
dpkg -s android-sdk-build-tools &>/dev/null 2>&1 || PACKAGES_NEEDED+=(android-sdk-build-tools)

if [[ ${#PACKAGES_NEEDED[@]} -gt 0 ]]; then
    echo "Installing: ${PACKAGES_NEEDED[*]}"
    sudo apt-get update -qq
    sudo apt-get install -y --no-install-recommends "${PACKAGES_NEEDED[@]}"
else
    echo "Required system packages already present."
fi

# ---------------------------------------------------------------------------
# 2. Locate or bootstrap Android SDK root
# ---------------------------------------------------------------------------
echo ""
echo "=== Configuring Android SDK environment ==="

# Prefer the CI-provided location, fall back to the Ubuntu apt-installed path
if [[ -z "${ANDROID_HOME:-}" ]]; then
    if [[ -d "/usr/lib/android-sdk" ]]; then
        export ANDROID_HOME="/usr/lib/android-sdk"
    elif [[ -d "${HOME}/android-sdk" ]]; then
        export ANDROID_HOME="${HOME}/android-sdk"
    else
        export ANDROID_HOME="${HOME}/android-sdk"
        mkdir -p "${ANDROID_HOME}"
    fi
fi
export ANDROID_SDK_ROOT="${ANDROID_HOME}"

echo "ANDROID_HOME=${ANDROID_HOME}"
echo "ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT}"

# Persist env vars for subsequent steps in the same GitHub Actions job
if [[ -n "${GITHUB_ENV:-}" ]]; then
    {
        echo "ANDROID_HOME=${ANDROID_HOME}"
        echo "ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT}"
    } >> "${GITHUB_ENV}"
fi

# ---------------------------------------------------------------------------
# 3. Locate sdkmanager
# ---------------------------------------------------------------------------
echo ""
echo "=== Locating sdkmanager ==="

SDKMANAGER=""
for candidate in \
    "${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager" \
    "${ANDROID_HOME}/cmdline-tools/bin/sdkmanager" \
    "${ANDROID_HOME}/tools/bin/sdkmanager" \
    "$(command -v sdkmanager 2>/dev/null || true)"
do
    if [[ -x "${candidate}" ]]; then
        SDKMANAGER="${candidate}"
        break
    fi
done

# If not found, download commandline-tools
if [[ -z "${SDKMANAGER}" ]]; then
    echo "sdkmanager not found — downloading Android command-line tools..."
    CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    WORK_DIR="$(mktemp -d)"
    trap 'rm -rf "${WORK_DIR}"' EXIT
    curl -fsSL --retry 3 -o "${WORK_DIR}/cmdline-tools.zip" "${CMDLINE_TOOLS_URL}"
    unzip -q "${WORK_DIR}/cmdline-tools.zip" -d "${WORK_DIR}"
    mkdir -p "${ANDROID_HOME}/cmdline-tools"
    mv "${WORK_DIR}/cmdline-tools" "${ANDROID_HOME}/cmdline-tools/latest"
    SDKMANAGER="${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager"
fi

echo "Using sdkmanager: ${SDKMANAGER}"

# ---------------------------------------------------------------------------
# 4. Accept licenses
# ---------------------------------------------------------------------------
echo ""
echo "=== Accepting SDK licenses ==="
yes | "${SDKMANAGER}" --licenses || true   # 'true' because it exits 1 even on success

# ---------------------------------------------------------------------------
# 5. Install SDK components
# ---------------------------------------------------------------------------
echo ""
echo "=== Installing SDK components ==="
"${SDKMANAGER}" \
    "platform-tools" \
    "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
    "platforms;${ANDROID_PLATFORM}"

# ---------------------------------------------------------------------------
# 6. Download and install Godot Android export templates
# ---------------------------------------------------------------------------
echo ""
echo "=== Installing Godot ${GODOT_TAG} Android export templates ==="

TEMPLATES_DIR="${HOME}/.local/share/godot/export_templates/${GODOT_VERSION}.${GODOT_RELEASE}"
TEMPLATES_ZIP="Godot_v${GODOT_TAG}_export_templates.tpz"
TEMPLATES_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_TAG}/${TEMPLATES_ZIP}"

if [[ -f "${TEMPLATES_DIR}/android_debug.apk" ]] || \
   [[ -f "${TEMPLATES_DIR}/android_source.zip" ]]; then
    echo "Godot export templates already installed — skipping download."
else
    mkdir -p "${TEMPLATES_DIR}"
    TPZWORK="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap 'rm -rf "${TPZWORK}"' EXIT
    echo "Downloading ${TEMPLATES_URL}..."
    curl -fsSL --retry 3 --retry-delay 5 \
        -o "${TPZWORK}/${TEMPLATES_ZIP}" \
        "${TEMPLATES_URL}"
    echo "Extracting export templates..."
    # .tpz is a zip; inner folder is named 'templates'
    unzip -q "${TPZWORK}/${TEMPLATES_ZIP}" -d "${TPZWORK}"
    cp -r "${TPZWORK}/templates/." "${TEMPLATES_DIR}/"
    echo "Export templates installed to ${TEMPLATES_DIR}"
fi

# ---------------------------------------------------------------------------
# 7. Done
# ---------------------------------------------------------------------------
echo ""
echo "=== Android SDK setup complete ==="
echo "  ANDROID_HOME        = ${ANDROID_HOME}"
echo "  ANDROID_SDK_ROOT    = ${ANDROID_SDK_ROOT}"
echo "  Build tools version = ${ANDROID_BUILD_TOOLS_VERSION}"
echo "  Platform            = ${ANDROID_PLATFORM}"
echo "  Godot templates     = ${TEMPLATES_DIR}"

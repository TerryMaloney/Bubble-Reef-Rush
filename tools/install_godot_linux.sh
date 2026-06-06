#!/usr/bin/env bash
# Install Godot 4.3 headless binary to ./bin/godot (Linux x86_64).
set -euo pipefail

GODOT_VERSION="4.3"
GODOT_RELEASE="stable"
GODOT_TAG="${GODOT_VERSION}-${GODOT_RELEASE}"
GODOT_FILENAME="Godot_v${GODOT_TAG}_linux.x86_64"
GODOT_ZIP="${GODOT_FILENAME}.zip"
DOWNLOAD_URL="https://github.com/godotengine/godot-builds/releases/download/${GODOT_TAG}/${GODOT_ZIP}"
BIN_DIR="./bin"
GODOT_BINARY="${BIN_DIR}/godot"

# --- Cache check -----------------------------------------------------------
if [[ -x "${GODOT_BINARY}" ]]; then
    echo "Godot binary already present and executable — skipping download."
    echo "Version: $(${GODOT_BINARY} --version 2>&1 || true)"
    exit 0
fi

# --- Prepare directories ---------------------------------------------------
mkdir -p "${BIN_DIR}"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "${WORK_DIR}"' EXIT

# --- Download --------------------------------------------------------------
echo "Downloading Godot ${GODOT_TAG} from:"
echo "  ${DOWNLOAD_URL}"
curl -fsSL --retry 3 --retry-delay 5 \
    -o "${WORK_DIR}/${GODOT_ZIP}" \
    "${DOWNLOAD_URL}"

# --- Extract ---------------------------------------------------------------
echo "Extracting ${GODOT_ZIP}..."
unzip -q "${WORK_DIR}/${GODOT_ZIP}" -d "${WORK_DIR}"

# The zip contains a single file named exactly $GODOT_FILENAME
EXTRACTED="${WORK_DIR}/${GODOT_FILENAME}"
if [[ ! -f "${EXTRACTED}" ]]; then
    echo "ERROR: Expected extracted binary not found at ${EXTRACTED}" >&2
    echo "Contents of work dir:" >&2
    ls -la "${WORK_DIR}" >&2
    exit 1
fi

# --- Install ---------------------------------------------------------------
mv "${EXTRACTED}" "${GODOT_BINARY}"
chmod +x "${GODOT_BINARY}"

# --- Verify ----------------------------------------------------------------
echo "Verifying Godot installation..."
VERSION_OUTPUT="$(${GODOT_BINARY} --version 2>&1)"
echo "Godot version: ${VERSION_OUTPUT}"

echo "Godot 4.3 headless installed successfully to ${GODOT_BINARY}"

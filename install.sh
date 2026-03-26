#!/bin/bash
set -e

FAB_HOME="$HOME/.fab"
BIN_DIR="$FAB_HOME/bin"

echo "Installing fabup..."

# Detect platform
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$ARCH" in
  arm64|aarch64) ARCH="arm64" ;;
  x86_64)        ARCH="x64" ;;
  *)             echo "Error: Unsupported architecture: $ARCH"; exit 1 ;;
esac
TARGET="$OS-$ARCH"
echo "Platform: $TARGET"

# Create directory
mkdir -p "$BIN_DIR"

# Determine repo (update this after creating the fabup repo)
REPO="xudshen/fabup"

# Get latest release tag
echo "Fetching latest version..."
LATEST=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep '"tag_name"' | cut -d'"' -f4)

if [ -z "$LATEST" ]; then
  echo "Error: Could not determine latest version."
  echo "If the repo is private, set GITHUB_TOKEN and retry."
  exit 1
fi
echo "Latest version: $LATEST"

# Download binary (fabup repo is public, no token needed)
DOWNLOAD_URL="https://github.com/$REPO/releases/download/$LATEST/fab-$TARGET"
echo "Downloading fab-$TARGET..."

curl -fsSL -o "$BIN_DIR/fab" "$DOWNLOAD_URL"
chmod +x "$BIN_DIR/fab"

# Verify
"$BIN_DIR/fab" --version

# Add to PATH if needed
SHELL_RC="$HOME/.zshrc"
if [[ "$SHELL" == */bash ]]; then
  SHELL_RC="$HOME/.bashrc"
elif [[ "$SHELL" == */fish ]]; then
  SHELL_RC="$HOME/.config/fish/config.fish"
fi

if grep -q "$BIN_DIR" "$SHELL_RC" 2>/dev/null; then
  echo "$BIN_DIR is already in $SHELL_RC."
else
  echo "" >> "$SHELL_RC"
  echo "# FAB version manager" >> "$SHELL_RC"
  echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_RC"
  echo ""
  echo "Added $BIN_DIR to PATH in $SHELL_RC"
  echo "Run: source $SHELL_RC"
fi

echo ""
echo "fabup installed successfully!"
echo "Next: fab install <version>"

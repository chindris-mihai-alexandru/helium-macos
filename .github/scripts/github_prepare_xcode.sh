#!/bin/bash -eux

set -o pipefail

# Find Xcode - handle both GitHub-hosted (versioned) and self-hosted (Xcode.app) runners
XCODE_PATH=""

for candidate in /Applications/Xcode_16.2.app /Applications/Xcode_16.2.0.app /Applications/Xcode_16.1.app /Applications/Xcode_16.1.0.app /Applications/Xcode_15.4.app /Applications/Xcode_15.4.0.app /Applications/Xcode_15.3.app /Applications/Xcode_26.0.app /Applications/Xcode_26.app /Applications/Xcode.app; do
  if [ -e "$candidate" ]; then
    XCODE_PATH="$candidate"
    break
  fi
done

if [ -z "$XCODE_PATH" ]; then
  echo "Failed to find a suitable version of Xcode"
  echo "Available Xcode versions:"
  ls -d /Applications/Xcode* 2>/dev/null || echo "  (none found)"
  exit 1
fi

echo "Using Xcode at: $XCODE_PATH"

# Switch to found Xcode
sudo xcode-select --switch "$XCODE_PATH"

# Clean simulators to save disk space
sudo xcrun simctl delete all || true

# Make sure metal toolchain is installed
xcodebuild -downloadComponent MetalToolchain || true

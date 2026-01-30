#!/bin/bash
# Copy the compiled metallib from Xcode to the swift build directory
# This allows running swift-build binaries from command line

set -e

XCODE_BUILD=$(ls -d ~/Library/Developer/Xcode/DerivedData/heylook-swift-*/Build/Products/Debug 2>/dev/null | head -1)
SWIFT_BUILD="/Users/fredbliss/workspace/heylook-swift/.build/arm64-apple-macosx/debug"

if [ -z "$XCODE_BUILD" ] || [ ! -f "$XCODE_BUILD/mlx-swift_Cmlx.bundle/Contents/Resources/default.metallib" ]; then
    echo "Metallib not found. Building with xcodebuild first..."
    cd /Users/fredbliss/workspace/heylook-swift
    xcodebuild build -scheme HeyLook -destination 'platform=macOS' -quiet
    XCODE_BUILD=$(ls -d ~/Library/Developer/Xcode/DerivedData/heylook-swift-*/Build/Products/Debug 2>/dev/null | head -1)
fi

METALLIB="$XCODE_BUILD/mlx-swift_Cmlx.bundle/Contents/Resources/default.metallib"

if [ ! -f "$METALLIB" ]; then
    echo "Error: Could not find default.metallib"
    exit 1
fi

# Create bundle structure for swift build
mkdir -p "$SWIFT_BUILD/mlx-swift_Cmlx.bundle/Contents/Resources"
cp "$METALLIB" "$SWIFT_BUILD/mlx-swift_Cmlx.bundle/Contents/Resources/"

# Also copy as colocated mlx.metallib for fallback loading
cp "$METALLIB" "$SWIFT_BUILD/mlx.metallib"

echo "Metallib copied to swift build directory!"
echo "You can now run: swift build && .build/debug/HeyLook"

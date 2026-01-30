#!/bin/bash
# Build script for HeyLook using xcodebuild (required for Metal shader compilation)

set -e

echo "Building HeyLook with xcodebuild..."
xcodebuild build -scheme HeyLook -destination 'platform=macOS' -quiet

BUILD_DIR=~/Library/Developer/Xcode/DerivedData/heylook-swift-*/Build/Products/Debug

echo ""
echo "Build complete!"
echo "Binary location: $BUILD_DIR/HeyLook"
echo ""
echo "To run: $BUILD_DIR/HeyLook"

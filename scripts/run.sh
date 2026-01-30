#!/bin/bash
# Run HeyLook from Xcode build output

BUILD_DIR=$(ls -d ~/Library/Developer/Xcode/DerivedData/heylook-swift-*/Build/Products/Debug 2>/dev/null | head -1)

if [ -z "$BUILD_DIR" ] || [ ! -f "$BUILD_DIR/HeyLook" ]; then
    echo "HeyLook not found. Building first..."
    ./scripts/build.sh
    BUILD_DIR=$(ls -d ~/Library/Developer/Xcode/DerivedData/heylook-swift-*/Build/Products/Debug 2>/dev/null | head -1)
fi

echo "Launching HeyLook..."
"$BUILD_DIR/HeyLook"

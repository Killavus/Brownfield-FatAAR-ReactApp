#!/bin/bash

CONFIGURATION=${1:-Debug}

# npx pod-install
pushd ios
xcodebuild \
  -workspace ReactApp.xcworkspace \
  -scheme RNLib \
  -derivedDataPath build \
  -destination "generic/platform=iphonesimulator" \
  -configuration $CONFIGURATION || { echo "Build failed"; exit 1; }
xcodebuild \
  -workspace ReactApp.xcworkspace \
  -scheme RNLib \
  -derivedDataPath build \
  -destination "generic/platform=iphoneos" \
  -configuration $CONFIGURATION || { echo "Build failed"; exit 1; }
xcodebuild -create-xcframework \
  -framework build/Build/Products/$CONFIGURATION-iphonesimulator/RNLib.framework \
  -framework build/Build/Products/$CONFIGURATION-iphoneos/RNLib.framework \
  -output RNLib.xcframework || { echo "Merge failed"; exit 1; }
popd

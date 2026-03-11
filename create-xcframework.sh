#!/bin/bash

CONFIGURATION=${1:-Debug}

# npx pod-install
pushd ios

rm -rf FrameworkOutputs
mkdir -p FrameworkOutputs

# Remove previously merged RNLib binaries to prevent stale symbols
# from accumulating across incremental builds.
rm -f build/Build/Products/*/RNLib.framework/RNLib

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

# Merge all static pod frameworks into RNLib for each platform
for PLATFORM in iphonesimulator iphoneos; do
  PRODUCTS="build/Build/Products/$CONFIGURATION-$PLATFORM"
  RNLIB_FW="$PRODUCTS/RNLib.framework"

  # Collect all static framework binaries from pod subdirectories
  # Exclude ReactBrownfield — it's shipped as a separate XCFramework
  # because RNLib's swiftinterface uses @_exported import ReactBrownfield,
  # so consumers need its module definition available.
  STATIC_LIBS=()
  for POD_FW in "$PRODUCTS"/*/; do
    POD_NAME=$(basename "$POD_FW")
    POD_BIN="$POD_FW$POD_NAME.framework/$POD_NAME"
    if [ "$POD_NAME" = "ReactBrownfield" ]; then
      continue
    fi
    if [ -f "$POD_BIN" ]; then
      # Only merge static archives, skip dynamic libs
      if file "$POD_BIN" | grep -q "ar archive"; then
        STATIC_LIBS+=("$POD_BIN")
      fi
    fi
  done

  # Merge static libraries into RNLib binary
  libtool -static -o "$RNLIB_FW/RNLib.merged" \
    "$RNLIB_FW/RNLib" \
    "${STATIC_LIBS[@]}" || { echo "libtool merge failed for $PLATFORM"; exit 1; }
  mv "$RNLIB_FW/RNLib.merged" "$RNLIB_FW/RNLib"
done

xcodebuild -create-xcframework \
  -framework build/Build/Products/$CONFIGURATION-iphonesimulator/RNLib.framework \
  -framework build/Build/Products/$CONFIGURATION-iphoneos/RNLib.framework \
  -output FrameworkOutputs/RNLib.xcframework || { echo "Merge failed"; exit 1; }
xcodebuild -create-xcframework \
  -framework build/Build/Products/$CONFIGURATION-iphonesimulator/ReactBrownfield/ReactBrownfield.framework \
  -framework build/Build/Products/$CONFIGURATION-iphoneos/ReactBrownfield/ReactBrownfield.framework \
  -output FrameworkOutputs/ReactBrownfield.xcframework || { echo "Merge failed"; exit 1; }

# Copy prebuilt dynamic XCFrameworks
cp -R Pods/hermes-engine/destroot/Library/Frameworks/universal/hermesvm.xcframework FrameworkOutputs/hermesvm.xcframework
cp -R Pods/React-Core-prebuilt/React.xcframework FrameworkOutputs/React.xcframework
cp -R Pods/ReactNativeDependencies/framework/packages/react-native/ReactNativeDependencies.xcframework FrameworkOutputs/ReactNativeDependencies.xcframework
popd

#!/bin/sh
set -e

# Clean previous
rm -rf .tmp/ || true
mkdir -p .tmp

# Variables
TAG_VERSION="4.0.0a13"
HASH="42e57023-0f69f7d4"
BASE_URL="https://download.videolan.org/pub/cocoapods/unstable"
# Note: VLCKit binary tarball contains "VLCKit-binary/VLCKit.xcframework"
IONAME="VLCKit-${TAG_VERSION}-${HASH}.tar.xz"

# Download iOS-only VLCKit XCFramework
curl -L "$BASE_URL/$IONAME" -o .tmp/VLCKit.tar.xz

# Extract into .tmp/
tar -xf .tmp/VLCKit.tar.xz -C .tmp/

# Point to extracted XCFramework
IOS_LOCATION=".tmp/VLCKit-binary/VLCKit.xcframework"

# Prepare output XCFramework (rename to VLCKit-all)
cp -R "$IOS_LOCATION" .tmp/VLCKit-all.xcframework

# Zip the combined framework
ditto -c -k --sequesterRsrc --keepParent ".tmp/VLCKit-all.xcframework" ".tmp/VLCKit-all.xcframework.zip"

# Compute checksum (sha256sum or fallback to shasum)
if command -v sha256sum >/dev/null 2>&1; then
  PACKAGE_HASH=$(sha256sum ".tmp/VLCKit-all.xcframework.zip" | awk '{print $1}')
else
  PACKAGE_HASH=$(shasum -a 256 ".tmp/VLCKit-all.xcframework.zip" | awk '{print $1}')
fi

# Update Package.swift with the new checksum
sed -i '' -e "s|checksum: \".*\"|checksum: \"$PACKAGE_HASH\"|" Package.swift

echo "Updated Package.swift with checksum: $PACKAGE_HASH"

# Copy license file
cp -f .tmp/VLCKit-binary/COPYING.txt ./LICENSE
#!/bin/bash

# Fix for missing privacy bundle files in Flutter iOS builds
# This script creates empty privacy files to resolve build errors

BUILD_DIR="$1"
if [ -z "$BUILD_DIR" ]; then
    BUILD_DIR="../build/ios/Release-iphoneos"
fi

echo "Fixing privacy bundles in: $BUILD_DIR"

# Create shared_preferences_foundation privacy bundle
SHARED_PREFS_DIR="$BUILD_DIR/shared_preferences_foundation/shared_preferences_foundation_privacy.bundle"
mkdir -p "$SHARED_PREFS_DIR"
touch "$SHARED_PREFS_DIR/shared_preferences_foundation_privacy"

# Create path_provider_foundation privacy bundle
PATH_PROVIDER_DIR="$BUILD_DIR/path_provider_foundation/path_provider_foundation_privacy.bundle"
mkdir -p "$PATH_PROVIDER_DIR"
touch "$PATH_PROVIDER_DIR/path_provider_foundation_privacy"

# Create permission_handler_apple privacy bundle
PERMISSION_DIR="$BUILD_DIR/permission_handler_apple/permission_handler_apple_privacy.bundle"
mkdir -p "$PERMISSION_DIR"
touch "$PERMISSION_DIR/permission_handler_apple_privacy"

echo "Privacy bundle files created successfully"

#!/bin/bash

# Fix iOS Privacy Bundle Build Issues
# This script creates missing privacy bundle files that cause iOS build failures

echo "🔧 Fixing iOS Privacy Bundle Issues..."

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build/ios/Release-iphoneos"

echo "📁 Project root: $PROJECT_ROOT"
echo "🏗️ Build directory: $BUILD_DIR"

# Function to create privacy bundle directory and file
create_privacy_bundle() {
    local plugin_name="$1"
    local bundle_dir="$BUILD_DIR/$plugin_name/${plugin_name}_privacy.bundle"
    local privacy_file="$bundle_dir/${plugin_name}_privacy"
    
    echo "📦 Creating privacy bundle for $plugin_name..."
    
    # Create bundle directory
    mkdir -p "$bundle_dir"
    
    # Create privacy file (can be empty or contain minimal content)
    cat > "$privacy_file" << EOF
# Privacy bundle for $plugin_name
# This file resolves iOS build issues related to privacy manifest bundles
# Generated automatically by fix_ios_privacy_bundles.sh
EOF
    
    echo "✅ Created: $privacy_file"
}

# Create build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

# Create privacy bundles for problematic plugins
create_privacy_bundle "shared_preferences_foundation"
create_privacy_bundle "permission_handler_apple"
create_privacy_bundle "path_provider_foundation"
create_privacy_bundle "camera_avfoundation"
create_privacy_bundle "tflite_flutter"

echo ""
echo "🎉 Privacy bundle fix completed!"
echo ""
echo "Next steps:"
echo "1. Run: flutter clean"
echo "2. Run: flutter pub get"
echo "3. Run: flutter build ios --release --no-codesign"
echo ""

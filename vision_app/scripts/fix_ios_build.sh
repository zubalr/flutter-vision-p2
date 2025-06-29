#!/bin/bash

# iOS Build Fix Script for TensorFlow Lite Issues
# This script cleans and rebuilds the iOS project to fix dylib loading issues

echo "🔧 Fixing iOS Build Issues for TensorFlow Lite"
echo "=============================================="

# Step 1: Clean Flutter build
echo "1️⃣ Cleaning Flutter build..."
flutter clean

# Step 2: Remove iOS build artifacts
echo "2️⃣ Removing iOS build artifacts..."
rm -rf ios/build
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec

# Step 3: Remove derived data (if accessible)
echo "3️⃣ Clearing Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

# Step 4: Get Flutter dependencies
echo "4️⃣ Getting Flutter dependencies..."
flutter pub get

# Step 5: Install CocoaPods dependencies
echo "5️⃣ Installing CocoaPods dependencies..."
cd ios
pod deintegrate 2>/dev/null || true
pod cache clean --all 2>/dev/null || true
pod install --repo-update
cd ..

# Step 6: Build iOS project
echo "6️⃣ Building iOS project..."
flutter build ios --debug --no-codesign

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ iOS build fix completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Open Xcode: open ios/Runner.xcworkspace"
    echo "2. Select your development team in Signing & Capabilities"
    echo "3. Run the app from Xcode or use: flutter run"
    echo ""
    echo "If you still get dylib errors:"
    echo "- Make sure you have the latest Xcode version"
    echo "- Try running on a different iOS simulator version"
    echo "- Check that your iOS deployment target is 13.0 or higher"
else
    echo ""
    echo "❌ iOS build fix failed"
    echo "Please check the error messages above and try:"
    echo "1. Update Xcode to the latest version"
    echo "2. Update CocoaPods: sudo gem install cocoapods"
    echo "3. Check iOS deployment target in Xcode"
    echo "4. Try running: flutter doctor -v"
fi
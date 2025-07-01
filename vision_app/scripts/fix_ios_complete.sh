#!/bin/bash

# Complete iOS Build Fix for Flutter Vision App
# Fixes privacy bundles, TensorFlow Lite, and camera permissions
echo "Complete iOS Build Fix for Flutter Vision App"
echo "=============================================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "ERROR: Please run this script from the Flutter project root directory"
    exit 1
fi

# Step 1: Clean everything
echo "1. Cleaning project..."
flutter clean
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks ios/build
rm -rf build/
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-* 2>/dev/null || true

# Step 2: Get dependencies
echo "2. Getting Flutter dependencies..."
flutter pub get

# Step 3: Create optimized Podfile
echo "3. Creating optimized Podfile..."
cat > ios/Podfile << 'EOF'
platform :ios, '13.0'

ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      
      # Camera permissions
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
      ]
      
      # TensorFlow Lite compatibility
      config.build_settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'gnu++17'
      config.build_settings['CLANG_CXX_LIBRARY'] = 'libc++'
      
      # Essential linker settings
      config.build_settings['OTHER_LDFLAGS'] ||= ['$(inherited)']
      config.build_settings['OTHER_LDFLAGS'] << '-ObjC'
      config.build_settings['OTHER_LDFLAGS'] << '-lc++'
      
      # Framework and runtime paths
      config.build_settings['FRAMEWORK_SEARCH_PATHS'] ||= ['$(inherited)']
      config.build_settings['LD_RUNPATH_SEARCH_PATHS'] ||= [
        '$(inherited)',
        '@executable_path/Frameworks',
        '@loader_path/Frameworks',
      ]
      
      # Swift libraries
      config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
      
      # Fix for privacy bundle issues
      if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
        config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = ''
      end
      
      # TensorFlow Lite specific fixes
      if target.name.include?('TensorFlow') || target.name.include?('tflite')
        config.build_settings['VALID_ARCHS'] = 'arm64 x86_64'
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'i386'
        config.build_settings['STRIP_INSTALLED_PRODUCT'] = 'NO'
        config.build_settings['COPY_PHASE_STRIP'] = 'NO'
      end
    end
  end
end
EOF

# Step 4: Install pods
echo "4. Installing CocoaPods..."
cd ios
export LANG=en_US.UTF-8
pod deintegrate 2>/dev/null || true
pod cache clean --all 2>/dev/null || true
pod install --repo-update
cd ..

# Step 5: Try building for simulator first
echo "5. Testing iOS simulator build..."
flutter build ios --simulator --debug

if [ $? -eq 0 ]; then
    echo ""
    echo "SUCCESS: iOS build completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Download YOLO11 model: ./scripts/setup_yolo11.sh"
    echo "2. Run on simulator: flutter run"
    echo "3. For device build: flutter build ios --release"
    echo ""
else
    echo ""
    echo "Build failed. Trying device build instead..."
    echo ""
    
    # Try device build
    flutter build ios --debug --no-codesign
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "SUCCESS: iOS device build completed!"
        echo ""
        echo "Next steps:"
        echo "1. Download YOLO11 model: ./scripts/setup_yolo11.sh"
        echo "2. Open Xcode: open ios/Runner.xcworkspace"
        echo "3. Set your development team in Signing & Capabilities"
        echo "4. Run the app from Xcode"
        echo ""
    else
        echo ""
        echo "Build still failing. Manual steps required:"
        echo ""
        echo "1. Open Xcode: open ios/Runner.xcworkspace"
        echo "2. Check these settings in Xcode:"
        echo "   - iOS Deployment Target: 13.0 or higher"
        echo "   - Enable Bitcode: NO"
        echo "   - Always Embed Swift Standard Libraries: YES"
        echo "3. Set your development team in Signing & Capabilities"
        echo "4. Try building from Xcode directly"
        echo ""
        echo "If issues persist:"
        echo "- Update Xcode to latest version"
        echo "- Update CocoaPods: sudo gem install cocoapods"
        echo "- Check Flutter doctor: flutter doctor -v"
    fi
fi
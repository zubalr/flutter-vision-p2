#!/bin/bash

# iOS TensorFlow Lite dylib fix script
echo "Fixing iOS TensorFlow Lite dylib loading issues..."
echo "================================================="

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "ERROR: Please run this script from the Flutter project root directory"
    exit 1
fi

# Step 1: Clean everything thoroughly
echo "1. Cleaning project..."
flutter clean
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf ios/build
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-* 2>/dev/null || true

# Step 2: Update dependencies
echo "2. Getting Flutter dependencies..."
flutter pub get

# Step 3: Create optimized Podfile for TensorFlow Lite
echo "3. Configuring iOS build settings..."

cat > ios/Podfile << 'EOF'
# Uncomment this line to define a global platform for your project
platform :ios, '13.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
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
      # Set minimum deployment target
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
      
      # Camera permissions
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
      ]
      
      # TensorFlow Lite specific fixes for iOS dylib issues
      config.build_settings['CLANG_CXX_LANGUAGE_STANDARD'] = 'gnu++17'
      config.build_settings['CLANG_CXX_LIBRARY'] = 'libc++'
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      
      # Critical fixes for dylib loading
      config.build_settings['OTHER_LDFLAGS'] ||= []
      config.build_settings['OTHER_LDFLAGS'] << '-ObjC'
      config.build_settings['OTHER_LDFLAGS'] << '-lc++'
      
      # Ensure proper framework embedding
      config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
      config.build_settings['LD_RUNPATH_SEARCH_PATHS'] ||= []
      config.build_settings['LD_RUNPATH_SEARCH_PATHS'] << '@executable_path/Frameworks'
      config.build_settings['LD_RUNPATH_SEARCH_PATHS'] << '@loader_path/Frameworks'
      
      # Fix for bundle targets
      if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      end
      
      # Specific fixes for TensorFlow Lite targets
      if target.name.include?('TensorFlow') || target.name.include?('tflite')
        config.build_settings['VALID_ARCHS'] = 'arm64 x86_64'
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'i386'
        config.build_settings['STRIP_INSTALLED_PRODUCT'] = 'NO'
        config.build_settings['COPY_PHASE_STRIP'] = 'NO'
        config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
      end
      
      # Ensure proper linking for all targets
      config.build_settings['DEAD_CODE_STRIPPING'] = 'NO'
      config.build_settings['PRESERVE_DEAD_CODE_INITS_AND_TERMS'] = 'YES'
    end
  end
end
EOF

# Step 4: Install pods with specific configuration
echo "4. Installing CocoaPods with optimized settings..."
cd ios
pod deintegrate 2>/dev/null || true
pod cache clean --all 2>/dev/null || true
pod install --repo-update --verbose
cd ..

# Step 5: Try building
echo "5. Testing iOS build..."
flutter build ios --debug --no-codesign --verbose

if [ $? -eq 0 ]; then
    echo ""
    echo "SUCCESS: iOS TensorFlow Lite dylib issues fixed!"
    echo ""
    echo "Next steps:"
    echo "1. Download YOLO11 model: ./scripts/setup_yolo11.sh"
    echo "2. Open Xcode: open ios/Runner.xcworkspace"
    echo "3. Set your development team in Signing & Capabilities"
    echo "4. Run the app: flutter run"
    echo ""
    echo "The app will now use real TensorFlow Lite inference!"
else
    echo ""
    echo "Build still failing. Additional troubleshooting:"
    echo ""
    echo "1. Check Xcode version (requires Xcode 14+)"
    echo "2. Update CocoaPods: sudo gem install cocoapods"
    echo "3. In Xcode, check these settings:"
    echo "   - iOS Deployment Target: 13.0"
    echo "   - Enable Bitcode: NO"
    echo "   - Always Embed Swift Standard Libraries: YES"
    echo ""
    echo "4. Try different iOS simulator versions"
    echo "5. Check Flutter doctor: flutter doctor -v"
    echo ""
    echo "If the error persists, the issue might be:"
    echo "- Incompatible Xcode/iOS version"
    echo "- Missing iOS development tools"
    echo "- Simulator-specific issues (try real device)"
fi
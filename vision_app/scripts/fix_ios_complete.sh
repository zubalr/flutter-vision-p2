#!/bin/bash

# Complete iOS build fix for privacy bundles and TensorFlow Lite
echo "🔧 Complete iOS Build Fix"
echo "========================"

# Step 1: Clean everything
echo "1️⃣ Cleaning project..."
flutter clean
rm -rf ios/Pods ios/Podfile.lock ios/.symlinks ios/build
rm -rf build/

# Step 2: Get dependencies
echo "2️⃣ Getting Flutter dependencies..."
flutter pub get

# Step 3: Create a minimal Podfile that works
echo "3️⃣ Creating working Podfile..."
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
      
      # Framework and runtime paths
      config.build_settings['FRAMEWORK_SEARCH_PATHS'] ||= ['$(inherited)']
      config.build_settings['LD_RUNPATH_SEARCH_PATHS'] ||= [
        '$(inherited)',
        '@executable_path/Frameworks',
      ]
      
      # Swift libraries
      config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'YES'
    end
  end
end
EOF

# Step 4: Install pods
echo "4️⃣ Installing CocoaPods..."
cd ios
export LANG=en_US.UTF-8
pod install
cd ..

# Step 5: Try building for simulator (easier than device)
echo "5️⃣ Testing simulator build..."
flutter build ios --simulator --debug

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ iOS build successful!"
    echo ""
    echo "Next steps:"
    echo "1. Download YOLO11 model: ./scripts/setup_yolo11.sh"
    echo "2. Run on simulator: flutter run"
    echo "3. For device build: flutter build ios --release"
    echo ""
else
    echo ""
    echo "❌ Build failed. Trying alternative approach..."
    echo ""
    
    # Alternative: Try with older dependency versions
    echo "Trying with compatible dependency versions..."
    
    # Update pubspec.yaml with more compatible versions
    cat > pubspec.yaml << 'EOF'
name: vision_app
description: 'A new Flutter project.'
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ^3.8.1

dependencies:
  flutter:
    sdk: flutter

  cupertino_icons: ^1.0.8
  camera: ^0.10.5+9
  tflite_flutter: ^0.10.4
  path_provider: ^2.1.3
  permission_handler: ^11.3.1
  shared_preferences: ^2.2.3
  provider: ^6.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/
EOF
    
    echo "Updated dependencies to more compatible versions"
    echo "Run: flutter pub get && flutter build ios --simulator"
fi
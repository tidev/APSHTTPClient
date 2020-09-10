BUILD_DIR=build
PROJECT_NAME=APSHTTPClient
UNIVERSAL_OUTPUTFOLDER=$BUILD_DIR/$PROJECT_NAME-universal

mkdir -p "${UNIVERSAL_OUTPUTFOLDER}"

#----- Make macCatalyst archive
xcodebuild archive \
  -scheme APSHTTPClient \
  -archivePath $BUILD_DIR/macCatalyst.xcarchive \
  -sdk macosx \
  SKIP_INSTALL=NO \
  BUILD_LIBRARIES_FOR_DISTRIBUTION=YES \
  SUPPORTS_MACCATALYST=YES

#----- Make iOS Simulator archive
xcodebuild archive \
  -scheme APSHTTPClient \
  -archivePath $BUILD_DIR/simulator.xcarchive \
  -sdk iphonesimulator \
  SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

#----- Make iOS device archive
xcodebuild archive \
  -scheme APSHTTPClient \
  -archivePath $BUILD_DIR/iosdevice.xcarchive \
  -sdk iphoneos \
  SKIP_INSTALL=NO BUILD_LIBRARIES_FOR_DISTRIBUTION=YES

#----- Make XCFramework
xcodebuild -create-xcframework \
  -library $BUILD_DIR/simulator.xcarchive/Products/usr/local/lib/lib$PROJECT_NAME.a \
  -headers $BUILD_DIR/simulator.xcarchive/Products/usr/local/include/ \
  -library $BUILD_DIR/iosdevice.xcarchive/Products/usr/local/lib/lib$PROJECT_NAME.a \
  -headers $BUILD_DIR/iosdevice.xcarchive/Products/usr/local/include/ \
  -library $BUILD_DIR/macCatalyst.xcarchive/Products/usr/local/lib/lib$PROJECT_NAME.a \
  -headers $BUILD_DIR/macCatalyst.xcarchive/Products/usr/local/include/ \
  -output $UNIVERSAL_OUTPUTFOLDER/$PROJECT_NAME.xcframework

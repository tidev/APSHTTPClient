BUILD_DIR=build
PROJECT_NAME=APSHTTPClient
UNIVERSAL_OUTPUTFOLDER=$BUILD_DIR/$PROJECT_NAME-universal

rm -rf $BUILD_DIR
rm -rf $UNIVERSAL_OUTPUTFOLDER
mkdir -p "$UNIVERSAL_OUTPUTFOLDER"

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

sleep 1

#----- Make XCFramework
xcodebuild -create-xcframework \
  -framework $BUILD_DIR/iosdevice.xcarchive/Products/Library/Frameworks/$PROJECT_NAME.framework \
  -framework $BUILD_DIR/simulator.xcarchive/Products/Library/Frameworks/$PROJECT_NAME.framework \
  -framework $BUILD_DIR/macCatalyst.xcarchive/Products/Library/Frameworks/$PROJECT_NAME.framework \
  -output $UNIVERSAL_OUTPUTFOLDER/$PROJECT_NAME.xcframework

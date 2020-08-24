#----- Make iOS device archive
xcodebuild archive \
  -scheme APSHTTPClient \
  -sdk iphoneos \
  -archivePath "archives/ios_devices.xcarchive" \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO

#----- Make iOS Simulator archive  
xcodebuild archive \
  -scheme APSHTTPClient \
  -sdk iphonesimulator \
  -archivePath "archives/ios_simulators.xcarchive" \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO

#----- Make macCatalyst archive
xcodebuild archive \
  -scheme APSHTTPClient \
  -sdk macosx \
  -archivePath "archives/macCatalyst.xcarchive" \
  BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
  SKIP_INSTALL=NO \
  SUPPORTS_MACCATALYST=YES

xcodebuild -create-xcframework \
  -framework archives/ios_devices.xcarchive/Products/Library/Frameworks/APSHTTPClient.framework \
  -framework archives/ios_simulators.xcarchive/Products/Library/Frameworks/APSHTTPClient.framework \
  -framework archives/macCatalyst.xcarchive/Products/Library/Frameworks/APSHTTPClient.framework \
  -output APSHTTPClient.xcframework
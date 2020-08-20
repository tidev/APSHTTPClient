BUILD_DIR=build
PROJECT_NAME=APSHTTPClient
CONFIGURATION=Release
UNIVERSAL_OUTPUTFOLDER=${BUILD_DIR}/${PROJECT_NAME}-universal

# Step 1. Build Device and Simulator versions
# for sdk in iphoneos; do
# xcodebuild -target APSHTTPClient -configuration ${CONFIGURATION} -sdk ${sdk} BUILD_DIR="${BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" OTHER_CFLAGS="-fembed-bitcode" CLANG_ENABLE_MODULE_DEBUGGING=NO GCC_PRECOMPILE_PREFIX_HEADER=NO DEBUG_INFORMATION_FORMAT="DWARF with dSYM"
# done
 
mkdir -p "${UNIVERSAL_OUTPUTFOLDER}"

# Step 2. Create universal binary file using lipo
#lipo -create -output "${UNIVERSAL_OUTPUTFOLDER}/lib${PROJECT_NAME}.a" "${BUILD_DIR}/${CONFIGURATION}-iphoneos/lib${PROJECT_NAME}.a" "${BUILD_DIR}/${CONFIGURATION}-iphonesimulator/lib${PROJECT_NAME}.a"

# Last touch. copy the header files. Just for convenience
#cp -R ${BUILD_DIR}/${CONFIGURATION}-iphoneos/include/APSHTTPClient/* "${UNIVERSAL_OUTPUTFOLDER}/"


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
-library $BUILD_DIR/simulator.xcarchive/Products/usr/local/lib/lib${PROJECT_NAME}.a \
-headers ${BUILD_DIR}/simulator.xcarchive/Products/usr/local/include/ \
-library $BUILD_DIR/iosdevice.xcarchive/Products/usr/local/lib/lib${PROJECT_NAME}.a \
-headers ${BUILD_DIR}/iosdevice.xcarchive/Products/usr/local/include/ \
-library $BUILD_DIR/macCatalyst.xcarchive/Products/usr/local/lib/lib${PROJECT_NAME}.a \
-headers ${BUILD_DIR}/macCatalyst.xcarchive/Products/usr/local/include/ \
-output ${UNIVERSAL_OUTPUTFOLDER}/${PROJECT_NAME}.xcframework

# open "${UNIVERSAL_OUTPUTFOLDER}"

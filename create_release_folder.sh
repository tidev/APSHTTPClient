#! /usr/bin/env bash

# Authors: Sabil and Matt
# Date: 2014.06.11
#
# IMPORTANT: This script should be retired after the SDK Engineering
# team migrates to Cocoa Pods for dependency management and
# distribution.
#
# This script creates a versioned directory of the APSHTTPClient
# library in a subdirectory named "build" under the project's root.
#
# The version of the library is the build timestamp formatted as the
# number of seconds since the Unix epoch. For example:
#
# build/APSHTTPClient-1402532543/

# This is a convenient command to determine a human readable date and
# time from the version number (replace the last number with the
# version number):
#
# date -j -f "%s" 1402532543
# Wed Jun 11 17:22:23 PDT 2014
#
#  The contents of this directory contain a "universal" library for
#  the architectures i386, armv7 and armv7s.

# Sabil and Matt are knowingly overriding the TARGET_NAME environment
# variable from Xcode since they named the Xcode target that executes
# this script "Create Release Folder".
TARGET_NAME="APSHTTPClient"

# Sabil and Matt are knowingly overriding the CONFIGURATION
# environment variable from Xcode since they only want distribute
# Release builds. Engineers wanting a Debug build should simply
# include this Xcode project directly into their project.
CONFIGURATION="Release"

APSHTTPCLIENT_VERSION=$(date +%s)

BUILD_DIR="${PWD}/build"
echo "Assuming BUILD_DIR=${BUILD_DIR}"

DEVICE_DIR="${BUILD_DIR}/${CONFIGURATION}-iphoneos"
SIMULATOR_DIR="${BUILD_DIR}/${CONFIGURATION}-iphonesimulator"
LIB_NAME="lib${TARGET_NAME}.a"
DIST_DIR="${BUILD_DIR}/${TARGET_NAME}-${APSHTTPCLIENT_VERSION}"

function echo_and_eval {
    local -r cmd="${1:?}"
    echo "${cmd}" && eval "${cmd}"
}

for sdk in iphoneos iphonesimulator; do
echo_and_eval "xcodebuild clean -target \"${TARGET_NAME}\" -sdk ${sdk}"
echo_and_eval "xcodebuild -configuration \"${CONFIGURATION}\" -target \"${TARGET_NAME}\" -sdk ${sdk}"
done

echo_and_eval "mkdir -p \"${DIST_DIR}\""
echo_and_eval "xcrun -sdk iphoneos lipo -create \"${DEVICE_DIR}/${LIB_NAME}\" \"${SIMULATOR_DIR}/${LIB_NAME}\" -o \"${DIST_DIR}/${LIB_NAME}\""
echo_and_eval "cp -r \"${DEVICE_DIR}/include\" \"${DIST_DIR}\""
echo_and_eval "rm -rf \"${DEVICE_DIR}\""
echo_and_eval "rm -rf \"${SIMULATOR_DIR}\""
echo_and_eval "rm -rf \"${BUILD_DIR}/${TARGET_NAME}.build\""

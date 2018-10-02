node('osx && xcode') {
	stage('Checkout') {
		checkout scm
	}

	stage('Clean') {
		sh 'xcodebuild clean -target "APSHTTPClient" -sdk iphoneos'
		sh 'xcodebuild clean -target "APSHTTPClient" -sdk iphonesimulator'
	}

	stage('Build') {
		sh 'xcodebuild -configuration "Release" -target "APSHTTPClient" -sdk iphoneos OTHER_CFLAGS="-fembed-bitcode" CLANG_ENABLE_MODULE_DEBUGGING=NO GCC_PRECOMPILE_PREFIX_HEADER=NO DEBUG_INFORMATION_FORMAT="DWARF with dSYM"'
		// generates build/Release-iphoneos/libAPSHTTPClient.a (also an include folder there)

		sh 'xcodebuild -configuration "Release" -target "APSHTTPClient" -sdk iphonesimulator OTHER_CFLAGS="-fembed-bitcode" CLANG_ENABLE_MODULE_DEBUGGING=NO GCC_PRECOMPILE_PREFIX_HEADER=NO DEBUG_INFORMATION_FORMAT="DWARF with dSYM"'
		// generates build/Release-iphonesimulator/libAPSHTTPClient.a (also an include folder there)
	}

	stage('Package') {
		sh 'mkdir -p out/APSHTTPClient'
		sh 'xcrun -sdk iphoneos lipo -create ./build/Release-iphoneos/libAPSHTTPClient.a ./build/Release-iphonesimulator/libAPSHTTPClient.a -o out/APSHTTPClient/libAPSHTTPClient.a'
		sh 'cp -r ./build/Release-iphoneos/include/. out/.'
		sh 'rm -rf build'

		dir('out') {
			archiveArtifacts '**'
		}
		sh 'rm -rf out'
	}
}

node('osx && xcode-12') {
	stage('Checkout') {
		checkout scm
	}

	stage('Clean') {
		sh 'rm -rf build'
		sh 'xcodebuild clean -target "APSHTTPClient" -sdk iphoneos'
		sh 'xcodebuild clean -target "APSHTTPClient" -sdk iphonesimulator'
		sh 'xcodebuild clean -target "APSHTTPClient" -sdk macosx'
	}

	stage('Build') {
		sh './build.sh'
	}

	stage('Package') {
		dir('build/APSHTTPClient-universal') {
			archiveArtifacts 'APSHTTPClient.xcframework/'
		}
		sh 'rm -rf build'
	}
}

#!/bin/bash

cd ios
xcodebuild -project 'Runner.xcodeproj' -scheme Runner -config Flutter/Debug.xcconfig -derivedDataPath "../build/ios_integ" -sdk iphonesimulator
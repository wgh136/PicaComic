#!/bin/bash

mkdir -p /Users/runner/work/PicaComic/PicaComic/build/ios/iphoneos/Payload
mv /Users/runner/work/PicaComic/PicaComic/build/ios/iphoneos/Runner.app /Users/runner/work/PicaComic/PicaComic/build/ios/iphoneos/Payload
cd /Users/runner/work/PicaComic/PicaComic/build/ios/iphoneos/
zip -r app-ios.ipa Payload
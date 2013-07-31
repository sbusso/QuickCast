# quickcast.io mac app

Please visit the [http://quickcast.io](QuickCast) site for links to the source for the QuickCast Viewer + API

You will need [http://cocoapods.org](Cocoa Pods) to build with the required external libraries.

The Amazon AWS Toolkit had to be embedded as it's a Frankenstein version of the library to cover the functionality required by QuickCast.

Encoding is done by FFMPEG to create a smaller MP4 for upload and then AWS Elastic Transcoding creates the mp4 and webm for use online.
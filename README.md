# SPMAssetExporter

SDAVAssetExportSession
======================

`AVAssetExportSession` drop-in replacement with customizable audio&amp;video settings.

You want the ease of use of `AVAssetExportSession` but default provided presets doesn't fit your needs? You then began to read documentation for `AVAssetWriter`, `AVAssetWriterInput`, `AVAssetReader`, `AVAssetReaderVideoCompositionOutput`, `AVAssetReaderAudioMixOutput`… and you went out of aspirin? `SDAVAssetExportSession` is a rewrite of `AVAssetExportSession` on top of `AVAssetReader*` and `AVAssetWriter*`. Unlike `AVAssetExportSession`, you are not limited to a set of presets – you have full access over audio and video settings.


Usage Example
-------------
For Objective-C:

``` objective-c
SDAVAssetExportSession *encoder = [SDAVAssetExportSession.alloc initWithAsset:anAsset];
encoder.outputFileType = AVFileTypeMPEG4;
encoder.outputURL = outputFileURL;
encoder.videoSettings = @
{
  AVVideoCodecKey: AVVideoCodecH264,
  AVVideoWidthKey: @1920,
  AVVideoHeightKey: @1080,
  AVVideoCompressionPropertiesKey: @
    {
      AVVideoAverageBitRateKey: @6000000,
      AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
    },
};
encoder.audioSettings = @
{
  AVFormatIDKey: @(kAudioFormatMPEG4AAC),
  AVNumberOfChannelsKey: @2,
  AVSampleRateKey: @44100,
  AVEncoderBitRateKey: @128000,
};

[encoder exportAsynchronouslyWithCompletionHandler:^
{
  if (encoder.status == AVAssetExportSessionStatusCompleted)
  {
    NSLog(@"Video export succeeded");
  }
  else if (encoder.status == AVAssetExportSessionStatusCancelled)
  {
    NSLog(@"Video export cancelled");
  }
  else
  {
    NSLog(@"Video export failed with error: %@ (%d)", encoder.error.localizedDescription, encoder.error.code);
  }
}];

```

And for Swift:

```swift
let exporter = SDAVAssetExportSession(asset: asset)!
exporter.outputFileType = processingParameters.outputFileType.rawValue
exporter.outputURL = processingParameters.outputUrl
exporter.videoSettings = [
  AVVideoCodecKey: AVVideoCodecType.h264,
  AVVideoWidthKey: targetSize.width,
  AVVideoHeightKey: targetSize.height,
  AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 1024_000, AVVideoProfileLevelKey: AVVideoProfileLevelH264High40]
]
exporter.audioSettings = [
  AVFormatIDKey: kAudioFormatMPEG4AAC,
  AVNumberOfChannelsKey: 1,
  AVSampleRateKey: 44100,
  AVEncoderBitRateKey: 96_000
]
exporter.videoComposition = videoComposition

exporter.exportAsynchronously(completionHandler: {
  switch exporter.status {
  // do your work here
  }
})
```

Licenses
--------

All source code is licensed under the [MIT-License](https://github.com/rs/SDAVAssetExportSession/blob/master/LICENSE).

SDAVAssetExportSession
======================

`AVAssetExportSession` drop-in remplacement with customizable audio&amp;video settings.

You want the ease of use of `AVAssetExportSession` but default provided presets doesn't fit your needs? You then began to read documentation for `AVAssetWriter`, `AVAssetWriterInput`, `AVAssetReader`, `AVAssetReaderVideoCompositionOutput`, `AVAssetReaderAudioMixOutput`… and you went out of aspirin? `SDAVAssetExportSession` is a rewrite of `AVAssetExportSession` on top of `AVAssetReader`* and `AVAssetWriter`. Unlike `AVAssetExportSession`, you are not limited to a set of presets – you have full access over audio and video settings.

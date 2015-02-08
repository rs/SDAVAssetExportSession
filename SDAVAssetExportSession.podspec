Pod::Spec.new do |s|
  s.name         = "SDAVAssetExportSession"
  s.version      = "0.0.2"
  s.summary      = "AVAssetExportSession drop-in replacement with customizable audio&video settings"
  s.description  = <<-DESC
                   AVAssetExportSession drop-in remplacement with customizable audio&video settings.

                   You want the ease of use of AVAssetExportSession but default provided presets doesn't fit your needs? You then began to read documentation for AVAssetWriter, AVAssetWriterInput, AVAssetReader, AVAssetReaderVideoCompositionOutput, AVAssetReaderAudioMixOutput… and you went out of aspirin? SDAVAssetExportSession is a rewrite of AVAssetExportSession on top of AVAssetReader* and AVAssetWriter*. Unlike AVAssetExportSession, you are not limited to a set of presets – you have full access over audio and video settings.
                   DESC
  s.homepage     = "https://github.com/rs/SDAVAssetExportSession"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author    = "Olivier Poitrey"
  s.platform     = :ios, "6.0"
  s.source       = { :git => "https://github.com/rs/SDAVAssetExportSession.git", :commit => "726f571" }
  s.source_files  = "**/*.{h,m}"
  s.requires_arc = true
end

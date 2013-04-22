//
//  SDAVAssetExportSession.m
//
//  Created by Olivier Poitrey on 13/03/13.
//  Copyright (c) 2013 Dailymotion. All rights reserved.
//

#import "SDAVAssetExportSession.h"

@interface SDAVAssetExportSession ()

@property (nonatomic, assign, readwrite) float progress;

@property (nonatomic, strong) AVAssetReader *reader;
@property (nonatomic, strong) AVAssetReaderVideoCompositionOutput *videoOutput;
@property (nonatomic, strong) AVAssetReaderAudioMixOutput *audioOutput;
@property (nonatomic, strong) AVAssetWriter *writer;
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor  *videoPixelBufferAdaptor;
@property (nonatomic, strong) AVAssetWriterInput *audioInput;
@property (nonatomic, strong) dispatch_queue_t inputQueue;
@property (nonatomic, strong) void (^completionHandler)();

@end

@implementation SDAVAssetExportSession
{
    NSError *_error;
    NSTimeInterval duration;
}

+ (id)exportSessionWithAsset:(AVAsset *)asset
{
    return [SDAVAssetExportSession.alloc initWithAsset:asset];
}

- (id)initWithAsset:(AVAsset *)asset
{
    if ((self = [super init]))
    {
        _asset = asset;
        _timeRange = CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity);
    }

    return self;
}

- (void)exportAsynchronouslyWithCompletionHandler:(void (^)())handler
{
    NSParameterAssert(handler != nil);
    [self cancelExport];
    self.completionHandler = handler;

    NSError *readerError;
    self.reader = [AVAssetReader.alloc initWithAsset:self.asset error:&readerError];
    if (readerError)
    {
        _error = readerError;
        handler();
        return;
    }

    NSError *writerError;
    self.writer = [AVAssetWriter assetWriterWithURL:self.outputURL fileType:self.outputFileType error:&writerError];
    if (writerError)
    {
        _error = writerError;
        handler();
        return;
    }

    self.reader.timeRange = self.timeRange;
    self.writer.shouldOptimizeForNetworkUse = self.shouldOptimizeForNetworkUse;
    self.writer.metadata = self.metadata;

    if (CMTIME_IS_VALID(self.timeRange.duration) && !CMTIME_IS_POSITIVE_INFINITY(self.timeRange.duration))
    {
        duration = CMTimeGetSeconds(self.timeRange.duration);
    }
    else
    {
        duration = CMTimeGetSeconds(self.asset.duration);
    }

    //
    // Video output
    //
    NSArray *videoTracks = [self.asset tracksWithMediaType:AVMediaTypeVideo];
    self.videoOutput = [AVAssetReaderVideoCompositionOutput assetReaderVideoCompositionOutputWithVideoTracks:videoTracks videoSettings:nil];
    self.videoOutput.alwaysCopiesSampleData = NO;
    self.videoOutput.videoComposition = self.videoComposition;
    if ([self.reader canAddOutput:self.videoOutput])
    {
        [self.reader addOutput:self.videoOutput];
    }

    //
    // Video input
    //
    // TODO: handle by preset size/bitrate etc.
    self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoSettings];
    self.videoInput.expectsMediaDataInRealTime = NO;
    if ([self.writer canAddInput:self.videoInput])
    {
        [self.writer addInput:self.videoInput];
    }
    NSDictionary *pixelBufferAttributes = @
    {
        (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
        (id)kCVPixelBufferWidthKey: @(((AVAssetTrack *)videoTracks[0]).naturalSize.width),
        (id)kCVPixelBufferHeightKey: @(((AVAssetTrack *)videoTracks[0]).naturalSize.height),
        @"IOSurfaceOpenGLESTextureCompatibility": @YES,
        @"IOSurfaceOpenGLESFBOCompatibility": @YES,
    };
    self.videoPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoInput sourcePixelBufferAttributes:pixelBufferAttributes];

    //
    //Audio output
    //
    NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
    self.audioOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:audioTracks audioSettings:nil];
    self.audioOutput.alwaysCopiesSampleData = NO;
    self.audioOutput.audioMix = self.audioMix;
    if ([self.reader canAddOutput:self.audioOutput])
    {
        [self.reader addOutput:self.audioOutput];
    }

    //
    // Audio input
    //
    self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioSettings];
    self.audioInput.expectsMediaDataInRealTime = NO;
    if ([self.writer canAddInput:self.audioInput])
    {
        [self.writer addInput:self.audioInput];
    }

    [self.writer startWriting];
    [self.reader startReading];
    [self.writer startSessionAtSourceTime:CMTimeMake(0, ((AVAssetTrack *)videoTracks[0]).naturalTimeScale)];

    self.inputQueue = dispatch_queue_create("VideoEncoderInputQueue", DISPATCH_QUEUE_SERIAL);
    __block BOOL videoCompleted = NO;
    __block BOOL audioCompleted = NO;
    __weak typeof(self) wself = self;
    [self.videoInput requestMediaDataWhenReadyOnQueue:self.inputQueue usingBlock:^
    {
        if (![wself encodeReadySamplesFromOutput:wself.videoOutput toInput:wself.videoInput])
        {
            @synchronized(wself)
            {
                videoCompleted = YES;
                if (audioCompleted)
                {
                    [wself finish];
                }
            }
        }
    }];
    [self.audioInput requestMediaDataWhenReadyOnQueue:self.inputQueue usingBlock:^
    {
        if (![wself encodeReadySamplesFromOutput:wself.audioOutput toInput:wself.audioInput])
        {
            @synchronized(wself)
            {
                audioCompleted = YES;
                if (videoCompleted)
                {
                    [wself finish];
                }
            }
        }
    }];
}

- (BOOL)encodeReadySamplesFromOutput:(AVAssetReaderOutput *)output toInput:(AVAssetWriterInput *)input
{
    while (input.isReadyForMoreMediaData)
    {
        CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
        if (sampleBuffer)
        {
            BOOL handled = NO;
            BOOL error = NO;
            if (self.videoOutput == output)
            {
                CMTime presTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                self.progress = duration == 0 ? 1 : CMTimeGetSeconds(presTime) / duration;

                if ([self.delegate respondsToSelector:@selector(exportSession:renderFrame:withPresentationTime:toBuffer:)])
                {
                    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
                    CVPixelBufferRef renderBuffer = NULL;
                    CVPixelBufferPoolCreatePixelBuffer(NULL, self.videoPixelBufferAdaptor.pixelBufferPool, &renderBuffer);
                    CVPixelBufferLockBaseAddress(renderBuffer, 0);
                    [self.delegate exportSession:self renderFrame:pixelBuffer withPresentationTime:presTime toBuffer:renderBuffer];
                    CVPixelBufferUnlockBaseAddress(renderBuffer, 0);
                    if (![self.videoPixelBufferAdaptor appendPixelBuffer:renderBuffer withPresentationTime:presTime])
                    {
                        error = YES;
                    }
                    CVPixelBufferRelease(renderBuffer);
                    handled = YES;
                }
            }
            if (!handled && ![input appendSampleBuffer:sampleBuffer])
            {
                error = YES;
            }
            CFRelease(sampleBuffer);

            if (error)
            {
                return NO;
            }
        }
        else
        {
            [input markAsFinished];
            return NO;
        }
    }

    return YES;
}

- (void)finish
{
    [self.writer finishWritingWithCompletionHandler:self.completionHandler];

    if (self.writer.status == AVAssetWriterStatusFailed)
    {
        [NSFileManager.defaultManager removeItemAtURL:self.outputURL error:nil];
        if (self.completionHandler)
        {
            self.completionHandler();
        }
    }

    self.completionHandler = nil;
}

- (NSError *)error
{
    if (_error)
    {
        return _error;
    }
    else
    {
        return self.writer.error ? : self.reader.error;
    }
}

- (AVAssetWriterStatus)status
{
    switch (self.writer.status)
    {
        default:
        case AVAssetWriterStatusUnknown:
            return AVAssetExportSessionStatusUnknown;
        case AVAssetWriterStatusWriting:
            return AVAssetExportSessionStatusExporting;
        case AVAssetWriterStatusFailed:
            return AVAssetExportSessionStatusFailed;
        case AVAssetWriterStatusCompleted:
            return AVAssetExportSessionStatusCompleted;
        case AVAssetWriterStatusCancelled:
            return AVAssetExportSessionStatusCancelled;
    }
}

- (void)cancelExport
{
    [self.writer cancelWriting];
    [self.reader cancelReading];
    [NSFileManager.defaultManager removeItemAtURL:self.outputURL error:nil];
    if (self.completionHandler)
    {
        self.completionHandler();
    }
    [self reset];
}

- (void)reset
{
    _error = nil;
    self.progress = 0;
    self.reader = nil;
    self.videoOutput = nil;
    self.audioOutput = nil;
    self.writer = nil;
    self.videoInput = nil;
    self.videoPixelBufferAdaptor = nil;
    self.audioInput = nil;
    self.inputQueue = nil;
    self.completionHandler = nil;
}

@end

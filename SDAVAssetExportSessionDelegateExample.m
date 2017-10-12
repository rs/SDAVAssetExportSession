//
//  SDAVAssetExportSessionDelegateExample.m
//
// This file is part of the SDAVAssetExportSession package.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

#import "SDAVAssetExportSessionDelegateExample.h"

/**
 * An example implementation of `SDAVAssetExportSessionDelegate` that just copies the input 'pixelBuffer' to the output 'renderBuffer' unmodified.
 * You can control the pixel format that the 'AVAssetReaderTrackOutput' produces by setting 'exportSession.videoInputSettings':
 *
 *     exportSession.videoInputSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
 *
 * The default format of kCVPixelFormatType_32BGRA is generally the fastest for transcoding, even when the input video is a YpCbCr format, such as H.264
 */

@implementation SDAVAssetExportSessionDelegateExample

- (void)exportSession:(SDAVAssetExportSession *)exportSession renderFrame:(CVPixelBufferRef)pixelBuffer withPresentationTime:(CMTime)presentationTime toBuffer:(CVPixelBufferRef)renderBuffer
{
    // Print the presentation times of the frames
    // CMTimeShow(presentationTime);
    
    // Print details -- just for the first frame
    if (presentationTime.value == 0)
    {
        OSType sourceFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
        OSType destFormat = CVPixelBufferGetPixelFormatType(renderBuffer);
        size_t dataSize = CVPixelBufferGetDataSize(pixelBuffer);
        
        NSLog(@"source format: %@, dest format: %@, planar: %d, size: %zu", NSFileTypeForHFSTypeCode(sourceFormat), NSFileTypeForHFSTypeCode(destFormat), CVPixelBufferIsPlanar(pixelBuffer), dataSize);
    }
    
    // Copy the source pixel buffer to the output pixel buffer.
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    CVPixelBufferLockBaseAddress(renderBuffer, 0);
    
    if (CVPixelBufferIsPlanar(pixelBuffer))
    {
        // Planar formats, such as kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange and kCVPixelFormatType_420YpCbCr8BiPlanarFullRange.
        size_t planeCount = CVPixelBufferGetPlaneCount(pixelBuffer);
        
        for (size_t i = 0; i < planeCount; i++)
        {
            int height = (int)CVPixelBufferGetHeightOfPlane(pixelBuffer, i);
            size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, i);
            
            void *pixelBufferBaseAddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, i);
            void *renderBufferBaseAddress = CVPixelBufferGetBaseAddressOfPlane(renderBuffer, i);
            
            memcpy(renderBufferBaseAddress, pixelBufferBaseAddress, height * bytesPerRow);
        }
    }
    else
    {
        // Packed formats, such as kCVPixelFormatType_32BGRA, kCVPixelFormatType_32ARGB, and kCVPixelFormatType_422YpCbCr8.
        int height = (int)CVPixelBufferGetHeight(pixelBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
        
        void *pixelBufferBaseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
        void *renderBufferBaseAddress = CVPixelBufferGetBaseAddress(renderBuffer);
        
        memcpy(renderBufferBaseAddress, pixelBufferBaseAddress, height * bytesPerRow);
    }
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferUnlockBaseAddress(renderBuffer, 0);
}

@end

//
//  SDAVAssetExportSessionDelegateExample.h
//
// This file is part of the SDAVAssetExportSession package.
//
// For the full copyright and license information, please view the LICENSE
// file that was distributed with this source code.
//

#import <Foundation/Foundation.h>
#import "SDAVAssetExportSession.h"

@interface SDAVAssetExportSessionDelegateExample : NSObject <SDAVAssetExportSessionDelegate>

- (void)exportSession:(SDAVAssetExportSession *)exportSession renderFrame:(CVPixelBufferRef)pixelBuffer withPresentationTime:(CMTime)presentationTime toBuffer:(CVPixelBufferRef)renderBuffer;

@end

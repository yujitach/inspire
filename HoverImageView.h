//
//  HoverImageView.h
//  spires
//
//  Created by Yuji on 2018/08/27.
//

#import <Cocoa/Cocoa.h>

@interface HoverImageView : NSImageView
@property (nonatomic) NSImage*alternateImage;
@property (nonatomic) NSImage*mainImage;
@property (nonatomic) NSBackgroundStyle backgroundStyle;
@end

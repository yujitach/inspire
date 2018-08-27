//
//  HoverImageView.m
//  spires
//
//  Created by Yuji on 2018/08/27.
//

#import "HoverImageView.h"

@implementation HoverImageView
{
    NSTrackingArea*trackingArea;
}
@synthesize backgroundStyle=_backgroundStyle;
@synthesize mainImage=_mainImage;
-(void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
    _backgroundStyle=backgroundStyle;
    if(!self.alternateImage)
        return;
    if(backgroundStyle==NSBackgroundStyleDark){
        self.image=self.alternateImage;
    }else{
        self.image=self.mainImage;
    }
}
-(void)setMainImage:(NSImage *)mainImage
{
    _mainImage=mainImage;
    self.image=mainImage;
}

-(void)mouseEntered:(NSEvent *)theEvent {
    [super mouseEntered:theEvent];
    
    if(self.alternateImage){
        self.image = self.alternateImage;
    }
}

-(void)mouseExited:(NSEvent *)theEvent {
    [super mouseExited:theEvent];
    
    self.image = self.mainImage;
}
-(void)updateTrackingAreas
{
    if(trackingArea != nil) {
        [self removeTrackingArea:trackingArea];
    }
    
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways);
    trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
                                                     options:opts
                                                       owner:self
                                                    userInfo:nil];
    
    [self addTrackingArea:trackingArea];
}


@end

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
    NSImage*savedImage;
}

-(void)mouseEntered:(NSEvent *)theEvent {
    [super mouseEntered:theEvent];
    
    savedImage=self.image;
    if(self.alternateImage){
        self.image = self.alternateImage;
    }
}

-(void)mouseExited:(NSEvent *)theEvent {
    [super mouseExited:theEvent];
    
    self.image = savedImage;
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

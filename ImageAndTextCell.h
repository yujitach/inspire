#import <Cocoa/Cocoa.h>

@interface ImageAndTextCell : NSTextFieldCell {
@private
    NSImage *image;
    NSButtonCell*button;
    BOOL showButton;
}

- (void)setImage:(NSImage *)anImage;
- (NSImage *)image;

- (void)setButton:(NSButtonCell *)aButton;
- (NSButtonCell *)button;


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize)cellSize;

@property(assign) BOOL showButton;
@end

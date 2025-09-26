//
//  SPSearchFieldWithProgressIndicator.m
//  spires
//
//  Created by Yuji on 3/31/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "SPSearchFieldWithProgressIndicator.h"
//@interface NSObject (privateCategoryToShutUpWarning)
//-(NSString*)placeholderForSearchField;
//@end
@interface SPSearchFieldWithProgressIndicator()
-(IBAction)cancelButtonClicked:(id)sender;
@end

@implementation SPSearchFieldWithProgressIndicator
@synthesize progressQuitAction;
-(BOOL)isKindOfClass:(Class)aClass
{
    // this is to fight with stupid Lion behavior
    if(@available(macOS 26,*)){
    }else{
        if([NSStringFromClass(aClass) isEqualToString:@"NSSearchField"])
            return NO;
    }
    return [super isKindOfClass:aClass];
}
-(void)awakeFromNib
{
//    [self startAnimation:self];
    [controller addObserver:self 
		 forKeyPath:@"selection"
		    options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew 
		    context:nil];
}
-(void)cancelButtonClicked:(id)sender
{
    if(self.progressQuitAction){
	[NSApp sendAction:[self progressQuitAction] to:[self target] from:self];
	[self stopAnimation:self];
    }
}
-(BOOL)abortEditing
{
    return NO;
}
-(void)startAnimation:(id)sender;
{
}
-(void)stopAnimation:(id)sender;
{
}
-(BOOL)mouseDownCanMoveWindow
{
    return NO;
}
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object==controller && [keyPath isEqualTo:@"selection"]) {
	NSString* s=[controller valueForKeyPath:@"selection.placeholderForSearchField"];
	[(NSTextFieldCell*)[self cell] setPlaceholderString:s];
    }else{
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

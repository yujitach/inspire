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
    if([NSStringFromClass(aClass) isEqualToString:@"NSSearchField"])
        return NO;
    return [super isKindOfClass:aClass];
}
-(void)awakeFromNib
{
//    NSLog(@"awake");
    bc=[[SPProgressIndicatingButtonCell alloc] init];
    NSButtonCell* searchCell=[[self cell] searchButtonCell] ;
//    NSLog(@"%@",cancelCell);
    [bc setImage:[searchCell image]];
    [bc setTarget:self];
    [bc setAction:@selector(cancelButtonClicked:)];
    [[self cell] setSearchButtonCell:bc];
//    [self startAnimation:self];
    [controller addObserver:self 
		 forKeyPath:@"selection"
		    options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew 
		    context:nil];
}
-(void)cancelButtonClicked:(id)sender
{
    if(!bc.isSpinning){
//	[self setStringValue:@""];
    }else if(self.progressQuitAction){
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
    [bc startAnimation:sender];
}
-(void)stopAnimation:(id)sender;
{
    [bc stopAnimation:sender];
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

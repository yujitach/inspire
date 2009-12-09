//
//  ProgressIndicatorController.m
//  spires
//
//  Created by Yuji on 09/02/01.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ProgressIndicatorController.h"
#import "SPSearchFieldWithProgressIndicator.h"
ProgressIndicatorController*_sharedInstance=nil;
@implementation ProgressIndicatorController
+(ProgressIndicatorController*)sharedController;
{
    return _sharedInstance;
}
-(ProgressIndicatorController*)init
{
    [super init];
 //   NSLog(@"PIController registered");
    _sharedInstance=self;
    return self;
}
-(void)startAnimation:(id)sender;
{
    [pi startAnimation:sender];
}
-(void)stopAnimation:(id)sender;
{
    [pi stopAnimation:sender];
}

@end

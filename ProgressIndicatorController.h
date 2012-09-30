//
//  ProgressIndicatorController.h
//  spires
//
//  Created by Yuji on 09/02/01.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SPSearchFieldWithProgressIndicator;
@interface ProgressIndicatorController : NSObject {
    IBOutlet SPSearchFieldWithProgressIndicator* pi;
}
+(ProgressIndicatorController*)sharedController;
-(IBAction)startAnimation:(id)sender;
-(IBAction)stopAnimation:(id)sender;
@end

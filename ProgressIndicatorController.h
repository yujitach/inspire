//
//  ProgressIndicatorController.h
//  spires
//
//  Created by Yuji on 09/02/01.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ProgressIndicatorController : NSObject {
    IBOutlet NSProgressIndicator* pi;
}
-(IBAction)startAnimation:(id)sender;
-(IBAction)stopAnimation:(id)sender;
+(IBAction)startAnimation:(id)sender;
+(IBAction)stopAnimation:(id)sender;
@end

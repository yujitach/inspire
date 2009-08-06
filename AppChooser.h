//
//  AppChooser.h
//  spires
//
//  Created by Yuji on 09/01/31.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppChooser : NSObject {
    IBOutlet NSPopUpButton* appToUsePopUp;
    NSMutableArray* apps;
    NSString* defaultsKey;
}
-(IBAction)appSelected:(id)sender;
@end

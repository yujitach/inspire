//
//  AuxPanelController.h
//  spires
//
//  Created by Yuji on 6/29/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AuxPanelController : NSWindowController {
    NSString*nibIsVisibleKey;
}
-(void)showhide:(id)sender;
@end

//
//  MigrationProgressController.h
//  spires
//
//  Created by Yuji on 11/27/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MigrationProgressController : NSWindowController {
    IBOutlet NSProgressIndicator*pi;
    NSMigrationManager*mm;
    NSString*message;
}
-(id)initWithMigrationManager:(NSMigrationManager*)mmm WithMessage:(NSString*)mes;
@end

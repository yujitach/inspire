//
//  MigrationProgressController.m
//  spires
//
//  Created by Yuji on 11/27/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "MigrationProgressController.h"


@implementation MigrationProgressController
-(id)initWithMigrationManager:(NSMigrationManager*)mmm WithMessage:(NSString*)mes;
{
    mm=mmm;
    message=mes;
    [mm addObserver:self 
	 forKeyPath:@"migrationProgress" 
	    options:NSKeyValueObservingOptionNew
	    context:NULL];
     return [super initWithWindowNibName:@"MigrationProgress"];
}
-(void)awakeFromNib
{
    [pi startAnimation:YES];
//    [pi setUsesThreadedAnimation:YES];
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // note that this is called from a background thread
    double progress=[mm migrationProgress];
    dispatch_async(dispatch_get_main_queue(),^{
	// NSMigrationManager takes some time after migrationProgress becomes 1
	// The empirical factor .95 accounts for that.
	[pi setDoubleValue:.95*progress];
    });
}
@end

//
//  ActivityMonitorController.m
//  spires
//
//  Created by Yuji on 09/02/08.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ActivityMonitorController.h"
#import "DumbOperation.h"

@implementation ActivityMonitorController

-(void)activityMonitorRefresher:(NSTimer*)timer
{
    array=[NSMutableArray array];
    [array addObjectsFromArray:[[DumbOperationQueue arxivQueue] operations]];
    [array addObjectsFromArray:[[DumbOperationQueue sharedQueue] operations]];
    [array addObjectsFromArray:[[DumbOperationQueue spiresQueue] operations]];
    [activityController  setContent:array];
    [activityController rearrangeObjects];
    [activityController didChangeArrangementCriteria];
}

-(ActivityMonitorController*)init
{
    self=[super initWithWindowNibName:@"ActivityMonitor"];
    [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(activityMonitorRefresher:) userInfo:nil repeats:YES];
    //    [activityTable setRowHeight:[activityTable rowHeight]*3];
    [self activityMonitorRefresher:nil];
    [[self window] setLevel:NSNormalWindowLevel];
    [[self window] setIsVisible:[[NSUserDefaults standardUserDefaults] boolForKey:@"ActivityMonitorIsVisible"]];
    return self;
}
-(void)showhide:(id)sender
{
    if([[self window] isVisible]){
	[[self window] setIsVisible:NO];
    }else{
	[[self window] makeKeyAndOrderFront:sender];
    }
}
-(void)windowDidBecomeKey:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"ActivityMonitorIsVisible"];
}
-(void)windowWillClose:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"ActivityMonitorIsVisible"];
}
@end

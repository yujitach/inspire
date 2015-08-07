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
{
    NSTimer*timer;
}
-(void)activityMonitorRefresher:(NSTimer*)timer
{
    array=[NSMutableArray array];
    [array addObjectsFromArray:[[OperationQueues arxivQueue] operations]];
    [array addObjectsFromArray:[[OperationQueues sharedQueue] operations]];
    [array addObjectsFromArray:[[OperationQueues spiresQueue] operations]];
    [activityController  setContent:array];
    [activityController rearrangeObjects];
    [activityController didChangeArrangementCriteria];
}
-(ActivityMonitorController*)init
{
    self=[super initWithWindowNibName:@"ActivityMonitor"];
    //    [activityTable setRowHeight:[activityTable rowHeight]*3];
    [self activityMonitorRefresher:nil];
    return self;
}
-(void)windowDidBecomeKey:(id)sender
{
    timer=[NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(activityMonitorRefresher:) userInfo:nil repeats:YES];
    [super windowDidBecomeKey:sender];
}
-(void)windowWillClose:(id)sender
{
    [timer invalidate];
    [super windowWillClose:sender];
}
@end

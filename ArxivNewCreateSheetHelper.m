//
//  ArxivNewCreateSheetHelper.m
//  spires
//
//  Created by Yuji on 8/17/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArxivNewCreateSheetHelper.h"
#import "AppDelegate.h"

@implementation ArxivNewCreateSheetHelper
{
    NSArray*topLevelObjects;
}
-(id)init
{
    self=[super init];
    NSArray*foo;
    [[NSBundle mainBundle] loadNibNamed:@"ArxivNewCreateSheet" owner:self topLevelObjects:&foo];
    topLevelObjects=foo;
    return self;
}
-(void)run
{
    [self setValue:@"untitled" forKey:@"head"];
    [self setValue:@"new" forKey:@"tail"];
    [[[NSApp appDelegate] mainWindow] beginSheet:sheet completionHandler:^(NSModalResponse returnCode) {
        [sheet orderOut:self];
    }];
}
-(IBAction)OK:(id)sender;
{
    [[[NSApp appDelegate] mainWindow] endSheet:sheet];
    [[NSApp appDelegate] addArxivArticleListWithName:[NSString stringWithFormat:@"%@/%@",head,tail]];
}
-(IBAction)cancel:(id)sender;
{
    [[[NSApp appDelegate] mainWindow] endSheet:sheet];
}
@end

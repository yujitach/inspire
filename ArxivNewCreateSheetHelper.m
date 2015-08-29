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
    [NSApp beginSheet:sheet
       modalForWindow:[[NSApp appDelegate] mainWindow]
	modalDelegate:self
       didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
	  contextInfo:nil];
}
-(IBAction)OK:(id)sender;
{
    [NSApp endSheet:sheet];
    [[NSApp appDelegate] addArxivArticleListWithName:[NSString stringWithFormat:@"%@/%@",head,tail]];
}
-(IBAction)cancel:(id)sender;
{
    [NSApp endSheet:sheet];
}
- (void)sheetDidEnd:(NSWindow *)_sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
    [sheet orderOut:self];
}
@end

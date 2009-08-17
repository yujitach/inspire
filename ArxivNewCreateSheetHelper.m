//
//  ArxivNewCreateSheetHelper.m
//  spires
//
//  Created by Yuji on 8/17/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArxivNewCreateSheetHelper.h"
#import "spires_AppDelegate.h"

@implementation ArxivNewCreateSheetHelper
-(id)initWithWindow:(NSWindow*)w delegate:(spires_AppDelegate*)d;
{
    self=[super init];
    windowToAttach=w;
    delegate=d;
    [NSBundle loadNibNamed:@"ArxivNewCreateSheet" owner:self];
    return self;
}
-(void)run
{
    [self setValue:@"untitled" forKey:@"head"];
    [self setValue:@"new" forKey:@"tail"];
    [NSApp beginSheet:sheet
       modalForWindow:windowToAttach
	modalDelegate:self
       didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) 
	  contextInfo:nil];
}
-(IBAction)OK:(id)sender;
{
    [NSApp endSheet:sheet];
    [delegate addArxivArticleListWithName:[NSString stringWithFormat:@"%@/%@",head,tail]];
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

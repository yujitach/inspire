//
//  PrefController.m
//  spires
//
//  Created by Yuji on 09/01/31.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "PrefController.h"
#import "MOC.h"

@implementation PrefController
#pragma mark Time Machine
-(void)setShouldBackUp:(BOOL)shouldBackUp
{
    NSString*path=[[MOC sharedMOCManager] dataFilePath];
    NSURL*url=[NSURL fileURLWithPath:path];
    NSLog(@"time machine backup: %@",(shouldBackUp?@"enabled":@"disabled"));
    CSBackupSetItemExcluded((CFURLRef)url,(shouldBackUp?false:true),true);    
}
-(IBAction)timeMachineSettingChanged:(id)sender;
{
    BOOL shouldBackUp=[[NSUserDefaults standardUserDefaults] boolForKey:@"shouldBackUpDatabaseInTimeMachine"];
    [self setShouldBackUp:shouldBackUp];
}
-(void)applicationWillTerminate:(NSNotification*)notification
{
    [self setShouldBackUp:YES];
}
/*-(void)readTimeMachineState;
{
    Boolean excluded;
    NSString*path=[[MOC sharedMOCManager] dataFilePath];
    NSURL*url=[NSURL fileURLWithPath:path];
    CSBackupIsItemExcluded((CFURLRef)url,&excluded);
    [[NSUserDefaults standardUserDefaults] setBool:(excluded?FALSE:TRUE) forKey:@"shouldBackUpDatabaseInTimeMachine"];
}*/

-(PrefController*)init
{
    self=[super initWithWindowNibName:@"PrefPane"];
    [self timeMachineSettingChanged:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
					     selector:@selector(applicationWillTerminate:) 
						 name:NSApplicationWillTerminateNotification
					       object:nil];
    return self;
}
#pragma mark Mirrors

-(void)selectMirrorToUse:(NSString*)mirror
{
    NSInteger i=0;
    NSInteger c=[mirrorToUsePopUp numberOfItems];
    for(i=0;i<c;i++){
	if([[mirrorToUsePopUp itemTitleAtIndex:i] isEqualToString:mirror]){
	    [mirrorToUsePopUp selectItemAtIndex:i];
	    break;
	}
    }
    [self mirrorSelected: self];
}

-(void)selectDatabaseToUse:(NSString*)mirror
{
    NSInteger i=0;
    NSInteger c=[databaseToUsePopUp numberOfItems];
    for(i=0;i<c;i++){
	if([[databaseToUsePopUp itemTitleAtIndex:i] isEqualToString:mirror]){
	    [databaseToUsePopUp selectItemAtIndex:i];
	    break;
	}
    }
    [self databaseSelected: self];
}

-(void)selectBibToUse:(NSString*)bib
{
    NSInteger i=0;
    NSInteger c=[bibPopUp numberOfItems];
    for(i=0;i<c;i++){
	if([[bibPopUp itemTitleAtIndex:i] isEqualToString:bib]){
	    [bibPopUp selectItemAtIndex:i];
	    break;
	}
    }
    [self bibSelected: self];
}

-(IBAction)setFolderForPDF:(id)sender
{
    NSOpenPanel*op=[NSOpenPanel openPanel];
    NSString*currentSetting=[[[NSUserDefaults standardUserDefaults]stringForKey:@"pdfDir"] stringByExpandingTildeInPath];
    [op setCanChooseFiles:NO];
    [op setCanChooseDirectories:YES];
    [op setCanCreateDirectories:YES];
    [op setMessage:@"Choose the folder to save PDFs..."];
    [op setPrompt:@"Choose"];
    NSInteger res=[op runModalForDirectory:currentSetting file:nil types:nil];
    if(res==NSOKButton){
	NSString*nextSetting=[[op filenames] objectAtIndex:0];
	[[NSUserDefaults standardUserDefaults] setObject:[nextSetting stringByAbbreviatingWithTildeInPath] 
						  forKey:@"pdfDir"];
    }
    
}

-(IBAction)mirrorSelected:(id)sender;
{
    NSString*mirrorToUse=[mirrorToUsePopUp titleOfSelectedItem];
    [[NSUserDefaults standardUserDefaults] setObject:mirrorToUse forKey:@"mirrorToUse"];
}
-(IBAction)databaseSelected:(id)sender;
{
    NSString*databaseToUse=[databaseToUsePopUp titleOfSelectedItem];
    [[NSUserDefaults standardUserDefaults] setObject:databaseToUse forKey:@"databaseToUse"];
}
-(IBAction)bibSelected:(id)sender;
{
    NSString*bibToUse=[bibPopUp titleOfSelectedItem];
    [[NSUserDefaults standardUserDefaults] setObject:bibToUse forKey:@"bibType"];
}
-(IBAction)pdfRadioSelected:(id)sender;
{
    NSInteger i=[journalPDFRadio selectedRow];
    [[NSUserDefaults standardUserDefaults] setBool:(i==0?YES:NO) forKey:@"tryToDownloadJournalPDF"];
}


#pragma mark awake
-(void)awakeFromNib
{
    [mirrorToUsePopUp removeAllItems];
    [mirrorToUsePopUp addItemsWithTitles:[[NSUserDefaults standardUserDefaults] objectForKey:@"arXivMirrors"]];
    [databaseToUsePopUp removeAllItems];
    [databaseToUsePopUp addItemsWithTitles:[NSArray arrayWithObjects:@"spires",@"inspire",nil]];
    
    [self selectMirrorToUse:[[NSUserDefaults standardUserDefaults] objectForKey:@"mirrorToUse"]];
    [self selectDatabaseToUse:[[NSUserDefaults standardUserDefaults] objectForKey:@"databaseToUse"]];
    [self selectBibToUse:[[NSUserDefaults standardUserDefaults] objectForKey:@"bibType"]];
    
/*    {// change in v0.98
	if(![[NSUserDefaults standardUserDefaults] boolForKey:@"nameChangeInJournalRegExDone"]){
	    NSString*l=[[NSUserDefaults standardUserDefaults] objectForKey:@"universityLibraryToGetPDF"];
	    if([l isEqualToString:@"Princeton"]){
		[[NSUserDefaults standardUserDefaults] setObject:@"IAS" forKey:@"universityLibraryToGetPDF"];	    
	    }
	    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"nameChangeInJournalRegExDone"];
	}
    }*/
    NSDictionary* regexes=[[NSUserDefaults standardUserDefaults] objectForKey:@"regExpsForUniversityLibrary"]; 
    NSMutableArray* array=[NSMutableArray array];
    for(NSString* s in [regexes keyEnumerator]){
	[array addObject:s];
    }
    [self setValue:array forKey:@"libraries"];
    [journalPDFRadio selectCellAtRow:([[NSUserDefaults standardUserDefaults] boolForKey:@"tryToDownloadJournalPDF"]?0:1) column:0];
    
//    [self readTimeMachineState];
}
#pragma mark Font
-(float)fontSize
{
    return [[NSUserDefaults standardUserDefaults] floatForKey:@"articleViewFontSize"];
}
-(void)setFontSize:(float)size
{
    if(size<8 || size>20) return;
    [[NSUserDefaults standardUserDefaults] setFloat:(float)size forKey:@"articleViewFontSize"];
}
+(NSSet*)keyPathsForValuesAffectingCurrentFont
{
    return [NSSet setWithObject:@"fontSize"];
}
-(NSFont*)currentFont
{
    NSString*name=[[NSUserDefaults standardUserDefaults] valueForKey:@"articleViewFontName"];
    CGFloat size=self.fontSize;
    NSFont*font= [NSFont fontWithName:name size:size];
//    NSLog(@"font:%@",font);
    return font;
}
-(void)setCurrentFont:(NSFont*)newFont
{
    [[NSUserDefaults standardUserDefaults] setValue:[newFont fontName] forKey:@"articleViewFontName"];
    [[NSUserDefaults standardUserDefaults] setFloat:(float)[newFont pointSize] forKey:@"articleViewFontSize"];
}
+(NSSet*)keyPathsForValuesAffectingCurrentFontString
{
    return [NSSet setWithObjects:@"currentFont",@"fontSize",nil];
}
-(NSString*)currentFontString
{
    NSString*displayName=[[self currentFont] displayName];
    CGFloat size=[[self currentFont] pointSize];
    return [NSString stringWithFormat:@"%@ %d",displayName,(int)size];
    return displayName;
}

-(IBAction)changeFont:(id)sender;
{
    NSFont *oldFont = [self currentFont];
    NSFont *newFont = [sender convertFont:oldFont];
//    NSLog(@"font changes to:%@",newFont);
    [self setCurrentFont:newFont];
}
-(IBAction)openFontPanel:(id)sender;
{
    NSFontPanel*panel=[NSFontPanel sharedFontPanel];
//    [panel setTarget:self];
    [[NSFontManager sharedFontManager] setTarget:self];
    [panel setPanelFont:[self currentFont] isMultiple:NO];
    [panel makeKeyAndOrderFront:self];
}
@end

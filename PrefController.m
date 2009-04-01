//
//  PrefController.m
//  spires
//
//  Created by Yuji on 09/01/31.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "PrefController.h"


@implementation PrefController
-(PrefController*)init
{
    return self=[super initWithWindowNibName:@"PrefPane"];
}

-(void)selectMirrorToUse:(NSString*)mirror
{
    int i=0;
    int c=[mirrorToUsePopUp numberOfItems];
    for(i=0;i<c;i++){
	if([[mirrorToUsePopUp itemTitleAtIndex:i] isEqualToString:mirror]){
	    [mirrorToUsePopUp selectItemAtIndex:i];
	    break;
	}
    }
    [self mirrorSelected: self];
}

-(void)selectBibToUse:(NSString*)bib
{
    int i=0;
    int c=[bibPopUp numberOfItems];
    for(i=0;i<c;i++){
	if([[bibPopUp itemTitleAtIndex:i] isEqualToString:bib]){
	    [bibPopUp selectItemAtIndex:i];
	    break;
	}
    }
    [self bibSelected: self];
}

-(void)awakeFromNib
{
    [mirrorToUsePopUp removeAllItems];
    [mirrorToUsePopUp addItemsWithTitles:[[NSUserDefaults standardUserDefaults] objectForKey:@"arXivMirrors"]];

    [self selectMirrorToUse:[[NSUserDefaults standardUserDefaults] objectForKey:@"mirrorToUse"]];
    [self selectBibToUse:[[NSUserDefaults standardUserDefaults] objectForKey:@"bibType"]];

    {// change in v0.98
	if(![[NSUserDefaults standardUserDefaults] boolForKey:@"nameChangeInJournalRegExDone"]){
	    NSString*l=[[NSUserDefaults standardUserDefaults] objectForKey:@"universityLibraryToGetPDF"];
	    if([l isEqualToString:@"Princeton"]){
		[[NSUserDefaults standardUserDefaults] setObject:@"IAS" forKey:@"universityLibraryToGetPDF"];	    
	    }
	    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"nameChangeInJournalRegExDone"];
	}
    }
    NSDictionary* regexes=[[NSUserDefaults standardUserDefaults] objectForKey:@"regExpsForUniversityLibrary"]; 
    NSMutableArray* array=[NSMutableArray array];
    for(NSString* s in [regexes keyEnumerator]){
	[array addObject:s];
    }
    [self setValue:array forKey:@"libraries"];
    [journalPDFRadio selectCellAtRow:([[NSUserDefaults standardUserDefaults] boolForKey:@"tryToDownloadJournalPDF"]?0:1) column:0];
    
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
							      forKeyPath:@"values.articleViewFontSize" 
								 options:NSKeyValueObservingOptionNew context:nil];
    
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
    int res=[op runModalForDirectory:currentSetting file:nil types:nil];
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
-(IBAction)bibSelected:(id)sender;
{
    NSString*bibToUse=[bibPopUp titleOfSelectedItem];
    [[NSUserDefaults standardUserDefaults] setObject:bibToUse forKey:@"bibType"];
}
-(IBAction)pdfRadioSelected:(id)sender;
{
    int i=[journalPDFRadio selectedRow];
    [[NSUserDefaults standardUserDefaults] setBool:(i==0?YES:NO) forKey:@"tryToDownloadJournalPDF"];
}
-(NSFont*)currentFont
{
    NSString*name=[[NSUserDefaults standardUserDefaults] valueForKey:@"articleViewFontName"];
    CGFloat size=[[NSUserDefaults standardUserDefaults] floatForKey:@"articleViewFontSize"];
    NSFont*font= [NSFont fontWithName:name size:size];
//    NSLog(@"font:%@",font);
    return font;
}
-(void)setCurrentFont:(NSFont*)newFont
{
    [self willChangeValueForKey:@"currentFont"];
    [self willChangeValueForKey:@"currentFontString"];
    [[NSUserDefaults standardUserDefaults] setValue:[newFont fontName] forKey:@"articleViewFontName"];
    [[NSUserDefaults standardUserDefaults] setFloat:[newFont pointSize] forKey:@"articleViewFontSize"];
    [self didChangeValueForKey:@"currentFontString"];
    [self didChangeValueForKey:@"currentFont"];    
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
    [self setCurrentFont:newFont];
}
-(IBAction)openFontPanel:(id)sender;
{
    NSFontPanel*panel=[NSFontPanel sharedFontPanel];
//    [panel setTarget:self];
    [panel setPanelFont:[self currentFont] isMultiple:NO];
    [panel makeKeyAndOrderFront:self];
}
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self willChangeValueForKey:@"currentFontString"];
    [self didChangeValueForKey:@"currentFontString"];
}
@end

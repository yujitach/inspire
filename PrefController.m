//
//  PrefController.m
//  spires
//
//  Created by Yuji on 09/01/31.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "PrefController.h"


@implementation PrefController
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
@end

//
//  PrefController.h
//  spires
//
//  Created by Yuji on 09/01/31.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AuxPanelController.h"

@interface PrefController : AuxPanelController {
    IBOutlet NSPopUpButton* mirrorToUsePopUp;
    IBOutlet NSPopUpButton* databaseToUsePopUp;
    IBOutlet NSPopUpButton* bibPopUp;
    IBOutlet NSMatrix*journalPDFRadio;
//    IBOutlet NSTextField* fontField;
    NSArray*libraries;

}
-(NSFont*)currentFont;
-(IBAction)changeFont:(id)sender;
-(IBAction)openFontPanel:(id)sender;
-(IBAction)mirrorSelected:(id)sender;
-(IBAction)databaseSelected:(id)sender;
-(IBAction)bibSelected:(id)sender;
-(IBAction)pdfRadioSelected:(id)sender;
-(IBAction)setFolderForPDF:(id)sender;
-(IBAction)timeMachineSettingChanged:(id)sender;
@property float fontSize;
@end

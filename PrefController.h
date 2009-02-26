//
//  PrefController.h
//  spires
//
//  Created by Yuji on 09/01/31.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PrefController : NSObject {
    IBOutlet NSPopUpButton* mirrorToUsePopUp;
    IBOutlet NSPopUpButton* bibPopUp;
    IBOutlet NSMatrix*journalPDFRadio;
    NSArray*libraries;

}
-(IBAction)mirrorSelected:(id)sender;
-(IBAction)bibSelected:(id)sender;
-(IBAction)pdfRadioSelected:(id)sender;
-(IBAction)setFolderForPDF:(id)sender;
@end

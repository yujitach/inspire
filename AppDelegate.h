//
//  AppDelegate.h
//  spires
//
//  Created by Yuji on 8/28/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#if TARGET_OS_IPHONE

@import UIKit;


#define NSApp InspireAppDelegate

@protocol AppDelegate
-(void)startProgressIndicator;
-(void)stopProgressIndicator;
-(void)querySPIRES:(NSString*)search;
-(void)handleURL:(NSURL*) url;
-(void)postMessage:(NSString*)message;
-(void)clearingUpAfterRegistration:(id)sender;
-(BOOL)currentListIsArxivReplaced;
-(UIViewController*)presentingViewController;
@end
#import "InspireAppDelegate.h"
#else

@import AppKit;

extern NSString *ArticleDropPboardType;
extern NSString *ArticleListDropPboardType;

@protocol AppDelegate
-(BOOL)currentListIsArxivReplaced;
-(void)addSimpleArticleListWithName:(NSString*)name;
-(void)addArxivArticleListWithName:(NSString*)name;
-(NSWindow*)mainWindow;
-(void)showInfoOnAssociation;
-(void)handleURL:(NSURL*) url;
-(void)querySPIRES:(NSString*)search;
-(void)postMessage:(NSString*)message;
-(void)clearingUpAfterRegistration:(id)sender;
-(void)makeTableViewFirstResponder;
-(void)makeSideViewFirstResponder;
-(void)startProgressIndicator;
-(void)stopProgressIndicator;
-(void)addToTeXLog:(NSString*)log;
-(void)presentFileSaveError;
/*-(void)startUpdatingMainView:(id)sender;
-(void)stopUpdatingMainView:(id)sender;*/
@end

@interface NSApplication (AppDelegate)
-(id<AppDelegate>)appDelegate;
@end
#endif

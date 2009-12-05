//
//  AppDelegate.h
//  spires
//
//  Created by Yuji on 8/28/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *ArticleDropPboardType;
extern NSString *ArticleListDropPboardType;

@protocol AppDelegate
-(BOOL)currentListIsArxivReplaced;
-(void)rearrangePositionInViewForArticleLists;
-(NSWindow*)mainWindow;
-(void)showInfoOnAssociation;
-(void)handleURL:(NSURL*) url;
-(void)postMessage:(NSString*)message;
-(void)clearingUpAfterRegistration:(id)sender;
/*-(void)startUpdatingMainView:(id)sender;
-(void)stopUpdatingMainView:(id)sender;*/
@end

//
//  AppDelegate.h
//  spires
//
//  Created by Yuji on 8/28/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@protocol AppDelegate
-(BOOL)currentListIsArxivReplaced;
-(void)rearrangePositionInViewForArticleLists;
-(NSWindow*)mainWindow;
-(void)handleURL:(NSURL*) url;
@end

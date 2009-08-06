//
//  AppDelegate.m
//  QuickLookHelper
//
//  Created by Yuji on 09/02/27.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "AppDelegate.h"

#define QLPreviewPanel NSClassFromString(@"QLPreviewPanel")

@interface SomeKindOfPanel : NSObject{
}
-(void)setURLs:(NSArray*)a currentIndex:(NSInteger)i preservingDisplayState:(BOOL)b;
-(void)makeKeyAndOrderFrontWithEffect:(NSInteger)i;
-(void)setDelegate:(id)i;
-(BOOL)isOpen;
-(BOOL)isOpaque;
@end
@interface NSObject (toShutUpWarningFromGCCaboutQuickLook)
-(SomeKindOfPanel*)sharedPreviewPanel;
@end

@implementation AppDelegate
+(void)initialize
{
    if([[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/QuickLookUI.framework"] load]){
//	NSLog(@"Quick Look loaded!"); 
	//[[[QLPreviewPanel sharedPreviewPanel] windowController] setDelegate:self];
    }
}

-(void)application:(NSApplication*)app openFiles:(NSArray*)array
{
    for(NSString*path in array){
	[[QLPreviewPanel sharedPreviewPanel] setURLs:[NSArray arrayWithObject:[NSURL fileURLWithPath:path]] 
					currentIndex:0 
			      preservingDisplayState:YES];
	[[QLPreviewPanel sharedPreviewPanel] setDelegate:self];
	[[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFrontWithEffect:1]; 
	//	NSLog(@"%@",path);
	
    }
}

-(void)notifyQuickLookCloseToSpiresApp
{
    [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:[NSURL URLWithString:@"spires-quicklook-closed://"]]
		    withAppBundleIdentifier:@"com.yujitach.spires" 
				    options:NSWorkspaceLaunchWithoutActivation 
	     additionalEventParamDescriptor:nil
			  launchIdentifiers:nil];
/*    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"SpiresQuickLookHelperClosed" 
								   object:nil];*/
}
-(void)activateSpiresApp
{
    [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.yujitach.spires" 
							 options: 0
				  additionalEventParamDescriptor:nil 
						launchIdentifier:nil];
}
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
//    NSLog(@"closed.");
    [self notifyQuickLookCloseToSpiresApp];
    return YES;
}

/*-(BOOL)previewPanel:(SomeKindOfPanel*)panel shouldHandleEvent:(NSEvent*)ev
{
    if(([ev type]==NSKeyDown || [ev type]==NSKeyUp) && [[ev characters] isEqualToString:@" "]){
	[self notifyQuickLookCloseToSpiresApp];
	[self activateSpiresApp];
    }
    else if([ev type]==NSLeftMouseUp && [ev clickCount]==2){
	[self notifyQuickLookCloseToSpiresApp];
    }
    return YES;
}*/

/*- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    [self performSelector:@selector(closeCheck:) withObject:nil afterDelay:1];
}
-(void)closeCheck:(id)dummy
{
    if(![[QLPreviewPanel sharedPreviewPanel] isOpen]){
	[self notifyQuickLookCloseToSpiresApp];
	[self activateSpiresApp];
    }
} */   
/*-(BOOL)respondsToSelector:(SEL)sel
 {
 NSLog(@"%@",NSStringFromSelector(sel));
 return [super respondsToSelector:sel];
 }*/
/*-(void)previewPanel:(SomeKindOfPanel*)panel didChangeDisplayStateForURL:(NSURL*)url
 {
 NSLog(@"didChange:%@",url);
 }*/
/*
 -(id)previewPanel:(SomeKindOfPanel*)panel syncDisplayState:(id)i forURL:(NSURL*)url
 {
 BOOL isOpen=[panel isOpen];
 BOOL isOpaque=[panel isOpaque];
 NSLog(@"state:%@",i);
 NSLog(@"url:%@",url);
 NSLog(@"isOpen:%@",isOpen?@"YES":@"NO");
 NSLog(@"isOpaque:%@",isOpaque?@"YES":@"NO");
 if(i){
 [[NSWorkspace sharedWorkspace] openURLs:[NSArray arrayWithObject:[NSURL URLWithString:@"spires-quicklook-closed://"]]
 withAppBundleIdentifier:@"com.yujitach.spires" 
 options:NSWorkspaceLaunchWithoutActivation 
 additionalEventParamDescriptor:nil
 launchIdentifiers:nil];	
 }
 return i;
 }*/
@end

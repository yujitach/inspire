//
//  ArxivHelper.h
//  spires
//
//  Created by Yuji on 08/10/14.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

@import Foundation;

@interface ArxivHelper : NSObject
+(ArxivHelper*)sharedHelper;
-(NSString*)arXivAbstractPathForID:(NSString*)arXivID;
-(void)startDownloadPDFforID:(NSString*)arXivID delegate:(id)delegate didEndSelector:(SEL)sel;
-(NSString*)list:(NSString*)path;
@end

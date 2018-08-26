//
//  ArxivHelper.h
//  spires
//
//  Created by Yuji on 08/10/14.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

@import Foundation;

@protocol ArxivHelperDelegate
-(void)pdfDownloadDidEnd:(NSDictionary*)dic;
@end
@interface ArxivHelper : NSObject<NSURLSessionDelegate>
+(ArxivHelper*)sharedHelper;
-(NSString*)arXivAbstractPathForID:(NSString*)arXivID;
-(void)startDownloadPDFforID:(NSString*)arXivID delegate:(id)delegate;
-(NSString*)list:(NSString*)path;
@end

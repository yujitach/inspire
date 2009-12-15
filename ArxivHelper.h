//
//  ArxivHelper.h
//  spires
//
//  Created by Yuji on 08/10/14.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ArxivHelper : NSObject {
    NSMutableArray*connections;
    NSURLConnection*connection;
    NSURLResponse*response;
    NSMutableData*temporaryData;
    NSMutableDictionary*returnDict;
    id delegate;
    SEL sel;
    
  
}
+(ArxivHelper*)sharedHelper;
-(NSString*)arXivAbstractPathForID:(NSString*)arXivID;
-(void)startDownloadPDFforID:(NSString*)arXivID delegate:(id)delegate didEndSelector:(SEL)sel;
-(NSString*)list:(NSString*)path;
@end

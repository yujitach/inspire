//
//  SpiresHelper.h
//  spires
//
//  Created by Yuji on 08/10/16.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SpiresHelper : NSObject {
    id userInfo;
    id delegate;
    SEL sel;
    NSString*searchString;
    NSMutableData*temporaryData;
    NSURLConnection*connection;
    NSURLRequest*urlRequest;
    
}
+(SpiresHelper*)sharedHelper;
-(NSPredicate*) predicateFromSPIRESsearchString:(NSString*)string;
//-(NSPredicate*) simplePredicateFromSPIRESsearchString:(NSString*)string;
-(NSURL*)spiresURLForQuery:(NSString*)search;
-(NSArray*)bibtexEntriesForQuery:(NSString*)search;
-(NSArray*)latexEUEntriesForQuery:(NSString*)search;
-(NSArray*)harvmacEntriesForQuery:(NSString*)search;
-(void)querySPIRES:(NSString*)s delegate:(id)d didEndSelector:(SEL)sel userInfo:(id)v;
@end

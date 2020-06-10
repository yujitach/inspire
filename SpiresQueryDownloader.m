//
//  SpiresQueryDownloader.m
//  spires
//
//  Created by Yuji on 7/3/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "SpiresQueryDownloader.h"
#import "SpiresHelper.h"
#import "NSString+magic.h"
#import "AppDelegate.h"
#import "Article.h"
#import "MOC.h"
#import "InspireXMLParser.h"


@implementation SpiresQueryDownloader{
    WhenDoneClosure whenDone;
    NSString*searchString;
    NSMutableData*temporaryData;
    NSURLSession*session;
    NSUInteger total;
    NSUInteger sofar;
    NSUInteger startIndex;
}


-(NSURL*)urlForInspireForString:(NSString*)search
{
    NSString*inspireQuery=nil;
    if([search hasPrefix:@"r"]||[search hasPrefix:@"c "]){
	NSString*rec=nil;
        Article*article=[Article articleForQuery:search inMOC:[MOC moc]];
	NSNumber*inspireKey=article.inspireKey;
	if(inspireKey && [inspireKey integerValue]!=0){
	    rec=[NSString stringWithFormat:@"recid:%@",inspireKey];
	}else if(article.eprint && ![article.eprint isEqualToString:@""]){
	    rec=[NSString stringWithFormat:@"%@",article.eprint];
	}else /*if(article.spiresKey && [article.spiresKey integerValue]!=0){
            NSString*query=[NSString stringWithFormat:@"find key %@&rg=1&of=xm",article.spiresKey];
            NSURL*url=[[SpiresHelper sharedHelper] inspireURLForQuery:query];
            NSXMLDocument*doc=[[NSXMLDocument alloc] initWithContentsOfURL:url
								   options:0
								     error:NULL];
	    NSArray*a=[[doc rootElement] nodesForXPath:@"record/controlfield" error:NULL];
	    NSLog(@"%@",a);
	    if([a count]>0){
		NSXMLElement*e=a[0];
		NSLog(@"%@",e);
		NSNumber*n=@([[e stringValue] integerValue]);
		article.inspireKey=n;
		rec=[NSString stringWithFormat:@"recid:%@",n];
	    }
	}else*/{
	    return nil;
	}
	NSString*head=nil;
	if([search hasPrefix:@"r"]){
	    head=@"citedby";
	}else{
	    head=@"refersto";
	}
	inspireQuery=[NSString stringWithFormat:@"%@:%@",head,rec];
    }else if([search hasPrefix:@"doi"]){
        inspireQuery=[search stringByReplacingOccurrencesOfRegex:@"^doi " withString:@"doi:"];
    }else{
        if(![search hasPrefix:@"find"]){
            inspireQuery=[NSString stringWithFormat:@"%@",search];
        }else{
            inspireQuery=search;
        }
    }
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"limitAuthorCount"]){
        inspireQuery=[inspireQuery stringByAppendingString:@"+and+ac+1->25"];
    }
//    NSString*str=[NSString stringWithFormat:@"%@&jrec=%d&rg=%d&of=xm&ot=%@",inspireQuery,(int)startIndex+1,MAXPERQUERY,[InspireXMLParser usedTags]];
    NSString*str=[NSString stringWithFormat:@"%@&page=%d&size=%d",inspireQuery,(int)(startIndex/MAXPERQUERY)+1,MAXPERQUERY];

    return [[SpiresHelper sharedHelper] newInspireAPIURLForQuery:str withFormat:@"json"];
}
-(id)initWithQuery:(NSString*)search startAt:(NSUInteger)start whenDone:(WhenDoneClosure)wd
{
    self=[super init];
    whenDone=wd;
    startIndex=start;
    search=[search normalizedString];
    // 29/6/2009
    // differences in the query strings of the real web spires and those of my spires app should be addressed more properly
    // than this
    search=[search stringByReplacingOccurrencesOfRegex:@"^e " withString:@"eprint "];
    search=[search stringByReplacingOccurrencesOfRegex:@" e " withString:@" eprint "];
    search=[search stringByReplacingOccurrencesOfRegex:@"^ep " withString:@"eprint "];
    search=[search stringByReplacingOccurrencesOfRegex:@" ep " withString:@" eprint "];
    // end target of the comment above
    searchString=search;
    NSURL*url=[self urlForInspireForString:search];
    NSLog(@"fetching:%@",url);
    NSURLRequest*urlRequest=[NSURLRequest requestWithURL:url
				cachePolicy:NSURLRequestUseProtocolCachePolicy
			    timeoutInterval:240];
    
    temporaryData=[NSMutableData data];
    NSURLSessionConfiguration*config=[NSURLSessionConfiguration defaultSessionConfiguration];
    session=[NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask*dataTask=[session dataTaskWithRequest:urlRequest];
    [dataTask resume];
    
    [[NSApp appDelegate] startProgressIndicator];
    if(startIndex==0){
        [[NSApp appDelegate] postMessage:@"Waiting reply from inspire..."];
    }else{
        [[NSApp appDelegate] postMessage:[NSString stringWithFormat:@"Articles #%d --",(int)startIndex]];
    }

    return self;
}
#pragma mark Bibtex parser


#pragma mark URL connection delegates
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);
}
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [temporaryData appendData:data];
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDataTask *)task didCompleteWithError:(NSError *)error
{
    [[NSApp appDelegate] postMessage:nil];
    [[NSApp appDelegate] stopProgressIndicator];
    if(!error){
        NSDictionary*d=[NSJSONSerialization JSONObjectWithData:temporaryData options:0 error:nil];
        whenDone(d);
        temporaryData=nil;
    }else{
        whenDone(nil);
#if !TARGET_OS_IPHONE
        NSAlert*alert=[[NSAlert alloc] init];
        alert.messageText=@"Connection Error to Inspire";
        [alert addButtonWithTitle:@"OK"];
        alert.informativeText=[error localizedDescription];
        //[alert setAlertStyle:NSCriticalAlertStyle];
        [alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
                      completionHandler:nil];
#endif
    }
}
@end

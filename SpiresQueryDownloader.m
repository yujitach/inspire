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
    NSNumber* total;
    NSUInteger sofar;
    NSUInteger startIndex;
    NSInteger sleep;
}
-(void)dealWith:(NSArray*)a
{
    NSString*q=[@"recid:" stringByAppendingString:[a componentsJoinedByString:@" or "]];
    [NSThread sleepForTimeInterval:sleep];
    NSURL*url=[[SpiresHelper sharedHelper] newInspireAPIURLForQuery:[q stringByAppendingString:@"&size=50"] withFormat:@"json"];
    NSUInteger count=a.count;
    NSLog(@"fetching:%@\nelements:%d",url,(int)count);
    dispatch_async(dispatch_get_main_queue(),^{
        [[NSApp appDelegate] postMessage:[NSString stringWithFormat:@"Obtaining articles #%d to #%d of %@", (int)(sofar+1),(int)(sofar+count),total]];
        sofar+=count;
    });
    NSData*data=[NSData dataWithContentsOfURL:url];
    if(data){
        NSDictionary*d=[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        dispatch_async(dispatch_get_main_queue(),^{
            whenDone(d);
        });
    }else{
        whenDone(nil);
    }
}
-(void)unfortunateCitedByMainWork:(NSString*)uniqueQuery
{
    dispatch_async(dispatch_get_main_queue(),^{
        [[NSApp appDelegate] postMessage:@"Fetching preliminary data..."];
    });
    NSURL*url=[[SpiresHelper sharedHelper] newInspireAPIURLForQuery:uniqueQuery withFormat:@"json" forFields:@"references"];
    NSLog(@"getting list of references for %@ via %@",uniqueQuery,url);
    NSData*data=[NSData dataWithContentsOfURL:url];
    NSDictionary*d=[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    d=d[@"hits"];
    NSArray*a=d[@"hits"];
    if(a.count==0){
        NSLog(@"inspire still doesn't have the data for %@",uniqueQuery);
        return;
    }
    d=a[0];
    d=d[@"metadata"];
    a=d[@"references"];
    total=@(a.count);
    NSMutableArray*ma=[NSMutableArray array];
    for(NSDictionary*x in a){
        NSDictionary*y=x[@"record"];
        NSString*s=y[@"$ref"];
        if([s containsString:@"inspirehep.net/api/literature/"]){
            NSString*z=[s lastPathComponent];
            [ma addObject:z];
        }
        if(ma.count>=50){
            [self dealWith:ma];
            [ma removeAllObjects];
        }
    }
    if(ma.count>0){
        [self dealWith:ma];
    }
    dispatch_async(dispatch_get_main_queue(),^{
        [[NSApp appDelegate] postMessage:nil];
    });
}
-(void)unfortunatelyCitedByHasNotBeenImplementedByNewInspireYet
{
    Article*article=[Article articleForQuery:searchString inMOC:[MOC moc]];
    NSString*uniqueQuery=[article uniqueInspireQueryString];
    [self performSelectorInBackground:@selector(unfortunateCitedByMainWork:) withObject:uniqueQuery];
}
-(void)ensureQueryHasRecIdAndStart:(NSString*)search
{
    Article*article=[Article articleForQuery:searchString inMOC:[MOC moc]];
    NSString*uniqueQuery=[article uniqueInspireQueryString];
    if([uniqueQuery hasPrefix:@"recid"]){
        [self startAt:0];
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0),^{
        NSURL*url=[[SpiresHelper sharedHelper] newInspireAPIURLForQuery:uniqueQuery withFormat:@"json" forFields:@"control_number"];
        NSLog(@"getting recid for %@ via %@",uniqueQuery,url);
        NSData*data=[NSData dataWithContentsOfURL:url];
        NSDictionary*d=[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        d=d[@"hits"];
        NSArray*a=d[@"hits"];
        if(a.count==0){
            NSLog(@"inspire still doesn't have the data for %@",uniqueQuery);
            return;
        }
        d=a[0];
        d=d[@"metadata"];
        NSNumber*r=d[@"control_number"];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, sleep * NSEC_PER_SEC),dispatch_get_main_queue(),^{
            article.inspireKey=r;
            [self startAt:0];
        });
    });
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
-(id)initWithQuery:(NSString*)search whenDone:(WhenDoneClosure)wd
{
    self=[super init];
    sleep=[[NSUserDefaults standardUserDefaults] integerForKey:@"inspireWaitInSeconds"];
    whenDone=wd;
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
    if([search hasPrefix:@"r "]){
        // as new inspire api hasn't implemented citedby:recid:, I need to write more code.
        [self unfortunatelyCitedByHasNotBeenImplementedByNewInspireYet];
        return self;
    }
    if([search hasPrefix:@"c "]){
        [self ensureQueryHasRecIdAndStart:search];
        return self;
    }
    [self startAt:0];
    return self;
}
-(void)startAt:(NSUInteger)start
{
    startIndex=start;
    NSURL*url=[self urlForInspireForString:searchString];
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
    if(!total){
        [[NSApp appDelegate] postMessage:@"Waiting reply from inspire..."];
    }else{
        NSUInteger a=startIndex+1;
        NSUInteger b=startIndex+MAXPERQUERY;
        NSUInteger tot=total.unsignedIntegerValue;
        if(b>tot){
            b=tot;
        }
        [[NSApp appDelegate] postMessage:[NSString stringWithFormat:@"Obtaining articles #%d to #%d of %@",(int)a,(int)b,total]];
    }
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
    if(!error){
        NSDictionary*d=[NSJSONSerialization JSONObjectWithData:temporaryData options:0 error:nil];
        whenDone(d);
        temporaryData=nil;
        
        NSDictionary*hits=d[@"hits"];
        total=hits[@"total"];
        NSDictionary*links=d[@"links"];
        if(links[@"next"]){
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, sleep * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [self startAt:startIndex+MAXPERQUERY];
            });
        }
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

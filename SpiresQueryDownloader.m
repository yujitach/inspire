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
#import "InspireXMLArticle.h"


@implementation SpiresQueryDownloader


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
            inspireQuery=[NSString stringWithFormat:@"find+%@",search];
        }else{
            inspireQuery=search;
        }
    }
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"limitAuthorCount"]){
        inspireQuery=[inspireQuery stringByAppendingString:@"+and+ac+1->25"];
    }
    NSString*str=[NSString stringWithFormat:@"%@&jrec=%d&rg=%d&of=xm&ot=%@",inspireQuery,(int)startIndex+1,MAXPERQUERY,[InspireXMLArticle usedTags]];
    return [[SpiresHelper sharedHelper] inspireURLForQuery:str];
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
    urlRequest=[NSURLRequest requestWithURL:url
				cachePolicy:NSURLRequestUseProtocolCachePolicy
			    timeoutInterval:240];
    
    temporaryData=[NSMutableData data];
    connection=[NSURLConnection connectionWithRequest:urlRequest
					     delegate:self];
    [[NSApp appDelegate] startProgressIndicator];
    if(start==0){
        [[NSApp appDelegate] postMessage:@"Waiting reply from inspire..."];
    }else{
        [[NSApp appDelegate] postMessage:[NSString stringWithFormat:@"Articles #%d --",(int)start]];
    }
    return self;
}
#pragma mark Bibtex parser

/*-(NSString*)transformBibtexToXML:(NSString*)s
{
    NSString*inPath=[NSString stringWithFormat:@"/tmp/inSPIRES-%d",getuid()];
    NSString*outPath=[NSString stringWithFormat:@"/tmp/outSPIRES-%d",getuid()];
    NSString*script=[[NSBundle mainBundle] pathForResource:@"wwwrefsbibtex2xmlpublic" ofType:@"perl"];
    NSString* command=[NSString stringWithFormat:@"/usr/bin/perl %@ <%@ >%@" , [script quotedForShell], inPath,outPath];
    NSError*error=nil;
    [s writeToFile:inPath atomically:NO encoding:NSUTF8StringEncoding error:&error];
    system([command UTF8String]);
    NSString*result=[[NSString alloc] initWithContentsOfFile:outPath encoding:NSUTF8StringEncoding error:&error];
    //   NSLog(@"%@",result);
    return result;
}*/

#pragma mark URL connection delegates
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [temporaryData appendData:data];
}
/*-(NSXMLDocument*)docFromSpiresData:(NSError**)error
{
    //	NSString*t=[[NSString alloc] initWithData:temporaryData encoding:NSUTF8StringEncoding];
    NSString*t=[[NSString alloc] initWithData:temporaryData encoding:NSISOLatin1StringEncoding];
    
    
    if([searchString hasPrefix:@"r"]){
	t=[self transformBibtexToXML:t];
    }
    return [[NSXMLDocument alloc] initWithXMLString:t options:0 error:error];
}*/




-(void)connectionDidFinishLoading:(NSURLConnection*)c
{
    [[NSApp appDelegate] postMessage:nil];
    [[NSApp appDelegate] stopProgressIndicator];

    NSString*s=[[NSString alloc] initWithData:temporaryData encoding:NSUTF8StringEncoding];
    NSString*t=[s stringByMatching:@"<!--.+?: *(\\d+?) *-->" capture:1];
    total=[t intValue];
    NSUInteger count=[[s componentsMatchedByRegex:@"<record>"] count];
    NSLog(@"count:%@",@(count));
    whenDone(temporaryData,count<MAXPERQUERY);
    temporaryData=nil;
    connection=nil;
    
}

-(void)connection:(NSURLConnection*)c didFailWithError:(NSError*)error
{
    whenDone(nil,YES);
    [[NSApp appDelegate] postMessage:nil];
    [[NSApp appDelegate] stopProgressIndicator];

    NSAlert*alert=[NSAlert alertWithMessageText:@"Connection Error to Inspire"
				  defaultButton:@"OK"
				alternateButton:nil
				    otherButton:nil informativeTextWithFormat:@"%@",[error localizedDescription]];
    //[alert setAlertStyle:NSCriticalAlertStyle];
    [alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
		      modalDelegate:nil 
		     didEndSelector:nil
			contextInfo:nil];
}

@end

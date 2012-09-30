//
//  ArxivHelper.m
//  spires
//
//  Created by Yuji on 08/10/14.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "ArxivHelper.h"
#import "AppDelegate.h"

ArxivHelper* _sharedHelper=nil;
@implementation ArxivHelper
+(ArxivHelper*)sharedHelper
{
    if(!_sharedHelper){
	_sharedHelper=[[ArxivHelper alloc]init];
    }
    return _sharedHelper;
}
-(ArxivHelper*)init
{
    self=[super init];
    connections=[NSMutableArray array];
    return self;
}
-(NSString*)arXivHead
{
    NSString*mirror= [[NSUserDefaults standardUserDefaults] stringForKey:@"mirrorToUse"];
    return [NSString stringWithFormat:@"http://%@arxiv.org/",mirror];
}

-(NSString*)arXivPDFPathForID:(NSString*)arXivID
{
    if([arXivID hasPrefix:@"arXiv:"]){
	arXivID=[arXivID substringFromIndex:[(NSString*)@"arXiv:" length]];
    }
    return [NSString stringWithFormat:@"%@pdf/%@",[self arXivHead],arXivID];
}
-(NSString*)arXivAbstractPathForID:(NSString*)arXivID
{
    if([arXivID hasPrefix:@"arXiv:"]){
	arXivID=[arXivID substringFromIndex:[(NSString*)@"arXiv:" length]];
    }
    return [NSString stringWithFormat:@"%@abs/%@",[self arXivHead],arXivID];
}



-(void)startDownloadPDFforID:(NSString*)arXivID delegate:(id)dele didEndSelector:(SEL)s;
{
    NSURL* url=[NSURL URLWithString:[self arXivPDFPathForID:arXivID]];
    NSLog(@"fetching:%@",url);
    NSURLRequest* urlRequest=[NSURLRequest requestWithURL:url
					      cachePolicy:NSURLRequestUseProtocolCachePolicy
					  timeoutInterval:30];
    
    temporaryData=[NSMutableData data];
    returnDict=[NSMutableDictionary dictionary];
    delegate=dele;
    sel=s;
    connection=[NSURLConnection connectionWithRequest:urlRequest
					     delegate:self];
}

/*-(NSXMLDocument*)xmlForPath:(NSString*)path
{
    NSString*p=[[path componentsSeparatedByString:@"/"]objectAtIndex:0];
    NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"%@/rss/%@",[self arXivHead],p]];
    NSError*error=nil;
    NSXMLDocument*doc=[[NSXMLDocument alloc] initWithContentsOfURL:url options:0   error:&error];
    return doc;
}*/

-(NSString*)list_internal:(NSString*)path
{
    NSURL* url=[NSURL URLWithString:[NSString stringWithFormat:@"%@list/%@",[self arXivHead],path]];
    NSURLRequest*request=[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    NSLog(@"fetching:%@",url);
    NSError*error=nil;
    NSURLResponse*responsee=nil;
    NSData*data=[NSURLConnection sendSynchronousRequest:request returningResponse:&responsee error:&error];
    NSString* s=nil;
    if(data){
	s=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if(!s){
	    s=[[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
	}
    }
    if(!s)return nil;  
    if([s isEqualToString:@""]) return nil;
    return s;
    
}
-(NSString*)list:(NSString*)path
{
    NSArray* a=[path componentsSeparatedByString:@"/"];
    NSString* category=[a objectAtIndex:0];
    NSString* t=[a objectAtIndex:1];
    if([t hasPrefix:@"new"]){
	NSString* content=[self list_internal:[NSString stringWithFormat:@"%@/%@",category,@"new"]];
	NSRange r=[content rangeOfString:@"<h3>Cross"];
	if(r.location!=NSNotFound){
	    content=[content substringToIndex:r.location];
	}
	NSRange s=[content rangeOfString:@"<h3>Repla"];
	if(s.location!=NSNotFound){
	    content=[content substringToIndex:s.location];
	}
	return content;
    }else if([t hasPrefix:@"rep"]){
	NSString* content=[self list_internal:[NSString stringWithFormat:@"%@/%@",category,@"new"]];
	NSRange r=[content rangeOfString:@"<h3>Repla"];
	if(r.location!=NSNotFound){
	    content=[content substringFromIndex:r.location];
	}else{
	    content=nil;
	}
	return content;
    }else if([t hasPrefix:@"cros"]){
	NSString* content=[self list_internal:[NSString stringWithFormat:@"%@/%@",category,@"new"]];
	NSRange r=[content rangeOfString:@"<h3>Cross"];
	NSRange s=[content rangeOfString:@"<h3>Repl"];
	if(r.location!=NSNotFound){
	    if(s.location!=NSNotFound){
		content=[content substringWithRange:NSMakeRange(r.location,s.location-r.location)];
	    }else{
		content=[content substringFromIndex:r.location];
	    }
	}else{
	    content=nil;
	}
	return content;
    }else if([t hasPrefix:@"rec"]){
	NSString* content=[self list_internal:[NSString stringWithFormat:@"%@/%@",category,@"pastweek?show=99"]];
	NSRange r=[content rangeOfString:@"<h3>Cross"];
	if(r.location!=NSNotFound){
	    content=[content substringToIndex:r.location];
	}
	return content;	
    }
    NSLog(@"arxiv list %@ not understood",path);
    return nil;
}

#pragma mark URL connection delegates
- (void)connection:(NSURLConnection *)c didReceiveData:(NSData *)data
{
    [temporaryData appendData:data];
}
-(void)connection:(NSURLConnection*)c didReceiveResponse:(NSURLResponse*)resp
{
    response=resp;
}
-(void)connectionDidFinishLoading:(NSURLConnection*)c
{
    if( ![[response MIMEType] hasSuffix:@"html"] && [temporaryData length]>10240){
	[returnDict setValue:temporaryData forKey:@"pdfData"];
	[returnDict setValue:[NSNumber numberWithBool:YES] forKey:@"success"];
    }else{
	[returnDict setValue:[NSNumber numberWithBool:NO] forKey:@"success"];
	if([[response MIMEType] hasSuffix:@"html"]){
	    NSString*s=[[NSString alloc] initWithData:temporaryData encoding:NSUTF8StringEncoding];
	    NSArray*a=[s componentsSeparatedByString:@"http-equiv=\"refresh\" content=\""];
	    if([a count]>1){
		s=[a objectAtIndex:1];
		a=[s componentsSeparatedByString:@"\""];
		if([a count]>0){
		    s=[a objectAtIndex:0];
		    NSNumber*num=[NSNumber numberWithInt:[s intValue]];
		    [returnDict setValue:num forKey:@"shouldReloadAfter"];
		}
	    }
	}
    }
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [delegate performSelector:sel withObject:returnDict];
    connection=nil;
}
-(void)connection:(NSURLConnection*)c didFailWithError:(NSError*)error
{
    [returnDict setValue:[NSNumber numberWithBool:NO] forKey:@"success"];
    [returnDict setValue:error forKey:@"error"];

    [delegate performSelector:sel withObject:returnDict];
    NSAlert*alert=[NSAlert alertWithMessageText:@"Connection Error to arXiv"
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

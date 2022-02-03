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
{
    NSURLSession*session;
    id<ArxivHelperDelegate> delegate;
    NSProgress*progress;
    NSMutableData*temporaryData;
    BOOL canceled;
}

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
    return self;
}
-(NSString*)arXivHead
{
    NSString*mirror= [[NSUserDefaults standardUserDefaults] stringForKey:@"mirrorToUse"];
    return [NSString stringWithFormat:@"https://%@arxiv.org/",mirror];
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



-(void)startDownloadPDFforID:(NSString*)arXivID delegate:(id)dele
{
    NSURL* url=[NSURL URLWithString:[self arXivPDFPathForID:arXivID]];
    NSLog(@"fetching:%@",url);
    NSURLSessionConfiguration*config=[NSURLSessionConfiguration defaultSessionConfiguration];
    session=[NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURLRequest* urlRequest=[NSURLRequest requestWithURL:url
					      cachePolicy:NSURLRequestUseProtocolCachePolicy
					  timeoutInterval:30];
    
    delegate=dele;
    temporaryData=[NSMutableData data];
    NSURLSessionDataTask*dataTask=[session dataTaskWithRequest:urlRequest];
    canceled=NO;
    [dataTask resume];
}

-(void)cancelDownloadPDF
{
    canceled=YES;
    [session invalidateAndCancel];
}
/*-(NSXMLDocument*)xmlForPath:(NSString*)path
{
    NSString*p=[[path componentsSeparatedByString:@"/"]objectAtIndex:0];
    NSURL *url=[NSURL URLWithString:[NSString stringWithFormat:@"%@/rss/%@",[self arXivHead],p]];
    NSError*error=nil;
    NSXMLDocument*doc=[[NSXMLDocument alloc] initWithContentsOfURL:url options:0   error:&error];
    return doc;
}*/

// taken from https://stackoverflow.com/a/34200617/239243
- (NSData *)sendSynchronousRequest:(NSURLRequest *)request
                 returningResponse:(__autoreleasing NSURLResponse **)responsePtr
                             error:(__autoreleasing NSError **)errorPtr {
    dispatch_semaphore_t    sem;
    __block NSData *        result;
    
    result = nil;
    
    sem = dispatch_semaphore_create(0);
    
    [[[NSURLSession sharedSession] dataTaskWithRequest:request
                                     completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                         if (errorPtr != NULL) {
                                             *errorPtr = error;
                                         }
                                         if (responsePtr != NULL) {
                                             *responsePtr = response;
                                         }
                                         if (error == nil) {
                                             result = data;
                                         }
                                         dispatch_semaphore_signal(sem);
                                     }] resume];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return result;
}

-(NSString*)list_internal:(NSString*)path
{
    NSURL* url=[NSURL URLWithString:[NSString stringWithFormat:@"%@list/%@",[self arXivHead],path]];
    NSURLRequest*request=[NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    NSLog(@"fetching:%@",url);
    NSError*error=nil;
    NSURLResponse*responsee=nil;
    NSData*data=[self sendSynchronousRequest:request returningResponse:&responsee error:&error];
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
    NSString* category=a[0];
    NSString* t=a[1];
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
	NSString* content=[self list_internal:[NSString stringWithFormat:@"%@/%@",category,@"pastweek?show=999"]];
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


- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [temporaryData appendData:data];
    progress.completedUnitCount=temporaryData.length;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"pdfDownloadProgress"
                                                        object:@{
                                                                 @"url":dataTask.originalRequest.URL,
                                                                 @"fractionCompleted":@(progress.fractionCompleted)
                                                                                               }];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);
    
    progress=[NSProgress progressWithTotalUnitCount:response.expectedContentLength];
    [progress setUserInfoObject:response.URL forKey:@"URL"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"pdfDownloadStarted" object:@{
                                                                                              @"url":dataTask.originalRequest.URL,
                                                                                              @"fractionCompleted":@(progress.fractionCompleted)
                                                                                              }];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDataTask *)task didCompleteWithError:(NSError *)error
{
    NSMutableDictionary*returnDict=[NSMutableDictionary dictionary];
    if(!error){
        NSURLResponse*response=task.response;
        if( ![[response MIMEType] hasSuffix:@"html"] && [temporaryData length]>10240){
            [returnDict setValue:temporaryData forKey:@"pdfData"];
            [returnDict setValue:@YES forKey:@"success"];
        }else{
            [returnDict setValue:@NO forKey:@"success"];
            if([[response MIMEType] hasSuffix:@"html"]){
                NSString*s=[[NSString alloc] initWithData:temporaryData encoding:NSUTF8StringEncoding];
                NSArray*a=[s componentsSeparatedByString:@"http-equiv=\"refresh\" content=\""];
                if([a count]>1){
                    s=a[1];
                    a=[s componentsSeparatedByString:@"\""];
                    if([a count]>0){
                        s=a[0];
                        NSNumber*num=@([s intValue]);
                        [returnDict setValue:num forKey:@"shouldReloadAfter"];
                    }
                }
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"pdfDownloadFinished" object:@{
                                                                                                   @"url":task.originalRequest.URL,
                                                                                                   @"fractionCompleted":@(progress.fractionCompleted)
                                                                                                   }];
        [delegate pdfDownloadDidEnd:returnDict];
    }else{
        [returnDict setValue:@NO forKey:@"success"];
        [returnDict setValue:error forKey:@"error"];
        
        [delegate pdfDownloadDidEnd:returnDict];
#if !TARGET_OS_IPHONE
        if(!canceled){
        NSAlert*alert=[[NSAlert alloc] init];
        alert.messageText=@"Connection Error to arXiv";
        [alert addButtonWithTitle:@"OK"
         ];
        alert.informativeText=[NSString stringWithFormat:@"%@",[error localizedDescription]];
        [alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
                      completionHandler:nil
         ];
        }
#endif
    }
}

@end

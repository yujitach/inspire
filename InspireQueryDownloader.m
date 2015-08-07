//
//  InspireQueryDonwloader.m
//  inspire
//
//  Created by Yuji on 2015/08/07.
//
//

#import "InspireQueryDownloader.h"
#import "Article.h"
#import "MOC.h"
#import "NSString+magic.h"
#import "AppDelegate.h"
#import "JSONArticle.h"

@implementation InspireQueryDownloader
{
    WhenDoneClosure whenDone;
    NSMutableData*temporaryData;
    NSURLConnection*connection;
    NSURLRequest*urlRequest;
    NSUInteger startIndex;
}
-(NSURL*)inspireURLForQuery:(NSString*)search
{
    return [NSURL URLWithString:[[NSString stringWithFormat:@"http://inspirehep.net/search?of=recjson&%@",search ] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding ] ];
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
        }else if(article.spiresKey && [article.spiresKey integerValue]!=0){
            NSString*query=[NSString stringWithFormat:@"find key %@&rg=1&ot=recid",article.spiresKey];
            NSURL*url=[self inspireURLForQuery:query];
            NSData*data=[[NSData alloc]initWithContentsOfURL:url];
            NSArray*a=(NSArray*)[NSJSONSerialization  JSONObjectWithData:data options:0 error:NULL];
            NSLog(@"%@",a);
            if([a count]>0){
                NSDictionary*e=a[0];
                NSNumber*n=@([[e[@"recid"] stringValue] integerValue]);
                article.inspireKey=n;
                rec=[NSString stringWithFormat:@"recid:%@",n];
            }
        }else{
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
    NSString*str=[NSString stringWithFormat:@"%@&jrec=%d&rg=%d&ot=%@",inspireQuery,(int)startIndex+1,MAXPERQUERY,[JSONArticle requiredFields]];
    return [self inspireURLForQuery:str];
}

-(instancetype)initWithQuery:(NSString*)search startAt:(NSUInteger)start whenDone:(WhenDoneClosure)wd
{
    self=[super init];
    startIndex=start;
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
//    searchString=search;
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
#pragma mark URL connection delegates
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [temporaryData appendData:data];
}


-(void)connectionDidFinishLoading:(NSURLConnection*)c
{
    [[NSApp appDelegate] postMessage:nil];
    [[NSApp appDelegate] stopProgressIndicator];
    
    NSError*error;
    NSArray*a=nil;
    if([temporaryData length]){
        a=[NSJSONSerialization JSONObjectWithData:temporaryData options:0 error:&error];
        if(!a){
            NSLog(@"json problem:%@",error);
            NSString*text=[NSString stringWithFormat:@"Please report it and help develop this app.\n"
                           @"Clicking Yes will open up an email.\n"
                           ];
            NSAlert*alert=[NSAlert alertWithMessageText:@"Inspire returned malformed JSON"
                                          defaultButton:@"Yes"
                                        alternateButton:@"No thanks"
                                            otherButton:nil informativeTextWithFormat:@"%@",text];
            //[alert setAlertStyle:NSCriticalAlertStyle];
            [alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
                              modalDelegate:self
                             didEndSelector:@selector(xmlAlertDidEnd:returnCode:contextInfo:)
                                contextInfo:nil];
        }
    }
    whenDone(a);
    temporaryData=nil;
    connection=nil;
    
}

- (void) xmlAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void*)ignored
{
    if(returnCode==NSAlertDefaultReturn){
        NSString*urlString=[[urlRequest URL]  absoluteString];
        NSString* version=[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
        [[NSWorkspace sharedWorkspace]
         openURL:[NSURL URLWithString:
                  [[NSString stringWithFormat:
                    @"mailto:yuji.tachikawa@ipmu.jp?subject=spires.app Bugs/Suggestions for v.%@&body=Following Inspire query returned an JSON error:\r\n%@\r\n%@",
                    version,urlString,[[NSString alloc] initWithData:temporaryData encoding:NSUTF8StringEncoding]]
                   stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
        
    }
}


-(void)connection:(NSURLConnection*)c didFailWithError:(NSError*)error
{
    whenDone(nil);
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

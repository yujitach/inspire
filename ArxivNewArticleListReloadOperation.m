//
//  ArxivNewArticleListReloadOperation.m
//  spires
//
//  Created by Yuji on 8/26/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArxivNewArticleListReloadOperation.h"
#import "ArxivNewArticleList.h"
#import "MOC.h"
#import "ArxivHelper.h"
#import "Article.h"
#import "ArticleData.h"
#import "AllArticleList.h"
#import "AppDelegate.h"
#import "NSString+magic.h"



@implementation ArxivNewArticleListReloadOperation
{
    NSManagedObjectID* alID;
    NSManagedObjectContext*secondMOC;
    NSString* listName;
}


-(NSOperation*)initWithArxivNewArticleList:(ArxivNewArticleList*)a;
{
    self=[super init];
    alID=a.objectID;
    listName=a.name;
    secondMOC=[[MOC sharedMOCManager] createSecondaryMOC];
    return self;
}
-(NSString*)description
{
    return [@"reloading " stringByAppendingString:listName];
}
-(void)registerAuthorsInString:(NSString*)tmp toArticle:(Article*)ar
{
    NSArray*authors=[tmp componentsSeparatedByString:@"\">"];
    NSMutableArray* array=[NSMutableArray array];
    if([authors count]>1){
	for(NSUInteger i=1;i<[authors count];i++){
	    NSString*s=authors[i];
	    s=[s componentsSeparatedByString:@"</a>"][0];
	    s=[s stringByReplacingOccurrencesOfString:@"." withString:@". "];
	    NSArray*x=[s componentsSeparatedByString:@" "];
	    NSString*lastName=[x lastObject];
	    if([lastName isEqualToString:@""] && [x count]>=3){
		// Names like "A. Bates, Jr." comes here
		NSString*n1=x[[x count]-3];
		NSString*n2=x[[x count]-2];
		lastName=[NSString stringWithFormat:@"%@ %@",n1,n2];
		x=[x subarrayWithRange:NSMakeRange(0,[x count]-2)];
	    }
	    if([x count]>=2){
		NSArray*particles=[[NSUserDefaults standardUserDefaults] objectForKey:@"particles"];
		NSString*pen=x[[x count]-2];
		if([x count]>=2 && [particles containsObject:[pen lowercaseString]] ){
		    lastName=[NSString stringWithFormat:@"%@ %@",pen,lastName];
		    x=[x subarrayWithRange:NSMakeRange(0,[x count]-1)];
		}
	    }
	    NSMutableArray*b=[NSMutableArray array];
	    for(NSUInteger j=0;j<[x count]-1;j++){
		NSString*t=x[j];
		if(![t isEqualToString:@""]){
		    [b addObject:t];
		}
	    }
	    s=[NSString stringWithFormat:@"%@, %@",lastName, [b componentsJoinedByString:@" "]];
	    [array addObject:s];
	}
	[ar setAuthorNames:array];
    }
}
-(NSString*)eprintFromChunk:(NSString*)s
{
    NSRange r=[s rangeOfRegex:@"arXiv:\\d\\d\\d\\d"];
    if(r.location==NSNotFound)
	return nil;
    NSString*eprint=[s substringFromIndex:r.location];
    {
	NSArray*x=[eprint componentsSeparatedByString:@"</a>"];
	eprint=x[0];
	if([eprint rangeOfString:@"/"].location!=NSNotFound){
	    eprint=[eprint substringFromIndex:[(NSString*)@"arXiv:" length]];
	}
        eprint=[eprint stringByReplacingOccurrencesOfRegex:@"[ \n]+" withString:@""];
    }
    return eprint;
}
-(Article*)dealWithChunk:(NSString*)s writeToArticle:(Article*)ar
{
    //    NSLog(@"%@",s);
    NSString*eprint=[self eprintFromChunk:s];
    
    NSArray*b=[s componentsSeparatedByString:@"<div class="];
    if([b count]<4)
	return nil;
    NSMutableArray*a=[NSMutableArray array];
    for(NSString*c in b){
        NSString*d=c;
        NSInteger i=[c rangeOfString:@"</span>"].location;
        if(i!=NSNotFound){
            d=[c substringFromIndex:i+[@"</span>" length]];
        }
        [a addObject:d];
    }
    /*
     a[0], a[1] :junk
     a[2]: title
     a[3]: authors
     a[4]: comments or abstract
     a[5]: abstract if there're comments
     */
    NSString*title=a[2];
    NSInteger i=[title rangeOfString:@"</div>"].location;
    title=[title substringToIndex:i];
    title=[title stringByExpandingAmpersandEscapes];
    title=[title stringByReplacingOccurrencesOfRegex:@"\n" withString:@""];
    title=[title stringByReplacingOccurrencesOfRegex:@" +$" withString:@""];
    title=[title stringByReplacingOccurrencesOfRegex:@"^ +" withString:@""];
    //    NSLog(@"%@",title);
    NSString*authorsList=a[3];
    i=[authorsList rangeOfString:@"</div>"].location;
    authorsList=[authorsList substringToIndex:i];
    authorsList=[authorsList stringByExpandingAmpersandEscapes];
    
    NSString*comments=nil;
    if([a[3] rangeOfString:@"omments"].location!=NSNotFound){
	comments=a[4];
	i=[comments rangeOfString:@"</div>"].location;
	comments=[comments substringToIndex:i];
	comments=[comments stringByExpandingAmpersandEscapes];
    }
    //    NSLog(@"%@",authorsList);
    NSString*abstract=[a lastObject];
    abstract=[abstract stringByReplacingOccurrencesOfRegex:@"<p class=.mathjax.>" withString:@"<p>"];
    if([abstract rangeOfString:@"<p>"].location!=NSNotFound){
	abstract=[abstract componentsSeparatedByString:@"<p>"][1];
	abstract=[abstract componentsSeparatedByString:@"</p>"][0];
	//	abstract=[abstract stringByExpandingAmpersandEscapes];
	// abstract is fed to the html view anyway, so there's no need to expand &...; escapes here.
    }else{
	abstract=nil;
    }
    abstract=[abstract stringByReplacingOccurrencesOfRegex:@"^[ \n]+" withString:@""];
    abstract=[abstract stringByReplacingOccurrencesOfRegex:@"[ \n]+$" withString:@""];
    NSString*subj=[s stringByMatching:@"primary-subject\">(.+?)</span>" capture:1];
    subj=[subj stringByMatching:@"\\((.+?)\\)" capture:1];
    ar.eprint=eprint;
    ar.abstract=abstract;
    ar.version=@1;
    ar.title=title;
    ar.comments=comments;
    ar.arxivCategory=subj;
    ArticleFlag af=ar.flag;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"shouldPutUnreadMarksForArxivNew"]){
	af|=AFIsUnread;
    }
    [ar setFlag:af];
    [self registerAuthorsInString:authorsList toArticle:ar];
    return ar;
}

-(void)main
{
    dispatch_async(dispatch_get_main_queue(),^{
	[[NSApp appDelegate] postMessage:[NSString stringWithFormat:@"Reloading %@",listName]];
    });
    NSString*s=[[ArxivHelper sharedHelper] list:listName];

    NSMutableArray*a=[[s componentsSeparatedByString:@"<dt>"] mutableCopy];
    NSMutableDictionary*dict=[NSMutableDictionary dictionary];
    for(NSString*chunk in a){
	NSString*eprint=[self eprintFromChunk:chunk];
	if(eprint){
	    dict[eprint] = chunk;
	}
    }
    if([[dict allKeys] count]==0){
	dispatch_async(dispatch_get_main_queue(),^{
            [[NSApp appDelegate] postMessage:nil];
#if !TARGET_OS_IPHONE
            NSAlert*alert=[[NSAlert alloc] init];
            alert.messageText=@"No new articles today.";
            [alert addButtonWithTitle:@"OK"];
            alert.informativeText=@"It might also be due to an internet problem.";
	    [alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
             completionHandler:nil];
#endif
	});
	return;
    }
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"ArticleData" inManagedObjectContext:secondMOC];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:entity];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"eprint IN %@",[dict allKeys]];
    [req setPredicate:pred];
    [req setIncludesPropertyValues:NO];
    [secondMOC performBlockAndWait:^{
        NSMutableSet*generated=[NSMutableSet set];
        NSArray*datas=[secondMOC executeFetchRequest:req error:nil];
	for(ArticleData*data in datas){
	    NSString*v=[data valueForKey:@"eprint"];
	    NSString*chunk=dict[v];
	    [self dealWithChunk:chunk writeToArticle:data.article];
	    [generated addObject:data.article];
	    [dict removeObjectForKey:v];
    	}
	NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:secondMOC];
	for(NSString*chunk in [dict allValues]){
	    Article*article=(Article*)[[NSManagedObject alloc] initWithEntity:articleEntity insertIntoManagedObjectContext:secondMOC];
	    [self dealWithChunk:chunk writeToArticle:article];
	    [generated addObject:article];
	}
	
        [[AllArticleList allArticleListInMOC:secondMOC] addArticles:generated];
        ArticleList*al=(ArticleList*)[secondMOC objectWithID:alID];
        al.articles=generated;
        [secondMOC save:NULL];
	
    }];
    dispatch_async(dispatch_get_main_queue(),^{
        [[NSApp appDelegate] postMessage:nil];
    });
}
@end

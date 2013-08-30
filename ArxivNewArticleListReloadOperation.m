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
-(NSOperation*)initWithArxivNewArticleList:(ArxivNewArticleList*)a;
{
    self=[super init];
    al=a;
    listName=al.name;
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
	    if([lastName isEqualTo:@""] && [x count]>=3){
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
    NSRange r=[s rangeOfString:@"arXiv:"];
    if(r.location==NSNotFound)
	return nil;
    NSString*eprint=[s substringFromIndex:r.location];
    {
	NSArray*x=[eprint componentsSeparatedByString:@"</a>"];
	eprint=x[0];
	if([eprint rangeOfString:@"/"].location!=NSNotFound){
	    eprint=[eprint substringFromIndex:[(NSString*)@"arXiv:" length]];
	}
    }
    return eprint;
}
-(Article*)dealWithChunk:(NSString*)s writeToArticle:(Article*)ar
{
    //    NSLog(@"%@",s);
    NSString*eprint=[self eprintFromChunk:s];
    
    NSArray*a=[s componentsSeparatedByString:@"</span>"];
    if([a count]<4)
	return nil;
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
    if([abstract rangeOfString:@"<p>"].location!=NSNotFound){
	abstract=[abstract componentsSeparatedByString:@"<p>"][1];
	abstract=[abstract componentsSeparatedByString:@"</p>"][0];
	//	abstract=[abstract stringByExpandingAmpersandEscapes];
	// abstract is fed to the html view anyway, so there's no need to expand &...; escapes here.
    }else{
	abstract=nil;
    }
    
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
	[[NSApp appDelegate] startProgressIndicator];
	[[NSApp appDelegate] postMessage:[NSString stringWithFormat:@"reloading %@",listName]];
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
	    [[NSApp appDelegate] stopProgressIndicator];
	    NSAlert*alert=[NSAlert alertWithMessageText:@"Cannot reach arXiv." 
					  defaultButton:@"OK"
					alternateButton:nil
					    otherButton:nil
			      informativeTextWithFormat:@"Not connected to the internet, or arXiv is down."];
	    [alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
			      modalDelegate:nil 
			     didEndSelector:nil
				contextInfo:nil];
	});
	return;
    }
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"ArticleData" inManagedObjectContext:secondMOC];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:entity];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"eprint IN %@",[dict allKeys]];
    [req setPredicate:pred];
    [req setIncludesPropertyValues:NO];
    [req setResultType:NSManagedObjectIDResultType];
    NSArray*datas=[secondMOC executeFetchRequest:req error:nil];
    dispatch_async(dispatch_get_main_queue(),^{
	[[MOC moc] disableUndo];

	
	NSMutableSet*generated=[NSMutableSet set];
	for(NSManagedObjectID*objID in datas){
	    ArticleData* data=(ArticleData*)[[MOC moc] objectWithID:objID];
	    if(!data.article){
		NSLog(@"inconsistency! stray ArticleData found and removed: %@",data);
		[[MOC moc] deleteObject:data];
		continue;
	    }
	    NSString*v=[data valueForKey:@"eprint"];
	    NSString*chunk=dict[v];
	    [self dealWithChunk:chunk writeToArticle:data.article];
	    [generated addObject:data.article];
	    [dict removeObjectForKey:v];
    	}
	NSEntityDescription*articleEntity=[NSEntityDescription entityForName:@"Article" inManagedObjectContext:[MOC moc]];
	for(NSString*chunk in [dict allValues]){
	    Article*article=(Article*)[[NSManagedObject alloc] initWithEntity:articleEntity insertIntoManagedObjectContext:[MOC moc]];
	    [self dealWithChunk:chunk writeToArticle:article];
	    [generated addObject:article];
	}
	
	[[AllArticleList allArticleList] addArticles:generated];
	
	al.articles=generated;
	
	NSError*error=nil;
	BOOL success=[[MOC moc] save:&error];
	if(!success){
	    [[MOC sharedMOCManager] presentMOCSaveError:error];
	}
	[[MOC moc] enableUndo];
	[[NSApp appDelegate] clearingUpAfterRegistration:self];        
	
    });
    dispatch_async(dispatch_get_main_queue(),^{
        [[NSApp appDelegate] postMessage:nil];
	[[NSApp appDelegate] stopProgressIndicator];
    });
}
@end

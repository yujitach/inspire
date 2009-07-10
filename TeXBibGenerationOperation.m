//
//  TeXBibGenerationOperation.m
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "TeXBibGenerationOperation.h"
#import "Article.h"
#import "SimpleArticleList.h"
#import "SideTableViewController.h"
#import "RegexKitLite.h"
#import "SpiresHelper.h"
#import "SpiresQueryOperation.h"
#import "ProgressIndicatorController.h"
#import "BatchBibQueryOperation.h"
#import "WaitOperation.h"
#import "NSString+magic.h"
#import "TeXWatcherController.h"

static NSMutableArray*instances;
@implementation TeXBibGenerationOperation
+(NSDictionary*)infoForTeXFile:(NSString*)texFile;
{
    NSString*script=[[NSBundle mainBundle] pathForResource:@"parseTeXandEmitPlist" ofType:@"perl"];
    NSString*outPath=[NSString stringWithFormat:@"/tmp/spiresoutput-%d.plist",getuid()];
    NSString*line=[NSString stringWithFormat:@"/usr/bin/perl %@ <%@ >%@",
		   [script quotedForShell],
		   [texFile quotedForShell],
		   outPath];
    system([line UTF8String]);
    NSDictionary* dict=[NSPropertyListSerialization propertyListFromData:[NSData dataWithContentsOfFile:outPath]
							mutabilityOption:NSPropertyListImmutable
								  format:NULL
							errorDescription:NULL];
    return dict;
}
-(TeXBibGenerationOperation*)initWithTeXFile:(NSString*)t andMOC:(NSManagedObjectContext*)m byLookingUpWeb:(BOOL)b;
{
    [super init];
    texFile=t;
    moc=m;
    twice=b;
    if(!instances){
	instances=[NSMutableArray array];
    }
    NSMutableArray*tbr=[NSMutableArray array];
    for(NSOperation*op in instances){
	if([op isFinished]){
	    [tbr addObject:op];
	}else{
	    [self addDependency:op];
	}
    }
    for(NSOperation*o in tbr){
	[instances removeObject:o];
    }
    [instances addObject:self];
    return self;
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"tex bib generation:%@",texFile];
}
/*-(void)addDependency:(NSOperation*)op
{
    [super addDependency:op];
    NSLog(@"dependency added:%@",op);
}*/
-(void)generateLookUps:(NSArray*)array
{
    
    if(!twice){
	return;
    }
    NSMutableString*log=[NSMutableString string];
    NSMutableArray*ops=[NSMutableArray array];
    for(NSString*idToLookUp in array){
	[log appendFormat:@"%@ ",idToLookUp];
	NSString*query=nil;
	if([idToLookUp hasPrefix:@"arXiv:"]){
	    idToLookUp=[idToLookUp substringFromIndex:[(NSString*)@"arXiv:" length]];
	    query=[NSString stringWithFormat:@"eprint %@",idToLookUp];
	}else if([idToLookUp rangeOfString:@"."].location!=NSNotFound){
	    query=[NSString stringWithFormat:@"eprint %@",idToLookUp];	
	}else if([idToLookUp rangeOfString:@"/"].location!=NSNotFound){
	    query=[NSString stringWithFormat:@"eprint %@",idToLookUp];	
	}else if([idToLookUp rangeOfString:@":"].location!=NSNotFound){
	    query=[NSString stringWithFormat:@"texkey %@",idToLookUp];
	}else{
	    query=@"eprint 0808.0808"; // shouldn't happen
	}
	NSOperation*op=[[SpiresQueryOperation alloc] initWithQuery:query 
							    andMOC:moc];
	[ops addObject:op];
	[[OperationQueues spiresQueue] addOperation:op];
	[[OperationQueues spiresQueue] addOperation:[[WaitOperation alloc] initWithTimeInterval:1]];
    }
    [log appendString:@" not found in local database. Looking up...\n"];
    [[TeXWatcherController sharedController]addToLog:log];
    NSOperation*op=[[TeXBibGenerationOperation alloc] initWithTeXFile:texFile 
							       andMOC:moc
						       byLookingUpWeb:NO];
    for(SpiresQueryOperation*o in ops){
	[o setParent:op];
    }
    [[OperationQueues spiresQueue] addOperation:op];
    
}
-(NSArray*)entriesAlreadyInBib:(NSString*)bibFile
{
    NSString*org=[NSString stringWithContentsOfFile:bibFile encoding:NSUTF8StringEncoding error:nil];
    NSArray*lines=[org componentsSeparatedByString:@"\n"];
    NSMutableArray*entriesAlreadyInBib=[NSMutableArray array];
    for(NSString*line in lines){
	NSString*entry=[line stringByMatching:@"^ *@[A-Za-z]+\\{([^,]+)," capture:1];
	if(entry &&![entry isEqualToString:@""]){
	    [entriesAlreadyInBib addObject:entry];
	}
    }
    return entriesAlreadyInBib;
}
-(NSString*)bibFileForDict:(NSDictionary*)dict
{
    BOOL isBibTeX=[[dict valueForKey:@"isBibTeX"] boolValue];
    if(!isBibTeX)
	return nil;
    NSString*bibname=[dict valueForKey:@"BibTeXFile"];
    if(![bibname hasSuffix:@".bib"]){
	bibname=[bibname stringByAppendingString:@".bib"];
    }
    NSString*bibFile=[[texFile stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@",bibname];
    return bibFile;
}
-(void)generateBibTeXFromInfo:(NSDictionary*)dict citations:(NSArray*)citations notFoundLocally:(NSArray*)notFound
{
    NSString*bibFile=[self bibFileForDict:dict];
    NSArray*entriesAlreadyInBib=[self entriesAlreadyInBib:bibFile];
    NSMutableArray*toAdd=[NSMutableArray array];
    for(NSString*key in citations){
	if([notFound containsObject:key]){
	    continue;
	}
	if([entriesAlreadyInBib containsObject:key]){
	    continue;
	}
	Article*a=[Article intelligentlyFindArticleWithId:key inMOC:moc];
	if(!a){
	    continue;
	}else{
	    NSString* bib=nil;
	    if((bib=[a extraForKey:@"bibtex"])){
		[toAdd addObject:a];
	    }
	}
	
    }
    
    if([toAdd count]>0){
	[[TeXWatcherController sharedController] addToLog:[NSString stringWithFormat:@"adding entries to %@\n",bibFile]];
	NSMutableString*appendix=[NSMutableString string];
	for(Article*a in toAdd){
	    [[TeXWatcherController sharedController] addToLog:[[a texKey] stringByAppendingString:@", "]];
	    NSString*bib=[a extraForKey:@"bibtex"];
	    bib=[bib stringByReplacingOccurrencesOfString:[a texKey] withString:@"*#*#*#"];
	    bib=[bib magicTeXed];
	    bib=[bib stringByReplacingOccurrencesOfString:@"*#*#*#" withString:[a texKey]];	    
	    [appendix appendString:bib];
	    [appendix appendString:@"\n\n"];	    
	}
	NSString*org=[NSString stringWithContentsOfFile:bibFile encoding:NSUTF8StringEncoding error:nil];
	if(!org){
	    org=@"";
	}    
	NSString*result=[NSString stringWithFormat:@"%@\n\n%@",org,appendix];
	[result writeToFile:bibFile atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	[[TeXWatcherController sharedController] addToLog:@"Done.\n"];
    }else{
	[[TeXWatcherController sharedController] addToLog:@"Nothing to add.\n"];	
    }

}
-(void)generateReferencesTeXFromInfo:(NSDictionary*)dict citations:(NSArray*)citations notFoundLocally:(NSArray*)notFound
{
    NSDictionary* definitions=[dict objectForKey:@"definitions"];
    NSDictionary* mappings=[dict objectForKey:@"mappings"];

    NSString* output=[dict objectForKey:@"outputFile"];
    if(!output || [output isEqualToString:@""]){
	//	    output=@"bibliography.tex";
	[self finish];
	return;
    }
    if(![output hasSuffix:@".tex"]){
	output=[output stringByAppendingString:@".tex"];
    }
    NSString* outputPath=[[texFile stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@",output];
    NSLog(@"outputPath:%@",outputPath);
    NSMutableString* result=[NSMutableString stringWithString:@"%This file is autogenerated. Do not edit.\n\n"];
    //    NSMutableArray* found=[NSMutableArray array];
    for(NSString*key in citations){
	[result appendFormat:@"\\bibitem{%@}\n",key];
	NSString*def=[definitions objectForKey:key];
	if(def){
	    [result appendFormat:@"%@\n",def];
	    continue;
	}
	NSString*idToLookUp=key;
	NSString*head=key;
	NSString*map=[mappings objectForKey:key];
	if(map){
	    idToLookUp=map;
	    head=[head stringByAppendingFormat:@" = %@",idToLookUp];
	}
	NSString*notFoundString=[NSString stringWithFormat:@" %@ not yet found in database -- will be updated in a minuite\n",head];
	Article*a=[Article intelligentlyFindArticleWithId:idToLookUp inMOC:moc];
	if(!a){
	    [result appendString:notFoundString];
	}else{
	    NSString* bib=nil;
	    if((bib=[a extraForKey:@"latex"])){
		bib=[bib stringByReplacingOccurrencesOfRegex:@"%\\\\cite.+?\n" withString:@""];
		bib=[bib stringByReplacingOccurrencesOfRegex:@"\\\\bibitem.+?\n" withString:@""];
		[result appendString:[bib magicTeXed]];
	    }else{
		[result appendString:notFoundString];
	    }
	}
    }
    
    NSString*s=result;//[result magicTeXed];
    NSString*articleTitle=[dict objectForKey:@"articleTitle"];
    if([articleTitle isEqualToString:@"none"]){
	s=[s stringByReplacingOccurrencesOfRegex:@"``(.+?)''" withString:@"\\\\relax "];
    }else if([articleTitle isEqualToString:@"italic"]){
	s=[s stringByReplacingOccurrencesOfRegex:@"``(.+?)''" withString:@"{\\\\itshape $1}"];
    }
    
    [s writeToFile:outputPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
    [[TeXWatcherController sharedController]addToLog:[NSString stringWithFormat:@"%@ generated\n",outputPath]];
}
-(NSArray*)fullCitationsForFile:(NSString*)file andInfo:(NSDictionary*)dict
{
    NSArray*inputs=[dict objectForKey:@"inputs"];
    if([inputs count]==0){
	return [dict objectForKey:@"citationsInOrder"];
    }
    NSMutableArray*citations=[[dict objectForKey:@"citationsInOrder"] mutableCopy];
    for(NSString*subfile in inputs){
	if(![subfile hasSuffix:@".tex"]){
	    subfile=[subfile stringByAppendingString:@".tex"];
	}
	NSString*fullPath=[[file stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@",subfile];
	NSDictionary*subDict=[TeXBibGenerationOperation infoForTeXFile:fullPath];
	NSArray*subCitations=[self fullCitationsForFile:fullPath andInfo:subDict];
	if(subCitations){
	    for(NSString*key in subCitations){
		if(![citations containsObject:key]){
		    [citations addObject:key];
		}
	    }
	}
    }
    return citations;
}
-(void)start
{
    self.isExecuting=YES;
    NSDictionary*dict=[TeXBibGenerationOperation infoForTeXFile:texFile];
    NSArray* citations=[self fullCitationsForFile:texFile andInfo:dict];
    NSDictionary* mappings=[dict objectForKey:@"mappings"];
    NSString* listName=[dict objectForKey:@"listName"];
    BOOL isBibTeX=[[dict objectForKey:@"isBibTeX"] boolValue];
    NSArray*entriesAlreadyInBib=nil;
    if(isBibTeX){
	entriesAlreadyInBib=[self entriesAlreadyInBib:[self bibFileForDict:dict]];
    }
    SimpleArticleList*list=nil;
    if(listName&&![listName isEqualToString:@""]){
	list=[SimpleArticleList simpleArticleListWithName:listName inMOC:moc];
	if(list){
	    [[[NSApplication sharedApplication]delegate] rearrangePositionInViewForArticleLists];
	}
    }
    BOOL forceRefresh=twice&&[[dict objectForKey:@"forceRefresh"] boolValue];
    if(forceRefresh){
	NSLog(@"forcing refresh of bibliography data");
    }

    NSMutableArray* notFound=[NSMutableArray array];
    for(NSString*key in citations){
	NSString*idToLookUp=key;
	NSString*map=[mappings objectForKey:key];
	if(map){
	    idToLookUp=map;
	}	
	Article*a=[Article intelligentlyFindArticleWithId:idToLookUp inMOC:moc];
	if(list && a){
	    [list addArticlesObject:a];
	}
	if(isBibTeX && [entriesAlreadyInBib containsObject:key] && !forceRefresh){
	    continue;
	}
	if(!a){
	    [notFound addObject:idToLookUp];
	}else{
	    NSString*latex=[a extraForKey:@"latex"];
	    if(latex){
		if(forceRefresh){
		    [notFound addObject:idToLookUp];		
		}
	    }else{
		[notFound addObject:idToLookUp];
	    }
	}
    }
    if([notFound count]>0){
	[self generateLookUps:notFound];
    }
    
    if(isBibTeX){
	[self generateBibTeXFromInfo:dict citations:citations notFoundLocally:notFound];
    }else{
	[self generateReferencesTeXFromInfo:dict citations:citations notFoundLocally:notFound];
    }
    [self finish];
}

@end

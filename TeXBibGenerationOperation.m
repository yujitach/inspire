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
#import "SpiresHelper.h"
#import "SpiresQueryOperation.h"
#import "BatchBibQueryOperation.h"
#import "BatchImportOperation.h"
#import "NSString+magic.h"
#import "AppDelegate.h"

static NSArray*fullCitationsForFileAndInfo(NSString*file,NSDictionary*dict)
{
    NSArray*inputs=dict[@"inputs"];
    if([inputs count]==0){
	return dict[@"citationsInOrder"];
    }
    NSMutableArray*citations=[dict[@"citationsInOrder"] mutableCopy];
    for(__strong NSString*subfile in inputs){
	if([subfile rangeOfString:@"."].location==NSNotFound){
	    subfile=[subfile stringByAppendingString:@".tex"];
	}
	NSString*fullPath=[[file stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@",subfile];
        if(![[NSFileManager defaultManager] fileExistsAtPath:fullPath]){
            continue;
        }
	NSDictionary*subDict=[TeXBibGenerationOperation infoForTeXFile:fullPath];
	NSArray*subCitations=fullCitationsForFileAndInfo(fullPath,subDict);
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


@implementation TeXBibGenerationOperation
+(NSDictionary*)infoForTeXFile:(NSString*)texFile
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
    self=[super init];
    texFile=t;
    moc=m;
    twice=b;
    return self;
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"tex bib generation:%@",texFile];
}


-(NSArray*)bibFilePaths
{
    NSString*bibnames=[dict valueForKey:@"BibTeXFile"];
    NSMutableArray*array=[NSMutableArray array];
    NSString*bibname;
    for(bibname in [bibnames componentsSeparatedByString:@","]){
        if(![bibname hasSuffix:@".bib"]){
            bibname=[bibname stringByAppendingString:@".bib"];
        }
        NSString*bibFile=[[texFile stringByDeletingLastPathComponent] stringByAppendingFormat:@"/%@",bibname];
        [array addObject:bibFile];
    }
    return array;
}


-(NSString*)idForKey:(NSString*)key
{
    NSString*map=mappings[key];
    if(map){
	return map;
    }else{
	return key;
    }
}
-(BOOL)setup
{
    dict=[TeXBibGenerationOperation infoForTeXFile:texFile];
    BOOL isBibTeX=[dict[@"isBibTeX"] boolValue];
    if(!isBibTeX){
	return NO;
    }
    citations=fullCitationsForFileAndInfo(texFile,dict);
    mappings=dict[@"mappings"];
    
    
    {
        NSMutableString*org=[NSMutableString stringWithString:@""];
        {
            for(NSString*bibFilePath in [self bibFilePaths]){
                NSString*content=[NSString stringWithContentsOfFile:bibFilePath encoding:NSUTF8StringEncoding error:nil];
                if(content){
                    [org appendString:content];
                }
            }
        }
	NSArray*lines=[org componentsSeparatedByString:@"\n"];
	NSMutableArray*e=[NSMutableArray array];
	for(NSString*line in lines){
	    NSString*entry=[line stringByMatching:@"^ *@[A-Za-z]+\\{([^,]+)," capture:1];
	    if(entry &&![entry isEqualToString:@""]){
		[e addObject:entry];
	    }
	}
	entriesAlreadyInBib=e;
    }
    
    {
	keyToArticle=[NSMutableDictionary dictionary];
	for(NSString*key in citations){
	    Article*a=[Article articleWith:[self idForKey:key]
                               inDataForKey:@"texKey"
                                            inMOC:moc];
	    if(a){
		keyToArticle[key] = a;
	    }
	}
    }
    return YES;
}

-(void)addQueries:(NSArray*)queries toOps:(NSMutableArray*)ops
{
    NSString*realQuery=[queries componentsJoinedByString:@" or "];
    NSOperation*op=[[SpiresQueryOperation alloc] initWithQuery:realQuery
							andMOC:moc];
    [ops addObject:op];    
}
-(void)generateLookUps:(NSArray*)keys
{
    
    if(!twice){
	return;
    }
    NSMutableString*logString=[NSMutableString string];
    NSMutableArray*queries=[NSMutableArray array];
    for(NSString*key in keys){
	NSString*idToLookUp=[self idForKey:key];
	[logString appendFormat:@"%@ ",idToLookUp];
	NSString*query=nil;
	if([idToLookUp hasPrefix:@"arXiv:"]){
	    idToLookUp=[idToLookUp substringFromIndex:[(NSString*)@"arXiv:" length]];
	    query=[NSString stringWithFormat:@"eprint %@",idToLookUp];
	}else if([idToLookUp rangeOfString:@"."].location!=NSNotFound){
	    query=[NSString stringWithFormat:@"eprint %@",idToLookUp];	
	}else if([idToLookUp rangeOfString:@"/"].location!=NSNotFound){
	    query=[NSString stringWithFormat:@"eprint %@",idToLookUp];	
	}else if([idToLookUp rangeOfString:@":"].location!=NSNotFound){
            idToLookUp=[idToLookUp correctToInspire];
            if([idToLookUp rangeOfString:@" "].location!=NSNotFound){
                query=[NSString stringWithFormat:@"texkey \"%@\"",idToLookUp];
            }else{
                query=[NSString stringWithFormat:@"texkey %@",idToLookUp];
            }
	}else{
	    query=nil;
	}
	if(query){
	    [queries addObject:query];
	}
    }

    NSMutableArray*tmp=[NSMutableArray array];
    NSMutableArray*ops=[NSMutableArray array];
    for(NSString*query in queries){
	[tmp addObject:query];
	if([tmp count]>3){
	    [self addQueries:tmp toOps:ops];
	    [tmp removeAllObjects];
	}
    }
    if([tmp count]>0){
	[self addQueries:tmp toOps:ops];
    }    
    
    NSOperation*again=[[TeXBibGenerationOperation alloc] initWithTeXFile:texFile 
								  andMOC:moc
							  byLookingUpWeb:NO];
    for(SpiresQueryOperation*q in ops){
	[again addDependency:q];
        [q setBlockToActOnBatchImport:^(BatchImportOperation*importer){
            [again addDependency:importer];
            BatchImportOperation*weakImporter=importer;
            [importer setCompletionBlock:^{
                NSSet*generated=weakImporter.generated;
                if(!generated)return;
                NSOperation*op=[[BatchBibQueryOperation alloc] initWithArray:[generated allObjects]];
                [again addDependency:op];
                [[OperationQueues spiresQueue] addOperation:op];
            }];
        }];
	[[OperationQueues spiresQueue] addOperation:q];
    }
    [[OperationQueues sharedQueue] addOperation:again];
    [logString appendString:@" not found in local database. Looking up...\n"];
    [[NSApp appDelegate] addToTeXLog:logString];
}

-(void)lookUpThingsNotFoundInDatabase
{
    BOOL forceRefresh=twice&&[dict[@"forceRefresh"] boolValue];
    if(forceRefresh){
	NSLog(@"forcing refresh of bibliography data");
    }
    NSMutableArray* notFound=[NSMutableArray array];
    for(NSString*key in citations){
	NSString*idForKey=[self idForKey:key];
	Article*a=keyToArticle[key];
	if(a){
	    NSString*latex=[a extraForKey:@"latex"];
	    if(!latex || forceRefresh){
		[notFound addObject:idForKey];		
	    }
	}else{
	    if( [idForKey rangeOfString:@":"].location!=NSNotFound){
		    [notFound addObject:idForKey];  
	    }
	}
    }
    if([notFound count]>0){
	[self generateLookUps:notFound];
    }    
}
-(void)registerEntriesToList
{
    SimpleArticleList*list=nil;
    NSString* listName=dict[@"listName"];
    NSArray*toAddToList=[keyToArticle allValues];
    if(listName&&![listName isEqualToString:@""]&&[toAddToList count]>0){
	list=[SimpleArticleList simpleArticleListWithName:listName inMOC:moc];
	if(!list){
	    [[NSApp appDelegate] addSimpleArticleListWithName:listName];
	    list=[SimpleArticleList simpleArticleListWithName:listName inMOC:moc];
	}
	[list addArticles:[NSSet setWithArray:toAddToList]];
    }
}

-(void)reallyGenerateBibFile
{
    NSMutableArray*toAddToBib=[NSMutableArray array];
    for(NSString*key in citations){
	if([entriesAlreadyInBib containsObject:key]){
	    continue;
	}
	Article*a=keyToArticle[key];
	if(a){
	    NSString* bib=[a extraForKey:@"bibtex"];
	    if(bib){
		[toAddToBib addObject:key];
	    }
	}
	
    }
    
    NSString*bibFilePath=[self bibFilePaths][0];
    
    if([toAddToBib count]>0){
	[[NSApp appDelegate] addToTeXLog:[NSString stringWithFormat:@"adding entries to %@\n",[bibFilePath lastPathComponent]]];
	NSMutableString*appendix=[NSMutableString string];
	for(NSString* key in toAddToBib){
	    Article*a=keyToArticle[key];
	    NSString*kk=key;
	    if(![key isEqualToString:[a texKey]]){
		kk=[key stringByAppendingFormat:@"(=%@)",[a texKey]];
	    }
	    [[NSApp appDelegate] addToTeXLog:[kk stringByAppendingString:@", "]];
	    NSString*bib=[a extraForKey:@"bibtex"];
	    bib=[bib stringByReplacingOccurrencesOfString:[a texKey] withString:@"*#*#*#"];
	    bib=[bib magicTeXed];
	    bib=[bib stringByReplacingOccurrencesOfString:@"*#*#*#" withString:[key inspireToCorrect]];
	    [appendix appendString:bib];
	    [appendix appendString:@"\n\n"];	    
	}
	NSString*org=[NSString stringWithContentsOfFile:bibFilePath encoding:NSUTF8StringEncoding error:nil];
	if(!org){
	    org=@"";
	}    
	NSString*result=[NSString stringWithFormat:@"%@\n\n%@",org,appendix];
	[result writeToFile:bibFilePath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
	[[NSApp appDelegate] addToTeXLog:@"Done.\n"];
    }else{
	[[NSApp appDelegate] addToTeXLog:@"Nothing to add.\n"];	
    }
    
}
-(void)run
{
    self.isExecuting=YES;
    
    if(![self setup]){
	// non bibtex biblio generation is no longer supported!
	NSLog(@"no \\bibliography found in %@",texFile);
	[self finish];
	return;	
    }

    [self lookUpThingsNotFoundInDatabase];
    [self registerEntriesToList];
    [self reallyGenerateBibFile];    
    [self finish];
}

@end

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
{
    NSString*texFile;
    NSManagedObjectContext*moc;
    BOOL twice;
    BOOL all;
    NSDictionary*dict;
    NSArray*citations;
    NSDictionary*mappings;
    NSMutableDictionary* keyToArticle;
    NSArray*entriesAlreadyInBib;
}
+(NSDictionary*)infoForTeXFile:(NSString*)texFile
{
    NSString*script=[[NSBundle mainBundle] pathForResource:@"parseTeXandEmitPlist" ofType:@"perl"];
    NSString*outPath=[NSString stringWithFormat:@"/tmp/spiresoutput-%d.plist",getuid()];
    NSString*line=[NSString stringWithFormat:@"/usr/bin/perl %@ <%@ >%@",
		   [script quotedForShell],
		   [texFile quotedForShell],
		   outPath];
    system([line UTF8String]);
    NSDictionary* dict=
    [NSPropertyListSerialization    propertyListWithData:[NSData dataWithContentsOfFile:outPath]
                                                 options:NSPropertyListImmutable
                                                  format:nil
                                                   error:nil];
    return dict;
}
-(TeXBibGenerationOperation*)initWithTeXFile:(NSString*)t andMOC:(NSManagedObjectContext*)m byLookingUpWeb:(BOOL)b andRefreshingAll:(BOOL)a;
{
    self=[super init];
    texFile=t;
    moc=m;
    twice=b;
    all=a;
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
        NSArray*entries=[org componentsMatchedByRegex:@"(@[^@]+)"];
        NSMutableArray*e=[NSMutableArray array];
        for(NSString*entry in entries){
            NSString*key=[entry stringByMatching:@"^ *@[A-Za-z ]+\\{([^,]+)," capture:1];
            if(key &&![key isEqualToString:@""]){
                [e addObject:key];
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
-(NSString*)generateLookUps:(NSArray*)keys
{
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
							  byLookingUpWeb:NO
                                                        andRefreshingAll:all];
    for(SpiresQueryOperation*q in ops){
	[again addDependency:q];
        [q setBlockToActOnBatchImport:^(BatchImportOperation*importer){
            [again addDependency:importer];
            __weak BatchImportOperation*weakImporter=importer;
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
    return logString;
}

-(void)lookUpThingsNotFoundInDatabase
{
    NSMutableArray* notFound=[NSMutableArray array];
    for(NSString*key in citations){
	NSString*idForKey=[self idForKey:key];
        if(!all){
            Article*a=keyToArticle[key];
            if(a){
                NSString*latex=[a extraForKey:@"latex"];
                if(!latex){
                    [notFound addObject:idForKey];
                }
            }else{
                if( [idForKey rangeOfString:@":"].location!=NSNotFound){
                    [notFound addObject:idForKey];
                }
            }
        }else{
            Article*a=keyToArticle[key];
            if(a){
                if(!a.journal){
                    [notFound addObject:idForKey];
                }
            }else{
                if( [idForKey rangeOfString:@":"].location!=NSNotFound){
                    [notFound addObject:idForKey];
                }
            }
        }
    }
    if([notFound count]>0 && twice){
        NSString*logString=[self generateLookUps:notFound];
        if(!all){
            [[NSApp appDelegate] addToTeXLog:logString];
            [[NSApp appDelegate] addToTeXLog:@" not found in local database. Looking up...\n"];
        }else{
            [[NSApp appDelegate] addToTeXLog:logString];
            [[NSApp appDelegate] addToTeXLog:@" don't have journal entries. Looking up...\n"];
        }
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

-(NSString*)bibEntryForArticle:(Article*)a{
    NSString*bib=[a extraForKey:@"bibtex"];
    if(!bib){
        return @"";
    }
    if([bib isMatchedByRegex:@"\\\\"] || [bib isMatchedByRegex:@"\\$"]){
        return [bib stringByAppendingString:@"\n\n"];
    }else{
        bib=[bib stringByReplacingOccurrencesOfString:[a texKey] withString:@"*#*#*#"];
        bib=[bib magicTeXed];
        bib=[bib stringByReplacingOccurrencesOfString:@"*#*#*#" withString:[[a texKey] inspireToCorrect]];
        return [bib stringByAppendingString:@"\n\n"];
    }
}
-(void)reallyGenerateBibFile
{
    
    NSString*bibFilePath=[self bibFilePaths][0];
    [[NSApp appDelegate] addToTeXLog:[NSString stringWithFormat:@"Updating %@:\n",[bibFilePath lastPathComponent]]];

    NSString*org=[NSString stringWithContentsOfFile:bibFilePath encoding:NSUTF8StringEncoding error:nil];
    if(!org){
        org=@"";
    }
    NSArray*bibEntries=[org componentsMatchedByRegex:@"(@[^@]+)"];
    NSMutableString*result=[NSMutableString string];
    NSMutableArray*updatedKeys=[NSMutableArray array];
    for(NSString*entry in bibEntries){
        if(!all){
            [result appendString:entry];
            continue;
        }
        if([[entry lowercaseString] containsString:@"journal"]||[[entry lowercaseString] containsString:@"booktitle"]){
            [result appendString:entry];
            continue;
        }
        if([entry containsString:@"dontUpdate"]){
            [result appendString:entry];
            continue;
        }
        NSString*key=[entry stringByMatching:@"^ *@[A-Za-z ]+\\{([^,]+)," capture:1];
        Article*a=[Article articleWith:[self idForKey:key]
                          inDataForKey:@"texKey"
                                 inMOC:moc];
        if(!a){
            [result appendString:entry];
            continue;
        }
        [updatedKeys addObject:key];
        [result appendString:[self bibEntryForArticle:a]];
    }
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

    if([updatedKeys count]>0){
        [[NSApp appDelegate] addToTeXLog:[NSString stringWithFormat:@"Updated:%@\n",[updatedKeys componentsJoinedByString:@", "]]];
    }
    if([toAddToBib count]>0){
        [[NSApp appDelegate] addToTeXLog:[NSString stringWithFormat:@"Added:%@\n",[toAddToBib componentsJoinedByString:@", "]]];
        NSMutableString*appendix=[NSMutableString string];
        for(NSString* key in toAddToBib){
            Article*a=keyToArticle[key];
            [appendix appendString:[self bibEntryForArticle:a]];
        }
        [result appendString:appendix];
    }
    
    if(![result isEqualToString:org]){
        [result writeToFile:bibFilePath atomically:YES encoding:NSUTF8StringEncoding error:NULL];
        if(all&&twice){
            [[NSApp appDelegate] addToTeXLog:@"Refreshing entries from inspire...\n"];
        }else{
            [[NSApp appDelegate] addToTeXLog:@"Done.\n"];
        }
    }else{
        [[NSApp appDelegate] addToTeXLog:@"Nothing to do.\n"];
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

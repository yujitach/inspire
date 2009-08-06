//
//  ArticleV1V2MigrationPolicy.m
//  spires
//
//  Created by Yuji on 09/02/26.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArticleV3V4MigrationPolicy.h"
#import "NSString+magic.h"
#import "RegexKitLite.h"
#import "Article.h"
#import "MOC.h"
#import "NDAlias.h"


typedef enum {
    AFNone_,
    AFUnread_,
    AFRead_,
    AFFlagged_
} ArticleFlagOld;


@implementation ArticleV3V4MigrationPolicy


-(NSString*)pdfPathForEntry:(NSManagedObject*)s
{
    NSData*d=[s valueForKey:@"pdfAlias"];
    NSString*eprint=[s valueForKey:@"eprint"];
    if(!eprint || [eprint isEqualToString:@""]){
	eprint=nil;
    }
    if(d){
	NDAlias* alias=[NDAlias aliasWithData:d];
	if(alias){
	    NSString* path=[alias path];
	    return path;
	}
    }else if(eprint){
	NSString* name=eprint;
	if([name hasPrefix:@"arXiv:"]){
	    name=[name substringFromIndex:[(NSString*)@"arXiv:" length]];
	}
	name=[name stringByReplacingOccurrencesOfString:@"/" withString:@""];
	NSString*pdfDir=[[NSUserDefaults standardUserDefaults] stringForKey:@"pdfDir"];
	return [[NSString stringWithFormat:@"%@/%@.pdf",pdfDir,name] stringByExpandingTildeInPath];
    }
    return nil;
}

-(BOOL)pdfAvailableAtPath:(NSString*)path
{
    BOOL b= [[NSFileManager defaultManager] fileExistsAtPath:path];
    return b;
}


-(ArticleFlagOld)oldFlagFromMemo:(NSString*)s
{
    if([s hasPrefix:@"unread;"]){
	return AFUnread_;
    }else if([s hasPrefix:@"0read;"]){
	return AFRead_;
    }else if([s hasPrefix:@"flagged;"]){
	return AFFlagged_;
    }
    return AFNone_;
}

-(ArticleFlag)flagFromMemo:(NSString*)s
{
    ArticleFlagOld f=[self oldFlagFromMemo:s];
    ArticleFlag result=0;
    if(f==AFUnread_){
	result|=AFIsUnread;
    }else if(f==AFFlagged_){
	result|=AFIsFlagged;
    }
    return result;
}


-(NSArray*)splitEA:(NSString*)s
{
    NSArray* a=[s componentsSeparatedByString:@"; "];
    NSMutableArray*result=[NSMutableArray array];
    for(NSString* x in a){
	if(![x isEqualToString:@""]){
	    [result addObject:x];
	}
    }
    return result;
}

- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    
    NSArray *attributeMappings = [mapping attributeMappings];
    NSSet*authorSet=[sInstance valueForKey:@"authors"];
    NSMutableArray*authorNames=[NSMutableArray array];
    for(NSManagedObject*mo in authorSet){
	NSString*name=[mo valueForKey:@"name"];
	if(name && ![name isEqualToString:@""]){
	    [authorNames addObject:[name normalizedString]];
	}
    }
//    NSString*EA=[sInstance valueForKey:@"longishAuthorListForEA"];
//    NSArray*authorNames=[self splitEA:EA];
    NSString*longishAuthorListForA=[Article longishAuthorListForAFromAuthorNames:authorNames];
    NSString*longishAuthorListForEA=[Article longishAuthorListForEAFromAuthorNames:authorNames];
    NSString*shortishAuthorList=[Article shortishAuthorListFromAuthorNames:authorNames];
    
    NSString*memo=[sInstance valueForKey:@"memo"];
    ArticleFlag flag=[self flagFromMemo:memo];
    if([self pdfAvailableAtPath:[self pdfPathForEntry:sInstance]]){
	flag|=AFHasPDF;
    }
    NSString*flagInternal=[Article flagInternalFromFlag:flag];
    
    for(NSPropertyMapping *currentMapping in attributeMappings) 
    {
	NSString*name=[currentMapping name];
	if( [name isEqualToString:@"longishAuthorListForA"] ){
	    [currentMapping setValueExpression:[NSExpression expressionForConstantValue:longishAuthorListForA ]];	    
	}else if( [name isEqualToString:@"longishAuthorListForEA"] ){
	    [currentMapping setValueExpression:[NSExpression expressionForConstantValue:longishAuthorListForEA ]];	    
	}else if( [name isEqualToString:@"shortishAuthorList"] ){
	    [currentMapping setValueExpression:[NSExpression expressionForConstantValue:shortishAuthorList ]];	    
	}else if( [name isEqualToString:@"flagInternal"] ){
	    [currentMapping setValueExpression:[NSExpression expressionForConstantValue:flagInternal ]];	    
	}	
    
    }
    return [super createDestinationInstancesForSourceInstance:sInstance entityMapping:mapping manager:manager error:error];

}
@end

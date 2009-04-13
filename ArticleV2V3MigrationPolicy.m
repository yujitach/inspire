//
//  ArticleV1V2MigrationPolicy.m
//  spires
//
//  Created by Yuji on 09/02/26.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArticleV2V3MigrationPolicy.h"
#import "NSString+magic.h"
#import "RegexKitLite.h"
#import "Article.h"
#import "MOC.h"

@implementation ArticleV2V3MigrationPolicy
/*- (BOOL)beginEntityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    [[NSFileManager defaultManager] createDirectoryAtPath:[[MOC sharedMOCManager] directoryForAbstract] 
					       attributes:nil];
    return YES;
}
-(ArticleType)articleType:(NSManagedObject*)article
{
    NSString*eprint=[article valueForKey:@"eprint"];
    NSString*spicite=[article valueForKey:@"spicite"];
    NSString*spiresKey=[article valueForKey:@"spiresKey"];
    if(eprint && ![eprint isEqualToString:@""]){
	return ATEprint;
    }else if(spicite && ![spicite isEqualToString:@""]){
	return ATSpires;
    }else if(spiresKey && ![spiresKey isEqualToString:@""]){
	return ATSpiresWithOnlyKey;
    }
    return ATGeneric;
}

-(NSString*)uniqueId:(NSManagedObject*)article
{
    ArticleType articleType=[self articleType:article];
    if(articleType==ATEprint){
	NSString*s=[article valueForKey:@"eprint"];
	s=[s stringByReplacingOccurrencesOfString:@"/" withString:@""];
	if([s hasPrefix:@"arXiv:"]){
	    return [s substringFromIndex:[(NSString*)@"arXiv:" length]];
	}else{
	    return s;
	}
    }else if(articleType==ATSpires){
	return [article valueForKey:@"spicite"];
    }else if(articleType==ATSpiresWithOnlyKey){
	return [article valueForKey:@"spiresKey"];
    }else{
	return @"shouldn't happen";
    }
}
-(NSString*)abstractFilePath:(NSManagedObject*)article
{
    return [NSString stringWithFormat:@"%@/%@.html",[[MOC sharedMOCManager] directoryForAbstract], [self uniqueId:article]];
}
-(void)emitAbstractIntoSeperateFile:(NSManagedObject*)article
{
    NSString*s=[article valueForKey:@"abstract"];
    if(s && ![s isEqualToString:@""]){
	NSString*path=[self abstractFilePath:article];
//	NSLog(@"emitting %@",path);
	[s writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];    
    }
}*/
- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    
    NSArray *attributeMappings = [mapping attributeMappings];
    NSString*forA=[sInstance valueForKey:@"longishAuthorListForA"];
    NSString*forEA=[sInstance valueForKey:@"longishAuthorListForEA"];
    for(NSPropertyMapping *currentMapping in attributeMappings) 
    {
	NSString*name=[currentMapping name];
	if( [name isEqualToString:@"longishAuthorListForA"] && ![forA hasPrefix:@"; "]){
	    [currentMapping setValueExpression:[NSExpression expressionForConstantValue:[@"; " stringByAppendingString:forA] ]];	    
	}else 	if( [name isEqualToString:@"longishAuthorListForEA"] && ![forEA hasPrefix:@"; "]){
	    [currentMapping setValueExpression:[NSExpression expressionForConstantValue:[@"; " stringByAppendingString:forEA]]];	    
	}	
    }
    return [super createDestinationInstancesForSourceInstance:sInstance entityMapping:mapping manager:manager error:error];

}
@end

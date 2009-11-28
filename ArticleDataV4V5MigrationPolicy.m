//
//  ArticleDataV4V5MigrationPolicy.m
//  spires
//
//  Created by Yuji on 11/27/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArticleDataV4V5MigrationPolicy.h"


@implementation ArticleDataV4V5MigrationPolicy
- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    
    NSArray *attributeMappings = [mapping attributeMappings];
    for(NSPropertyMapping *currentMapping in attributeMappings) 
    {
	NSString*name=[currentMapping name];
	if( [name isEqualToString:@"pdfAlias"] ){
	    NSData*aliasData=[sInstance valueForKey:@"pdfAlias"];
	    if(aliasData&&[aliasData length]>0){
		CFDataRef bookmarkData=CFURLCreateBookmarkDataFromAliasRecord(kCFAllocatorDefault, (CFDataRef)aliasData);
		[currentMapping setValueExpression:[NSExpression expressionForConstantValue:(NSData*)bookmarkData ]];
		CFRelease(bookmarkData);
	    }else{
		[currentMapping setValueExpression:[NSExpression expressionForConstantValue:(NSData*)nil ]];
	    }
	}	
	if( [name isEqualToString:@"spiresKey"] ){
	    NSString*string=[sInstance valueForKey:@"spiresKey"];
	    NSNumber*number=[NSNumber numberWithInteger:[string integerValue]];
	    [currentMapping setValueExpression:[NSExpression expressionForConstantValue:number]];
	}	
	
    }
    return [super createDestinationInstancesForSourceInstance:sInstance entityMapping:mapping manager:manager error:error];
    
}
@end

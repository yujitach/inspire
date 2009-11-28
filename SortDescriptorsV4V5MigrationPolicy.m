//
//  SortDescriptorsV4V5MigrationPolicy.m
//  spires
//
//  Created by Yuji on 11/27/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "SortDescriptorsV4V5MigrationPolicy.h"


@implementation SortDescriptorsV4V5MigrationPolicy
-(NSArray*)xformedSortDescriptorsFromArray:(NSArray*)src
{
    NSMutableArray*dest=[NSMutableArray array];
    for(NSSortDescriptor*desc in src){
	NSString*key=[desc key];
	if([key isEqualToString:@"eprint"]){
	    key=@"eprintForSorting";
	}else if([key isEqualToString:@"shortishAuthorList"]){
	    key=@"longishAuthorListForA";
	}
	NSSortDescriptor*d=[NSSortDescriptor sortDescriptorWithKey:key 
							 ascending:[desc ascending]
							  selector:[desc selector]];
	[dest addObject:d];
    }
    return dest;
}
- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error
{
    
    NSArray *attributeMappings = [mapping attributeMappings];
    for(NSPropertyMapping *currentMapping in attributeMappings) 
    {
	NSString*name=[currentMapping name];
	if( [name isEqualToString:@"sortDescriptors"] ){
	    NSArray*org=[sInstance valueForKey:@"sortDescriptors"];
	    NSArray*xformed=[self xformedSortDescriptorsFromArray:org];
	    [currentMapping setValueExpression:[NSExpression expressionForConstantValue:xformed ]];
	}	
	
    }
    return [super createDestinationInstancesForSourceInstance:sInstance entityMapping:mapping manager:manager error:error];
    
}

@end

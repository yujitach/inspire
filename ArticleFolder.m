//
//  ArticleFolder.m
//  spires
//
//  Created by Yuji on 09/03/18.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "ArticleFolder.h"


@implementation ArticleFolder
+(ArticleFolder*)articleFolderWithName:(NSString*)s inMOC:(NSManagedObjectContext*)moc
{
    NSEntityDescription*authorEntity=[NSEntityDescription entityForName:@"ArticleFolder" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:authorEntity];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"name = %@",s];
    [req setPredicate:pred];
    NSError*error=nil;
    NSArray*a=[moc executeFetchRequest:req error:&error];
    if([a count]>0){
	return [a objectAtIndex:0];
    }else{
	ArticleFolder* mo=[[NSManagedObject alloc] initWithEntity:authorEntity 
				       insertIntoManagedObjectContext:moc];
	[mo setValue:s forKey:@"name"];
	return mo;
    }    
}
-(void)reload
{
}
-(NSImage*)icon
{
    return [[NSWorkspace sharedWorkspace] iconForFile:[[NSBundle mainBundle] resourcePath]];
}
-(BOOL)searchStringEnabled
{
    return NO;
}
@end

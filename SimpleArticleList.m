// 
//  SimpleArticleList.m
//  spires
//
//  Created by Yuji on 08/10/15.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "SimpleArticleList.h"


@implementation SimpleArticleList 
+(SimpleArticleList*)simpleArticleListWithName:(NSString*)s inMOC:(NSManagedObjectContext*)moc
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"SimpleArticleList" inManagedObjectContext:moc];
    NSFetchRequest*req=[[NSFetchRequest alloc]init];
    [req setEntity:entity];
    NSPredicate*pred=[NSPredicate predicateWithFormat:@"name = %@",s];
    [req setPredicate:pred];
    NSError*error=nil;
    NSArray*a=[moc executeFetchRequest:req error:&error];
    if([a count]>0){
	return a[0];
    }else {
	return nil;
    }
}
+(SimpleArticleList*)createSimpleArticleListWithName:(NSString*)s inMOC:(NSManagedObjectContext*)moc
{
    NSEntityDescription*entity=[NSEntityDescription entityForName:@"SimpleArticleList" inManagedObjectContext:moc];
    SimpleArticleList* mo=(SimpleArticleList*)[[NSManagedObject alloc] initWithEntity:entity
				   insertIntoManagedObjectContext:moc];
    mo.name=s;

    return mo;
}
-(void)awakeFromInsert
{
    self.sortDescriptors=@[[NSSortDescriptor sortDescriptorWithKey:@"eprintForSorting" ascending:NO]];
}
-(void)reload
{
}
-(BOOL)searchStringEnabled
{
    return YES;
}

-(NSImage*)icon
{
    return [NSImage imageNamed:@"spires-red"];
}
@end

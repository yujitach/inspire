//
//  SideTableViewController.m
//  spires
//
//  Created by Yuji on 08/10/25.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "SideTableViewController.h"
#import "spires_AppDelegate.h"
#import "Article.h"
#import "ArticleList.h"
#import "AllArticleList.h"
#import "SimpleArticleList.h"
#import "ArxivNewArticleList.h"
#import "MOC.h"

@implementation SideTableViewController
-(NSManagedObjectContext*)managedObjectContext
{
    return [MOC moc];
}
-(ArticleList*)currentArticleList
{
    NSArray*a=[articleListController selectedObjects];
    if(a && [a count]>0){
	return [a objectAtIndex:0];
    }else{
	return nil;
    }
}
-(void)addArticleList:(ArticleList*)al
{
    [articleListController insertObject:al atArrangedObjectIndex:[[articleListController arrangedObjects] count]];
}
-(void)removeArticleList:(ArticleList*)al;
{
    [articleListController removeObject:al];
}
-(void)selectAllArticleList;
{
    [articleListController setSelectionIndex:0];
}
-(void)selectArticleList:(ArticleList*)al;
{
    [articleListController setSelectedObjects:[NSArray arrayWithObject:al]];
}
-(void)rearrangePositionInViewForArticleLists
{
    int i=0;
    NSMutableArray* a=[NSMutableArray array];
    NSMutableArray* b=[NSMutableArray array];
    NSEntityDescription* entity=[NSEntityDescription entityForName:@"ArticleList" inManagedObjectContext:[self managedObjectContext]];
    NSFetchRequest* request=[[NSFetchRequest alloc] init];
    [request setEntity:entity];
    NSPredicate*pred=[NSPredicate predicateWithValue:YES];
    [request setPredicate:pred];
    [request setSortDescriptors:[NSArray arrayWithObjects:[[NSSortDescriptor alloc] initWithKey:@"positionInView" ascending:YES], nil]];
    
    NSError*error=nil;
    NSArray*all=[[self managedObjectContext] executeFetchRequest:request error:&error];
    // NSLog(@"articleLists:%@",all);
    for(ArticleList*al in all){
	if([al isKindOfClass:[ArxivNewArticleList class]]){
	    [a addObject:al];
	}
	if([al isKindOfClass:[SimpleArticleList class]]){
	    [b addObject:al];
	}
    }
    allArticleList.positionInView=[NSNumber numberWithInt:0];
    i=1;
    for(ArticleList*x in a){
	x.positionInView=[NSNumber numberWithInt:2*i];
	i++;
    }
    for(ArticleList*x in b){
	x.positionInView=[NSNumber numberWithInt:2*i];
	i++;
    }
    [articleListController rearrangeObjects];
   [articleListController didChangeArrangementCriteria];
    /*    for(ArticleList*i in [articleListController arrangedObjects]){
     NSLog(@"%@ position:%@",i.name,i.positionInView);
     }*/
}
-(void)loadArticleLists
{
    [articleListController setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"positionInView" ascending:YES]]];
    [articleListController rearrangeObjects];
   [articleListController didChangeArrangementCriteria];
    allArticleList=[AllArticleList allArticleListInMOC:[self managedObjectContext]];
    allArticleList.positionInView=[NSNumber numberWithInt:0];
    allArticleList.searchString=@"";
    if(![[NSUserDefaults standardUserDefaults]boolForKey:@"specialListPrepared"]){
	[[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"specialListPrepared"];
	ArticleList*hepph=[ArxivNewArticleList arXivNewArticleListWithName:@"hep-ph/new" inMOC:[self managedObjectContext]];
	hepph.positionInView=[NSNumber numberWithInt:2];
	ArticleList*hepth=[ArxivNewArticleList arXivNewArticleListWithName:@"hep-th/new" inMOC:[self managedObjectContext]];
	hepth.positionInView=[NSNumber numberWithInt:4];
    }
    if(![[NSUserDefaults standardUserDefaults]boolForKey:@"replacedListPrepared"]){
	[[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"replacedListPrepared"];
	NSEntityDescription*authorEntity=[NSEntityDescription entityForName:@"ArxivNewArticleList" inManagedObjectContext:[self managedObjectContext]];
	NSFetchRequest*req=[[NSFetchRequest alloc]init];
	[req setEntity:authorEntity];
	NSPredicate*pred=[NSPredicate predicateWithValue:YES];
	[req setPredicate:pred];
	NSError*error=nil;
	NSArray*a=[[self managedObjectContext] executeFetchRequest:req error:&error];
	if([a count]>0){
	    for(ArticleList* al in a){
		NSArray* x=[al.name componentsSeparatedByString:@"/"];
		ArticleList*replaced=[ArxivNewArticleList arXivNewArticleListWithName:[NSString stringWithFormat:@"%@/%@",[x objectAtIndex:0],@"replaced"]
										inMOC:[self managedObjectContext]];
		replaced.positionInView=[NSNumber numberWithInt:[al.positionInView intValue]+1];
	    }
	}
    }
    
    [self rearrangePositionInViewForArticleLists];
    NSError*error=nil;
    [[MOC moc] save:&error]; // ensure the lists can be accessed from the second MOC
    if(error){
	NSLog(@"moc error:%@",error);
    }
}
/*-(void)saveArticleLists
{
}
*/

-(void)awakeFromNib
{
    [articleListView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,ArticleDropPboardType,ArticleListDropPboardType,nil]];
    allArticleList=[AllArticleList allArticleListInMOC:[self managedObjectContext]];
    [self loadArticleLists];
    
}

#pragma mark NSTableView delegate

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    NSManagedObjectContext* moc=[MOC moc];
    if([[[info draggingPasteboard] types] containsObject:ArticleDropPboardType]){
	ArticleList* al=[[articleListController arrangedObjects] objectAtIndex:row];
	NSData* d=[[info draggingPasteboard] dataForType:ArticleDropPboardType];
	if(d){
	    NSArray* a=[NSKeyedUnarchiver unarchiveObjectWithData:d];
	    for(NSURL*url in a){
		NSManagedObjectID* moID=[[moc persistentStoreCoordinator] 
					 managedObjectIDForURIRepresentation:url];
		Article*x=(Article*)[moc objectWithID:moID];
		if(x){
		    [al addArticlesObject:x];
		}
	    }
	    return YES;
	}
	return NO;
    }
    if([[[info draggingPasteboard] types] containsObject:ArticleListDropPboardType]){
	NSData* d=[[info draggingPasteboard] dataForType:ArticleListDropPboardType];
	if(d){
	    NSArray* a=[NSKeyedUnarchiver unarchiveObjectWithData:d];
	    NSMutableArray* ma=[NSMutableArray array];
	    for(NSURL*url in a){
		NSManagedObjectID* moID=[[moc persistentStoreCoordinator] 
					 managedObjectIDForURIRepresentation:url];
		ArticleList*x=(ArticleList*)[moc objectWithID:moID];
		if(x){
		    [ma addObject:x];
		}
	    }
	    int r=row*2-2;
	    for(ArticleList* x in ma){
		x.positionInView=[NSNumber numberWithInt:++r];
		[self rearrangePositionInViewForArticleLists];
		++r;
	    }
	    return YES;
	}	
    }  
    return NO;
}
- (NSDragOperation)tableView:(NSTableView*)tvv validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    if([[[info draggingPasteboard] types] containsObject:ArticleDropPboardType]){
	if(operation==NSTableViewDropAbove)
	    return NSDragOperationNone;
	if(row<[[articleListController arrangedObjects] count]){
	    ArticleList* al=[[articleListController arrangedObjects] objectAtIndex:row];
	    if([al isKindOfClass:[ArxivNewArticleList class]])
		return NSDragOperationNone;
	    
	}
	
	return NSDragOperationCopy; 
    }
    if([[[info draggingPasteboard] types] containsObject:ArticleListDropPboardType]){
	if(operation!=NSTableViewDropAbove)
	    return NSDragOperationNone;
	return NSDragOperationMove;
    }
    return NSDragOperationNone;
}
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{


    NSArray* a=[[articleListController arrangedObjects] objectsAtIndexes:rowIndexes];
    NSMutableArray* b=[NSMutableArray array];
    for(ArticleList*i in a){
	[b addObject:[[i objectID] URIRepresentation]];
    }
    [pboard declareTypes:[NSArray arrayWithObject:ArticleListDropPboardType] owner:nil];
    [pboard setData:[NSKeyedArchiver archivedDataWithRootObject:b] forType:ArticleListDropPboardType];
    return YES;
}
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
   
	if(rowIndex<1)
	    return NO;
	else
	    return YES;

}
-(NSMenu*)tableView:(NSTableView*)tvv contextMenuForColumn:(NSTableColumn*)col atRow:(int)i;
{
    //    NSLog(@"context menu for %@:%d",col,i);
  	NSMenu* menu=[[NSMenu alloc] initWithTitle:@"context menu"];
	if(i==-1){
	    [menu insertItemWithTitle:@"Add" 
			       action:@selector(addArticleList:)
			keyEquivalent:@""
			      atIndex:0];
	    [menu insertItemWithTitle:@"Add arxiv/new" 
			       action:@selector(addArxivArticleList:)
			keyEquivalent:@""
			      atIndex:1];
	}else{
	    
	    ArticleList* al=[[articleListController arrangedObjects] objectAtIndex:i];
	    if([al isKindOfClass:[ArxivNewArticleList class]]){
		[menu insertItemWithTitle:@"Reload" 
				   action:@selector(reloadSelectedArticleList:)
			    keyEquivalent:@""
				  atIndex:0];
		[menu insertItemWithTitle:@"Delete" 
				   action:@selector(deleteArticleList:)
			    keyEquivalent:@""
				  atIndex:1];	
		[tvv selectRow:i byExtendingSelection:NO];
	    }else if([al isKindOfClass:[SimpleArticleList class]]) {
		
		//if(i>[self numberOfSpecialArticleLists]){
		[menu insertItemWithTitle:@"Delete" 
				   action:@selector(deleteArticleList:)
			    keyEquivalent:@""
				  atIndex:0];	
		[tvv selectRow:i byExtendingSelection:NO];
	    }
	}
	return menu;
}

@end

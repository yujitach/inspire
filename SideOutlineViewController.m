//
//  SideTableViewController.m
//  spires
//
//  Created by Yuji on 08/10/25.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "SideOutlineViewController.h"
#import "spires_AppDelegate.h"
#import "Article.h"
#import "ArticleList.h"
#import "AllArticleList.h"
#import "SimpleArticleList.h"
#import "ArxivNewArticleList.h"
#import "ArticleFolder.h"
#import "ImageAndTextCell.h"
#import "MOC.h"

/*@interface NSSourceListCell:NSTextFieldCell
{
}
- (id)copyWithZone:(struct _NSZone *)fp8;
- (id)init;
- (id)initWithCoder:(id)fp8;
- (void)dealloc;
- (void)setImage:(id)fp8;
- (id)image;
- (float)imageSize;
- (unsigned int)hitTestForEvent:(id)fp8 inRect:(struct _NSRect)fp12 ofView:(id)fp28;
- (struct _NSRect)expansionFrameWithFrame:(struct _NSRect)fp8 inView:(id)fp24;
@end*/

@implementation SideOutlineViewController
-(NSManagedObjectContext*)managedObjectContext
{
    return [MOC moc];
}
-(ArticleList*)currentArticleList
{
//    NSArray*a=[articleListController selectedObjects];
    NSIndexPath*ip=[articleListController selectionIndexPath];
    NSTreeNode*root=[articleListController arrangedObjects];
    if(ip){
	ArticleList* a=[[root descendantNodeAtIndexPath:ip] representedObject];
//	NSLog(@"current al:%@",a.name);
	return a;
    }else{
	return nil;
    }
/*    if(a && [a count]>0){
	return [a objectAtIndex:0];
    }else{
	return nil;
    }*/
}
-(void)addArticleList:(ArticleList*)al
{
    [articleListController insertObject:al 
	      atArrangedObjectIndexPath:[NSIndexPath indexPathWithIndex:[[articleListController arrangedObjects] count]]];
}

-(void)selectAllArticleList;
{
    [articleListController setSelectionIndexPath:[NSIndexPath indexPathWithIndex:0]];
}
-(NSIndexPath*)indexPathForArticleList:(ArticleList*)al
{
    if(al.parent==nil){
	return [NSIndexPath indexPathWithIndex:[al.positionInView integerValue]/2];
    }
    return [[self indexPathForArticleList:al.parent] indexPathByAddingIndex:[al.positionInView integerValue]/2];
}
-(void)selectArticleList:(ArticleList*)al;
{
    [articleListController setSelectionIndexPath:[self indexPathForArticleList:al]];
}
-(void)removeCurrentArticleList;
{
    [articleListController remove:self];
}
-(void)updatePositionInViewFor:(ArticleList*)al to:(NSInteger)i
{
    if([al.positionInView integerValue]!=i){
	al.positionInView=[NSNumber numberWithInteger:i];
    }
}
-(NSArray*)articleListsInArticleList:(ArticleList*)parent
{
    NSArray*array=nil;
    NSSortDescriptor*desc=[[NSSortDescriptor alloc] initWithKey:@"positionInView" ascending:YES];
    if(!parent){
	NSEntityDescription* entity=[NSEntityDescription entityForName:@"ArticleList" inManagedObjectContext:[self managedObjectContext]];
	NSFetchRequest* request=[[NSFetchRequest alloc] init];
	[request setEntity:entity];
	NSPredicate*pred=[NSPredicate predicateWithFormat:@"parent == nil"];
	[request setPredicate:pred];
	[request setSortDescriptors:[NSArray arrayWithObject:desc]];
	
	NSError*error=nil;
	array=[[self managedObjectContext] executeFetchRequest:request error:&error];
    }else{
	array=[parent.children allObjects];
	array=[array sortedArrayUsingDescriptors:[NSArray arrayWithObject:desc]];
    }
    return array;
}
-(void)rearrangePositionInViewForArticleListsInArticleList:(ArticleList*)parent
{
    NSArray*array=[self articleListsInArticleList:parent];
/*    for(ArticleList*aa in array){
	NSLog(@"%@",aa.name);
    }*/
//    NSLog(@"rearranges:%@",parent.name);
    NSMutableArray* a=[NSMutableArray array];
    NSMutableArray* b=[NSMutableArray array];
    ArticleList* o=nil;
    //NSLog(@"articleLists:%@",all);
    for(ArticleList*al in array){
//	NSLog(@"al:%@",al.name);
	if([al isKindOfClass:[AllArticleList class]]){
	    o=al;
	}else if([al isKindOfClass:[ArxivNewArticleList class]]){
	    [a addObject:al];
	}else if(![al isKindOfClass:[AllArticleList class]]){
	    [b addObject:al];
	}
    }
    int i=0;
    if(o){
	[self updatePositionInViewFor:o to:2*i];
	i++;
    }
    for(ArticleList*x in a){
	[self updatePositionInViewFor:x to:2*i];
//	NSLog(@"al:%d:%@ ",i,x.name);
	i++;
    }
    for(ArticleList*x in b){
	[self updatePositionInViewFor:x to:2*i];
//	NSLog(@"al:%d:%@ ",i,x.name);
	i++;
    }
    [articleListController rearrangeObjects];
//   [articleListController didChangeArrangementCriteria];
    /*    for(ArticleList*i in [articleListController arrangedObjects]){
     NSLog(@"%@ position:%@",i.name,i.positionInView);
     }*/
}
-(void)rearrangePositionInViewForArticleLists
{
    [self rearrangePositionInViewForArticleListsInArticleList:nil];
    NSEntityDescription* entity=[NSEntityDescription entityForName:@"ArticleFolder" inManagedObjectContext:[self managedObjectContext]];
    NSFetchRequest* request=[[NSFetchRequest alloc] init];
    [request setEntity:entity];
    NSPredicate*pred=[NSPredicate predicateWithValue:YES];
    [request setPredicate:pred];    
    NSError*error=nil;
    NSArray*array=[[self managedObjectContext] executeFetchRequest:request error:&error];
    for(ArticleList*al in array){
	[self rearrangePositionInViewForArticleListsInArticleList:al];	
    }
}

-(void)loadArticleLists
{
//   [articleListController didChangeArrangementCriteria];
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
//    [articleListController setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"positionInView" ascending:YES]]];
    [articleListController rearrangeObjects];

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
    NSActionCell* browserCell = [[ImageAndTextCell alloc] init];//[[NSSourceListCell alloc] init];
    [browserCell setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
    [[articleListView tableColumnWithIdentifier:@"name"] setDataCell:browserCell];   
    [articleListView registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType,ArticleDropPboardType,ArticleListDropPboardType,nil]];
    [articleListView setIndentationPerLevel:20];

    NSSortDescriptor*desc=[[NSSortDescriptor alloc] initWithKey:@"positionInView" ascending:YES];
    [articleListController setSortDescriptors:[NSArray arrayWithObject:desc]];
    [articleListView setSortDescriptors:[NSArray arrayWithObject:desc]];
    allArticleList=[AllArticleList allArticleListInMOC:[self managedObjectContext]];
    [self loadArticleLists];
}

#pragma mark NSOutlineView delegate
- (void)outlineView:(NSOutlineView *)outlineView
    willDisplayCell:(ImageAndTextCell*)cell 
     forTableColumn:(NSTableColumn *)tableColumn 
	       item:(NSTreeNode*)item
{
    ArticleList*al=[item representedObject];
    [cell setImage: al.icon];
}

- (NSDragOperation)outlineView:(NSOutlineView*)tvv validateDrop:(id <NSDraggingInfo>)info proposedItem:(NSTreeNode*)item proposedChildIndex:(NSInteger)index
{
    
    ArticleList*al=[item representedObject];
    if([[[info draggingPasteboard] types] containsObject:ArticleDropPboardType]){
	if(index!=-1)
	    return NSDragOperationNone;
	if(!item)
	    return NSDragOperationNone;	    
	else if(![al isKindOfClass:[SimpleArticleList class]])
	    return NSDragOperationNone;
	else
	    return NSDragOperationCopy; 
    }
    if([[[info draggingPasteboard] types] containsObject:ArticleListDropPboardType]){
	ArticleList*al=[item representedObject];
	if(al && ![al isKindOfClass:[ArticleFolder class]])
	    return NSDragOperationNone;
	else
	    return NSDragOperationMove;
    }
    return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    NSMutableArray*paths=[NSMutableArray array];
    [pboard declareTypes:[NSArray arrayWithObject:ArticleListDropPboardType] owner:self];
    for(NSTreeNode*item in items){
	if([[item representedObject] isKindOfClass:[AllArticleList class]])
	    return NO;
	[paths addObject:[item indexPath]];
    }
    NSData *indexPathData = [NSKeyedArchiver archivedDataWithRootObject:paths];
    [pboard setData:indexPathData forType:ArticleListDropPboardType];
    // Return YES so that the drag actually begins...
    return YES;
}

/*
 Performing a drop in the outline view. This allows the user to manipulate the structure of the tree by moving subtrees under new parent nodes.
 */
-(BOOL)articleList:(ArticleList*)al hasAncestor:(ArticleList*)o
{
    if(o==al)
	return YES;
    if(!al.parent)
	return NO;
    return [self articleList:al.parent hasAncestor:o];
}
- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(NSTreeNode*)item childIndex:(NSInteger)index {
    
    NSManagedObjectContext* moc=[MOC moc];
    if([[[info draggingPasteboard] types] containsObject:ArticleDropPboardType]){
	ArticleList*al=[item representedObject];
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
    
    ArticleList*al=[item representedObject];  
    if(al && ![al isKindOfClass:[ArticleFolder class]])
	return NO;
    // Retrieve the index path from the pasteboard.
    NSTreeNode* treeRoot = [articleListController arrangedObjects];
    NSArray*paths=   [NSKeyedUnarchiver unarchiveObjectWithData:[[info draggingPasteboard] dataForType:ArticleListDropPboardType]];
    NSMutableArray*droppedObjects=[NSMutableArray array];
    NSMutableArray*droppedNodes=[NSMutableArray array];
    for(NSIndexPath*ip in paths){
	NSTreeNode*n=[treeRoot descendantNodeAtIndexPath:ip];
	ArticleList* dropped=[n representedObject];
	if([self articleList:al hasAncestor:dropped])
	    return NO;
	[droppedObjects addObject:dropped];
	[droppedNodes addObject:n];
    }
    if(index==-1)
	index=0;
    NSArray*ch=[self articleListsInArticleList:al];
    
//    for(ArticleList*aa in ch){
//	NSLog(@"al:%@ was at %@",aa.name,aa.positionInView);
//    }
//    NSLog(@"dropping into index:%d",index);
    for(int c=0;c<[droppedObjects count];c++){
	ArticleList*al=[droppedObjects objectAtIndex:c];
	al.positionInView=[NSNumber numberWithInteger:2*(index+c)];	
//	NSLog(@"al:%@ now at %@",al.name,al.positionInView);
    }
    for(int c=index;c<[ch count];c++){
	ArticleList*al=[ch objectAtIndex:c];
	if([droppedObjects containsObject:al])
	    continue;
	al.positionInView=[NSNumber numberWithInteger:2*(c+[paths count])];
//	NSLog(@"al:%@ now at %@",al.name,al.positionInView);
    }
    [articleListController moveNodes:droppedNodes toIndexPath:[[item indexPath] indexPathByAddingIndex:index]];
//    [articleListController rearrangeObjects];
//    [self rearrangePositionInViewForArticleListsInArticleList:[item representedObject]];
    [self rearrangePositionInViewForArticleLists];
    // Return YES so that the user gets visual feedback that the drag was successful...
    return YES;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(NSTreeNode*)item
{
    ArticleList*al=[item representedObject];
    if([al isKindOfClass:[AllArticleList class]])
	return NO;
    else
	return YES;
}

-(NSMenu*)tableView:(NSOutlineView*)ov contextMenuForColumn:(NSTableColumn*)col atRow:(int)i;
{
//    NSLog(@"context menu for %@:%d",col,i);
    NSMenu* menu=[[NSMenu alloc] initWithTitle:@"context menu"];
    if(i==-1){
	[menu insertItemWithTitle:@"Add List..." 
			   action:@selector(addArticleList:)
		    keyEquivalent:@""
			  atIndex:0];
	[menu insertItemWithTitle:@"Add Folder..." 
			   action:@selector(addArticleFolder:)
		    keyEquivalent:@""
			  atIndex:1];
	[menu insertItemWithTitle:@"Add arxiv/new..." 
			   action:@selector(addArxivArticleList:)
		    keyEquivalent:@""
			  atIndex:2];
    }else{
	NSTreeNode*item=[ov itemAtRow:i];
	
	ArticleList* al=[item representedObject];
	if([al isKindOfClass:[ArxivNewArticleList class]]){
	    [menu insertItemWithTitle:@"Reload" 
			       action:@selector(reloadSelectedArticleList:)
			keyEquivalent:@""
			      atIndex:0];
	    [menu insertItemWithTitle:@"Delete" 
			       action:@selector(deleteArticleList:)
			keyEquivalent:@""
			      atIndex:1];	
	    [ov selectRow:i byExtendingSelection:NO];
	}else if(![al isKindOfClass:[AllArticleList class]]) {
	    
	    //if(i>[self numberOfSpecialArticleLists]){
	    [menu insertItemWithTitle:@"Delete" 
			       action:@selector(deleteArticleList:)
			keyEquivalent:@""
			      atIndex:0];	
	    [ov selectRow:i byExtendingSelection:NO];
	}
    }
    return menu;
}



#pragma mark NSTableView delegate
/*
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
}*/
@end

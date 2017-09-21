//
//  SideTableViewController.m
//  spires
//
//  Created by Yuji on 08/10/25.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "SideOutlineViewController.h"
#import "Article.h"
#import "ArticleList.h"
#import "AllArticleList.h"
#import "SimpleArticleList.h"
#import "ArxivNewArticleList.h"
#import "ArticleFolder.h"
#import "CannedSearch.h"
#import "ImageAndTextCell.h"
#import "MOC.h"
#import "AppDelegate.h"
#import "SpiresAppDelegate_actions.h"



@implementation SideOutlineViewController
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
	      atArrangedObjectIndexPath:[NSIndexPath indexPathWithIndex:[(NSArray*)[articleListController arrangedObjects] count]]];
    al.positionInView=@(2000);
    [ArticleList rearrangePositionInView];
    [articleListController rearrangeObjects];
    [al.managedObjectContext save:NULL];
}

-(void)selectAllArticleList;
{
    [articleListController setSelectionIndexPath:[NSIndexPath indexPathWithIndex:0]];
}
-(void)selectArticleList:(ArticleList*)al;
{
    [articleListController setSelectionIndexPath:al.indexPath];
}
-(void)removeArticleFolder:(ArticleList*)al
{
    NSSet*set=al.children;
    for(ArticleList* c in set){
	if([c isKindOfClass:[ArticleFolder class]]){
	    [self removeArticleFolder:c];
	}
	[[MOC moc] deleteObject:c];
    }
    [[MOC moc] deleteObject:al];
}
-(void)removeCurrentArticleList;
{
    ArticleList*al=[articleListController selectedObjects][0];
    if([al isKindOfClass:[ArticleFolder class]]){
	NSAlert*alert=[NSAlert alertWithMessageText:[NSString stringWithFormat:@"Do you want to remove folder %@",al.name]
				      defaultButton:@"Yes" 
				    alternateButton:@"No"
					otherButton:nil
			  informativeTextWithFormat:@"Removing a folder recursively removes its contents.\n You can undo it by Cmd-Z."];
	NSUInteger result=[alert runModal];
	if(result!=NSAlertDefaultReturn)
	    return;
	[self removeArticleFolder:al];
    }else{
	[[MOC moc] deleteObject:al];
//	[articleListController removeObject:tn];
    }
}



-(void)loadArticleLists;
{
    // should be called from applicationDidFinishLaunching of the app delegate

    [articleListController prepareContent];
    
    [ArticleList createStandardArticleLists];
    [ArticleList rearrangePositionInView];
    
    [articleListController rearrangeObjects];
    
}
-(void)awakeFromNib
{
    NSActionCell* browserCell = [[ImageAndTextCell alloc] init];//[[NSSourceListCell alloc] init];
    [browserCell setFont:[NSFont systemFontOfSize:[NSFont systemFontSize]]];
    [[articleListView tableColumnWithIdentifier:@"name"] setDataCell:browserCell];   
    [articleListView registerForDraggedTypes:@[NSFilenamesPboardType,ArticleDropPboardType,ArticleListDropPboardType]];
    [articleListView setIndentationPerLevel:20];

    NSSortDescriptor*desc=[[NSSortDescriptor alloc] initWithKey:@"positionInView" ascending:YES];
    [articleListController setSortDescriptors:@[desc]];
    [articleListView setSortDescriptors:@[desc]];
}
-(void)detachFromMOC
{
    [articleListController setManagedObjectContext:nil];
}
-(void)attachToMOC
{
    [articleListController setManagedObjectContext:[MOC moc]];
}
#pragma mark NSOutlineView delegate
-(void)outlineViewSelectionDidChange:(NSNotification*)notification
{
/*    NSArray*a=[articleListController selectedObjects];
    if([a count]==1){
	[[NSApp appDelegate] makeTableViewFirstResponder];
    }*/
    [articleListView updateTrackingAreas];
}
- (void)outlineView:(NSOutlineView *)outlineView
    willDisplayCell:(ImageAndTextCell*)cell 
     forTableColumn:(NSTableColumn *)tableColumn 
	       item:(NSTreeNode*)item
{
    ArticleList*al=[item representedObject];
    [cell setButton: al.button];
    [cell setImage: al.icon];
    [cell setShowButton:[cell isHighlighted]];
}

- (NSDragOperation)outlineView:(NSOutlineView*)tvv validateDrop:(id <NSDraggingInfo>)info proposedItem:(NSTreeNode*)item proposedChildIndex:(NSInteger)ind
{
    
    ArticleList*al=[item representedObject];
    if([[[info draggingPasteboard] types] containsObject:ArticleDropPboardType]){
	if(ind!=-1)
	    return NSDragOperationNone;
	if(!item)
	    return NSDragOperationNone;	    
	else if(![al isKindOfClass:[SimpleArticleList class]])
	    return NSDragOperationNone;
	else
	    return NSDragOperationCopy; 
    }
    if([[[info draggingPasteboard] types] containsObject:ArticleListDropPboardType]){
	if(al && ![al isKindOfClass:[ArticleFolder class]])
	    return NSDragOperationNone;
	else
	    return NSDragOperationMove;
    }
    return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    NSMutableArray*paths=[NSMutableArray array];
    [pboard declareTypes:@[ArticleListDropPboardType] owner:self];
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
- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id <NSDraggingInfo>)info item:(NSTreeNode*)item childIndex:(NSInteger)ind {
    
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
    if(ind==-1)
	ind=0;
    NSArray*ch=[ArticleList articleListsInArticleList:al];
    
//    for(ArticleList*aa in ch){
//	NSLog(@"al:%@ was at %@",aa.name,aa.positionInView);
//    }
//    NSLog(@"dropping into index:%d",index);
    for(NSUInteger c=0;c<[droppedObjects count];c++){
	ArticleList*dropped=droppedObjects[c];
	dropped.positionInView=[NSNumber numberWithInteger:2*(ind+c)];	
//	NSLog(@"al:%@ now at %@",al.name,al.positionInView);
    }
    for(NSUInteger c=ind;c<[ch count];c++){
	ArticleList*pre=ch[c];
	if([droppedObjects containsObject:pre])
	    continue;
	pre.positionInView=[NSNumber numberWithInteger:2*(c+[paths count])];
//	NSLog(@"al:%@ now at %@",al.name,al.positionInView);
    }
    [articleListController moveNodes:droppedNodes toIndexPath:[[item indexPath] indexPathByAddingIndex:ind]];
//    [articleListController rearrangeObjects];
//    [self rearrangePositionInViewForArticleListsInArticleList:[item representedObject]];
    [ArticleList rearrangePositionInView];
    [articleListController rearrangeObjects];
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

-(NSMenu*)tableView:(NSOutlineView*)ov contextMenuForColumn:(NSTableColumn*)col atRow:(NSInteger)i;
{
//    NSLog(@"context menu for %@:%d",col,i);
    NSMenu* menu=[[NSMenu alloc] initWithTitle:@"context menu"];
    if(i==-1){
	[menu insertItemWithTitle:@"Add Playlist..." 
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
	[menu insertItemWithTitle:@"Save Current Search..." 
			   action:@selector(addCannedSearch:)
		    keyEquivalent:@""
			  atIndex:3];
    }else{
	NSTreeNode*item=[ov itemAtRow:i];
	NSIndexSet*is=[NSIndexSet indexSetWithIndex:i];
	ArticleList* al=[item representedObject];
	if([al isKindOfClass:[ArxivNewArticleList class]]||[al isKindOfClass:[CannedSearch class]]){
	    [menu insertItemWithTitle:@"Reload" 
			       action:@selector(reloadSelectedArticleList:)
			keyEquivalent:@""
			      atIndex:0];
	    [menu insertItemWithTitle:@"Delete" 
			       action:@selector(deleteArticleList:)
			keyEquivalent:@""
			      atIndex:1];	
	    [ov selectRowIndexes:is byExtendingSelection:NO];
	}else if(![al isKindOfClass:[AllArticleList class]]) {
	    
	    //if(i>[self numberOfSpecialArticleLists]){
	    [menu insertItemWithTitle:@"Delete" 
			       action:@selector(deleteArticleList:)
			keyEquivalent:@""
			      atIndex:0];	
	    [ov selectRowIndexes:is byExtendingSelection:NO];
	}
    }
    return menu;
}


@end

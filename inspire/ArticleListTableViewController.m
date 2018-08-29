//
//  MasterViewController.m
//  inspire
//
//  Created by Yuji on 2015/08/27.
//
//

#import "ArticleListTableViewController.h"
#import "ArticleTableViewController.h"
#import "AddFolderViewController.h"
#import "AllArticleList.h"
#import "ArticleList.h"
#import "ArticleFolder.h"
#import "MOC.h"
#import "SpecificArticleListTableViewController.h"

@interface ArticleListTableViewController ()

@end

@implementation ArticleListTableViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.navigationItem.leftItemsSupplementBackButton=YES;
    self.detailViewController = (ArticleTableViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
}

- (void)viewWillAppear:(BOOL)animated {
    self.clearsSelectionOnViewWillAppear = self.splitViewController.isCollapsed;
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - state restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [[MOC moc] encodeObject:self.parent toCoder:coder forKey:@"parent"];
    [super encodeRestorableStateWithCoder:coder];
}
-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    ArticleList*a=(ArticleList*)[[MOC moc] decodeFromCoder:coder forKey:@"parent"];
    self.parent=a;
    [self fetchedResultsController];
    [super decodeRestorableStateWithCoder:coder];
}
#pragma mark - Segues
-(IBAction)unwindFromAddFolder:(UIStoryboardSegue*)segue
{
    [[MOC moc] save:NULL];
}
-(IBAction)unwindFromChoosingSimpleArticleList:(UIStoryboardSegue*)segue
{
    [[MOC moc] save:NULL];
    [self.tableView reloadData];
}
-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"ShowDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        ArticleList *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        if([object isKindOfClass:[ArticleFolder class]]){
            ArticleListTableViewController*vc=(ArticleListTableViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"ArticleListTableView"];
//            NSLog(@"self:%@",self);
//            NSLog(@"new:%@",vc);
            vc.parent=object;
            [self.navigationController pushViewController:vc animated:YES];
            return NO;
        }
    }
    return YES;
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"ShowDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if(!indexPath){
            indexPath=[NSIndexPath indexPathForRow:0 inSection:0];
        }
        ArticleList *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        ArticleTableViewController *controller = (ArticleTableViewController *)[[segue destinationViewController] topViewController];
        [controller setArticleList:object];
        controller.navigationItem.leftItemsSupplementBackButton = YES;
        controller.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
        if(self.splitViewController.displayMode==UISplitViewControllerDisplayModePrimaryOverlay){
            self.splitViewController.preferredDisplayMode=UISplitViewControllerDisplayModePrimaryHidden;            
        }
    }else if([[segue identifier] isEqualToString:@"AddFolder"]){
        AddFolderViewController *controller = (AddFolderViewController *)[[segue destinationViewController] topViewController];
        controller.parent=self.parent;
    }else if([[segue identifier] isEqualToString:@"ChooseArticleFolder"]){
        NSIndexPath*indexPath=(NSIndexPath*)sender;
        ArticleList*articleList=[self.fetchedResultsController objectAtIndexPath:indexPath];
        
        UINavigationController*nc=(UINavigationController*)[segue destinationViewController];
        UITableViewCell*cell=[self.tableView cellForRowAtIndexPath:indexPath];
        CGRect frame=cell.bounds;
        frame.origin.x=frame.size.width*.8;
        frame.origin.y=frame.size.height*.5;
        frame.size=CGSizeMake(0, 0);
        nc.popoverPresentationController.sourceView=cell;
        nc.popoverPresentationController.sourceRect=frame;
        SpecificArticleListTableViewController*vc=(SpecificArticleListTableViewController*)nc.topViewController;
        vc.entityName=@"ArticleFolder";
        vc.parent=nil;
        vc.actionBlock=^(ArticleList*al){
            articleList.parent=al;
        };
    }
}

#pragma mark - Table View

-(void)moveToArticleFolderArticleListAtIndexPath:(NSIndexPath*)indexPath
{
    // to be implemented
    [self performSegueWithIdentifier:@"ChooseArticleFolder" sender:indexPath];
}
-(void)renameArticleListAtIndexPath:(NSIndexPath*)indexPath
{
    // to be implemented
    ArticleList*articleList=[self.fetchedResultsController objectAtIndexPath:indexPath];
    if([articleList isKindOfClass:[AllArticleList class]]){
        return;
    }
    UIAlertController*ac=[UIAlertController alertControllerWithTitle:@"Rename this list to..." message:nil preferredStyle:UIAlertControllerStyleAlert];
    [ac addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text=articleList.name;
    }];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        articleList.name=ac.textFields[0].text;
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }];
    [ac addAction:confirmAction];
    UITableViewCell*cell=[self.tableView cellForRowAtIndexPath:indexPath];
    CGRect frame=cell.bounds;
    frame.origin.x=frame.size.width*.8;
    frame.origin.y=frame.size.height*.5;
    frame.size=CGSizeMake(0, 0);
    ac.popoverPresentationController.sourceView=cell;
    ac.popoverPresentationController.sourceRect=frame;
    [self presentViewController:ac animated:NO completion:nil];
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewRowAction*deleteAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"Delete" handler:^(UITableViewRowAction * action, NSIndexPath * ip) {
        [self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:ip];
    }];
    UITableViewRowAction*addToAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Move to..." handler:^(UITableViewRowAction * action, NSIndexPath * ip) {
        [self moveToArticleFolderArticleListAtIndexPath:ip];
    }];
    UITableViewRowAction*renameAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Rename..." handler:^(UITableViewRowAction * action, NSIndexPath * ip) {
        [self renameArticleListAtIndexPath:ip];
    }];
    renameAction.backgroundColor=[UIColor orangeColor];
    return @[renameAction,addToAction,deleteAction];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}
-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    ArticleList*articleList=[self.fetchedResultsController objectAtIndexPath:indexPath];
    if([articleList isKindOfClass:[AllArticleList class]]){
        return NO;
    }else{
        return YES;
    }
}
-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(nonnull NSIndexPath *)sourceIndexPath toIndexPath:(nonnull NSIndexPath *)destinationIndexPath
{
    ArticleList*from=[self.fetchedResultsController objectAtIndexPath:sourceIndexPath];
    ArticleList*to=[self.fetchedResultsController objectAtIndexPath:destinationIndexPath];
    NSNumber*n=from.positionInView;
    from.positionInView=to.positionInView;
    to.positionInView=n;
    [[MOC moc] save:NULL];
    [self.tableView reloadData];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
            
        NSError *error = nil;
        if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    ArticleList*al = (ArticleList*)[self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = al.name;
    cell.imageView.contentMode=UIViewContentModeScaleAspectFit;
    cell.imageView.image =al.icon;
    if([al isKindOfClass:[ArticleFolder class]]){
        cell.accessoryType=UITableViewCellAccessoryDisclosureIndicator;
    }else{
        cell.accessoryType=UITableViewCellAccessoryNone;
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ArticleList" inManagedObjectContext:[MOC moc]];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"positionInView" ascending:YES];

    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    NSPredicate* predicate=[NSPredicate predicateWithFormat:@"parent==%@",self.parent];
    
    [fetchRequest setPredicate:predicate];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:[MOC moc] sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            return;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

@end

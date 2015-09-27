//
//  DetailViewController.m
//  inspire
//
//  Created by Yuji on 2015/08/27.
//
//

#import "ArticleTableViewController.h"
#import "ArticleTableViewCell.h"
#import "ArticleViewController.h"
#import "ArticleList.h"
#import "Article.h"
#import "SpiresHelper.h"
#import "AppDelegate.h"
#import "MOC.h"
#import "CannedSearch.h"
#import "SpecificArticleListTableViewController.h"
#import "SimpleArticleList.h"

@interface ArticleTableViewController ()

@end

@implementation ArticleTableViewController

#pragma mark - Managing the detail item

@synthesize articleList=_articleList;
@synthesize fetchedResultsController=_fetchedResultsController;
-(void)setArticleList:(ArticleList *)articleList
{
    _articleList=articleList;
    self.navigationItem.rightBarButtonItem=articleList.barButtonItem;
    self.navigationItem.title=self.articleList.name;
    if([self.articleList isKindOfClass:[CannedSearch class]]){
        self.navigationItem.title=[NSString stringWithFormat:@"%@ (%@)",self.articleList.name,self.articleList.searchString];
    }
    if(self.articleList.searchStringEnabled){
        self.searchBar=[[UISearchBar alloc] initWithFrame:CGRectMake(0,0,self.tableView.frame.size.width,44)];
        self.searchBar.placeholder=self.articleList.placeholderForSearchField;
        if(self.articleList.searchString&&![self.articleList.searchString isEqualToString:@""]){
            self.searchBar.text=self.articleList.searchString;
        }
        self.searchBar.delegate=self;
        self.tableView.tableHeaderView=self.searchBar;
    }else{
        self.tableView.tableHeaderView=nil;
    }
    [self recreateFetchedResultsController];
}
-(ArticleList*)articleList
{
    return _articleList;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

-(void)addToSomeListArticleAtIndexPath:(NSIndexPath*)indexPath
{
    Article*article=[self.fetchedResultsController objectAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"ChooseSimpleList" sender:article];
}
-(void)toggleFlag:(NSIndexPath*)indexPath
{
    Article*article=[self.fetchedResultsController objectAtIndexPath:indexPath];
    if(article.flag & AFIsFlagged){
        [article setFlag:article.flag&~AFIsFlagged];
    }else{
        [article setFlag:article.flag|AFIsFlagged];
    }    
}
- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView
                  editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewRowAction*deleteAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:@"Delete" handler:^(UITableViewRowAction * action, NSIndexPath * ip) {
        [self tableView:tableView commitEditingStyle:UITableViewCellEditingStyleDelete forRowAtIndexPath:ip];
    }];
    UITableViewRowAction*addToAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:@"Add..." handler:^(UITableViewRowAction * action, NSIndexPath * ip) {
        [self addToSomeListArticleAtIndexPath:ip];
    }];
    
    Article*article=[self.fetchedResultsController objectAtIndexPath:indexPath];
    NSString*flag=(article.flag & AFIsFlagged) ? @"Unflag": @"Flag";
    UITableViewRowAction*flagAction=[UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:flag handler:^(UITableViewRowAction * action, NSIndexPath * ip) {
        [self toggleFlag:ip];
    }];
    flagAction.backgroundColor=[UIColor orangeColor];
    return @[flagAction,addToAction,deleteAction];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:(ArticleTableViewCell*)cell atIndexPath:indexPath];
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

- (void)configureCell:(ArticleTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Article *article = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.title.attributedText=article.attributedTitle;
    cell.authors.text=article.shortishAuthorList;
    cell.eprint.text=article.eprintToShow;
}

#pragma mark - Searchbar delegates
-(BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    return self.articleList.searchStringEnabled;
}
/*-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    self.articleList.searchString=searchBar.text;
    [self recreateFetchedResultsController];
    [[NSApp appDelegate] querySPIRES:self.articleList.searchString];
}*/
-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    self.articleList.searchString=searchBar.text;
    [self recreateFetchedResultsController];
    [[NSApp appDelegate] querySPIRES:self.articleList.searchString];
}
#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    return _fetchedResultsController;
}

-(void)recreateFetchedResultsController
{
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Article" inManagedObjectContext:[MOC moc]];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"eprintForSorting" ascending:NO];
    
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    NSPredicate* predicate=[NSPredicate predicateWithFormat:@"inLists contains %@", self.articleList];
    NSPredicate* searchPredicate=[[SpiresHelper sharedHelper] predicateFromSPIRESsearchString:self.articleList.searchString];
    
    if(searchPredicate){
        predicate=[NSCompoundPredicate andPredicateWithSubpredicates:@[predicate,searchPredicate]];
    }
    [fetchRequest setPredicate:predicate];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
//    [NSFetchedResultsController deleteCacheWithName:@"Detail"];
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
    
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
/*
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
*/
#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"ShowArticle"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        ArticleViewController *controller = (ArticleViewController *)[segue destinationViewController];
        controller.fetchedResultsController=self.fetchedResultsController;
        controller.indexPath=indexPath;
    }else if([[segue identifier] isEqualToString:@"ChooseSimpleList"]){
        Article*a=(Article*)sender;
        UINavigationController*nc=(UINavigationController*)[segue destinationViewController];
        SpecificArticleListTableViewController*vc=(SpecificArticleListTableViewController*)nc.topViewController;
        vc.entityName=@"SimpleArticleList";
        vc.actionBlock=^(ArticleList*al){
            [al addArticlesObject:a];
        };
    }
}
-(IBAction)unwindFromChoosingSimpleArticleList:(UIStoryboardSegue*)segue
{
    [[MOC moc] save:NULL];
}


@end

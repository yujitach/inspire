//
//  SimpleArticleListTableViewController.m
//  inspire
//
//  Created by Yuji on 2015/09/17.
//
//

#import "SpecificArticleListTableViewController.h"
#import "MOC.h"
#import "ArticleList.h"
#import "SimpleArticleList.h"

@interface ArticleList (CombinedCategory)
-(NSNumber*)combinedPosition;
-(NSString*)combinedName;
@end

@implementation ArticleList (CombinedCategory)
-(NSNumber*)combinedPosition
{
    return nil;
}
-(NSString*)combinedName
{
    if(!self.parent){
        return self.name;
    }else{
        return [NSString stringWithFormat:@"%@:%@",self.parent.combinedName,self.name];
    }
}
@end


@interface SpecificArticleListTableViewController ()

@end

@implementation SpecificArticleListTableViewController
{
    NSArray*articleLists;
}
-(IBAction)addNew:(id)sender
{
    if([self.entityName isEqualToString:@"SimpleArticleList"]){
        [self performSegueWithIdentifier:@"AddSimpleArticleList" sender:sender];
    }else if([self.entityName isEqualToString:@"ArticleFolder"]){
        [self performSegueWithIdentifier:@"AddArticleFolder" sender:sender];
    }
}
-(void)reload{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:self.entityName inManagedObjectContext:[MOC moc]];
    [fetchRequest setEntity:entity];
    
    NSArray*a=[[MOC moc] executeFetchRequest:fetchRequest error:NULL];
    articleLists=[a sortedArrayUsingDescriptors:@[
                                                  [NSSortDescriptor sortDescriptorWithKey:@"combinedPosition" ascending:YES]
                                                  ]];
    [self.tableView reloadData];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [self reload];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return articleLists.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"default" forIndexPath:indexPath];
    SimpleArticleList*l=(SimpleArticleList*)articleLists[[indexPath indexAtPosition:1]];
    cell.textLabel.text=l.combinedName;
    cell.imageView.image =l.icon;
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation
-(IBAction)unwindFromAddFolder:(UIStoryboardSegue*)segue
{
    [[MOC moc] save:NULL];
    [self reload];
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([[segue identifier] isEqualToString:@"unwind"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        SimpleArticleList*al=articleLists[[indexPath indexAtPosition:1]];
        if(self.actionBlock){
            self.actionBlock(al);
        }
    }else if ([[segue identifier] isEqualToString:@"unwindDoingNothing"]) {
        // do nothing
    }else{
        // add folder
        UIViewController*controller = [segue destinationViewController];
        [controller setValue:nil forKey:@"parent"];
    }
}


@end

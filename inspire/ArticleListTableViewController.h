//
//  MasterViewController.h
//  inspire
//
//  Created by Yuji on 2015/08/27.
//
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class ArticleTableViewController;
@class ArticleList;
@interface ArticleListTableViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) ArticleTableViewController *detailViewController;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) ArticleList*parent;


@end


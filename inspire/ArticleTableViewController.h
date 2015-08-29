//
//  DetailViewController.h
//  inspire
//
//  Created by Yuji on 2015/08/24.
//
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
@class ArticleList;

@interface ArticleTableViewController : UITableViewController <NSFetchedResultsControllerDelegate,UISearchBarDelegate>

@property (strong, nonatomic) ArticleList* articleList;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (strong, nonatomic) UISearchBar*searchBar;
@end


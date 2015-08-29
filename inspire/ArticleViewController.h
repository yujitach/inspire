//
//  ArticleViewController.h
//  inspire
//
//  Created by Yuji on 2015/08/29.
//
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <WebKit/WebKit.h>
@class Article;
@interface ArticleViewController : UIViewController<WKNavigationDelegate>
@property (nonatomic,strong) NSFetchedResultsController*fetchedResultsController;
@property (nonatomic,strong) NSIndexPath*indexPath;
@property (nonatomic,strong) IBOutlet UIBarButtonItem*nextButton;
@property (nonatomic,strong) IBOutlet UIBarButtonItem*prevButton;
@property (nonatomic,strong) WKWebView*webView;
-(IBAction)next:(id)sender;
-(IBAction)prev:(id)sender;
@end

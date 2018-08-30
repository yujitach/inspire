//
//  AppDelegate.h
//  inspire
//
//  Created by Yuji on 2015/08/27.
//
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "AppDelegate.h"
#import "IntroViewController.h"
@class ArticleListTableViewController;
@class ArticleTableViewController;
@interface InspireAppDelegate : UIResponder <UIApplicationDelegate,AppDelegate,UIDocumentInteractionControllerDelegate,IntroDelegate>

@property (strong, nonatomic) UIWindow *window;

+(id<AppDelegate>)appDelegate;

@property (strong,nonatomic) UISplitViewController*splitViewController;
@property (strong,nonatomic) UINavigationController*masterNavigationController;
@property (strong,nonatomic) UINavigationController*detailNavigationController;
@property (strong,nonatomic) ArticleListTableViewController*articleListTableViewController;
@property (strong,nonatomic) ArticleTableViewController*articleTableViewController;
@property (strong,nonatomic) UIDocumentInteractionController*dic;

@end


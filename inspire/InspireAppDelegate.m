//
//  AppDelegate.m
//  inspire
//
//  Created by Yuji on 2015/08/27.
//
//

#import "InspireAppDelegate.h"
#import "ArticleTableViewController.h"
#import "ArticleListTableViewController.h"
#import "NSUserDefaults+defaults.h"
#import "MOC.h"
#import "ArticleList.h"

@interface InspireAppDelegate () <UISplitViewControllerDelegate>

@end

static InspireAppDelegate*globalAppDelegate=nil;


@implementation InspireAppDelegate
#pragma mark Global AppDelegate methods
+(id<AppDelegate>)appDelegate
{
    return globalAppDelegate;
}
-(void)startProgressIndicator
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}
-(void)stopProgressIndicator
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}
-(void)querySPIRES:(NSString*)search
{
    
}
-(void)postMessage:(NSString*)message
{
    
}
-(void)clearingUpAfterRegistration:(id)sender
{
    
}

#pragma mark Other pieces

+(void)initialize
{
    [NSUserDefaults loadInitialDefaults];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    globalAppDelegate=self;
    
    UISplitViewController *splitViewController = (UISplitViewController *)self.window.rootViewController;
    UINavigationController *navigationController = [splitViewController.viewControllers lastObject];
    navigationController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;
    splitViewController.delegate = self;

    
/*
    UINavigationController *masterNavigationController = splitViewController.viewControllers[0];
    MasterViewController *controller = (MasterViewController *)masterNavigationController.topViewController;
*/
    [ArticleList createStandardArticleLists];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [[MOC moc] save:NULL];
}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    return NO;
    // should return YES if the detail view needs to be discarded
}

@end

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
#import "DumbOperation.h"
#import "SpiresQueryOperation.h"
#import "SpiresHelper.h"
#import "ArticleList.h"
#import "AllArticleList.h"
#import "Article.h"
#import "PDFHelper.h"
#import "SyncManager.h"

@interface InspireAppDelegate () <UISplitViewControllerDelegate>

@end

static InspireAppDelegate*globalAppDelegate=nil;


@implementation InspireAppDelegate
{
    SyncManager*syncManager;
}
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
    if(!search)return;
    NSPredicate*pred=[[SpiresHelper sharedHelper] predicateFromSPIRESsearchString:search];
    if(!pred)return;
    [self selectAllArticleList];
    [AllArticleList allArticleList].searchString=search;
    [[OperationQueues spiresQueue] addOperation:[[SpiresQueryOperation alloc] initWithQuery:search andMOC:[MOC moc]]];
}
-(void)postMessage:(NSString*)message
{
    
}
-(void)clearingUpAfterRegistration:(id)sender
{
    
}
-(BOOL)currentListIsArxivReplaced
{
    return NO;
}
-(UIViewController*)presentingViewController
{
    return self.splitViewController;
}
#pragma mark PDF
-(void)setupPDFdir
{
    NSURL*docDirURL=[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSString*docDir=[docDirURL path];
    NSString*dir=[docDir stringByAppendingPathComponent:@"pdf"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:NULL];
    [[NSUserDefaults standardUserDefaults] setObject:dir forKey:@"pdfDir"];
}
#pragma clang diagnostic ignored "-Wdeprecated"
-(NSString*)extractArXivID:(NSString*)x
{
    NSString*s=[x stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if(s==nil)return @"";
    if([s isEqualToString:@""])return @"";
    //    NSLog(@"%@",s);
    NSRange r=[s rangeOfString:@"/" options:NSBackwardsSearch];
    if(r.location!=NSNotFound){
        s=[s substringFromIndex:r.location+1];
    }
    if(s==nil)return @"";
    if([s isEqualToString:@""])return @"";
    
    NSScanner*scanner=[NSScanner scannerWithString:s];
    NSCharacterSet*set=[NSCharacterSet characterSetWithCharactersInString:@".0123456789"];
    [scanner scanUpToCharactersFromSet:set intoString:NULL];
    NSString* d=nil;
    [scanner scanCharactersFromSet:set intoString:&d];
    if(d){
        if([d hasSuffix:@"."]){
            d=[d substringToIndex:[d length]-1];
        }
        for(NSString*cat in @[@"hep-th",@"hep-ph",@"hep-ex",@"hep-lat",@"astro-ph",@"math-ph",@"math"]){
            if([x rangeOfString:cat].location!=NSNotFound){
                d=[NSString stringWithFormat:@"%@/%@",cat,d];
                break;
            }
        }
        return d;
    }
    else return nil;
}
-(void)handleURL:(NSURL*) url
{
    //    NSLog(@"handles %@",url);
    if([[url scheme] isEqualToString:@"spires-search"]){
        NSString*searchString=[[[url absoluteString] substringFromIndex:[(NSString*)@"spires-search://" length]] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        AllArticleList*allArticleList=[AllArticleList allArticleList];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"newSearchInitiated" object:nil];
//        if(![allArticleList.searchString isEqualToString:searchString]){
//            [historyController mark:self];
//        }
        allArticleList.searchString=searchString;
//        [historyController mark:self];
        [self querySPIRES:searchString];
    }else if([[url scheme] isEqualToString:@"spires-open-pdf-internal"]){
        NSString*x=[url absoluteString];
        NSString*y=[x substringFromIndex:[@"spires-open-pdf-internal://" length]];
        y=[y stringByReplacingOccurrencesOfString:@"x-coredata//" withString:@"x-coredata://"];
        NSURL*z=[NSURL URLWithString:y];
        Article*a=(Article*)[[MOC moc] objectRegisteredForID:[[MOC moc].persistentStoreCoordinator managedObjectIDForURIRepresentation:z]];
        [[PDFHelper sharedHelper] openPDFforArticle:a usingViewer:openWithPrimaryViewer];
    }else if([[url scheme] isEqualToString:@"spires-flag"]){
        NSString*x=[url absoluteString];
        NSString*y=[x substringFromIndex:[@"spires-flag://" length]];
        y=[y stringByReplacingOccurrencesOfString:@"x-coredata//" withString:@"x-coredata://"];
        NSURL*z=[NSURL URLWithString:y];
        Article*a=(Article*)[[MOC moc] objectRegisteredForID:[[MOC moc].persistentStoreCoordinator managedObjectIDForURIRepresentation:z]];
       [a setFlag: a.flag | AFIsFlagged];
        [[MOC moc] save:NULL];
    }else if([[url scheme] isEqualToString:@"spires-unflag"]){
        NSString*x=[url absoluteString];
        NSString*y=[x substringFromIndex:[@"spires-unflag://" length]];
        y=[y stringByReplacingOccurrencesOfString:@"x-coredata//" withString:@"x-coredata://"];
        NSURL*z=[NSURL URLWithString:y];
        Article*a=(Article*)[[MOC moc] objectRegisteredForID:[[MOC moc].persistentStoreCoordinator managedObjectIDForURIRepresentation:z]];
        [a setFlag: a.flag & ~AFIsFlagged];
        [[MOC moc] save:NULL];
    }else if([[url scheme] isEqualToString:@"spires-lookup-eprint"]){
        NSString*eprint=[self extractArXivID:[url absoluteString]];
        if(eprint){
            NSString*searchString=[@"spires-search://eprint%20" stringByAppendingString:eprint];
            [self performSelector:@selector(handleURL:)
                       withObject:[NSURL URLWithString:searchString]
                       afterDelay:.5];
        }
    }else if([[url scheme] isEqualToString:@"spires-open-journal"]){
//        [self openJournal:self];
    }else if([[url scheme] isEqualToString:@"http"]){
        [[UIApplication sharedApplication] openURL:url];
    }
}
#pragma mark Other pieces

+(void)initialize
{
    [NSUserDefaults loadInitialDefaults];
}

-(void)selectAllArticleList
{
//    [self.articleListTableViewController.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    self.articleTableViewController.articleList=[AllArticleList allArticleList];
    if(self.articleTableViewController != self.articleTableViewController.navigationController.visibleViewController){
        [self.articleListTableViewController performSegueWithIdentifier:@"ShowDetail" sender:self];
    }
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    globalAppDelegate=self;

    [ArticleList createStandardArticleListsInMOC:[MOC moc]];
    [self setupPDFdir];

    self.splitViewController = (UISplitViewController *)self.window.rootViewController;
    self.splitViewController.delegate = self;

    self.masterNavigationController=self.splitViewController.viewControllers[0];
    self.articleListTableViewController=(ArticleListTableViewController*)self.masterNavigationController.topViewController;
    self.articleListTableViewController.parent=nil;
    
    self.detailNavigationController=self.splitViewController.viewControllers[1];
    self.articleTableViewController=(ArticleTableViewController*)self.detailNavigationController.topViewController;
    
    self.articleTableViewController.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.articleTableViewController.navigationItem.leftItemsSupplementBackButton = YES;

    
    [self selectAllArticleList];
    
    syncManager=[[SyncManager alloc] init];
    
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

- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController {
    return self.masterNavigationController;
}
- (UIViewController *)primaryViewControllerForExpandingSplitViewController:(UISplitViewController *)splitViewController {
    return self.masterNavigationController;
}
- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    return YES;
}
- (UIViewController *)splitViewController:(UISplitViewController *)splitViewController separateSecondaryViewControllerFromPrimaryViewController:(UIViewController *)primaryViewController {
    self.articleTableViewController.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.articleTableViewController.navigationItem.leftItemsSupplementBackButton = YES;

    return self.detailNavigationController;
}
@end

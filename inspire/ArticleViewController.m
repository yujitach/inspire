//
//  ArticleViewController.m
//  inspire
//
//  Created by Yuji on 2015/08/29.
//
//

#import "ArticleViewController.h"
#import "ArticleTableViewController.h"
#import "Article.h"
#import "RegexKitLite.h"
#import "HTMLArticleHelper.h"
#import "AppDelegate.h"
#import "AbstractRefreshManager.h"
#import "DumbOperation.h"
#import "SpecificArticleListTableViewController.h"
#import "ArticleList.h"
#import "MOC.h"
#import "MergeNotifyingBarButtonItem.h"


@implementation ArticleViewController
{
    NSMutableDictionary*handlerDic;
    UIBarButtonItem*pdfButton;
    UIBarButtonItem*otherButton;
    NSProgress*progress;
    BOOL pdfShown;
    BOOL restoringPDF;
}
@synthesize indexPath=_indexPath;
-(BOOL)isMyURL:(NSURL*)url
{
    Article*a=[self.fetchedResultsController objectAtIndexPath:self.indexPath];
    return [a.pdfPath.lastPathComponent containsString:url.lastPathComponent];
}
-(void)pdfPreviewStarted:(NSNotification*)n
{
    pdfShown=YES;
}
-(void)pdfPreviewEnded:(NSNotification*)n
{
    pdfShown=NO;
}
-(void)pdfDownloadStarted:(NSNotification*)n
{
    pdfButton.enabled=NO;
}
-(void)pdfDownloadFinished:(NSNotification*)n
{
    NSDictionary*dic=(NSDictionary*)n.object;
    if([self isMyURL:dic[@"url"]]){
        pdfButton.title=@"show pdf";
        pdfButton.enabled=YES;
    }
}
-(void)pdfDownloadProgress:(NSNotification*)n
{
    NSDictionary*dic=(NSDictionary*)n.object;
    if([self isMyURL:dic[@"url"]]){
        NSNumber*num=dic[@"fractionCompleted"];
        int percent=100*(num.doubleValue);
        pdfButton.title=[NSString stringWithFormat:@"download pdf (%@%%)",@(percent)];
        pdfButton.enabled=NO;
    }
}
-(void)mocSaved:(NSNotification*)n
{
    [self performSelectorOnMainThread:@selector(refresh) withObject:nil waitUntilDone:NO];
}
-(void)newSearchInitiated:(NSNotification*)n
{
    [self performSegueWithIdentifier:@"unwind" sender:nil];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    handlerDic=[NSMutableDictionary dictionary];
    self.webView=[[WKWebView alloc] init];
    self.webView.navigationDelegate=self;
    self.view=self.webView;
    pdfButton=            [[UIBarButtonItem alloc]  initWithTitle:@"pdf"
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(pdf:)
                           ];
    otherButton=          [[MergeNotifyingBarButtonItem alloc]  initWithTitle:@"menu"
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(other:)
                           ];
    self.toolbarItems=@[
                        pdfButton,
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                        otherButton,
            ];
    
    
//    [self.webView addSubview:self.progressView];
//    [self.progressView sizeToFit];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pdfPreviewStarted:) name:@"pdfPreviewStarted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pdfPreviewEnded:) name:@"pdfPreviewEnded" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pdfDownloadStarted:) name:@"pdfDownloadStarted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pdfDownloadFinished:) name:@"pdfDownloadFinished" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pdfDownloadProgress:) name:@"pdfDownloadProgress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mocSaved:) name:NSManagedObjectContextDidSaveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newSearchInitiated:) name:@"newSearchInitiated" object:nil];
    // [self refresh];
    // Do any additional setup after loading the view.
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:animated];
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refresh];
    if(restoringPDF){
        [self pdf:nil];
        restoringPDF=NO;
    }
}
-(void)viewWillDisappear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:animated];
    [super viewWillDisappear:animated];
}
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
        // Place code here to perform animations during the rotation.
        // You can pass nil or leave this block empty if not necessary.
        
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
 
        [self refresh];
        
    }];
}
-(void)setIndexPath:(NSIndexPath *)indexPath
{
    _indexPath=indexPath;
    [self refresh];
}
-(NSIndexPath*)indexPath
{
    return _indexPath;
}
-(NSIndexPath*)indexPathWithDelta:(NSInteger)x
{
    return [self.indexPath.indexPathByRemovingLastIndex indexPathByAddingIndex:[self.indexPath indexAtPosition:1]+x];
}
-(void)refresh
{
    NSUInteger i=[self.indexPath indexAtPosition:1];
    NSUInteger total=self.fetchedResultsController.fetchedObjects.count;
    if(i>0){
        self.prevButton.enabled=YES;
    }else{
        self.prevButton.enabled=NO;
    }
    if(i<total-1){
        self.nextButton.enabled=YES;
    }else{
        self.nextButton.enabled=NO;
    }
    self.navigationItem.title=[NSString stringWithFormat:@"%@ of %@",@(i+1),@(total)];
    Article*a=[self.fetchedResultsController objectAtIndexPath:self.indexPath];
    if(a){
        [[AbstractRefreshManager sharedAbstractRefreshManager] refreshAbstractOfArticle:a whenRefreshed:^(Article *refreshedArticle) {
            [self refresh];
        }];
        NSString*template=[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"template-ios"
                                                                                                       ofType:@"html"]
                                                              encoding:NSUTF8StringEncoding
                                                                 error:NULL];
        NSMutableString*html=[template mutableCopy];
        
        UIFontDescriptor* fontDesc = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
        NSString* fontSize=[@(fontDesc.pointSize) stringValue];
        [html replaceOccurrencesOfRegex:@"#fontSize#" withString:fontSize];
        
        NSString* width=[@(self.webView.bounds.size.width) stringValue];
        [html replaceOccurrencesOfRegex:@"#width#" withString:width];
        
        
        HTMLArticleHelper* helper=[[HTMLArticleHelper alloc] initWithArticle:a];
        for(NSString*key in @[@"abstract",@"arxivCategory",@"authors",@"comments",@"eprint",
                             @"journal",@"flagged",@"title",@"spires"]){
            NSString*value=[helper valueForKey:key];
            if(!value){
                value=@"";
            }
            [html replaceOccurrencesOfRegex:[NSString stringWithFormat:@"id=\"%@\">",key] withString:[NSString stringWithFormat:@"id=\"%@\">%@",key,value]];
            [self.webView loadHTMLString:html baseURL:nil];
        }
        for(NSString*key in @[@"flagUnflag",@"pdfPath",@"citedBy",@"refersTo",@"spires"]){
            NSURL*u=nil;
            NSString*value=[helper valueForKey:key];
            if(!value || [value hasPrefix:@"<del>"]){
                u=[NSURL URLWithString:@"foo://"];
            }else{
                NSString*s=[value stringByMatching:@"href=\"(.+?)\"" capture:1];
                NSString*ss=[s stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                u=[NSURL URLWithString:ss];
            }
            handlerDic[key]=u;
        }
        {
            Article*x=[self.fetchedResultsController objectAtIndexPath:self.indexPath];
            if(x.hasPDFLocally){
                pdfButton.enabled=YES;
                pdfButton.title=@"show pdf";
            }else if(!x.isEprint){
                pdfButton.enabled=YES;
                pdfButton.title=@"inspire page";
            }else if(!([OperationQueues arxivQueue].isOnline)){
                pdfButton.enabled=NO;
                pdfButton.title=@"pdf";
            }else{
                pdfButton.enabled=YES;
                pdfButton.title=@"download pdf";
            }
        }
    }
    if(i+1<total){
        Article*b=[self.fetchedResultsController objectAtIndexPath:[self indexPathWithDelta:+1]];
        if(b){
            [[AbstractRefreshManager sharedAbstractRefreshManager] refreshAbstractOfArticle:b
                                                                              whenRefreshed:nil];
        }
    }
    if(i+2<total){
        Article*b=[self.fetchedResultsController objectAtIndexPath:[self indexPathWithDelta:+2]];
        if(b){
            [[AbstractRefreshManager sharedAbstractRefreshManager] refreshAbstractOfArticle:b
                                                                              whenRefreshed:nil];
        }
    }
    if(i>0){
        Article*b=[self.fetchedResultsController objectAtIndexPath:[self indexPathWithDelta:-1]];
        if(b){
            [[AbstractRefreshManager sharedAbstractRefreshManager] refreshAbstractOfArticle:b
                                                                              whenRefreshed:nil];
        }
    }
    if(i>1){
        Article*b=[self.fetchedResultsController objectAtIndexPath:[self indexPathWithDelta:-2]];
        if(b){
            [[AbstractRefreshManager sharedAbstractRefreshManager] refreshAbstractOfArticle:b
                                                                              whenRefreshed:nil];
        }
    }
}
-(IBAction)pdf:(id)sender;
{
    Article*x=[self.fetchedResultsController objectAtIndexPath:self.indexPath];
    if(x.isEprint){
        NSURL*u=handlerDic[@"pdfPath"];
        [[NSApp appDelegate] handleURL:u];
    }else{
        NSURL*u=handlerDic[@"spires"];
        [[NSApp appDelegate] handleURL:u];
    }
}
-(IBAction)citedBy:(id)sender;
{
    NSURL*u=handlerDic[@"citedBy"];
    [[NSApp appDelegate] handleURL:u];
}
-(IBAction)refersTo:(id)sender;
{
    NSURL*u=handlerDic[@"refersTo"];
    [[NSApp appDelegate] handleURL:u];
}
-(IBAction)flag:(id)sender;
{
    NSURL*u=handlerDic[@"flagUnflag"];
    [[NSApp appDelegate] handleURL:u];
}

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if(navigationAction.navigationType==WKNavigationTypeLinkActivated){
        decisionHandler(WKNavigationActionPolicyCancel);
        [[NSApp appDelegate] handleURL:navigationAction.request.URL];
    }else{
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)next:(id)sender
{
    NSUInteger i=[self.indexPath indexAtPosition:1];
    if(i<self.fetchedResultsController.fetchedObjects.count-1){
        self.indexPath=[self indexPathWithDelta:+1];
        [self refresh];
    }
}
-(IBAction)prev:(id)sender
{
    NSUInteger i=[self.indexPath indexAtPosition:1];
    if(i>0){
        self.indexPath=[self indexPathWithDelta:-1];
        [self refresh];
    }
}
-(IBAction)addTo:(id)sender
{
    [self performSegueWithIdentifier:@"AddTo" sender:nil];
}
-(IBAction)other:(id)sender
{
    UIAlertController*ac=[UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction*c=[UIAlertAction actionWithTitle:@"cited by" style:UIAlertActionStyleDefault handler:^(UIAlertAction*aa){[self citedBy:nil];}];
    UIAlertAction*r=[UIAlertAction actionWithTitle:@"refers to" style:UIAlertActionStyleDefault handler:^(UIAlertAction*aa){[self refersTo:nil];}];

    Article*a=[self.fetchedResultsController objectAtIndexPath:self.indexPath];
    NSString*x=(a.flag&AFIsFlagged)?@"unflag":@"flag";
    UIAlertAction*f=[UIAlertAction actionWithTitle:x style:UIAlertActionStyleDefault handler:^(UIAlertAction*aa){[self flag:nil];}];

    UIAlertAction*t=[UIAlertAction actionWithTitle:@"add to a list..." style:UIAlertActionStyleDefault handler:^(UIAlertAction*aa){[self addTo:nil];}];

    UIAlertAction*cancel=[UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:nil];

    
    [ac addAction:c];
    [ac addAction:r];
    [ac addAction:f];
    [ac addAction:t];
    [ac addAction:cancel];
    
    ac.popoverPresentationController.barButtonItem=otherButton;
    
    [self presentViewController:ac animated:YES completion:nil];
}

#pragma mark - state restoration
-(void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    Article*a=[self.fetchedResultsController objectAtIndexPath:self.indexPath];
    [[MOC moc] encodeObject:a toCoder:coder forKey:@"article"];
    [coder encodeBool:pdfShown forKey:@"pdfShown"];
    [super encodeRestorableStateWithCoder:coder];
}
-(void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    NSArray*a=self.navigationController.viewControllers;
    ArticleTableViewController*vc=(ArticleTableViewController*)a[a.count-2];
    self.fetchedResultsController=vc.fetchedResultsController;
    
    Article*ar=(Article*)[[MOC moc] decodeFromCoder:coder forKey:@"article"];
    if(ar){
        NSIndexPath*ip=[self.fetchedResultsController indexPathForObject:ar];
        if(ip){
            self.indexPath=ip;
        }else{
            self.indexPath=[NSIndexPath indexPathForRow:0 inSection:0];
        }
    }
    restoringPDF=[coder decodeBoolForKey:@"pdfShown"];
    [super decodeRestorableStateWithCoder:coder];
}
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([[segue identifier] isEqualToString:@"AddTo"]){
        UINavigationController*nc=(UINavigationController*)[segue destinationViewController];
        nc.popoverPresentationController.barButtonItem=otherButton;
        SpecificArticleListTableViewController*vc=(SpecificArticleListTableViewController*)nc.topViewController;
        vc.entityName=@"SimpleArticleList";
        vc.parent=nil;
        Article*a=[self.fetchedResultsController objectAtIndexPath:self.indexPath];
        vc.actionBlock=^(ArticleList*al){
            [al addArticlesObject:a];
        };
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end

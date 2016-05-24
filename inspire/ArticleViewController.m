//
//  ArticleViewController.m
//  inspire
//
//  Created by Yuji on 2015/08/29.
//
//

#import "ArticleViewController.h"
#import "Article.h"
#import "RegexKitLite.h"
#import "HTMLArticleHelper.h"
#import "AppDelegate.h"
#import "AbstractRefreshManager.h"
@interface ArticleViewController ()

@end

@implementation ArticleViewController
@synthesize indexPath=_indexPath;
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if([keyPath isEqualToString:@"fractionCompleted"]){
        NSNumber*n=change[NSKeyValueChangeNewKey];
        [self.progressView setProgress:[n floatValue] animated:YES];
    }
}
-(void)pdfDownloadStarted:(NSNotification*)n
{
    NSProgress*progress=(NSProgress*)n.object;
    self.progressView.hidden=NO;
    [progress addObserver:self forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionNew context:NULL];
}
-(void)pdfDownloadFinished:(NSNotification*)n
{
    NSProgress*progress=(NSProgress*)n.object;
    self.progressView.hidden=YES;
    [progress removeObserver:self forKeyPath:@"fractionCompleted"];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.webView=[[WKWebView alloc] init];
    self.webView.navigationDelegate=self;
    self.view=self.webView;
    
    self.progressView=[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.translatesAutoresizingMaskIntoConstraints=NO;
    [self.navigationController.view addSubview:self.progressView];
    UINavigationBar *navBar = self.navigationController.navigationBar;
    
    NSLayoutConstraint *constraint;
    constraint = [NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:navBar attribute:NSLayoutAttributeBottom multiplier:1 constant:-0.5];
    [self.navigationController.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:navBar attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
    [self.navigationController.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.progressView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:navBar attribute:NSLayoutAttributeRight multiplier:1 constant:0];
    [self.navigationController.view addConstraint:constraint];
    self.progressView.hidden=YES;
//    [self.webView addSubview:self.progressView];
//    [self.progressView sizeToFit];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pdfDownloadStarted:) name:@"pdfDownloadStarted" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pdfDownloadFinished:) name:@"pdfDownloadFinished" object:nil];
    // [self refresh];
    // Do any additional setup after loading the view.
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self refresh];
}
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Code here will execute before the rotation begins.
    // Equivalent to placing it in the deprecated method -[willRotateToInterfaceOrientation:duration:]
    
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
                              @"journal",@"pdfPath",@"title",@"spires",@"citedBy",@"refersTo"]){
            NSString*value=[helper valueForKey:key];
            if(!value){
                value=@"";
            }
            [html replaceOccurrencesOfRegex:[NSString stringWithFormat:@"id=\"%@\">",key] withString:[NSString stringWithFormat:@"id=\"%@\">%@",key,value]];
            [self.webView loadHTMLString:html baseURL:nil];
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
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

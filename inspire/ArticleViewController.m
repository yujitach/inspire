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
@interface ArticleViewController ()

@end

@implementation ArticleViewController
@synthesize indexPath=_indexPath;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.webView=[[WKWebView alloc] init];
    self.webView.navigationDelegate=self;
    self.view=self.webView;
    [self refresh];
    // Do any additional setup after loading the view.
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
        NSString*template=[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"template-ios"
                                                                                                       ofType:@"html"]
                                                              encoding:NSUTF8StringEncoding
                                                                 error:NULL];
        NSMutableString*html=[template mutableCopy];
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
        i++;
        self.indexPath=[self.indexPath.indexPathByRemovingLastIndex indexPathByAddingIndex:i];
        [self refresh];
    }
}
-(IBAction)prev:(id)sender
{
    NSUInteger i=[self.indexPath indexAtPosition:1];
    if(i>0){
        i--;
        self.indexPath=[self.indexPath.indexPathByRemovingLastIndex indexPathByAddingIndex:i];
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

//
//  AddCannedSearchViewController.m
//  inspire
//
//  Created by Yuji on 2015/08/30.
//
//

#import "AddCannedSearchViewController.h"
#import "CannedSearch.h"
#import "AllArticleList.h"
#import "MOC.h"

@implementation AddCannedSearchViewController
-(IBAction)create:(id)sender
{
    ArticleList*al=[CannedSearch createCannedSearchWithName:self.textField.text inMOC:[MOC moc]];
    al.parent=self.parent;
    al.positionInView=@1000;
    AllArticleList*allArticleList=[AllArticleList allArticleList];
    al.searchString=self.searchTextField.text;
    al.sortDescriptors=allArticleList.sortDescriptors;
    [ArticleList rearrangePositionInViewInMOC:[MOC moc]];
    [self performSegueWithIdentifier:@"unwind" sender:self];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    AllArticleList*allArticleList=[AllArticleList allArticleList];
    self.searchTextField.text=allArticleList.searchString;
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

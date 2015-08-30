//
//  AddSimpleArticleListViewController.m
//  inspire
//
//  Created by Yuji on 2015/08/30.
//
//

#import "AddSimpleArticleListViewController.h"
#import "SimpleArticleList.h"
#import "MOC.h"
@interface AddSimpleArticleListViewController ()

@end

@implementation AddSimpleArticleListViewController
-(IBAction)create:(id)sender
{
    ArticleList*al=[SimpleArticleList createSimpleArticleListWithName:self.textField.text inMOC:[MOC moc]];
    al.parent=self.parent;
    al.positionInView=@1000;
    [ArticleList rearrangePositionInView];
    [self performSegueWithIdentifier:@"unwind" sender:self];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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

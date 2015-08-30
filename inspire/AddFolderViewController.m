//
//  AddFolderViewController.m
//  inspire
//
//  Created by Yuji on 2015/08/30.
//
//

#import "AddFolderViewController.h"
#import "AddArxivNewContoller.h"
#import "AddArticleFolderViewController.h"
#import "AddCannedSearchViewController.h"
#import "AddSimpleArticleListViewController.h"
@implementation AddFolderViewController
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UIViewController*controller = [segue destinationViewController];
    [controller setValue:self.parent forKey:@"parent"];
}
@end

//
//  AddArticleFodlerViewController.h
//  inspire
//
//  Created by Yuji on 2015/08/30.
//
//

#import <UIKit/UIKit.h>
@class ArticleList;
@interface AddArticleFolderViewController : UIViewController
@property (strong,nonatomic) ArticleList*parent;
@property (strong,nonatomic) IBOutlet UITextField*textField;
-(IBAction)create:(id)sender;

@end

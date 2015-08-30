//
//  AddCannedSearchViewController.h
//  inspire
//
//  Created by Yuji on 2015/08/30.
//
//

#import <UIKit/UIKit.h>
@class ArticleList;
@interface AddCannedSearchViewController : UIViewController
@property (strong,nonatomic) ArticleList*parent;
@property (strong,nonatomic) IBOutlet UITextField*textField;
@property (strong,nonatomic) IBOutlet UITextField*searchTextField;
-(IBAction)create:(id)sender;

@end

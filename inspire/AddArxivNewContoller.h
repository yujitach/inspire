//
//  AddArxivNewContoller.h
//  inspire
//
//  Created by Yuji on 2015/08/30.
//
//

#import <UIKit/UIKit.h>
@class ArticleList;
@interface AddArxivNewContoller : UIViewController<UIPickerViewDataSource,UIPickerViewDelegate>
@property (strong,nonatomic) ArticleList*parent;
@property (strong,nonatomic) IBOutlet UITextField*textField;
-(IBAction)create:(id)sender;
@property (strong,nonatomic) IBOutlet UIPickerView*pickerView;
@end

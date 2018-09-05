//
//  IntroViewController.h
//  inspire
//
//  Created by Yuji on 2018/08/30.
//

#import <UIKit/UIKit.h>

@protocol IntroDelegate
-(void)closed:(id)sender;
@end


@interface IntroViewController : UIViewController
@property (nonatomic,strong) IBOutlet UITextView*tv;
@property (nonatomic,strong) IBOutlet UIBarButtonItem*doneButton;
@property (nonatomic,strong) IBOutlet UIToolbar*toolBar;
@property (nonatomic,weak) id<IntroDelegate> delegate;
@end


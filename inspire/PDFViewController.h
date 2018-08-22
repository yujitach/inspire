//
//  PDFViewController.h
//  inspire
//
//  Created by Yuji on 2018/08/22.
//

#import <UIKit/UIKit.h>

@protocol MyPDFViewControllerDelegate
-(void)simplyClosed;
-(void)sendingFileTo:(NSString*)application;
-(void)fileSentTo:(NSString*)application;
@end

@interface MyPDFViewController : UIViewController<UIDocumentInteractionControllerDelegate>
@property NSURL*pdfURL;
@property NSObject<MyPDFViewControllerDelegate>*delegate;
@end

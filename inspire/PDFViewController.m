//
//  PDFViewController.m
//  inspire
//
//  Created by Yuji on 2018/08/22.
//

@import PDFKit;
#import "PDFViewController.h"

@interface MyPDFViewController ()

@end

@implementation MyPDFViewController
{
IBOutlet    PDFView*pdfView;
    IBOutlet    PDFThumbnailView*pdfThumbnailView;
    IBOutlet UIBarButtonItem*openInItem;
    UIDocumentInteractionController*documentInteractionContoller;

}
-(instancetype)init
{
    self=[super initWithNibName:@"PDFViewController" bundle:nil];
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    pdfView.document=[[PDFDocument alloc] initWithURL:self.pdfURL];
    pdfThumbnailView.PDFView=pdfView;
    pdfThumbnailView.layoutMode=PDFThumbnailLayoutModeVertical;
    pdfThumbnailView.thumbnailSize=CGSizeMake(55, 100);
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)done:(id)sender
{
    [self.delegate simplyClosed];
}
-(IBAction)open:(id)sender
{
    documentInteractionContoller=[[UIDocumentInteractionController alloc] init];
    documentInteractionContoller.URL=self.pdfURL;
    documentInteractionContoller.delegate=self;
    [documentInteractionContoller presentOpenInMenuFromBarButtonItem:openInItem animated:NO];
}
-(void)documentInteractionController:(UIDocumentInteractionController *)controller willBeginSendingToApplication:(NSString *)application
{
    [self.delegate sendingFileTo:application];
}
-(void)documentInteractionController:(UIDocumentInteractionController *)controller didEndSendingToApplication:(NSString *)application
{
    [self.delegate fileSentTo:application];
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

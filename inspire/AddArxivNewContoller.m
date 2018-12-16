//
//  AddArxivNewContoller.m
//  inspire
//
//  Created by Yuji on 2015/08/30.
//
//

#import "AddArxivNewContoller.h"
#import "MOC.h"
#import "ArxivNewArticleList.h"
@implementation AddArxivNewContoller
-(void)viewDidLoad
{
    [super viewDidLoad];
    self.pickerView.dataSource=self;
    self.pickerView.delegate=self;
}
-(NSArray*)content
{
    return @[@"new",@"recent",@"replaced",@"cross-list"];
}
-(IBAction)create:(id)sender
{
    NSString*name=[NSString stringWithFormat:@"%@/%@", self.textField.text,self.content[[self.pickerView selectedRowInComponent:0]]];
    ArticleList*al=[ArxivNewArticleList createArXivNewArticleListWithName:name inMOC:[MOC moc]];
    al.parent=self.parent;
    al.positionInView=@1000;
    [ArticleList rearrangePositionInViewInMOC:[MOC moc]];
    [self performSegueWithIdentifier:@"unwind" sender:self];
}
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}
-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self content].count;
}
-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self content][row];
}
@end

//
//  IntroViewController.m
//  inspire
//
//  Created by Yuji on 2018/08/30.
//

#import "IntroViewController.h"
#import "MergeNotifyingBarButtonItem.h"

@implementation IntroViewController
{
    NSTimer*timer;
    BOOL initialMergeDone;
}
-(instancetype)init
{
    self=[super initWithNibName:@"IntroViewController" bundle:nil];
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSURL* url=[[NSBundle mainBundle] URLForResource:@"intro" withExtension:@"rtfd"];
    NSMutableAttributedString*s=[[NSMutableAttributedString alloc] initWithURL:url options:@{} documentAttributes:nil error:nil];
    if(@available(iOS 13,*)){
        [s addAttribute:NSForegroundColorAttributeName value:[UIColor labelColor] range:NSMakeRange(0, s.length)];
    }
    self.tv.attributedText=s;
    timer=[NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timerr) {
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"initialMergeDone"]){
            [self initialMergeDone:nil];
        }
    }];
    self.doneButton=[[MergeNotifyingBarButtonItem alloc] initWithTitle:@"OK" style:UIBarButtonItemStylePlain target:self action:@selector(close:)];
    self.toolBar.items=@[self.doneButton];
}
-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.tv.contentOffset=CGPointZero;
}
-(void)initialMergeDone:(NSNotification*)n
{
    initialMergeDone=YES;
    [timer invalidate];
    self.doneButton.enabled=YES;
    self.doneButton.title=@"OK";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)close:(id)sender
{
    [self.delegate closed:sender];
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

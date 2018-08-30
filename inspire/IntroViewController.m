//
//  IntroViewController.m
//  inspire
//
//  Created by Yuji on 2018/08/30.
//

#import "IntroViewController.h"

@interface IntroViewController ()

@end

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
    NSAttributedString*s=[[NSAttributedString alloc] initWithURL:url options:@{} documentAttributes:nil error:nil];
    self.tv.attributedText=s;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(merging:) name:@"merging" object:nil];
    self.doneButton.enabled=NO;
    self.doneButton.title=@"initializing...";
    timer=[NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timerr) {
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"initialMergeDone"]){
            [self initialMergeDone:nil];
        }
    }];
}
-(void)merging:(NSNotification*)n
{
    if(initialMergeDone)
        return;
    NSString*target=n.object;
    self.doneButton.enabled=NO;
    self.doneButton.title=[NSString stringWithFormat:@"merging from %@ ...",target];
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

//
//  MergeNotifyingBarButtonItem.m
//  inspire
//
//  Created by Yuji on 2018/09/05.
//

#import "MergeNotifyingBarButtonItem.h"

@implementation MergeNotifyingBarButtonItem
{
    NSString*savedTitle;
}
-(instancetype)init
{
    self=[super init];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willMerge:) name:@"willMerge" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doMerge:) name:@"doMerge" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didMerge:) name:@"didMerge" object:nil];
    return self;
}
-(void)setTitle:(NSString *)title
{
    savedTitle=title;
    NSString*target=[[NSUserDefaults standardUserDefaults] objectForKey:@"mergingFrom"];
    if(target){
        [super setTitle:[NSString stringWithFormat:@"syncing %@",target]];
    }else{
        [super setTitle:title];
    }
}
-(void)willMerge:(NSNotification*)n
{
    NSString*target=n.object;
    [super setTitle:[NSString stringWithFormat:@"syncing %@ ",target]];
}
-(void)doMerge:(NSNotification*)n
{
    [super setTitle:[NSString stringWithFormat:@"merging data"]];
}
-(void)didMerge:(NSNotification*)n
{
    [super setTitle:savedTitle];
}
@end

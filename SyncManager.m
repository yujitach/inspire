//
//  SyncManager.m
//  inspire
//
//  Created by Yuji on 2015/08/11.
//
//

#import "SyncManager.h"

@implementation SyncManager
{
    DirWatcher*dw;
    NSTimer*archiveTimer;
    NSDictionary*lastSavedSnapshot;
    NSString*listsSyncFolder;
}
-(instancetype)init
{
    self=[super init];
    listsSyncFolder=[[NSUserDefaults standardUserDefaults] stringForKey:@"listsSyncFolder"];
    if(listsSyncFolder){
        dw=[[DirWatcher alloc] initWithPath:listsSyncFolder delegate:self];
        NSTimeInterval interval=10;
        archiveTimer=[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(archiveTimerFired:) userInfo:nil repeats:YES];
        if([archiveTimer respondsToSelector:@selector(setTolerance:)]){
            [archiveTimer setTolerance:.1*interval];
        }
    }
    return self;
}
-(NSDictionary*)snapShot
{
    return nil;
}
-(void)loadSnapshot:(NSDictionary*)snapShot
{
    
}
-(void)archiveTimerFired:(NSTimer*)timer
{
    NSDictionary*snapShot=[self snapShot];
    if(snapShot && ![snapShot isEqual:lastSavedSnapshot]){
        lastSavedSnapshot=snapShot;
        NSString*fileName=[listsSyncFolder stringByAppendingPathComponent:@"inspireSidebarContents.plist"];
        NSData*data=[NSPropertyListSerialization dataWithPropertyList:lastSavedSnapshot format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
        [data writeToFile:fileName atomically:NO];
    }
}
-(void)modifiedFileAtPath:(NSString *)file
{
    if([file hasSuffix:@"inspireSidebarContents.plist"]){
        NSData*data=[NSData dataWithContentsOfFile:file];
        NSDictionary*snapShot=[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:NULL];
        if(snapShot && ![lastSavedSnapshot isEqual:snapShot]){
            [self loadSnapshot:snapShot];
            lastSavedSnapshot=snapShot;
        }
    }
}
@end

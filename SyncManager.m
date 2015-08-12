//
//  SyncManager.m
//  inspire
//
//  Created by Yuji on 2015/08/11.
//
//

#import "SyncManager.h"
#import "MOC.h"
#import "ArticleListArchiveAdditions.h"
#import "AppDelegate.h"
#import <SystemConfiguration/SystemConfiguration.h>

#define SAVEFILENAME @"inspireSidebarContents.plist"
@implementation SyncManager
{
    DirWatcher*dw;
    NSTimer*archiveTimer;
    NSDictionary*lastSavedSnapshot;
    NSString*listsSyncFolder;
}
-(void)setupTimer_
{
    NSTimeInterval interval=60;
    archiveTimer=[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(archiveTimerFired:) userInfo:nil repeats:YES];
    if([archiveTimer respondsToSelector:@selector(setTolerance:)]){
        [archiveTimer setTolerance:.1*interval];
    }
}
-(void)setupTimer
{
    dispatch_async(dispatch_get_main_queue(),^{
        [self setupTimer_];
    });
}
-(instancetype)init
{
    self=[super init];
    listsSyncFolder=[[NSUserDefaults standardUserDefaults] stringForKey:@"listsSyncFolder"];
    if(listsSyncFolder){
        dw=[[DirWatcher alloc] initWithPath:listsSyncFolder delegate:self];
        [self setupTimer];
        [self modifiedFileAtPath:[listsSyncFolder stringByAppendingPathComponent:SAVEFILENAME]];
    }
    return self;
}
-(NSString*)machineName
{
    SCDynamicStoreRef store=SCDynamicStoreCreate(NULL,(CFStringRef)@"foo",NULL,NULL);
    NSString*name=CFBridgingRelease(SCDynamicStoreCopyComputerName(store, NULL));
    CFRelease(store);
    return name;
}

-(void)archiveTimerFired:(NSTimer*)timer
{
    [ArticleList prepareSnapShotAndPerform:^(NSDictionary*snapShot){
        if(snapShot && ![snapShot isEqual:lastSavedSnapshot]){
            lastSavedSnapshot=snapShot;
            NSString*fileName=[listsSyncFolder stringByAppendingPathComponent:SAVEFILENAME];
            NSMutableDictionary*dic=[lastSavedSnapshot mutableCopy];
            dic[@"machineName"]=[self machineName];
            NSData*data=[NSPropertyListSerialization dataWithPropertyList:dic format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
            NSLog(@"writing out the sidebar content...");
            [data writeToFile:fileName atomically:NO];
        }
    }];
}
-(void)modifiedFileAtPath:(NSString *)file
{
    if([file hasSuffix:SAVEFILENAME]){
        [ArticleList prepareSnapShotAndPerform:^(NSDictionary *currentSnapShot) {
            NSData*data=[NSData dataWithContentsOfFile:file];
            if(!data) return;
            NSMutableDictionary*snapShotFromFile=[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:NULL error:NULL];
            if(!snapShotFromFile)return;
            NSString*machineName=snapShotFromFile[@"machineName"];
            [snapShotFromFile removeObjectForKey:@"machineName"];
            if([machineName isEqualToString:[self machineName]])return;
            if([snapShotFromFile isEqual:currentSnapShot])return;
            [archiveTimer invalidate];
            [ArticleList mergeSnapShot:snapShotFromFile andDealWithArticleListsToBeRemoved:^(NSArray *articleListsToBeRemoved) {
                [self setupTimer];
                if(!articleListsToBeRemoved)return;
                if(articleListsToBeRemoved.count==0)return;
                ArticleList*a=articleListsToBeRemoved[0];
                NSManagedObjectContext*secondMOC=a.managedObjectContext;
                [secondMOC performBlock:^{
                    NSArray*names=[articleListsToBeRemoved valueForKey:@"name"];
                    NSString*removedNamesString=[names componentsJoinedByString:@", "];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSAlert*alert=[[NSAlert alloc] init];
                        alert.alertStyle=NSInformationalAlertStyle;
                        alert.messageText=[NSString stringWithFormat:@"Some article lists are removed on \"%@\"",machineName ];
                        alert.informativeText=[NSString stringWithFormat:@"Do you want to remove also on this machine the following article lists: \"%@\" ?",removedNamesString];
                        [alert addButtonWithTitle:@"Keep"];
                        [alert addButtonWithTitle:@"Remove"];
                        [alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
                                      completionHandler:^(NSModalResponse returnCode) {
                                          if(returnCode==NSAlertSecondButtonReturn){
                                              [secondMOC performBlock:^{
                                                  for(ArticleList* al in articleListsToBeRemoved){
                                                      [secondMOC deleteObject:al];
                                                  }
                                                  [secondMOC save:NULL];
                                                  dispatch_async(dispatch_get_main_queue(), ^{
                                                      [[MOC moc] save:NULL];
                                                  });
                                                  [self setupTimer];
                                              }];
                                          }else{
                                              [self setupTimer];
                                          }
                                      }];
                    });
                }];
            }];
        }];
    }
}
@end

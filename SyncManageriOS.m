//
//  SyncManageriOS.m
//  inspire
//
//  Created by Yuji on 2015/09/26.
//
//
#import <UIKit/UIKit.h>
#import "SyncManageriOS.h"
#import "AppDelegate.h"
#import "ArticleListArchiveAdditions.h"
#import "iCloud.h"
#import "MOC.h"

#define SAVEFILENAME @"inspireSidebarContents.plist"



@implementation SyncManageriOS
{
    NSMetadataQuery*metadataQuery;
    NSTimer*archiveTimer;
    NSDictionary*lastSavedSnapshot;
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
-(NSString*)machineName
{
    return [[UIDevice currentDevice] name];
}

-(instancetype)init
{
    self=[super init];

    [[iCloud sharedCloud] setDelegate:self];
    [[iCloud sharedCloud] setupiCloudDocumentSyncWithUbiquityContainer:nil];

    if(![[iCloud sharedCloud] checkCloudAvailability]){
        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"iCloudAlertShown"]){
            UIAlertController*alert=[UIAlertController alertControllerWithTitle:@"iCloud Drive not available"
                                                                        message:@"If you enable iCloud Drive, the app will sync the contents of the article lists and flagged articles across iOS devices and spires.app on OS X." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:nil];
            
            [alert addAction:defaultAction];
            [[[NSApp appDelegate] presentingViewController] presentViewController:alert animated:YES completion:nil];
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"iCloudAlertShown"];
        }
    }
    return self;
}
-(void)iCloudDidFinishInitializingWitUbiquityToken:(id)cloudToken withUbiquityContainer:(NSURL *)ubiquityContainer
{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        if([[iCloud sharedCloud] doesFileExistInCloud:SAVEFILENAME]){
            [self stateChanged:nil];
        }
        [[iCloud sharedCloud] monitorDocumentStateForFile:SAVEFILENAME onTarget:self withSelector:@selector(stateChanged:)];
        [self setupTimer];
    });    
}
-(void)archiveTimerFired:(NSTimer*)timer
{
    [archiveTimer invalidate];
    [ArticleList prepareSnapShotAndPerform:^(NSDictionary*snapShot){
        if(snapShot && ![snapShot isEqual:lastSavedSnapshot]){
            lastSavedSnapshot=snapShot;
            NSMutableDictionary*dic=[lastSavedSnapshot mutableCopy];
            dic[@"machineName"]=[self machineName];
            NSData*data=[NSPropertyListSerialization dataWithPropertyList:dic format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
            [[iCloud sharedCloud] saveAndCloseDocumentWithName:SAVEFILENAME withContent:data completion:^(UIDocument *cloudDocument, NSData *documentData, NSError *error) {
                    // nothing particular to do
                NSLog(@"sidebar content written on the iCloud");
            }];
            [self setupTimer];
        }
    }];
}
-(void)stateChanged:(NSNotification*)n
{
        [ArticleList prepareSnapShotAndPerform:^(NSDictionary *currentSnapShot) {
            [archiveTimer invalidate];
            [[iCloud sharedCloud] retrieveCloudDocumentWithName:SAVEFILENAME completion:^(UIDocument *cloudDocument, NSData *data, NSError *error) {
                if(!data) {[self setupTimer]; return;}
                NSMutableDictionary*snapShotFromFile=[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:NULL error:NULL];
                if(!snapShotFromFile)return;
                NSString*machineName=snapShotFromFile[@"machineName"];
                [snapShotFromFile removeObjectForKey:@"machineName"];
                if([machineName isEqualToString:[self machineName]]){[self setupTimer]; return;}
                if([snapShotFromFile isEqual:currentSnapShot]){[self setupTimer]; return;}
                NSLog(@"newer snapshot on %@ found, merging.",machineName);
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
                            UIAlertController*alert=[UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Some article lists are removed on \"%@\"",machineName ]
                                                                                        message:[NSString stringWithFormat:@"Do you want to remove also on this machine the following article lists: \"%@\" ?",removedNamesString] preferredStyle:UIAlertControllerStyleAlert];
                            UIAlertAction* keepAction = [UIAlertAction actionWithTitle:@"Keep" style:UIAlertActionStyleDefault
                                                                               handler:^(UIAlertAction *  action) {
                                                                                   [self setupTimer];
                                                                               }];
                            UIAlertAction* removeAction = [UIAlertAction actionWithTitle:@"Remove" style: UIAlertActionStyleDestructive
                                                                                 handler:^(UIAlertAction *  action) {
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
                                                                                     
                                                                                 }];
                            [alert addAction:keepAction];
                            [alert addAction:removeAction];
                            [[[NSApp appDelegate] presentingViewController] presentViewController:alert animated:YES completion:nil];
                        });
                    }];
                }];

            }];
        }];

}
@end

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
#import "RegexKitLite.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <SystemConfiguration/SystemConfiguration.h>
#endif

#define SYNCDATAEXTENSION @"sidebarContents"

@implementation SyncManager
{
#if TARGET_OS_IPHONE
    NSMetadataQuery*metadataQuery;
#else
    DirWatcher*dw;
#endif
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
#if TARGET_OS_IPHONE
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
        return self;
    }
    [[iCloud sharedCloud] updateFiles];
#else
    listsSyncFolder=[[@"~/Library/Mobile Documents/" stringByExpandingTildeInPath] stringByAppendingPathComponent:@"iCloud~com~yujitach~inspire/Documents"];
    if([[NSFileManager defaultManager] fileExistsAtPath:listsSyncFolder]){
        NSLog(@"enabling iCloud sync");
        dw=[[DirWatcher alloc] initWithPath:listsSyncFolder delegate:self];
        [self setupTimer];
        [self modifiedFileAtPath:[listsSyncFolder stringByAppendingPathComponent:self.saveFileName]];
    }
#endif
    return self;
}
#if TARGET_OS_IPHONE
-(void)iCloudDidFinishInitializingWitUbiquityToken:(id)cloudToken withUbiquityContainer:(NSURL *)ubiquityContainer
{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
        if([[iCloud sharedCloud] doesFileExistInCloud:SAVEFILENAME]){
            [self stateChanged:nil];
        }
        //        [[iCloud sharedCloud] monitorDocumentStateForFile:SAVEFILENAME onTarget:self withSelector:@selector(stateChanged:)];
        metadataQuery=[[NSMetadataQuery alloc] init];
        metadataQuery.predicate=[NSPredicate predicateWithFormat:@"%K LIKE %@", NSMetadataItemFSNameKey,SAVEFILENAME];
        metadataQuery.searchScopes=@[NSMetadataQueryUbiquitousDocumentsScope];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stateChanged:) name:NSMetadataQueryDidUpdateNotification object:nil];
        [metadataQuery startQuery];
        [self setupTimer];
    });
}
#endif
-(NSString*)machineName
{
#if TARGET_OS_IPHONE
    return [[UIDevice currentDevice] name];
#else
    SCDynamicStoreRef store=SCDynamicStoreCreate(NULL,(CFStringRef)@"foo",NULL,NULL);
    NSString*name=CFBridgingRelease(SCDynamicStoreCopyComputerName(store, NULL));
    CFRelease(store);
    return name;
#endif
}
-(NSString*)saveFileName{
    return [NSString stringWithFormat:@"%@.%@",self.machineName,SYNCDATAEXTENSION];
}
-(NSString*)machineNameFromSaveFileName:(NSString*)newFile{
    NSMutableArray*a=[[newFile componentsSeparatedByString:@"."] mutableCopy];
    [a removeLastObject];
    NSString*targetMachineName=[a componentsJoinedByString:@"."];
    return targetMachineName;
}
-(void)writeData:(NSData*)data andThen:(void(^)(void))block
{
#if TARGET_OS_IPHONE
    [[iCloud sharedCloud] saveAndCloseDocumentWithName:saveFileName withContent:data completion:^(UIDocument *cloudDocument, NSData *documentData, NSError *error) {
        // nothing particular to do
        NSLog(@"sidebar content written on the iCloud");
        block();
    }];
#else
    NSString*fileName=[listsSyncFolder stringByAppendingPathComponent:self.saveFileName];
    [data writeToFile:fileName atomically:NO];
    block();
#endif
}
-(void)archiveTimerFired:(NSTimer*)timer
{
    [archiveTimer invalidate];
    [ArticleList prepareSnapShotAndPerform:^(NSDictionary*snapShot){
        if(snapShot && ![snapShot isEqual:lastSavedSnapshot]){
            lastSavedSnapshot=snapShot;
            NSData*data=[NSPropertyListSerialization dataWithPropertyList:lastSavedSnapshot format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
            NSLog(@"writing out the sidebar content...");
            [self writeData:data andThen:^{
                [self setupTimer];
            }];
        }
    }];
}
-(void)modifiedFileAtPath:(NSString *)file
{
    if([file hasSuffix:SYNCDATAEXTENSION]){
        NSString*fileName=[file lastPathComponent];
        [self stateChanged:fileName];
    }
}
-(void)retrieveDataFromFile:(NSString*)file AndThen:(void(^)(NSData*data))block
{
#if TARGET_OS_IPHONE
    NSArray*versions=[[iCloud sharedCloud] findUnresolvedConflictingVersionsOfFile:SAVEFILENAME];
    NSFileVersion*latestVersion=versions[0];
    NSDate*latestDate=latestVersion.modificationDate;
    for(NSFileVersion*version in versions){
        NSLog(@"%@ versions found.",@(versions.count));
        if([version.modificationDate laterDate:latestDate]){
            latestVersion=version;
            latestDate=latestVersion.modificationDate;
        }
    }
    [[iCloud sharedCloud] resolveConflictForFile:SAVEFILENAME withSelectedFileVersion:latestVersion];
    [[iCloud sharedCloud] retrieveCloudDocumentWithName:SAVEFILENAME completion:^(UIDocument *cloudDocument, NSData *data, NSError *error) {
        block(data);
    }];
#else
    NSString*fileName=[listsSyncFolder stringByAppendingPathComponent:file];
    NSData*data=[NSData dataWithContentsOfFile:fileName];
    block(data);
#endif
}
-(void)confirmRemovalOfListsWithNames:(NSArray*)names onMachine:(NSString*)machineName blockForRemoval:(void(^)(void))blockForRemoval blockForKeeping:(void(^)(void))blockForKeeping
{
    NSString*removedNamesString=[names componentsJoinedByString:@", "];
#if TARGET_OS_IPHONE
    UIAlertController*alert=[UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Some article lists are removed on \"%@\"",machineName ]
                                                                message:[NSString stringWithFormat:@"Do you want to remove also on this machine the following article lists: \"%@\" ?",removedNamesString] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* keepAction = [UIAlertAction actionWithTitle:@"Keep" style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *  action) {
                                                           blockForKeeping();
                                                       }];
    UIAlertAction* removeAction = [UIAlertAction actionWithTitle:@"Remove" style: UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *  action) {
                                                             blockForRemoval();
                                                         }];
    [alert addAction:keepAction];
    [alert addAction:removeAction];
    [[[NSApp appDelegate] presentingViewController] presentViewController:alert animated:YES completion:nil];
#else
    NSAlert*alert=[[NSAlert alloc] init];
    alert.alertStyle=NSInformationalAlertStyle;
    alert.messageText=[NSString stringWithFormat:@"Some article lists are removed on \"%@\"",machineName ];
    alert.informativeText=[NSString stringWithFormat:@"Do you want to remove also on this machine the following article lists: \"%@\" ?",removedNamesString];
    [alert addButtonWithTitle:@"Keep"];
    [alert addButtonWithTitle:@"Remove"];
    [alert beginSheetModalForWindow:[[NSApp appDelegate] mainWindow]
                  completionHandler:^(NSModalResponse returnCode) {
                      if(returnCode==NSAlertSecondButtonReturn){
                          blockForRemoval();
                      }else{
                          blockForKeeping();
                      }
                  }];
#endif
}
-(void)stateChanged:(NSString*)newFile{
    NSString*targetMachineName=[self machineNameFromSaveFileName:newFile];
    if([targetMachineName isEqualToString:[self machineName]]){[self setupTimer]; return;}
    NSLog(@"newer snapshot on %@ found, merging.",targetMachineName);

    [ArticleList prepareSnapShotAndPerform:^(NSDictionary *currentSnapShot) {
        [archiveTimer invalidate];
        [self retrieveDataFromFile:newFile AndThen:^(NSData*data){
            if(!data) {[self setupTimer]; return;}
            NSMutableDictionary*snapShotFromFile=[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:NULL error:NULL];
            if(!snapShotFromFile)return;
            if([snapShotFromFile isEqual:currentSnapShot]){[self setupTimer]; return;}
            [ArticleList mergeSnapShot:snapShotFromFile andDealWithArticleListsToBeRemoved:^(NSArray *articleListsToBeRemoved) {
                if(!articleListsToBeRemoved){[self setupTimer];return;}
                if(articleListsToBeRemoved.count==0){[self setupTimer];return;}
                ArticleList*a=articleListsToBeRemoved[0];
                NSManagedObjectContext*secondMOC=a.managedObjectContext;
                [secondMOC performBlock:^{
                    NSArray*names=[articleListsToBeRemoved valueForKey:@"name"];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self confirmRemovalOfListsWithNames:names
                                                   onMachine:targetMachineName
                                             blockForRemoval:^{
                                                 [secondMOC performBlock:^{
                                                     for(ArticleList* al in articleListsToBeRemoved){
                                                         [secondMOC deleteObject:al];
                                                     }
                                                     [secondMOC save:NULL];
                                                     [self setupTimer];
                                                 }];
                                             }
                                             blockForKeeping:^{
                                                 [self setupTimer];
                                             }];
                    });
                }];
            }];
        }];
    }];
}

@end


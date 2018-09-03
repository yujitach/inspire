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
#import "DumbOperation.h"
#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <SystemConfiguration/SystemConfiguration.h>
#endif

#define SYNCDATAEXTENSION @"inspireSidebarContents"


@interface ReadSnapshotFromFileOperation:ConcurrentOperation
-(instancetype)initWithFileName:(NSURL*)f;
@property NSDictionary*snapShot;
@end

@implementation ReadSnapshotFromFileOperation
{
    NSURL*file;
}
-(instancetype)initWithFileName:(NSURL*)f
{
    self=[super init];
    file=f;
    return self;
}
-(void)run
{
#if TARGET_OS_IPHONE
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0),^{
        [iCloudHelper retrieveCloudDocumentWithName:file completion:^(NSData *data) {
            if(data){
                self.snapShot=[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:NULL error:NULL];
            }else{
                self.snapShot=nil;
            }
            [self finish];
        }];
    });
#else
    NSData*data=[NSData dataWithContentsOfURL:file];
    self.snapShot=[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainers format:NULL error:NULL];
    [self finish];
#endif
}
@end

@interface MergeSnapShotOperation:ConcurrentOperation
-(instancetype)initWithPSO:(PrepareSnapshotOperation*)p andRSO:(ReadSnapshotFromFileOperation*)r forTargetMachineName:(NSString*)tmn;
@end


@implementation SyncManager
{
#if TARGET_OS_IPHONE
    NSMetadataQuery*query;
#else
    DirWatcher*dw;
#endif
    NSDictionary*lastSavedSnapshot;
    NSString*listsSyncFolder;
    NSOperationQueue*queue;
}
-(void)saveNotified:(NSNotification*)n
{
    NSManagedObjectContext*moc=n.object;
    if(moc!=[MOC moc])
        return;
    [moc performBlock:^{
        [self archive];
    }];
}
-(void)prepareFirstSnapshot
{
    PrepareSnapshotOperation*op=[[PrepareSnapshotOperation alloc] init];
    op.completionBlock=^{
        lastSavedSnapshot=op.snapShot;
    };
    [queue addOperation:op];
}
-(instancetype)init
{
    self=[super init];
    queue=[[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount=1;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(saveNotified:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:nil];
    [self prepareFirstSnapshot];
#if TARGET_OS_IPHONE
    if(![iCloudHelper iCloudAvailable]){
        return self;
    }
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"initialMergeDone"];
    [iCloudHelper setupWithUbiquityContainerIdentifier:nil completion:^(NSURL *ubiquityContainerURL) {
        if(!ubiquityContainerURL){
            return;
        }
        query=[iCloudHelper metadataQueryForExtension:SYNCDATAEXTENSION];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startedGathering:) name:NSMetadataQueryDidStartGatheringNotification object:query];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedGathering:) name:NSMetadataQueryDidFinishGatheringNotification object:query];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(update:) name:NSMetadataQueryDidUpdateNotification object:query];
        query.operationQueue=queue;
        [query.operationQueue addOperationWithBlock:^{
            [query startQuery];
        }];
    }];
#else
    NSString*iCloudDocumentsPath=[@"~/Library/Mobile Documents/" stringByExpandingTildeInPath];
    listsSyncFolder=[iCloudDocumentsPath stringByAppendingPathComponent:@"iCloud~com~yujitach~inspire/Documents"];

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0),^{
        NSURL*x=[[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:@"iCloud.com.yujitach.inspire"];
        NSLog(@"ubiquity container at:%@",x);
        if(x){
            if([[NSUserDefaults standardUserDefaults] boolForKey:@"doSync"]){
                dispatch_async(dispatch_get_main_queue(),^{
                    NSLog(@"enabling iCloud sync");
                    dw=[[DirWatcher alloc] initWithPath:listsSyncFolder delegate:self];
                    NSArray*a=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:listsSyncFolder error:NULL];
                    for(NSString*fileName in a){
                        if([fileName hasSuffix:SYNCDATAEXTENSION]){
                            NSString*fullPath=[listsSyncFolder stringByAppendingPathComponent:fileName];
                            NSDate*date=[[[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:NULL] fileModificationDate];
                            [self stateChanged:[NSURL fileURLwithPath:fullPath] atDate:date];
                        }
                    }
                });
            }
        }
    });
#endif
    return self;
}

#if TARGET_OS_IPHONE
-(void)startedGathering:(NSNotification*)n
{
    
}
-(void)finishedGathering:(NSNotification*)n
{
    [self update:n];
    NSOperation*op=[NSBlockOperation blockOperationWithBlock:^{
        dispatch_async(dispatch_get_main_queue(),^{
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"initialMergeDone"];
        });
    }];
    [queue addOperation:op];
}
-(void)update:(NSNotification*)n
{
    NSArray*items=query.results;
    for(NSMetadataItem*item in items){
        NSURL*f =[item valueForKey:NSMetadataItemURLKey];
        if(![f isStatusCurrent]){
            continue;
        }
        if(![f.absoluteString hasSuffix:SYNCDATAEXTENSION])
            continue;
        NSString*targetMachineName=[self machineNameFromSaveFileName:f];
        if([targetMachineName isEqualToString:self.machineName])
            continue;
        NSDate*fileDate=[item valueForAttribute:NSMetadataItemFSContentChangeDateKey];
        [self stateChanged:f atDate:fileDate];
    }
}
#endif
-(NSString*)machineName
{
#if TARGET_OS_SIMULATOR
    return @"simulator";
#elif TARGET_OS_IPHONE
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
-(NSString*)machineNameFromSaveFileName:(NSURL*)newFile{
    NSString*lastComponent=[newFile lastPathComponent];
    NSMutableArray*a=[[lastComponent componentsSeparatedByString:@"."] mutableCopy];
    [a removeLastObject];
    NSString*targetMachineName=[a componentsJoinedByString:@"."];
    return targetMachineName;
}
-(void)writeData:(NSData*)data andThen:(void(^)(void))block
{
#if TARGET_OS_IPHONE
    [iCloudHelper saveAndCloseDocumentWithName:self.saveFileName withContent:data completion:^(BOOL success) {
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
-(void)archive
{
    PrepareSnapshotOperation*op=[[PrepareSnapshotOperation alloc] init];
    [queue addOperation:op];
    NSBlockOperation*bop=[NSBlockOperation blockOperationWithBlock:^{
        NSDictionary*snapShot=op.snapShot;
        if(snapShot && ![snapShot isEqual:lastSavedSnapshot]){
            lastSavedSnapshot=snapShot;
            NSData*data=[NSPropertyListSerialization dataWithPropertyList:lastSavedSnapshot format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
            NSLog(@"writing out the sidebar content...");
            [self writeData:data andThen:^{}];
        }
    }];
    [bop addDependency:op];
    [queue addOperation:bop];
}
-(void)modifiedFileAtPath:(NSString *)file
{
    NSLog(@"noted:%@",file);
    if([file hasSuffix:SYNCDATAEXTENSION]){
        NSDate*date=[[[NSFileManager defaultManager] attributesOfItemAtPath:file error:NULL] fileModificationDate];
        [self stateChanged:[NSURL fileURLWithPath:file] atDate:date];
    }
}

-(void)stateChanged:(NSURL*)newFile atDate:(NSDate*)date{
    NSString*targetMachineName=[self machineNameFromSaveFileName:newFile];
    if([targetMachineName isEqualToString:[self machineName]])
        return;
    NSString*key=[NSString stringWithFormat:@"lastseen-%@",targetMachineName];
    NSDate* lastSeen=[[NSUserDefaults standardUserDefaults] objectForKey:key];
    if(lastSeen && [lastSeen timeIntervalSinceDate:date]>=0){
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:key];

    NSOperation*op=[NSBlockOperation blockOperationWithBlock:^{
        dispatch_async(dispatch_get_main_queue(),^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"merging" object:targetMachineName];
        });
    }];

    [queue addOperation:op];
    
    PrepareSnapshotOperation*pso=[[PrepareSnapshotOperation alloc] init];
    [queue addOperation:pso];
    ReadSnapshotFromFileOperation*rso=[[ReadSnapshotFromFileOperation alloc] initWithFileName:newFile];
    [queue addOperation:rso];
    MergeSnapShotOperation*mso=[[MergeSnapShotOperation alloc] initWithPSO:pso andRSO:rso forTargetMachineName:targetMachineName];
    [queue addOperation:mso];
}


@end

@implementation MergeSnapShotOperation
{
    PrepareSnapshotOperation*pso;
    ReadSnapshotFromFileOperation*rso;
    NSString*targetMachineName;
}
-(instancetype)initWithPSO:(PrepareSnapshotOperation *)p andRSO:(ReadSnapshotFromFileOperation *)r forTargetMachineName:(NSString*)tmn;
{
    self=[super init];
    pso=p;
    [self addDependency:p];
    rso=r;
    [self addDependency:r];
    targetMachineName=tmn;
    return self;
}
-(void)confirmRemovalOfListsWithNames:(NSArray*)names onMachine:(NSString*)machineName blockForRemoval:(void(^)(void))blockForRemoval blockForKeeping:(void(^)(void))blockForKeeping
{
    NSString*removedNamesString=[names componentsJoinedByString:@", "];
#if TARGET_OS_IPHONE

    UIAlertController*alert=[UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Some article lists are (re)moved on \"%@\"",machineName ]
                                                                message:[NSString stringWithFormat:@"Do you want to (re)move also on this machine the following article lists: \"%@\" ?",removedNamesString] preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* keepAction = [UIAlertAction actionWithTitle:@"Keep" style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *  action) {
                                                           blockForKeeping();
                                                       }];
    UIAlertAction* removeAction = [UIAlertAction actionWithTitle:@"(Re)move" style: UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction *  action) {
                                                             blockForRemoval();
                                                         }];
    [alert addAction:keepAction];
    [alert addAction:removeAction];
    [[[NSApp appDelegate] presentingViewController] presentViewController:alert animated:YES completion:nil];
 
#else
    NSAlert*alert=[[NSAlert alloc] init];
    alert.alertStyle=NSAlertStyleInformational;
    alert.messageText=[NSString stringWithFormat:@"Some article lists are (re)moved on \"%@\"",machineName ];
    alert.informativeText=[NSString stringWithFormat:@"Do you want to (re)move also on this machine the following article lists: \"%@\" ?",removedNamesString];
    [alert addButtonWithTitle:@"Keep"];
    [alert addButtonWithTitle:@"(Re)move"];
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
-(void)run
{
    NSDictionary*snapShotFromFile=rso.snapShot;
    if(!snapShotFromFile){
        [self finish];
        return;
    }
    {
        NSDictionary*snapShot=pso.snapShot;
        if([snapShotFromFile isEqual:snapShot]){
            [self finish];
            return;
        }
    }
    
    NSLog(@"merges %@",targetMachineName);
    NSManagedObjectContext*secondMOC=[[MOC sharedMOCManager]createSecondaryMOC];
    [secondMOC performBlockAndWait:^{
        NSArray*articleListsToBeRemoved=[ArticleList notFoundArticleListsAfterMergingChildren:snapShotFromFile[@"children"] toArticleFolder:nil usingMOC:secondMOC];
        [ArticleList populateFlaggedArticlesFrom:snapShotFromFile[@"flagged"] usingMOC:secondMOC];
        [ArticleList rearrangePositionInViewInMOC:secondMOC];
        [secondMOC save:NULL];
        if(!articleListsToBeRemoved){
            [self finish];
            return;
        }
        if(articleListsToBeRemoved.count==0){
            [self finish];
            return;
        }
        NSArray*names=[articleListsToBeRemoved valueForKey:@"fullName"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self confirmRemovalOfListsWithNames:names
                                       onMachine:targetMachineName
                                 blockForRemoval:^{
                                     [secondMOC performBlockAndWait:^{
                                         for(ArticleList* al in articleListsToBeRemoved){
                                             [secondMOC deleteObject:al];
                                         }
                                         [secondMOC save:NULL];
                                     }];
                                     [self finish];
                                 }
                                 blockForKeeping:^{
                                     [self finish];
                                 }];
        });
    }];
}
@end


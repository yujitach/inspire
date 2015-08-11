//
//  SyncManager.m
//  inspire
//
//  Created by Yuji on 2015/08/11.
//
//

#import "SyncManager.h"
#import "MOC.h"
#import "ArticleListDictionaryRepresentation.h"
#import <SystemConfiguration/SystemConfiguration.h>


typedef void (^SnapShotBlock)(NSDictionary*snapShot);
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
        NSTimeInterval interval=60;
        archiveTimer=[NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(archiveTimerFired:) userInfo:nil repeats:YES];
        if([archiveTimer respondsToSelector:@selector(setTolerance:)]){
            [archiveTimer setTolerance:.1*interval];
        }
        [self archiveTimerFired:nil];
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
-(void)prepareSnapShotAndPerform:(SnapShotBlock)block
{
    NSManagedObjectContext*secondMOC=[[MOC sharedMOCManager] createSecondaryMOC];
    [secondMOC performBlock:^{
        NSEntityDescription*entity=[NSEntityDescription entityForName:@"ArticleList" inManagedObjectContext:secondMOC];
        NSPredicate*predicate=[NSPredicate predicateWithFormat:@"parent == nil"];
        NSFetchRequest*req=[[NSFetchRequest alloc] init];
        [req setPredicate:predicate];
        [req setEntity:entity];
        [req setIncludesPropertyValues:YES];
        NSError*error=nil;
        NSArray*a=[secondMOC executeFetchRequest:req error:&error];
        NSMutableArray*ar=[NSMutableArray array];
        for(ArticleList*al in a){
            NSDictionary*dic=[al dictionaryRepresentation];
            if(dic){
                [ar addObject:dic];
            }
        }
        [ar sortUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"positionInView" ascending:YES ]]];
        block(@{@"machineName":[self machineName],@"children":ar});
    }];
}
-(void)loadSnapshot:(NSDictionary*)snapShot
{
    
}
-(void)archiveTimerFired:(NSTimer*)timer
{
    [self prepareSnapShotAndPerform:^(NSDictionary*snapShot){
        if(snapShot && ![snapShot isEqual:lastSavedSnapshot]){
            lastSavedSnapshot=snapShot;
            NSString*fileName=[listsSyncFolder stringByAppendingPathComponent:@"inspireSidebarContents.plist"];
            NSData*data=[NSPropertyListSerialization dataWithPropertyList:lastSavedSnapshot format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
            [data writeToFile:fileName atomically:NO];
        }
    }];
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

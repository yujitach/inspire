//
//  SpiresQueryOperation.m
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "SpiresQueryOperation.h"
#import "Article.h"
#import "BatchImportOperation.h"
#import "SpiresHelper.h"
#import "SpiresQueryDownloader.h"
#import "BatchBibQueryOperation.h"
#import "AppDelegate.h"
#import "MOC.h"
@interface SpiresQueryOperation ()
{
    NSString*search;
    NSManagedObjectContext*moc;
    SpiresQueryDownloader*downloader;
    NSInteger startAt;
    BatchImportOperation*importer;
    ActionOnBatchImportBlock actionBlock;
}
@end
@implementation SpiresQueryOperation
-(void)setBlockToActOnBatchImport:(ActionOnBatchImportBlock)_actionBlock;
{
    actionBlock=[_actionBlock copy];
}

-(SpiresQueryOperation*)initWithQuery:(NSString*)q andMOC:(NSManagedObjectContext*)m;
{
    self=[super init];
    search=q;
    moc=m;
    startAt=0;
    return self;
}
-(SpiresQueryOperation*)initWithQuery:(NSString*)q andMOC:(NSManagedObjectContext*)m startAt:(NSInteger)sa;
{
    self=[super init];
    search=q;
    moc=m;
    startAt=sa;
    return self;
}
-(void)run
{
    self.isExecuting=YES;
    [self startAt:startAt];
}
-(void)startAt:(NSInteger)start
{
    __weak ConcurrentOperation*me=self;
    downloader=[[SpiresQueryDownloader alloc] initWithQuery:search startAt:start whenDone:^(NSData*xmlData,BOOL last){
        if(!xmlData){
            [me finish];
            return;
        }
        if([me isCancelled]){
            [me finish];
            return;
        }
        importer=[[BatchImportOperation alloc] initWithXMLData:xmlData
                                                 originalQuery:search];
        if(actionBlock){
            actionBlock(importer);
        }
        [[OperationQueues sharedQueue] addOperation:importer];
        if(!last){
            SpiresQueryOperation*op=[[SpiresQueryOperation alloc] initWithQuery:search andMOC:moc startAt:start+MAXPERQUERY];
            if(actionBlock){
                [op setBlockToActOnBatchImport:actionBlock];
            }
            [op setQueuePriority:NSOperationQueuePriorityLow];
            [[OperationQueues spiresQueue] addOperation:op];
        }
        [me finish];
    }];
    if(!downloader){
	[self finish];
    }
}
-(NSString*)description
{
    return [NSString stringWithFormat:@"spires query:%@ from %d",search,(int)startAt];
}
@end

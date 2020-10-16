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
#import "InspireJSONTransformer.h"
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
-(void)cancel{
    [super cancel];
    if(downloader){
        [downloader cancel];
    }
}
-(void)run
{
    self.isExecuting=YES;
    __weak ConcurrentOperation*me=self;
    downloader=[[SpiresQueryDownloader alloc] initWithQuery:search whenDone:^(NSDictionary*jsonDict){
        if(!jsonDict){
            [me finish];
            return;
        }
        NSArray*a=[InspireJSONTransformer articlesFromJSON:jsonDict];
        importer=[[BatchImportOperation alloc] initWithProtoArticles:a
                                                       originalQuery:search
                                                    updatesCitations:YES
                                                            usingMOC:[[MOC sharedMOCManager] createSecondaryMOC]
                                                            whenDone:^(BatchImportOperation*op){
                                                                [op.secondMOC performBlockAndWait:^{
                                                                    [op.secondMOC save:NULL];
                                                                }];
                                                            }];
        if(actionBlock){
            actionBlock(importer);
        }
        [[OperationQueues importQueue] addOperation:importer];
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

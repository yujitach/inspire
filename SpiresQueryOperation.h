//
//  SpiresQueryOperation.h
//  spires
//
//  Created by Yuji on 09/02/07.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

@import CoreData;
#import "DumbOperation.h"
@class Article;
@class SpiresQueryDownloader;
@class BatchImportOperation;
typedef void (^ActionOnBatchImportBlock)(BatchImportOperation*);
@interface SpiresQueryOperation : ConcurrentOperation
-(SpiresQueryOperation*)initWithQuery:(NSString*)q andMOC:(NSManagedObjectContext*)m;
-(void)setBlockToActOnBatchImport:(ActionOnBatchImportBlock)actionBlock;
@end

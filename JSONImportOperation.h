//
//  JSONImportOperation.h
//  inspire
//
//  Created by Yuji on 2015/08/07.
//
//

#import <Foundation/Foundation.h>

@interface JSONImportOperation : NSOperation
-(instancetype)initWithJSONArray:(NSArray*)jsonArray originalQuery:(NSString*)search;
@property (readonly)NSMutableSet*generated;
@end

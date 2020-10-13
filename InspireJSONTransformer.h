//
//  InspireJSONTransformer.h
//  inspire
//
//  Created by Yuji on 2020/06/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
extern NSString*usedFields;
@interface InspireJSONTransformer : NSObject
+(NSArray*)articlesFromJSON:(NSDictionary*)jsonDict;
@end

NS_ASSUME_NONNULL_END

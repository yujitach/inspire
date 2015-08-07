//
//  InspireQueryDonwloader.h
//  inspire
//
//  Created by Yuji on 2015/08/07.
//
//

#import <Foundation/Foundation.h>
#define MAXPERQUERY 50
typedef void (^WhenDoneClosure)(NSArray*jsonArray);
@interface InspireQueryDownloader : NSObject
-(instancetype)initWithQuery:(NSString*)s startAt:(NSUInteger)start whenDone:(WhenDoneClosure)wd ;
@end

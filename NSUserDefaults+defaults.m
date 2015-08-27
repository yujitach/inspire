//
//  NSUserDefaults+defaults.m
//  inspire
//
//  Created by Yuji on 2015/08/27.
//
//

#import "NSUserDefaults+defaults.h"

@implementation NSUserDefaults (LoadInitialDefaultsCategory)
+(void)loadInitialDefaults
{
    NSData* data=[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist"]];
    NSError* error=nil;
    NSPropertyListFormat format;
    NSMutableDictionary* defaultDict=[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:&format error:&error];
    
    //sythesize the list of all known journals
    
    NSArray* annualReviewJournals=defaultDict[@"AnnualReviewJournals"];
    NSArray* elsevierJournals=defaultDict[@"ElsevierJournals"];
    NSArray* apsJournals=defaultDict[@"APSJournals"];
    NSArray* aipJournals=defaultDict[@"AIPJournals"];
    NSArray* iopJournals=defaultDict[@"IOPJournals"];
    NSArray* springerJournals=defaultDict[@"SpringerJournals"];
    NSArray* wsJournals=defaultDict[@"WSJournals"];
    NSArray* ptpJournals=defaultDict[@"PTPJournals"];
    NSMutableArray* knownJournals=[NSMutableArray array ];
    [knownJournals addObjectsFromArray:annualReviewJournals];
    [knownJournals addObjectsFromArray:elsevierJournals];
    [knownJournals addObjectsFromArray:apsJournals];
    [knownJournals addObjectsFromArray:aipJournals];
    [knownJournals addObjectsFromArray:iopJournals];
    [knownJournals addObjectsFromArray:springerJournals];
    [knownJournals addObjectsFromArray:wsJournals];
    [knownJournals addObjectsFromArray:ptpJournals];
    defaultDict[@"KnownJournals"] = knownJournals;
    
    
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaultDict];
}
@end

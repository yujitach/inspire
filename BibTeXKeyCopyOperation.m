//
//  BibTeXKeyCopyOperation.m
//  spires
//
//  Created by Yuji on 6/30/09.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "BibTeXKeyCopyOperation.h"
#import "NSString+magic.h"
#import "Article.h"

@implementation BibTeXKeyCopyOperation
-(id)initWithArticles:(NSArray*)as;
{
    self=[super init];
    articles=as;
    return self;
}
-(void)run{
    self.isExecuting=YES;
    NSString*key=[[NSUserDefaults standardUserDefaults] stringForKey:@"bibType"];
    NSMutableArray*keys=[NSMutableArray array];
    for(Article*a in articles){
	NSString*c=nil;
	if([key isEqualToString:@"harvmac"]){
	    c=[a extraForKey:@"harvmacKey"];
	}else{
	    c=a.texKey;
	}
	if(c&&![c isEqualToString:@""]){
            [keys addObject:c];
	}
    }
    NSString*s=[keys componentsJoinedByString:@","];
    NSPasteboard*pb=[NSPasteboard generalPasteboard];
    [pb declareTypes:@[NSStringPboardType] owner:self];
    [pb setString:[s inspireToCorrect] forType:NSStringPboardType];
    [[NSSound soundNamed:@"Submarine"] play];
    [self finish];
}
-(NSString*)description
{
    return @"Copying bibtex key to pasteboard...";
}
@end

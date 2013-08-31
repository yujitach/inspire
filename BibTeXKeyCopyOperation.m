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
    int i=0;
    NSMutableString* s=[NSMutableString string];
    for(Article*a in articles){
	if(i!=0){
	    [s appendString:@","];
	    i=1;
	}
	NSString*c=nil;
	if([key isEqualToString:@"harvmac"]){
	    c=[a extraForKey:@"harvmacKey"];
	}else{
	    c=a.texKey;
	}
	if(c&&![c isEqualToString:@""]){
	    [s appendString:c];
	}
    }
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

//
//  BibViewController.m
//  spires
//
//  Created by Yuji on 09/02/01.
//  Copyright 2009 Y. Tachikawa. All rights reserved.
//

#import "BibViewController.h"
#import "Article.h"
#import "NSString+magic.h"
#import "MOC.h"

@implementation BibViewController
-(id)init
{
    self=[super initWithWindowNibName:@"BibView"];
    return self;
}
-(void)refresh
{
    NSString*key=[[NSUserDefaults standardUserDefaults] stringForKey:@"bibType"];
    NSMutableString*s=[NSMutableString string];
    for(Article*i in articles){
	NSString *t=[i extraForKey:key];
	if(t){
	    [s appendString:t];
	}
	[s appendString:@"\n"];
    }
    NSString*x=s;
    if([key isEqualToString:@"latex"]){
	x=[x magicTeXed];
    }
    [tv setString:x];
    [tv selectAll:self];

    if(!articles)return;
    if([articles count]==0) return;
    Article*a=articles[0];
    NSString*c=nil;
    if([key isEqualToString:@"harvmac"]){
	c=[a extraForKey:@"harvmacKey"];
    }else{
	c=a.texKey;
    }
    NSPasteboard*pb=[NSPasteboard generalPasteboard];
    [pb declareTypes:@[NSStringPboardType] owner:self];
    [pb setString:[c inspireToCorrect] forType:NSStringPboardType];
}
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self refresh];
}
-(void)setArticles:(NSArray*)a
{
/*
    if(articles){
	for(Article*article in articles){
	    [article removeObserver:self forKeyPath:@"texKey"];
	}
    }
 */
    articles=a;
/*
    for(Article*article in articles){
	[article addObserver:self
		  forKeyPath:@"texKey"
		     options:NSKeyValueObservingOptionNew//|NSKeyValueObservingOptionInitial
		     context:nil];
    }
 */
    [self refresh];
}
-(void)awakeFromNib
{
       [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
	      forKeyPath:@"defaults.bibType"
		 options:NSKeyValueObservingOptionNew//|NSKeyValueObservingOptionInitial
		 context:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mocMerged:) name:UIMOCDidMergeNotification object:nil];
}
-(void)mocMerged:(NSNotification*)notification
{
    [self refresh];
}


@end

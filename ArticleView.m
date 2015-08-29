//
//  ArticleView.m
//  spires
//
//  Created by Yuji on 08/10/17.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import "ArticleView.h"
#import "Author.h"
#import "Article.h"
#import "JournalEntry.h"
#import "SpiresHelper.h"
#import "ArxivHelper.h"
#import "NSString+magic.h"
#import "SpiresAppDelegate_actions.h"
#import "HTMLArticleHelper.h"

static NSArray*observedKeys=nil;
@implementation ArticleView
#pragma mark UI glues
-(void)awakeFromNib
{
    [self setShouldCloseWithWindow:NO];
    article=nil;
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
							      forKeyPath:@"defaults.bibType"
								 options:NSKeyValueObservingOptionNew//|NSKeyValueObservingOptionInitial
								 context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
							      forKeyPath:@"defaults.articleViewFontSize"
								 options:NSKeyValueObservingOptionNew//|NSKeyValueObservingOptionInitial
								 context:nil];
    [[NSUserDefaultsController sharedUserDefaultsController] addObserver:self
							      forKeyPath:@"defaults.showDistractingMessage"
								 options:NSKeyValueObservingOptionNew//|NSKeyValueObservingOptionInitial
								 context:nil];
    NSError*error;
    NSString*templateForWebView=[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"template" 
												   ofType:@"html"] 
							  encoding:NSUTF8StringEncoding
							     error:&error];
    [[self mainFrame] loadHTMLString:templateForWebView baseURL:nil];    
    
    observedKeys=@[@"abstract",@"arxivCategory",@"authors",@"comments",@"eprint",
		  @"journal",@"pdfPath",@"title",@"texKey"];

    
}
-(BOOL)acceptsFirstResponder
{
    return NO;
}
-(void)keyDown:(NSEvent*)ev
{
    //    NSLog(@"%x",[ev keyCode]);
    if([[ev characters] isEqualToString:@" "]){
	[NSApp sendAction:@selector(openSelectionInQuickLook:) to:nil from:self];
    }else if([ev keyCode]==0x24 || [ev keyCode]==76){ // if return or enter
	[NSApp sendAction:@selector(openPDForJournal:) to:nil from:self];
    }else{
	[super keyDown:ev];
    }
}

#pragma mark property generation

-(NSString*)articleViewFontSize
{
    float fontSize=[[[NSUserDefaults standardUserDefaults] valueForKey:@"articleViewFontSize"] floatValue];
    return [NSString stringWithFormat:@"%fpt",(double)fontSize];
}
-(NSString*)articleViewFontName
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:@"articleViewFontName"];
}

#pragma mark KVO
-(void)refresh
{
    HTMLArticleHelper*helper=[[HTMLArticleHelper alloc] initWithArticle:article];
    DOMDocument*doc=[[self mainFrame] DOMDocument];
    DOMHTMLElement*mainBox=(DOMHTMLElement*)[doc getElementById:@"mainBox"];
    DOMHTMLElement*centerBox=(DOMHTMLElement*)[doc getElementById:@"centerBox"];
    DOMHTMLElement*messageBox=(DOMHTMLElement*)[doc getElementById:@"messageBox"];
    if(!article || article==NSNoSelectionMarker){
	mainBox.style.visibility=@"hidden";
	centerBox.style.visibility=@"visible";
	centerBox.innerHTML=@"No Selection";
    }else if(article==NSMultipleValuesMarker){
	mainBox.style.visibility=@"hidden";
	centerBox.style.visibility=@"visible";
	centerBox.innerHTML=@"Multiple Selections";
    }else{
	mainBox.style.visibility=@"visible";
	centerBox.style.visibility=@"hidden";
	NSMutableArray*keys=[NSMutableArray arrayWithObjects:@"spires",@"citedBy",@"refersTo",nil];
	[keys addObjectsFromArray:observedKeys];
	for(NSString* key in keys){
	    NSString* x=[helper valueForKey:key];
	    if(!x)x=@"";
	    if(x==NSNoSelectionMarker)x=@"";
	    ((DOMHTMLElement*)[doc getElementById:key]).innerHTML=x;
	}
	mainBox.style.fontSize=[self articleViewFontSize];
	mainBox.style.fontFamily=[self articleViewFontName];
    }
    if(message && [[NSUserDefaults standardUserDefaults] boolForKey:@"showDistractingMessage"]){
	messageBox.style.visibility=@"visible";
        [self stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"messageBox\").style.webkitAnimationName=\"blinking\";"];
        [self stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"messageBox\").style.webkitAnimationIterationCount=\"infinite\";"];
	messageBox.innerHTML=message;
    }else{
        [self stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"messageBox\").style.webkitAnimationName=\"steady\";"];
        [self stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"messageBox\").style.webkitAnimationIterationCount=\"0\";"];
	messageBox.style.visibility=@"hidden";
    }
//    doc.body.scrollTop=0;
//    [doc.body scrollIntoViewIfNeeded:YES];
 //      NSLog(@"%@",[self mainFrame]);
    
}
-(void)setArticle:(Article*)a
{
    if(article && article!=NSNoSelectionMarker && article!=NSMultipleValuesMarker){
	for(NSString* i in observedKeys){
	    [article removeObserver:self forKeyPath:i];
	}
    }
    article=a;
    if(article&& article!=NSNoSelectionMarker && article!=NSMultipleValuesMarker){
	for(NSString* i in observedKeys){
		[article addObserver:self
			  forKeyPath:i
			     options:NSKeyValueObservingOptionNew//|NSKeyValueObservingOptionInitial
			     context:nil];
	}
    }
    
    [self refresh];
}
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self refresh];
}
-(NSString*)message
{
    return message;
}
-(void)setMessage:(NSString*)m
{
    message=m;
    [self refresh];
}

@end

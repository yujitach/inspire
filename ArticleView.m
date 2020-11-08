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
#import "MOC.h"

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mocMerged:) name:UIMOCDidMergeNotification object:nil];

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(onAppearanceChanged:) name:@"AppleInterfaceThemeChangedNotification" object:nil];

    
    NSError*error;
    NSString*templateForWebView=[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"template" 
												   ofType:@"html"] 
							  encoding:NSUTF8StringEncoding
							     error:&error];
    if(@available(macOS 10.15,*)){
    }else{
        if([self isDark]){
            templateForWebView=[templateForWebView stringByReplacingOccurrencesOfString:@"background-color:white;color:black;" withString:@"background-color:#292a30;color:white;"];
        }
    }
    [[self mainFrame] loadHTMLString:templateForWebView baseURL:nil];
    
    observedKeys=@[@"abstract",@"arxivCategory",@"authors",@"comments",@"eprint",
		  @"journal",@"pdfPath",@"title",@"texKey"];

    
}
-(void)onAppearanceChanged:(NSNotification*)n
{
    [self refresh];
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
-(void)mocMerged:(NSNotification*)notification
{
    [self refresh];
}
-(BOOL)isDark
{
    NSString*appearance=[[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
    return [appearance isEqualToString:@"Dark"] && [[NSProcessInfo processInfo] operatingSystemVersion].minorVersion>=14;
}
-(void)setElementId:(NSString*)elementId visible:(BOOL)visible
{
    [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById(\"%@\").style.visibility=\"%@\";",elementId,visible?@"visible":@"hidden"]];
}
-(void)setElementId:(NSString*)elementId fontSize:(NSString*)fontSize
{
    [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById(\"%@\").style.fontSize=\"%@\";",elementId,fontSize]];
}
-(NSString*)JSONArrayFrom:(NSString*)input
{
    NSData*d=[NSJSONSerialization dataWithJSONObject:@[input] options:0 error:nil];
    NSString*s=[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    return s;
}
-(void)setElementId:(NSString*)elementId fontFamily:(NSString*)fontName
{
    [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById(\"%@\").style.fontFamily=%@[0];",elementId,[self JSONArrayFrom:fontName]]];
}
-(void)setElementId:(NSString*)elementId innerHTML:(NSString*)innerHTML
{
    [self stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.getElementById(\"%@\").innerHTML=%@[0];",elementId,[self JSONArrayFrom:innerHTML]]];
}
-(void)refresh
{
    HTMLArticleHelper*helper=[[HTMLArticleHelper alloc] initWithArticle:article];

    if(@available(macOS 10.15,*)){
        // taken care of within the template.html
    }else{
    if([self isDark]){
        [self stringByEvaluatingJavaScriptFromString:@"document.body.style.color=\"white\";"];
        [self stringByEvaluatingJavaScriptFromString:@"document.body.style.backgroundColor=\"#292a30\";"];
        [self stringByEvaluatingJavaScriptFromString:@"document.styleSheets[0].cssRules[1].style.color=\"rgb(105, 184, 218)\";"];
        [self stringByEvaluatingJavaScriptFromString:@"document.styleSheets[0].cssRules[2].style.color=\"rgb(105, 184, 218)\";"];
    }else{
        [self stringByEvaluatingJavaScriptFromString:@"document.body.style.color=\"black\";"];
        [self stringByEvaluatingJavaScriptFromString:@"document.body.style.backgroundColor=\"white\";"];
        [self stringByEvaluatingJavaScriptFromString:@"document.styleSheets[0].cssRules[1].style.color=\"rgb(59, 53, 244)\";"];
        [self stringByEvaluatingJavaScriptFromString:@"document.styleSheets[0].cssRules[2].style.color=\"rgb(59, 53, 244)\";"];
    }
    }

    if(!article || article==(Article*)NSNoSelectionMarker){
        [self setElementId:@"mainBox" visible:NO];
        [self setElementId:@"centerBox" visible:YES];
        [self setElementId:@"centerBox" innerHTML:@"No Selection"];
    }else if(article==(Article*)NSMultipleValuesMarker){
        [self setElementId:@"mainBox" visible:NO];
        [self setElementId:@"centerBox" visible:YES];
        [self setElementId:@"centerBox" innerHTML:@"Multiple Selections"];
    }else{
        [self setElementId:@"mainBox" visible:YES];
        [self setElementId:@"centerBox" visible:NO];
	NSMutableArray*keys=[NSMutableArray arrayWithObjects:@"spires",@"citedBy",@"refersTo",nil];
	[keys addObjectsFromArray:observedKeys];
	for(NSString* key in keys){
	    NSString* x=[helper valueForKey:key];
	    if(!x)x=@"";
	    if(x==(NSString*)NSNoSelectionMarker)x=@"";
            [self setElementId:key innerHTML:x];
	}
        [self setElementId:@"mainBox" fontSize:[self articleViewFontSize]];
        [self setElementId:@"mainBox" fontFamily:[self articleViewFontName]];
    }
    if(message && [[NSUserDefaults standardUserDefaults] boolForKey:@"showDistractingMessage"]){
        [self setElementId:@"messageBox" visible:YES];
        [self stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"messageBox\").style.webkitAnimationName=\"blinking\";"];
        [self stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"messageBox\").style.webkitAnimationIterationCount=\"infinite\";"];
        [self setElementId:@"messageBox" innerHTML:[message stringByAppendingString:@" <a href=\"spires-cancel://\">🅧</a>"]];
    }else{
        [self stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"messageBox\").style.webkitAnimationName=\"steady\";"];
        [self stringByEvaluatingJavaScriptFromString:@"document.getElementById(\"messageBox\").style.webkitAnimationIterationCount=\"0\";"];
        [self setElementId:@"messageBox" visible:NO];
    }
//    doc.body.scrollTop=0;
//    [doc.body scrollIntoViewIfNeeded:YES];
 //      NSLog(@"%@",[self mainFrame]);
    
}
-(void)setArticle:(Article*)a
{
/*
    if(article && article!=(Article*)NSNoSelectionMarker && article!=(Article*)NSMultipleValuesMarker){
	for(NSString* i in observedKeys){
	    [article removeObserver:self forKeyPath:i];
	}
    }
 */
    article=a;
/*
    if(article&& article!=(Article*)NSNoSelectionMarker && article!=(Article*)NSMultipleValuesMarker){
	for(NSString* i in observedKeys){
		[article addObserver:self
			  forKeyPath:i
			     options:NSKeyValueObservingOptionNew//|NSKeyValueObservingOptionInitial
			     context:nil];
	}
    }
 */
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

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
#import "RegExKitLite.h"
#import "NSString+magic.h"

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
	[NSApp sendAction:@selector(openPDF:) to:nil from:self];
    }else{
	[super keyDown:ev];
    }
}
#pragma mark MockTeX
-(NSString*)mockTeX:(NSString*)string
{
    NSMutableString*s=[NSMutableString stringWithString:string];
//    [s replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSLiteralSearch range:NSMakeRange(0,[s length])];
//    [s replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange(0,[s length])];

    [s replaceOccurrencesOfString:@"\n" withString:@" " options:NSLiteralSearch range:NSMakeRange(0,[s length])];
    [s replaceOccurrencesOfString:@"\\ " withString:@"SpaceMarker" options:NSLiteralSearch range:NSMakeRange(0,[s length])];
    [s replaceOccurrencesOfString:@"\\_" withString:@"UnderscoreMarker" options:NSLiteralSearch range:NSMakeRange(0,[s length])];
    
    {
	NSDictionary* texMacrosWithoutArguments=[[NSUserDefaults standardUserDefaults] objectForKey:@"htmlTeXMacrosWithoutArguments"];
	NSArray* prepositions=[[NSUserDefaults standardUserDefaults] objectForKey:@"prepositions"];
	NSArray* stop=[[NSUserDefaults standardUserDefaults] objectForKey:@"htmlTeXMacrosWithoutArgumentsWhichRequireBackSlash"];
	for(NSString* key in [texMacrosWithoutArguments keyEnumerator]){
	    NSString* from=[NSString stringWithFormat:@"\\\\%@(_|\\W)",key];
	    NSString* to=[texMacrosWithoutArguments objectForKey:key];
	    NSString* rep=[NSString stringWithFormat:@"%@$1",to];
	    [s replaceOccurrencesOfRegex:from withString:rep];
	    [s replaceOccurrencesOfRegex:from withString:rep];
	    if([prepositions containsObject:key])
		continue;
	    if([stop containsObject:key])
		continue;
	    from=[NSString stringWithFormat:@"(\\W)%@(\\W)",key];
	    rep=[NSString stringWithFormat:@"$1%@$2",to];
	    [s replaceOccurrencesOfRegex:from withString:rep];
	    [s replaceOccurrencesOfRegex:from withString:rep];
	}
    }
    
    {
	NSDictionary* texMacrosWithOneArgument=[[NSUserDefaults standardUserDefaults] objectForKey:@"htmlTeXMacrosWithOneArgument"];
	for(NSString* key in [texMacrosWithOneArgument keyEnumerator]){
	    NSString* from=[NSString stringWithFormat:@"\\\\%@ +(.)",key];
	    NSString* to=[texMacrosWithOneArgument objectForKey:key];
	    [s replaceOccurrencesOfRegex:from withString:to];
	    
	    from=[NSString stringWithFormat:@"\\\\%@\\{(.+?)\\}",key];
	    [s replaceOccurrencesOfRegex:from withString:to];
	}
    }
    
    {
	NSArray* texRegExps=[[NSUserDefaults standardUserDefaults] objectForKey:@"htmlTeXRegExps"];
	for(NSArray* pair in texRegExps){
	    NSString* from=[pair objectAtIndex:0];
	    NSString* to=[pair objectAtIndex:1];
	    [s replaceOccurrencesOfRegex:from withString:to];	
	}
	[s replaceOccurrencesOfString:@"SpaceMarker" withString:@" " options:NSLiteralSearch range:NSMakeRange(0,[s length])];
	[s replaceOccurrencesOfString:@"UnderscoreMarker" withString:@"_" options:NSLiteralSearch range:NSMakeRange(0,[s length])];
	[s replaceOccurrencesOfString:@"}" withString:@" " options:NSLiteralSearch range:NSMakeRange(0,[s length])];
	[s replaceOccurrencesOfString:@"{" withString:@" " options:NSLiteralSearch range:NSMakeRange(0,[s length])];
    }
    return s;
}
#pragma mark Property Generation
-(NSString*)author
{
    NSArray*names=[article.longishAuthorListForEA componentsSeparatedByString:@"; "];
    NSMutableArray* a=[NSMutableArray array];
    for(NSString*x in names){
	if(![x isEqualToString:@""]){
	    [a addObject:x];
	}
    }
    [a sortUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableArray*b=[NSMutableArray array];
    for(NSString*s in a){
	NSString* searchString=[NSString stringWithFormat:@"spires-search://a %@",s];
	searchString=[searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSMutableString*result=[NSMutableString stringWithFormat:@"<a href=\"%@\">",searchString];
	NSArray* c=[s componentsSeparatedByString:@", "];
	NSString* last=[c objectAtIndex:0];
	if([c count]>1){
	    NSArray* d=[[c objectAtIndex:1] componentsSeparatedByString:@" "];
	    if([last hasPrefix:@"collaboration"]){
		[result appendString:[[d lastObject] uppercaseString]];
		last=@" Collaboration";
	    }else if([[c objectAtIndex:1] hasPrefix:@"for the"]){
		[result appendString:[last uppercaseString]];
		last=@" Collaboration";		
	    }else{
		for(NSString*i in d){
		    if(!i || [i isEqualToString:@""]) continue;
		    [result appendString:[[i substringToIndex:1] capitalizedStringForName]];
		    [result appendString:@". "];
		}
	    }
	}
	[result appendString:[last capitalizedStringForName]];
	[result appendString:@"</a>"];
	[b addObject: result];
    }
    
    return [b componentsJoinedByString:@", "];
}
-(NSString*)abstract
{
 /*   NSString*tmp=article.abstract;
    if(!tmp){
	return nil;
    }
    NSMutableString*a=[NSMutableString stringWithString:tmp];
    int location;
    while((location=[a rangeOfString:@"_"].location)!=NSNotFound){
	NSString*s=[a substringWithRange:NSMakeRange(location+1,1)];
	[a replaceCharactersInRange:NSMakeRange(location,2) withString:[NSString stringWithFormat:@"<sub>%@</sub>",s]];
    }
    while((location=[a rangeOfString:@"^"].location)!=NSNotFound){
	NSString*s=[a substringWithRange:NSMakeRange(location+1,1)];
	[a replaceCharactersInRange:NSMakeRange(location,2) withString:[NSString stringWithFormat:@"<sub>%@</sub>",s]];
    }
    return a;*/
    if(article.abstract==nil)
	return nil;
    NSString* result= [[self mockTeX:article.abstract] stringByReplacingOccurrencesOfString:@"href=\"" withString:@"href=\"spires-lookup-eprint://"];
//    NSLog(@"%@",result);
    return result;
    
}
-(NSString*)comments
{
    if(article.comments==nil)
	return nil;
    return [NSString stringWithFormat:@"<b>Comments:</b> %@",article.comments];
    
}

-(NSString*)title
{
    return [self mockTeX:[article valueForKey:@"quieterTitle"]];
}
-(NSString*)eprint
{
    if(article.articleType!=ATEprint)
	return nil;
    NSString* eprint= article.eprint;
    //return [NSString stringWithFormat:@"[%@]&nbsp;&nbsp;", eprint];
    NSString*path=[[ArxivHelper sharedHelper] arXivAbstractPathForID:eprint];

    return [NSString stringWithFormat:@"[<a class=\"nonloudlink\" href=\"%@\">%@</a>]",path, eprint];
}
-(NSString*)pdf
{
    if(article.articleType==ATEprint ){
//	if(article.hasPDFLocally){
	    return @"<a href=\"spires-open-pdf-internal://\">pdf</a>";
//	}else{
//	    return @"get <a href=\"spires-download-and-open-pdf-internal://\">pdf</a>";
//	}
    }
    if(article.hasPDFLocally){
	NSString* path=[article.pdfPath stringByAbbreviatingWithTildeInPath];
	NSString* dir=[[NSUserDefaults standardUserDefaults] stringForKey:@"pdfDir"];
	if([path hasPrefix:dir]){
	    path=@"pdf";
	}
	return [NSString stringWithFormat:@"<a href=\"spires-open-pdf-internal://\">%@</a>",path];
	
    }else{
	return @"<del>pdf</del>";
    }
}
-(NSString*)spires{
    NSString* target=nil;
    if(article.articleType==ATEprint){
	target=[@"eprint " stringByAppendingString:article.eprint];
    }else if(article.articleType==ATSpires){
	target=[@"spicite " stringByAppendingString:article.spicite];	
    }else if(article.articleType==ATSpiresWithOnlyKey){
	target=[@"key " stringByAppendingString:[article.spiresKey stringValue]];	
    }
    if(target){
	NSURL*url=[[SpiresHelper sharedHelper] spiresURLForQuery:target];
	NSString* urlString=[url absoluteString];
	return [NSString stringWithFormat:@"<a href=\"%@\">spires</a>",urlString];
    }else{
	return [NSString stringWithFormat:@"<del>spires</del>"];
    }
    return nil;
}
-(NSString*)journal{
    if(!article.journal)return nil;
    JournalEntry*j=article.journal;
    NSString* str=[NSString stringWithFormat:@"%@ <span class=\"vol\">%@</span> (%@) %@",j.name,j.volume,j.year,j.page];
    if(article.eprint && ![article.eprint isEqualTo:@""]){
	str=[NSString stringWithFormat:@"<a class=\"nonloudlink\" href=\"spires-open-journal://\">%@</a>",str];
	return str;
    }
    if(article.hasPDFLocally){
	str=[NSString stringWithFormat:@"<a class=\"nonloudlink\" href=\"spires-open-journal://\">%@</a>",str];	
	return str;
    }
    if(article.doi && ![article.doi isEqualTo:@""]){
//	NSString* doiURL=[@"http://dx.doi.org/" stringByAppendingString:article.doi];
	str=[NSString stringWithFormat:@"<a href=\"spires-open-journal://\">%@</a>",str];
    }
    return str;
}
-(NSString*)bibEntry{
    NSString* x=article.texKey;
    if(x &&[[[NSUserDefaults standardUserDefaults] stringForKey:@"bibType"] isEqualToString:@"harvmac"]){
	x=[article extraForKey:@"harvmacKey"];
    }
    if(!x || [x isEqualToString:@""]){
	x=@"\\bibitem{?}";
    }
    return [NSString stringWithFormat:@"<a href=\"spires-get-bib-entry://\">%@</a>",x];
}
-(NSString*)citedBy{
    if(article.eprint && ![article.eprint isEqualToString:@""]){
	return [NSString stringWithFormat:@"<a href=\"spires-search://c %@\">cited by</a>",article.eprint];
    }
    if(article.spicite && ![article.spicite isEqualToString:@""]){
	return [NSString stringWithFormat:@"<a href=\"spires-search://c %@\">cited by</a>",article.spicite];
    }
    return @"<del>cited by</del>";
}
-(NSString*)refersTo{
    if(article.eprint && ![article.eprint isEqualToString:@""]){
	return [NSString stringWithFormat:@"<a href=\"spires-search://r %@\">refers to</a>",article.eprint];
    }
    if(article.spiresKey && [article.spiresKey integerValue]!=0){
	return [NSString stringWithFormat:@"<a href=\"spires-search://r key %@\">refers to</a>",article.spiresKey];
    }
    return @"<del>refers to</del>";
}
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
    if(!article || article==NSNoSelectionMarker){
	[[self mainFrame] loadHTMLString:@"<div style=\"text-align:center;font-family:optima\">No Selection</div>" baseURL:nil];
	return;
    }else if(article==NSMultipleValuesMarker){
	[[self mainFrame] loadHTMLString:@"<div style=\"text-align:center;font-family:optima\">Multiple Selections</div>" baseURL:nil];
	return;	
    }
    NSMutableString* s=[NSMutableString stringWithString:templateForWebView];
    for(NSString* key in [NSArray arrayWithObjects:@"articleViewFontSize",@"articleViewFontName",@"abstract",@"comments",@"title",@"eprint",@"author",@"pdf",@"spires",@"journal",@"bibEntry",@"citedBy",@"refersTo",nil]){
	NSString* keyInHTML=[@"$" stringByAppendingString:key];
	NSString* x=[self valueForKey:key];
	if(!x)x=@"";
	if(x==NSNoSelectionMarker)x=@"";
	[s replaceOccurrencesOfString:keyInHTML
			   withString:x    
			      options:NSLiteralSearch
				range:NSMakeRange(0,[s length])];
    }
 //      NSLog(@"%@",[self mainFrame]);
    [[self mainFrame] loadHTMLString:s baseURL:nil];//[NSURL URLWithString:@""]];
    
}
-(void)setArticle:(Article*)a
{
    NSArray*observedKeys=[NSArray arrayWithObjects:@"abstract",@"title",@"authors",@"texKey",@"pdfPath",@"journal",@"comments",nil];
    if(article && article!=NSNoSelectionMarker && article!=NSMultipleValuesMarker){
	for(NSString* i in observedKeys){
	    [article removeObserver:self forKeyPath:i];
	}
    }
    article=a;
    NSError*error=nil;
/*    if(!a || a==NSNoSelectionMarker || a==NSNotApplicableMarker){
//	NSLog(@"article:nil");
	templateForWebView=nil;
    }else if(a==NS){
    }else{*/
//	NSLog(@"%@",article);
	templateForWebView=[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"template" 
											  ofType:@"html"] 
						 encoding:NSUTF8StringEncoding
						    error:&error];
//    }
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
@end

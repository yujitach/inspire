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
#import "SpiresAppDelegate_actions.h"

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
    
    observedKeys=[NSArray arrayWithObjects:
		  @"abstract",@"arxivCategory",@"authors",@"comments",@"eprint",
		  @"journal",@"pdfPath",@"title",@"texKey",nil];

    
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

#pragma mark Property Generation
-(NSString*)authors
{
    NSArray*names=[article.longishAuthorListForEA componentsSeparatedByString:@"; "];
    NSString*collaboration=nil;
    NSMutableArray* a=[NSMutableArray array];
    for(NSString*x in names){
	if(![x isEqualToString:@""]){
	    if([x rangeOfString:@"collaboration"].location!=NSNotFound){
		collaboration=x;
	    }else{
		[a addObject:x];
	    }
	}
    }
//    [a sortUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableArray*b=[NSMutableArray array];
    NSArray*particles=[[NSUserDefaults standardUserDefaults] objectForKey:@"particles"];
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
	    }else if([last isEqualTo:@"group"]||
		     [last isEqualTo:@"groups"]||
		     [last isEqualTo:@"physics"]){
		[result appendFormat:@"%@ ",[[c objectAtIndex:1] capitalizedString]];		
	    }else{
		for(NSString*i in d){
		    if(!i || [i isEqualToString:@""]) continue;
                    if(![particles containsObject:i]){
                        [result appendString:[[i substringToIndex:1] capitalizedStringForName]];
                        [result appendString:@". "];
                    }else{
                        [result appendString:i];                        
                        [result appendString:@" "];                        
                    }
		}
	    }
	}
	[result appendString:[last capitalizedStringForName]];
	[result appendString:@"</a>"];
	[b addObject: result];
    }
    if(collaboration){
	collaboration=[collaboration uppercaseString];
	collaboration=[collaboration stringByReplacingOccurrencesOfRegex:@"COLLABORATION(S?)" withString:@"Collaboration$1"];
	NSString* searchString=[collaboration stringByReplacingOccurrencesOfRegex:@"Collaborations?" withString:@""];
	searchString=[NSString stringWithFormat:@"spires-search://cn %@",searchString];
	searchString=[searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSMutableString*result=[NSMutableString stringWithFormat:@"<a href=\"%@\">",searchString];
	[result appendFormat:@"%@</a>",collaboration];
	if([b count]>0 && [b count]<10){
	    [result appendFormat:@" (%@)",[b componentsJoinedByString:@", "]];
	}
	return result;
    }else{
	return [b componentsJoinedByString:@", "];
    }
}
-(NSString*)abstract
{
    if(article.abstract==nil)
	return nil;
    NSString* result= [[article.abstract stringByConvertingTeXintoHTML] stringByReplacingOccurrencesOfString:@"href=\"" withString:@"href=\"spires-lookup-eprint://"];
//    NSLog(@"%@",result);
    return result;
    
}
-(NSString*)arxivCategory
{
    NSString* category=article.arxivCategory;
    if(category && ![category isEqualToString:@""] && [article.eprint rangeOfString:@"/"].location==NSNotFound){
	return [NSString stringWithFormat:@"[%@]",category];
    }else{
	return nil;
    }
}
-(NSString*)comments
{
    if(!article.comments)
	return nil;
    return article.comments;
    //[NSString stringWithFormat:@"<b>Comments:</b> %@",article.comments];    
}

-(NSString*)title
{
    NSString*s=article.quieterTitle;
    s=[s stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    s=[s stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
    s=[s stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
    s=[s stringByConvertingTeXintoHTML];
    return s;
}
-(NSString*)eprint
{
    if(![article isEprint])
	return nil;
    NSString* eprint= article.eprint;
    //return [NSString stringWithFormat:@"[%@]&nbsp;&nbsp;", eprint];
    NSString*path=[[ArxivHelper sharedHelper] arXivAbstractPathForID:eprint];
    
    return [NSString stringWithFormat:@"[<a class=\"nonloudlink\" href=\"%@\">%@</a>]&nbsp;",path, eprint];
}
-(NSString*)pdfPath
{
    if([article isEprint]){
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
-(NSString*)inspire_
{
    NSString* target=[article uniqueInspireQueryString];
    if(target){
        NSURL*url=[[SpiresHelper sharedHelper] inspireURLForQuery:target];
	NSString* urlString=[url absoluteString];
	return [NSString stringWithFormat:@"<a href=\"%@&of=hd\">inspire</a>",urlString];
    }else{
	return [NSString stringWithFormat:@"<del>spires</del>"];
    }
    return nil;
}
-(NSString*)spires_
{
    NSString* target=[article uniqueSpiresQueryString];
    if(target){
	NSURL*url=[[SpiresHelper sharedHelper] spiresURLForQuery:target];
	NSString* urlString=[url absoluteString];
	return [NSString stringWithFormat:@"<a href=\"%@\">spires</a>",urlString];
    }else{
	return [NSString stringWithFormat:@"<del>spires</del>"];
    }
    return nil;
}
-(NSString*)spires
{
    if([[NSApp appDelegate] useInspire]){
        return [self inspire_];
    }else{
        return [self spires_];
    }
}
-(NSString*)journalNumber:(JournalEntry*)j
{
    if(j.volume){
	return [NSString stringWithFormat:@"<span class=\"vol\">%@</span> (%@) %@",j.volume,j.year,j.page];
    }else{
	return @"";
    }
}
-(NSString*)journal{
    if(!article.journal)return nil;
    JournalEntry*j=article.journal;
    NSString* str=[NSString stringWithFormat:@"%@ %@",j.name,[self journalNumber:j]];
    if((article.eprint && ![article.eprint isEqualTo:@""]) || article.hasPDFLocally){
	str=[NSString stringWithFormat:@"<a class=\"nonloudlink\" href=\"spires-open-journal://\">%@</a>",str];
	return str;
    }
    if(article.doi && ![article.doi isEqualTo:@""]){
//	NSString* doiURL=[@"http://dx.doi.org/" stringByAppendingString:article.doi];
	str=[NSString stringWithFormat:@"<a href=\"spires-open-journal://\">%@</a>",str];
    }
    return str;
}
-(NSString*)texKey{
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
    if([[[NSUserDefaults standardUserDefaults] stringForKey:@"databaseToUse"] isEqualToString:@"inspire"] 
       && article.spiresKey && [article.spiresKey integerValue]!=0){
	return [NSString stringWithFormat:@"<a href=\"spires-search://c key %@\">cited by</a>",article.spiresKey];
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
	    NSString* x=[self valueForKey:key];
	    if(!x)x=@"";
	    if(x==NSNoSelectionMarker)x=@"";
	    ((DOMHTMLElement*)[doc getElementById:key]).innerHTML=x;
	}
	mainBox.style.fontSize=[self articleViewFontSize];
	mainBox.style.fontFamily=[self articleViewFontName];
    }
    if(message && [[NSUserDefaults standardUserDefaults] boolForKey:@"showDistractingMessage"]){
	messageBox.style.visibility=@"visible";
	messageBox.innerHTML=message;
    }else{
	messageBox.style.visibility=@"hidden";
    }
    doc.body.scrollTop=0;
    [doc.body focus];
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

//
//  HTMLArticleHelper.m
//  inspire
//
//  Created by Yuji on 2015/08/29.
//
//

#import "HTMLArticleHelper.h"
#import "Article.h"
#import "JournalEntry.h"
#import "RegexKitLite.h"
#import "NSString+magic.h"
#import "ArxivHelper.h"
#import "SpiresHelper.h"
@implementation HTMLArticleHelper
{
    Article*article;
}
-(instancetype)initWithArticle:(Article*)a
{
    self=[super init];
    article=a;
    return self;
}
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
        searchString=[searchString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSMutableString*result=[NSMutableString stringWithFormat:@"<a href=\"%@\">",searchString];
        NSArray* c=[s componentsSeparatedByString:@", "];
        NSString* last=c[0];
        if([c count]>1){
            NSArray* d=[c[1] componentsSeparatedByString:@" "];
            if([last hasPrefix:@"collaboration"]){
                [result appendString:[[d lastObject] uppercaseString]];
                last=@" Collaboration";
            }else if([c[1] hasPrefix:@"for the"]){
                [result appendString:[last uppercaseString]];
                last=@" Collaboration";
            }else if([last isEqualToString:@"group"]||
                     [last isEqualToString:@"groups"]||
                     [last isEqualToString:@"physics"]){
                [result appendFormat:@"%@ ",[c[1] capitalizedString]];
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
        searchString=[searchString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
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
    // the code here is to trim excessive & escapes introduced in older versions
    NSString*trim=[article.abstract stringByReplacingOccurrencesOfRegex:@"&(amp;)+" withString:@"&"];
    for(NSString*tag in @[@"i",@"sub",@"sup"]){
        NSString*from=[NSString stringWithFormat:@"&lt;(/*)%@&gt;",tag];
        NSString*to=[NSString stringWithFormat:@"<$1%@>",tag];
        trim=[trim stringByReplacingOccurrencesOfRegex:from withString:to];
    }
    if(![trim isEqualToString:article.abstract]){
        article.abstract=trim;
    }
    //    trim=[trim stringByReplacingOccurrencesOfRegex:@"&lt;img.+&gt;" withString:@"_"];
    // up to this point.
    NSString* result= [[trim stringByConvertingTeXintoHTML] stringByReplacingOccurrencesOfString:@"href=\"" withString:@"href=\"spires-lookup-eprint://"];
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
    return [article.comments stringByReplacingOccurrencesOfString:@"href=\"" withString:@"href=\"spires-lookup-eprint://"];
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
        return [NSString stringWithFormat:@"<a href=\"spires-open-pdf-internal://%@\">pdf</a>",article.objectID.URIRepresentation];
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
        return [NSString stringWithFormat:@"<a href=\"spires-open-pdf-internal://%@\">%@</a>",article.objectID.URIRepresentation,path];
        
    }else{
        return @"<del>pdf</del>";
    }
}
-(NSString*)spires
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
    if((article.eprint && ![article.eprint isEqualToString:@""]) || article.hasPDFLocally){
        str=[NSString stringWithFormat:@"<a class=\"nonloudlink\" href=\"spires-open-journal://\">%@</a>",str];
        return str;
    }
    if(article.doi && ![article.doi isEqualToString:@""]){
        //	NSString* doiURL=[@"http://dx.doi.org/" stringByAppendingString:article.doi];
        str=[NSString stringWithFormat:@"<a href=\"spires-open-journal://\">%@</a>",str];
    }
    return str;
}
-(NSString*)flagUnflag{
    if(article.flag&AFIsFlagged){
        return [NSString stringWithFormat:@"<a href=\"spires-unflag://%@\">(un)flag</a>",article.objectID.URIRepresentation];
    }else{
        return [NSString stringWithFormat:@"<a href=\"spires-flag://%@\">(un)flag</a>",article.objectID.URIRepresentation];
    }
}
-(NSString*)flagged{
    if(article.flag&AFIsFlagged){
        return @"⭐️";
    }else{
        return @"";
    }
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
    //    if(article.spicite && ![article.spicite isEqualToString:@""]){
    //	return [NSString stringWithFormat:@"<a href=\"spires-search://c %@\">cited by</a>",article.spicite];
    //    }
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

@end

//
//  LightweightArticle.m
//  inspire
//
//  Created by Yuji on 2015/08/11.
//
//

#import "LightweightArticle.h"
#import "Article.h"
#import "JournalEntry.h"

@implementation LightweightArticle
{
    NSMutableDictionary*dic;
    NSString*sortKey;
}

#define STANDARDKEYS @"spiresKey,inspireKey,eprint,title,collaboration,doi,abstract,comments,citecount,pages,date"

-(void)populatePropertiesOfArticle:(Article*)o
{
    for(NSString*key in [STANDARDKEYS componentsSeparatedByString:@","]){
        NSObject*x=[self valueForKey:key];
        if(x){
            [o setValue:x forKey:key];
        }
    }
    [o setAuthorNames:self.authors];
    if(!(o.journal) && self.journalTitle){
        o.journal=[JournalEntry journalEntryWithName:self.journalTitle
                                              Volume:self.journalVolume
                                                Year:self.journalYear
                                                Page:self.journalPage
                                               inMOC:[o managedObjectContext]];
    }
    
    if(o.abstract){
        NSString*abstract=o.abstract;
        abstract=[abstract stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
        abstract=[abstract stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"];
        abstract=[abstract stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
        o.abstract=abstract;
    }

}
-(instancetype)initWithArticle:(Article *)a
{
    self=[self init];
    for(NSString*key in [STANDARDKEYS componentsSeparatedByString:@","]){
        NSObject*x=[a valueForKey:key];
        if(x){
            [self setValue:x forKey:key];
        }
    }
    NSArray*names=[a.longishAuthorListForEA componentsSeparatedByString:@"; "];
    if(a.collaboration && ![a.collaboration isEqualToString:@""]){
        names=[names subarrayWithRange:NSMakeRange(1, names.count-1)];
    }
    self.authors=names;
    if(!a.journal){
        JournalEntry*j=a.journal;
        self.journalTitle=j.name;
        self.journalPage=j.page;
        self.journalVolume=j.volume;
        self.journalYear=j.year;
    }
    if(self.abstract){
        NSString*abstract=self.abstract;
        abstract=[abstract stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
        abstract=[abstract stringByReplacingOccurrencesOfString:@"&lt;" withString:@"<"];
        abstract=[abstract stringByReplacingOccurrencesOfString:@"&gt;" withString:@">"];
        self.abstract=abstract;
    }
    return self;
}
-(instancetype)initWithDictionary:(NSDictionary*)dic_
{
    self=[self init];
    dic=[dic_ mutableCopy];
    if([dic[@"inspireKey"] integerValue]==0){
        [dic removeObjectForKey:@"inspireKey"];
    }
    if([dic[@"spiresKey"] integerValue]==0){
        [dic removeObjectForKey:@"spiresKey"];
    }
    return self;
}
-(NSDictionary*)dic
{
    return dic;
}
-(NSString*)sortKey
{
    if(!sortKey){
        NSString*s=[NSString stringWithFormat:@"%@%@%@%@%@",self.inspireKey,self.eprint,self.spiresKey,self.doi,self.title];
        sortKey=s;
    }
    return sortKey;
}
-(instancetype)init{
    self=[super init];
    dic=[NSMutableDictionary dictionary];
    dic[@"authors"]=[NSMutableArray array];
    return self;
}
-(void)addAuthor:(NSString *)author
{
    NSMutableArray*a=dic[@"authors"];
    [a addObject:author];
}
-(void)setTitle:(NSString*)x
{
    dic[@"title"]=x;
}
-(NSString*)title
{
    return dic[@"title"];
}
-(void)setInspireKey:(NSNumber*)x
{
    dic[@"inspireKey"]=x;
}
-(NSNumber*)inspireKey
{
    return dic[@"inspireKey"];
}
-(void)setSpiresKey:(NSNumber*)x
{
    dic[@"spiresKey"]=x;
}
-(NSNumber*)spiresKey
{
    return dic[@"spiresKey"];
}
-(void)setEprint:(NSString*)x
{
    dic[@"eprint"]=x;
}
-(NSString*)eprint
{
    return dic[@"eprint"];
}
-(void)setAuthors:(NSArray*)x
{
    dic[@"authors"]=x;
}
-(NSArray*)authors
{
    return dic[@"authors"];
}
-(void)setAbstract:(NSString*)x
{
    dic[@"abstract"]=x;
}
-(NSString*)abstract
{
    return dic[@"abstract"];
}
-(void)setCollaboration:(NSString*)x
{
    dic[@"collaboration"]=x;
}
-(NSString*)collaboration
{
    return dic[@"collaboration"];
}
-(void)setPages:(NSNumber*)x
{
    dic[@"pages"]=x;
}
-(NSNumber*)pages
{
    return dic[@"pages"];
}
-(void)setCitecount:(NSNumber*)x
{
    dic[@"citecount"]=x;
}
-(NSNumber*)citecount
{
    return dic[@"citecount"];
}
-(void)setDate:(NSDate*)x
{
    dic[@"date"]=x;
}
-(NSDate*)date
{
    return dic[@"date"];
}
-(void)setDoi:(NSString*)x
{
    dic[@"doi"]=x;
}
-(NSString*)doi
{
    return dic[@"doi"];
}
-(void)setComments:(NSString*)x
{
    dic[@"comments"]=x;
}
-(NSString*)comments
{
    return dic[@"comments"];
}
-(void)setJournalTitle:(NSString*)x
{
    dic[@"journalTitle"]=x;
}
-(NSString*)journalTitle
{
    return dic[@"journalTitle"];
}
-(void)setJournalVolume:(NSString*)x
{
    dic[@"journalVolume"]=x;
}
-(NSString*)journalVolume
{
    return dic[@"journalVolume"];
}
-(void)setJournalPage:(NSString*)x
{
    dic[@"journalPage"]=x;
}
-(NSString*)journalPage
{
    return dic[@"journalPage"];
}
-(void)setJournalYear:(NSNumber*)x
{
    dic[@"journalYear"]=x;
}
-(NSNumber*)journalYear
{
    return dic[@"journalYear"];
}
@end

/*
 while(<>){
	($c,$a)=(/ (NS.+?\*)(.+?);/);
	$b=ucfirst $a;
	print <<EOF;
 -(void)set$b:($c)x
 {
	dic[@"$a"]=x;
 }
 -($c)$a
 {
	return dic[@"$a"];
 }
 EOF
 }

*/

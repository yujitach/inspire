//
//  LightweightArticle.m
//  inspire
//
//  Created by Yuji on 2015/08/11.
//
//

#import "LightweightArticle.h"

@implementation LightweightArticle
{
    NSMutableDictionary*dic;
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

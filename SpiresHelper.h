//
//  SpiresHelper.h
//  spires
//
//  Created by Yuji on 08/10/16.
//  Copyright 2008 Y. Tachikawa. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define SPIRESXMLHEAD @"http://www.slac.stanford.edu/spires/find/hep/xmlpublic?rawcmd=find+"
#define SPIRESREFHEAD @"http://www.slac.stanford.edu/spires/find/hep/wwwrefsbibtex?"
#define SPIRESWWWHEAD @"http://www.slac.stanford.edu/spires/find/hep/www?rawcmd=find+"
#define SPIRESBIBTEXHEAD @"http://www.slac.stanford.edu/spires/find/hep/wwwbriefbibtex?rawcmd=find+"
#define SPIRESLATEX2HEAD @"http://www.slac.stanford.edu/spires/find/hep/wwwbrieflatex2?rawcmd=find+"
#define SPIRESHARVMACHEAD @"http://www.slac.stanford.edu/spires/find/hep/wwwbriefharvmac?rawcmd=find+"


@interface SpiresHelper : NSObject {
      
}
+(SpiresHelper*)sharedHelper;
-(NSPredicate*) predicateFromSPIRESsearchString:(NSString*)string;
//-(NSPredicate*) simplePredicateFromSPIRESsearchString:(NSString*)string;
-(NSURL*)spiresURLForQuery:(NSString*)search;
-(NSArray*)bibtexEntriesForQuery:(NSString*)search;
-(NSArray*)latexEUEntriesForQuery:(NSString*)search;
-(NSArray*)harvmacEntriesForQuery:(NSString*)search;
@end

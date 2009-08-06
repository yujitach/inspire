#import "spiresHook.h"
#import <objc/objc-runtime.h>
#import <WebKit/WebKit.h>
#define THISBUNDLE @"com.yujitach.spiresHook"
#pragma mark Safari Hook
typedef void (*hook)(id,SEL,id,id);
hook original=(hook)NULL;
NSDate* lastInvocation=nil;
#define DONOTDIVERTMARK @"?doNotCallSpiresHook"
void new(id self,SEL sel,id a,id b)
{
//    NSLog(@"log:%@,%@",s,t);
    NSAppleEventDescriptor *d=a;
    if([d eventID]!='GURL')goto XXX;
    if([d eventClass]!='GURL')goto XXX;
    NSString* s=[[d paramDescriptorForKeyword:keyDirectObject] stringValue];

    if([s hasSuffix:DONOTDIVERTMARK]){
	NSString* x=[s substringToIndex:[s length]-[DONOTDIVERTMARK length]];
	[d setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:x]
		   forKeyword:keyDirectObject];
	goto XXX;
    }
    NSRange r;
    r=[s rangeOfString:@"arxiv.org" options:NSCaseInsensitiveSearch];
    if(r.location==NSNotFound){
	r=[s rangeOfString:@"xxx.lanl.gov" options:NSCaseInsensitiveSearch];	
	if(r.location==NSNotFound) goto XXX;
    }
    
  /*  if(lastInvocation && (-[lastInvocation timeIntervalSinceNow]<10)){
	goto XXX;
    }*/

    [lastInvocation release];
    lastInvocation=[[NSDate date] retain];
    
    NSString* ss=[s stringByReplacingOccurrencesOfString:@"http" withString:@"spires-lookup-eprint"];
    NSURL* x=[NSURL URLWithString: ss];
    [[NSWorkspace sharedWorkspace] openURL:x];
    return;
XXX:
    original(self,sel,a,b);
}

#pragma mark menuForEvent hook

@interface NSObject (iXHookDummyToEliminateWarning)
-(NSAttributedString*)currentSelection;
//-(id)selectedDOMRange;
//-(NSString*)text;
@end

typedef NSMenu* (*menuForEventHook)(id,SEL,NSEvent*);

#define IXHOOKPDFVIEWSELECTOR @selector(iXHookPDFViewMenuItemSearch:)
menuForEventHook menuForEventOriginalPDFView=(menuForEventHook)NULL;

NSMenu* menuForEventNewPDFView(id self,SEL sel,NSEvent* ev)
{
    NSMenu* m=menuForEventOriginalPDFView(self,sel,ev);
    NSString* s=[[self currentSelection] string];
    if(!s)return m;
    if([s rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location==NSNotFound) return m;
    NSMenuItem* mi=[[[NSMenuItem alloc] init] autorelease];
    [mi setTitle:@"Search by spires"];
    [mi setTarget:self];
    [mi setAction:IXHOOKPDFVIEWSELECTOR];
    [m insertItem:mi atIndex:0];
    return m;
}
void iXHookPDFViewMenuItemSearch(id self,SEL sel,id sender)
{
    NSString*s=[[self currentSelection] string];
    NSURL* u=[NSURL URLWithString:[NSString stringWithFormat:@"spires-lookup-eprint://PreviewHook/%@",s]];
     [[NSWorkspace sharedWorkspace] openURL:u];
    return;
}

#define IXHOOKNSTEXTVIEWSELECTOR @selector(iXHookNSTextViewMenuItemSearch:)
menuForEventHook menuForEventOriginalNSTextView=(menuForEventHook)NULL;

NSMenu* menuForEventNewNSTextView(NSTextView* self,SEL sel,NSEvent* ev)
{
    NSMenu* m=menuForEventOriginalNSTextView(self,sel,ev);
    NSRange r=[self selectedRange];
    if(r.location==NSNotFound)return m;
    NSString* s=[[self attributedSubstringFromRange:r] string];
    if(!s)return m;
    if([s rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location==NSNotFound) return m;
    NSMenuItem* mi=[[[NSMenuItem alloc] init] autorelease];
    [mi setTitle:@"Search by spires"];
    [mi setTarget:self];
    [mi setAction:IXHOOKNSTEXTVIEWSELECTOR];
    [m insertItem:mi atIndex:0];
    return m;
}
void iXHookNSTextViewMenuItemSearch(NSTextView* self,SEL sel,id sender)
{
    NSRange r=[self selectedRange];
    if(r.location==NSNotFound)return;
    NSString* s=[[self attributedSubstringFromRange:r] string];
    if(!s)return;
    NSURL* u=[NSURL URLWithString:[NSString stringWithFormat:@"spires-lookup-eprint://PreviewHook/%@",s]];
    [[NSWorkspace sharedWorkspace] openURL:u];
    return;
}

#pragma mark Mail Hook
#define IXHOOKWEBMESSAGECONTROLLERSELECTOR @selector(iXHookWebMessageControllerMenuItemSearch:)
typedef NSArray* (*MailHook)(id,SEL,WebView*,NSDictionary*,NSArray*);
MailHook mailHookOriginal=(MailHook)NULL;
NSString* savedSelection=nil;
NSArray* mailHookNew(id self,SEL sel,WebView* wv,NSDictionary*dic,NSArray*a)
{
    NSArray* m=mailHookOriginal(self,sel,wv,dic,a);
    NSString* s=[[wv selectedDOMRange] text];
    if(!s)return m;
    if([s rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location==NSNotFound) return m;
    [savedSelection autorelease];
    savedSelection=[s retain];

    NSMenuItem* mi=[[[NSMenuItem alloc] init] autorelease];
    [mi setTitle:@"Search by spires"];
    [mi setTarget:self];
    [mi setAction:IXHOOKWEBMESSAGECONTROLLERSELECTOR];
    NSArray* x=[NSArray arrayWithObject:mi];
    NSArray* y=[x arrayByAddingObjectsFromArray:m];
    return y;
}
void iXHookWebMessageControllerMenuItemSearch(id self,SEL sel,id sender)
{
    if(!savedSelection)return;
    NSURL* u=[NSURL URLWithString:[NSString stringWithFormat:@"spires-lookup-eprint://PreviewHook/%@",savedSelection]];
    [[NSWorkspace sharedWorkspace] openURL:u];
    return;
}

#pragma mark Safari Context Menu Hook
#define IXHOOKSAFARICONTEXTMENUSELECTOR @selector(iXHookWebMessageControllerMenuItemSearch:)
typedef NSArray* (*SafariContextMenuHook)(id,SEL,WebView*,NSDictionary*,NSArray*);
SafariContextMenuHook safariContextMenuHookOriginal=(SafariContextMenuHook)NULL;
NSString* savedSafariSelection=nil;
NSArray* safariContextMenuHookNew(id self,SEL sel,WebView* wv,NSDictionary*dic,NSArray*a)
{
    NSArray* m=safariContextMenuHookOriginal(self,sel,wv,dic,a);
    
    NSURL*url=[dic objectForKey:WebElementLinkURLKey];
    if(url){
	NSString*host=[url host];
	if([host rangeOfString:@"arxiv.org" options:NSCaseInsensitiveSearch].location!=NSNotFound){
	    [savedSafariSelection autorelease];
	    savedSafariSelection=[[url absoluteString]retain];
	}else{
	    return m;
	}
    }else{
	NSString* s=[[wv selectedDOMRange] text];
	if(!s)return m;
	if([s rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location==NSNotFound) return m;
	[savedSafariSelection autorelease];
	savedSafariSelection=[s retain];
    }
    
    NSMenuItem* mi=[[[NSMenuItem alloc] init] autorelease];
    [mi setTitle:@"Search by spires"];
    [mi setTarget:self];
    [mi setAction:IXHOOKSAFARICONTEXTMENUSELECTOR];
    NSArray* x=[NSArray arrayWithObject:mi];
    NSArray* y=[x arrayByAddingObjectsFromArray:m];
    return y;
}
void iXHookSafariContextMenu(id self,SEL sel,id sender)
{
    if(!savedSafariSelection)return;
    NSURL* u;
    if([savedSafariSelection hasPrefix:@"http://"]){
	u=[NSURL URLWithString:[savedSafariSelection stringByReplacingOccurrencesOfString:@"http:" withString:@"spires-lookup-eprint:"]];
    }else{
	u=[NSURL URLWithString:[NSString stringWithFormat:@"spires-lookup-eprint://PreviewHook/%@",savedSafariSelection]];
    }
    [[NSWorkspace sharedWorkspace] openURL:u];
    return;
}


#pragma mark Black Magic
inline void installAndSaveOriginalIMP(NSString* className,SEL sel,IMP new,IMP* old){
    Class c=NSClassFromString(className);
    if(!c)return;
    Method m=class_getInstanceMethod(c,sel);
    if(m){
	*old=method_getImplementation(m);
	method_setImplementation(m,new);
    }	
}
inline void installIMP(NSString* className,SEL sel,IMP new,char*signature){
    Class c=NSClassFromString(className);
    if(!c)return;
    class_addMethod(c,sel,new,signature);
}

@implementation iXHookLoader;


+ (void)load
{
    NSString* bundleIdentifier=[[NSBundle mainBundle] bundleIdentifier];
    if([bundleIdentifier isEqualToString:@"com.apple.Safari"]
	||[bundleIdentifier isEqualToString:@"org.webkit.nightly.WebKit"]){
	NSString* defaultBrowserID=(NSString*)LSCopyDefaultHandlerForURLScheme((CFStringRef)@"http");
	if(([defaultBrowserID compare:@"com.apple.Safari" options:NSCaseInsensitiveSearch]==NSOrderedSame)
	    || ([defaultBrowserID compare:@"org.webkit.nightly.WebKit" options:NSCaseInsensitiveSearch]==NSOrderedSame)){
	    installAndSaveOriginalIMP(@"AppController",@selector(_handleURLEvent:withReplyEvent:),(IMP)new,(IMP*)&original);
	}
	[defaultBrowserID release];
	
	installAndSaveOriginalIMP(@"BrowserWebView",@selector(webView:contextMenuItemsForElement:defaultMenuItems:),
				  (IMP)safariContextMenuHookNew,(IMP*)&safariContextMenuHookOriginal);
	installIMP(@"BrowserWebView",IXHOOKSAFARICONTEXTMENUSELECTOR,(IMP)iXHookSafariContextMenu,"v@:@");
	
    }


    installAndSaveOriginalIMP(@"PDFView",@selector(menuForEvent:),(IMP)menuForEventNewPDFView,(IMP*)&menuForEventOriginalPDFView);
    installIMP(@"PDFView",IXHOOKPDFVIEWSELECTOR,(IMP)iXHookPDFViewMenuItemSearch,"v@:@");

    installAndSaveOriginalIMP(@"NSTextView",@selector(menuForEvent:),(IMP)menuForEventNewNSTextView,(IMP*)&menuForEventOriginalNSTextView);
    installIMP(@"NSTextView",IXHOOKNSTEXTVIEWSELECTOR,(IMP)iXHookNSTextViewMenuItemSearch,"v@:@");

    if([bundleIdentifier isEqualToString:@"com.apple.mail"]){

	installAndSaveOriginalIMP(@"WebMessageController",@selector(webView:contextMenuItemsForElement:defaultMenuItems:),
	(IMP)mailHookNew,(IMP*)&mailHookOriginal);
	installIMP(@"WebMessageController",IXHOOKWEBMESSAGECONTROLLERSELECTOR,(IMP)iXHookWebMessageControllerMenuItemSearch,"v@:@");
	
    }
}


@end

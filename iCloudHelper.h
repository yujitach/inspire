//
//  iCloudHelper.h
//  inspire
//
//  Created by Yuji on 2018/09/02.
//

@import Foundation;

// completion handlers can be called from non-main thread.

@interface NSURL (iCloudAddition)
-(BOOL)isStatusCurrent;
@end


@interface iCloudHelper : NSObject
+(BOOL)iCloudAvailable;
+(void)setupWithUbiquityContainerIdentifier:(NSString*)container completion:(void(^)(NSURL*ubiquityContainerURL))handler;
+(NSMetadataQuery*)metadataQueryForExtension:(NSString*)extension;
+ (void)saveAndCloseDocumentWithName:(NSString *)documentName withContent:(NSData *)content completion:(void (^)(BOOL success))handler __attribute__((nonnull));
+ (void)retrieveCloudDocumentWithName:(NSURL *)documentName completion:(void (^)(NSData *documentData))handler __attribute__((nonnull));

/** Find all the conflicting versions of a specified document
 
 @param documentName The name of the file in iCloud. This value must not be nil.
 @return An array of NSFileVersion objects, or nil if no such version object exists. */
+ (NSArray *)findUnresolvedConflictingVersionsOfFile:(NSString *)documentName __attribute__((nonnull));

/** Resolve a document conflict for a file stored in iCloud
 
 @abstract Your application can follow one of three strategies for resolving document-version conflicts:
 
 * Merge the changes from the conflicting versions.
 * Choose one of the document versions based on some pertinent factor, such as the version with the latest modification date.
 * Enable the user to view conflicting versions of a document and select the one to use.
 
 @param documentName The name of the file in iCloud. This value must not be nil.
 @param documentVersion The version of the document which should be kept and saved. All other conflicting versions will be removed. */
+ (void)resolveConflictForFile:(NSString *)documentName withSelectedFileVersion:(NSFileVersion *)documentVersion __attribute__((nonnull));

@end


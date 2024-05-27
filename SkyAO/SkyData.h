//
//  SkyData.h
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/08.
//

#import <Foundation/Foundation.h>
#import "SkyEpub.h"
#import "Setting.h"
#import "FMDatabase.h"
#import "SkyKeyManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface SkyData : NSObject<SkyProviderDataSource> {
    FMDatabase* database;
    SkyKeyManager* keyManager;
}

-(BOOL)openDatabase;
-(void)closeDatabase;
-(void)checkDatabase;
-(NSString *)getDocumentsPath;
-(NSString*)getDatabasePath;
-(NSString*)getBooksDirectory;
-(NSString*)getCacheDirectory;
-(NSString*)getBookPath:(NSString*)fileName;
-(NSString*)getCoverPath:(NSString*)coverName;
-(NSString*)getCoversDirectory;
-(NSString*)getDownloadsDirectory;
-(NSString *)getDownloadPath:(NSString*)fileName;
-(void)copyFileFromBundleToDownloads:(NSString*)fileName;
-(BOOL)fileExists:(NSString*)filePath;
-(NSString*)getEPubDirectory:(NSString*)fileName;
-(void)removeFile:(NSString*)path;
-(void)updateSetting:(Setting*)setting;
-(Setting*)fetchSetting;
-(void)insertBookInformation:(BookInformation*)bi;
-(void)updateBookPosition:(BookInformation*)bi;
-(void)deleteBookByBookCode:(int)bookCode;
-(NSMutableArray*)fetchBookInformationsBySQL:(NSString*)sql;
-(NSMutableArray*)fetchBookInformations:(int)sortType key:(NSString*)key;
-(BookInformation*)fetchBookInformation:(int)bookCode;
-(int)getNumberOfBooks;
-(void)insertHighlight:(Highlight*)highlight;
-(void)updateHighlight:(Highlight*)highlight;
-(void)deleteHighlight:(Highlight*)highlight;
-(NSMutableArray*)fetchHighlightsBySQL:(NSString*)sql;
-(NSMutableArray*)fetchHighlights:(int)bookCode chapterIndex:(int)chapterIndex;
-(NSMutableArray*)fetchHighlightsByBookCode:(int)bookCode;
-(BOOL)isSameHighlight:(Highlight*)first secondHighlight:(Highlight*)second;
-(BOOL)isBookmarked:(PageInformation*)pageInformation;
-(BOOL)isFixedLayout:(int)bookCode;
-(int)getBookmarkCode:(PageInformation*)pageInformation;
-(void)insertBookmark:(PageInformation*)pageInformation;
-(void)deleteBookmarkByCode:(long)code;
-(void)deleteBookmark:(PageInformation*)pageInformation;
-(void)toggleBookmark:(PageInformation*)pageInformation;
-(NSMutableArray*)fetchBookmarks:(int)bookCode;
-(void)deletePagingInformation:(PagingInformation*)pgi;
-(void)insertPagingInformation:(PagingInformation*)pgi;
-(NSMutableArray*)fetchPagingInformationsBySQL:(NSString*)sql;
-(NSMutableArray*)fetchPagingInformationsByBookCode:(int)bookCode;
-(NSMutableArray*)fetchPagingInformationsByPagingInformation:(PagingInformation*)pgi;
-(NSMutableArray*)fetchPagingInformationsForScan:(int)bookCode numberOfChapters:(int)numberOfChapters;
-(PagingInformation*)fetchPagingInformation:(PagingInformation*)pgi;
-(void)insertItemRef:(ItemRef*)itemRef;
-(void)updateItemRef:(ItemRef*)itemRef;
-(void)deleteItemRefs:(int)bookCode;
-(ItemRef*)fetchItemRef:(int)bookCode chapterIndex:(int)chapterIndex;
-(void)installEpubByFileName:(NSString*)fileName;
-(void)installEpubByURL:(NSURL*)url;
-(void)createCachesDirectory;


@property (nonatomic) FMDatabase* database;
@property (nonatomic) SkyKeyManager* keyManager;

@end

NS_ASSUME_NONNULL_END

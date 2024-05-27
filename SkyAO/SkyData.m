//
//  SkyData.m
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/08.
//

#import "SkyData.h"

@implementation SkyData
@synthesize database,keyManager;

-(id)init {
    self = [super init];
    if(self){
        Setting* setting = [self fetchSetting];
        setting.fontName = @"Book Fonts";
        [self updateSetting:setting];
        setting = [self fetchSetting];
        NSLog(@"%@",setting.fontName);
        NSLog(@"%@",[self getDatabasePath]);
        [self checkDatabase];
        self.keyManager = [[SkyKeyManager alloc]initWithClientId:@"A3UBZzJNCoXmXQlBWD4xNo" clientSecret:@"zfZl40AQXu8xHTGKMRwG69"];
    }
    return self;
}

-(BOOL)openDatabase {
    [self closeDatabase];
    BOOL result = false;
    
    if (![NSFileManager.defaultManager fileExistsAtPath:[self getDatabasePath]]) {
        database = [FMDatabase databaseWithPath: [self getDatabasePath]];
        if (database!=nil) {
            if ([database open]) {
                NSString *ddlPath = [[NSBundle mainBundle] pathForResource:@"/Books" ofType:@"sql"];
                NSString *ddl = [NSString stringWithContentsOfFile:ddlPath encoding:NSUTF8StringEncoding error:NULL];
                [database executeStatements:ddl];
                NSString* sql = @"INSERT INTO Setting(BookCode,FontName,FontSize,LineSpacing,Foreground,Background,Theme,Brightness,TransitionType,LockRotation,DoublePaged,Allow3G,GlobalPagination,MediaOverlay,TTS,AutoStartPlaying,AutoLoadNewChapter,HighlightTextToVoice) VALUES(0,'Book Fonts',2,0,-1,-1,0,1,2,0,1,0,0,1,1,0,1,1)";
                [database executeUpdate:sql];
                result = true;
                [database close];
                NSLog(@"Database Successfully Created.");
            }else {
                NSLog(@"Could not open the database.");
            }
        }
    }else {
        database = [FMDatabase databaseWithPath: [self getDatabasePath]];
        [database open];
        NSLog(@"Database Successfully Opened.");
        result = true;
    }
    return result;
}



-(void)closeDatabase {
    if (database!=nil) {
        [database close];
    }
}

-(void)checkDatabase {
    if (self.database == nil || !self.database.isOpen) {
        if (![self openDatabase]) {
            NSLog(@"unabled to open database !!!!!");
        }
    }
}



-(NSString *)getDocumentsPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return documentsDirectory;
}

-(NSString*)getDatabasePath {
    NSString *docPath = [self getDocumentsPath];
    NSString *dbPath = [docPath stringByAppendingFormat:@"/book.sqlite"];
    return dbPath;
}

-(void)createBooksDirectory {
    NSString *docPath = [self getDocumentsPath];
    NSString *booksDir = [docPath stringByAppendingFormat:@"/books"];
    NSFileManager *fm =[NSFileManager defaultManager];
    NSError *error;
    if (![fm fileExistsAtPath:booksDir]) {
        [fm createDirectoryAtPath:booksDir withIntermediateDirectories:NO attributes:nil error:&error];
        
    }
}

-(void)createCoversDirectory {
    NSString *docPath = [self getDocumentsPath];
    NSString *booksDir = [docPath stringByAppendingFormat:@"/covers"];
    NSFileManager *fm =[NSFileManager defaultManager];
    NSError *error;
    if (![fm fileExistsAtPath:booksDir]) {
        [fm createDirectoryAtPath:booksDir withIntermediateDirectories:NO attributes:nil error:&error];
        
    }
}

-(void)createDownloadsDirectory {
    NSString *docPath = [self getDocumentsPath];
    NSString *downloadsDir = [docPath stringByAppendingFormat:@"/downloads"];
    NSFileManager *fm =[NSFileManager defaultManager];
    NSError *error;
    if (![fm fileExistsAtPath:downloadsDir]) {
        [fm createDirectoryAtPath:downloadsDir withIntermediateDirectories:NO attributes:nil error:&error];
    }
}

-(void)createCachesDirectory {
    NSString *docPath = [self getDocumentsPath];
    NSString *cachesDir = [docPath stringByAppendingFormat:@"/caches"];
    NSFileManager *fm =[NSFileManager defaultManager];
    NSError *error;
    if (![fm fileExistsAtPath:cachesDir]) {
        [fm createDirectoryAtPath:cachesDir withIntermediateDirectories:NO attributes:nil error:&error];
    }
}

-(void)createDirectories {
    [self createBooksDirectory];
    [self createDownloadsDirectory];
    [self createCoversDirectory];
    [self createCachesDirectory];
}

-(NSString*)getBooksDirectory {
    [self createBooksDirectory];
    NSString *docPath = [self getDocumentsPath];
    NSString *booksDir = [docPath stringByAppendingFormat:@"/books"];
    
    return booksDir;
}

-(NSString*)getCacheDirectory {
    [self createBooksDirectory];
    NSString *docPath = [self getDocumentsPath];
    NSString *cacheDir = [docPath stringByAppendingFormat:@"/caches"];
    
    return cacheDir;
}

-(NSString*)getBookPath:(NSString*)fileName {
    NSString* dir = [self getBooksDirectory];
    NSString* bookPath = [NSString stringWithFormat:@"%@/%@",dir,fileName];
    return bookPath;
}

// since 5.1.0, coverPath changed.
-(NSString*)getCoverPath:(NSString*)coverName {
//    NSString* dir = [self getEPubDirectory:coverName];
    NSString* dir = [self getBooksDirectory];
//    NSString* coverPath = [NSString stringWithFormat:@"%@/%@",dir,coverName];
    NSString* coverPath = [NSString stringWithFormat:@"%@/%@",dir,coverName];
    coverPath = [coverPath stringByReplacingOccurrencesOfString:@"epub" withString:@"jpg"];
    return coverPath;
}

-(NSString*)getCoversDirectory {
    [self createCoversDirectory];
    NSString *docPath = [self getDocumentsPath];
    NSString *coversDir = [docPath stringByAppendingFormat:@"/covers"];
    
    return coversDir;
}


-(NSString*)getDownloadsDirectory {
    [self createDownloadsDirectory];
    NSString *docPath = [self getDocumentsPath];
    NSString *downloadsDir = [docPath stringByAppendingFormat:@"/downloads"];
    
    return downloadsDir;
}


-(void)createEPubDirectory:(NSString *)fileName {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *ePubDir = [self getEPubDirectory:fileName];
    NSError *error;
    if (![fm fileExistsAtPath:ePubDir]) {
        [fm createDirectoryAtPath:ePubDir withIntermediateDirectories:NO attributes:nil error:&error];
    }
}

-(NSString *)getDownloadPath:(NSString*)fileName {
    NSString *downloadsDirectory = [self getDownloadsDirectory];
    // the path to write file
    NSString *filePath = [downloadsDirectory stringByAppendingPathComponent:fileName];
    return filePath;
}

// copy file from bundle(resource) to downloads folders
-(void)copyFileFromBundleToDownloads:(NSString*)fileName {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    
    NSString *downloadPath = [self getDownloadPath:fileName];
    BOOL success = [fm fileExistsAtPath:downloadPath];
    if (!success) {
        NSString *bundlePath = [[[NSBundle mainBundle] resourcePath]
                                       stringByAppendingPathComponent:fileName];
        success = [fm copyItemAtPath:bundlePath toPath:downloadPath error:&error];
    }
}

-(void)copyFileFromDownloadsToBooks:(NSString*)fileName {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    
    NSString* sourcePath = [self getDownloadPath:fileName];
    NSString* targetPath = [NSString stringWithFormat:@"%@/%@",[self getBooksDirectory],fileName];
    @try {
        [fm copyItemAtPath:sourcePath toPath:targetPath error:&error];
    }@catch (NSException* ne){}
}

-(void)copyFileFromURLToBooks:(NSURL*)url {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error;
    NSString* sourcePath = [self getFilePathFromURL:url];
    NSString* fileName = [sourcePath lastPathComponent];
    NSString* targetPath = [NSString stringWithFormat:@"%@/%@",[self getBooksDirectory],fileName];
    @try {
        [fm copyItemAtPath:sourcePath toPath:targetPath error:&error];
    }@catch (NSException* ne){}
}

-(NSString*)getFilePathFromURL:(NSURL*)url {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString* sourcePath = [url absoluteString];
    sourcePath = [sourcePath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
    sourcePath = [sourcePath stringByRemovingPercentEncoding];
    return sourcePath;
}

-(NSString*)getFileNameFromURL:(NSURL*)url {
    NSString* filePath = [self getFilePathFromURL:url];
    NSString* fileName = [filePath lastPathComponent];
    return fileName;
}

-(BOOL)fileExists:(NSString*)filePath {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL success = [fm fileExistsAtPath:filePath];
    if (!success) {
        return NO;
    }else {
        return YES;
    }
}

// returns the path of epub unzipped like "../books/sampleF0"
-(NSString*)getEPubDirectory:(NSString*)fileName {
    NSString *pureName = [fileName stringByDeletingPathExtension];
    NSString *booksDir = [self getBooksDirectory];
    NSString *ePubDir = [booksDir stringByAppendingPathComponent:pureName];
    return ePubDir;
}


-(void)removeFile:(NSString*)path {
    NSFileManager *fm =[NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        return;
    }
    NSError *error;
    [fm removeItemAtPath:path error:&error];
}


-(NSString *)getValueFromString:(NSString*)str withStartTag:(NSString*)startTag withEndTag:(NSString*)endTag {
    NSMutableString *mstr = [NSMutableString stringWithString:str];
    NSRange startRange,endRange;
    NSString *search = startTag;
    startRange = [mstr rangeOfString:search];
    search = endTag;
    endRange = [mstr rangeOfString:search];
    NSRange dataRange = NSMakeRange(startRange.location+startRange.length,endRange.location-(startRange.location+startRange.length));
    NSString *res = [mstr substringWithRange:dataRange];
    return res;
}

-(NSString*)getNowString {
    NSDate *now = [NSDate date];
    NSDateFormatter* fomatter = [[NSDateFormatter alloc]init];
    [fomatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [fomatter stringFromDate:now];
    return dateString;
}


// Database Routines

// Setting
-(void)updateSetting:(Setting*)setting {
    [self checkDatabase];
    if (setting.fontName == nil) {
        setting.fontName = @"";
    }
    NSString* sql = @"UPDATE Setting SET FontName=?, FontSize=? , LineSpacing=? , Foreground=? , Background=? , Theme=? , Brightness=?, TransitionType=? , LockRotation=? , DoublePaged=?,Allow3G=?,GlobalPagination=?,MediaOverlay=?,TTS=?,AutoStartPlaying=?,AutoLoadNewChapter=?,HighlightTextToVoice=? where BookCode=0";
    NSArray *arguments = [NSArray arrayWithObjects: setting.fontName,[NSNumber numberWithInt:setting.fontSize],[NSNumber numberWithInt:setting.lineSpacing],[NSNumber numberWithInt:setting.foreground],[NSNumber numberWithInt:setting.background],[NSNumber numberWithInt:setting.theme],[NSNumber numberWithDouble:setting.brightness],[NSNumber numberWithInt:setting.transitionType],[NSNumber numberWithInt:setting.lockRotation ? 1:0] ,[NSNumber numberWithInt:setting.doublePaged ? 1:0],[NSNumber numberWithInt:setting.allow3G ? 1:0],[NSNumber numberWithInt:setting.globalPagination ? 1:0],[NSNumber numberWithInt:setting.mediaOverlay ? 1:0] ,[NSNumber numberWithInt:setting.tts ? 1:0],[NSNumber numberWithInt:setting.autoStartPlaying ? 1:0],[NSNumber numberWithInt:setting.autoLoadNewChapter ? 1:0],[NSNumber numberWithInt:setting.highlightTextToVoice ? 1:0], nil];
    [database executeUpdate:sql withArgumentsInArray:arguments];
}

-(Setting*)fetchSetting {
    [self checkDatabase];
    NSString* sql = @"SELECT * FROM Setting where BookCode=0";
    @try {
        FMResultSet* results = [database executeQuery:sql];
        while ([results next]) {
            Setting* setting = [[Setting alloc]init];
            setting.bookCode =                      0;
            setting.fontName                        =   [results stringForColumn:@"FontName"];
            setting.fontSize                        =   [results intForColumn:@"FontSize"];
            setting.lineSpacing                     =   [results intForColumn:@"LineSpacing"];
            setting.foreground                      =   [results intForColumn:@"Foreground"];
            setting.background                      =   [results intForColumn:@"Background"];
            setting.theme                           =   [results intForColumn:@"Theme"];
            setting.brightness                      =   [results doubleForColumn:@"Brightness"];
            setting.transitionType                  =   [results intForColumn:@"TransitionType"];
            setting.lockRotation                    =   [results intForColumn:@"LockRotation"] !=0 ? true:false;
            setting.doublePaged                     =   [results intForColumn:@"DoublePaged"] !=0 ? true:false;
            setting.allow3G                         =   [results intForColumn:@"Allow3G"] !=0 ? true:false;
            setting.globalPagination                =   [results intForColumn:@"GlobalPagination"] !=0 ? true:false;
            setting.mediaOverlay                    =   [results intForColumn:@"MediaOverlay"] !=0 ? true:false;
            setting.tts                             =   [results intForColumn:@"TTS"] !=0 ? true:false;
            setting.autoStartPlaying                =   [results intForColumn:@"AutoStartPlaying"] !=0 ? true:false;
            setting.autoLoadNewChapter              =   [results intForColumn:@"AutoLoadNewChapter"] !=0 ? true:false;
            setting.highlightTextToVoice            =   [results intForColumn:@"HighlightTextToVoice"] !=0 ? true:false;
            return setting;
        }
    }@catch(NSException* ne) {
        
    }
    return nil;
}

// BookInformation
-(void)insertBookInformation:(BookInformation*)bi {
    [self checkDatabase];
    NSString* ns = [self getNowString];
    NSString* sql = @"INSERT INTO Book (Title,Author,Publisher,Subject,Type,Date,Language,Filename,IsFixedLayout,IsRTL,Position,Spread) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)";
    @try {
        NSArray *arguments = [NSArray arrayWithObjects:bi.title ? bi.title : @"" ,bi.creator ? bi.creator : @"", bi.publisher ? bi.publisher : @"" ,bi.subject ? bi.subject : @"",bi.type  ? bi.type : @"",ns,  bi.language ? bi.language : @"",bi.fileName ? bi.fileName : @"",[NSNumber numberWithInt:bi.isFixedLayout ? 1:0],[NSNumber numberWithInt:bi.isRTL ? 1:0] ,[NSNumber numberWithInt:-1.0],[NSNumber numberWithInt:bi.spread],nil];
        [database executeUpdate:sql withArgumentsInArray:arguments];
    }@catch(NSException *ne) {
        NSLog(@"%@",ne.reason);
    }
}

-(void)updateBookPosition:(BookInformation*)bi {
    NSString* ns = [self getNowString];
    NSString* sql = @"UPDATE Book SET Position=?,LastRead=?,IsRead=? where BookCode=?";
    @try {
        NSArray *arguments = [NSArray arrayWithObjects:[NSNumber numberWithDouble:bi.position],ns,[NSNumber numberWithInt:1],[NSNumber numberWithInt:bi.bookCode],nil];
        [database executeUpdate:sql withArgumentsInArray:arguments];
    }@catch(NSException* ne) {
        
    }
}

-(void)deleteBookByBookCode:(int)bookCode {
    [self checkDatabase];
    
    BookInformation* bi = [self fetchBookInformation:bookCode];
    NSString *bookPath = [self getBookPath:bi.fileName];
    NSString *coverPath = [self getCoverPath:bi.fileName];
    NSString *cacheFolder = [self getCacheDirectory];
    NSError* error;
    
    NSFileManager *fileManager =[NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:bookPath]) {
        @try {
            [fileManager removeItemAtPath:bookPath error:&error];
        }@catch(NSException* ne) {
            
        }
    }
    if ([fileManager fileExistsAtPath:coverPath]) {
        @try {
            [fileManager removeItemAtPath:coverPath error:&error];
        }@catch(NSException* ne) {
            
        }
    }
    if (bi.isFixedLayout) {
        NSDirectoryEnumerator *filesEnumerator = [fileManager enumeratorAtPath:cacheFolder];
        NSString *fileName;
        while ((fileName = [filesEnumerator nextObject])) {
            NSString* prefix = [NSString stringWithFormat:@"sb%d",bookCode];
            if ([fileName hasPrefix:prefix]) {
                NSString* path = [NSString stringWithFormat:@"%@%@",cacheFolder,fileName];
                @try {
                    [fileManager removeItemAtPath:path error:&error];
                }@catch(NSException* ne) {
                }
            }
        }
    }
    
    NSString* sql = [NSString stringWithFormat:@"DELETE FROM Book where BookCode=%d",bookCode];
    [database executeUpdate:sql];
    sql = [NSString stringWithFormat:@"DELETE FROM Highlight where BookCode=%d",bookCode];
    [database executeUpdate:sql];
    sql = [NSString stringWithFormat:@"DELETE FROM Bookmark where BookCode=%d",bookCode];
    [database executeUpdate:sql];
    sql = [NSString stringWithFormat:@"DELETE FROM ItemRef where BookCode=%d",bookCode];
    [database executeUpdate:sql];
}

-(NSMutableArray*)fetchBookInformationsBySQL:(NSString*)sql {
    [self checkDatabase];
    NSMutableArray* rets = [[NSMutableArray alloc]init];
    FMResultSet* results;
    @try {
         results = [database executeQuery:sql];
        
    }@catch(NSException* ne) {}
    while ([results next]) {
        BookInformation* bi = [[BookInformation alloc]init];
        bi.title            =   [results stringForColumn:@"Title"];
        bi.creator          =   [results stringForColumn:@"Author"];
        bi.publisher        =   [results stringForColumn:@"Publisher"];
        bi.subject          =   [results stringForColumn:@"Subject"];
        bi.date             =   [results stringForColumn:@"Date"];
        bi.language         =   [results stringForColumn:@"Language"];
        bi.fileName         =   [results stringForColumn:@"FileName"];
        bi.url              =   [results stringForColumn:@"URL"];
        bi.coverUrl         =   [results stringForColumn:@"CoverURL"];
        bi.lastRead         =   [results stringForColumn:@"LastRead"];
        bi.type             =   [results stringForColumn:@"Type"];

        bi.bookCode         =   [results intForColumn:@"BookCode"];
        bi.fileSize         =   [results intForColumn:@"FileSize"];
        bi.customOrder      =   [results intForColumn:@"CustomOrder"];
        bi.downSize         =   [results intForColumn:@"DownSize"];
        bi.spread           =   [results intForColumn:@"Spread"];

        bi.position         =   [results doubleForColumn:@"Position"];
        
        bi.isRead           =   [results intForColumn:@"IsRead"] != 0 ? true:false;
        bi.isRTL            =   [results intForColumn:@"IsRTL"] != 0 ? true:false;
        bi.isVerticalWriting =  [results intForColumn:@"IsVerticalWriting"] != 0 ? true:false;
        bi.isFixedLayout    =   [results intForColumn:@"IsFixedLayout"] != 0 ? true:false;
        bi.isGlobalPagination = [results intForColumn:@"IsGlobalPagination"] != 0 ? true:false;
        bi.isDownloaded     =   [results intForColumn:@"IsDownloaded"] != 0 ? true:false;
        
        [rets addObject:bi];
    }
    return rets;
}

-(NSMutableArray*)fetchBookInformations:(int)sortType key:(NSString*)key {
    [self checkDatabase];
    NSString* orderBy = @"";
    if (sortType==0) {
        orderBy = @" ORDER BY Title";
    }else if (sortType==1) {
        orderBy = @" ORDER BY Author";
    }else if (sortType==2) {
        orderBy = @" ORDER BY LastRead DESC";
    }
    NSString* condition = @"";
    if (key!=nil && [key length]!=0 ) {
        condition = [NSString stringWithFormat:@" WHERE Title like '%%%@%%' OR Author like '%%%@%%'",key,key];
    }
    NSString* sql = [NSString stringWithFormat:@"Select * from Book %@ %@",condition,orderBy];
    return [self fetchBookInformationsBySQL:sql];
}


-(BookInformation*)fetchBookInformation:(int)bookCode {
    [self checkDatabase];
    NSString* sql = [NSString stringWithFormat:@"SELECT * FROM Book where BookCode=%d",bookCode];
    NSMutableArray* rets = [self fetchBookInformationsBySQL:sql];
    if ([rets count]==0) {
        return nil;
    }else {
        BookInformation* bi = [rets objectAtIndex:0];
        return bi;
    }
}

-(int)getNumberOfBooks {
    [self checkDatabase];
    NSString* sql = @"SELECT COUNT(*) as Count FROM Book";
    @try {
        FMResultSet* results = [database executeQuery:sql];
        while ([results next]) {
            int count = [results intForColumn:@"Count"];
            return count;
        }
    }@catch(NSException *ne){}
    return -1;
}

// Highlight
-(void)insertHighlight:(Highlight*)highlight {
    [self checkDatabase];
    NSString* ns = [self getNowString];
    if (highlight.text==nil) {
        highlight.text = @"";
    }
    if (highlight.note==nil) {
        highlight.note = @"";
    }
    NSString* sql = @"INSERT INTO Highlight (BookCode,ChapterIndex,StartIndex,StartOffset,EndIndex,EndOffset,Color,Text,Note,IsNote,CreatedDate) VALUES(?,?,?,?,?,?,?,?,?,?,?)";
    @try {
        NSArray* arguments = [NSArray arrayWithObjects: [NSNumber numberWithInt:highlight.bookCode],[NSNumber numberWithInt:highlight.chapterIndex],[NSNumber numberWithInt:highlight.startIndex],[NSNumber numberWithInt:highlight.startOffset],[NSNumber numberWithInt:highlight.endIndex],[NSNumber numberWithInt:highlight.endOffset],[NSNumber numberWithInt:highlight.highlightColor],highlight.text,highlight.note, [NSNumber numberWithInt:highlight.isNote ? 1:0] ,ns,nil];
        [database executeUpdate:sql withArgumentsInArray:arguments];
    }@catch(NSException *ne) {
        NSLog(@"%@",ne.reason);
    }
}

-(void)updateHighlight:(Highlight*)highlight {
    [self checkDatabase];
    NSString* ns = [self getNowString];
    if (highlight.text==nil) {
        highlight.text = @"";
    }
    if (highlight.note==nil) {
        highlight.note = @"";
    }
    
    NSString* sql = @"UPDATE Highlight SET StartIndex=?,StartOffset=?,EndIndex=?,EndOffset=?,Color=?,Text=?,Note=?,IsNote=?,CreatedDate=? where BookCode=? and ChapterIndex=? and StartIndex=? and StartOffset=? and EndIndex=? and EndOffset=?";
    NSArray * arguments = [NSArray arrayWithObjects:[NSNumber numberWithInt:highlight.startIndex],[NSNumber numberWithInt:highlight.startOffset],[NSNumber numberWithInt:highlight.endIndex],[NSNumber numberWithInt:highlight.endOffset],[NSNumber numberWithInt:highlight.highlightColor],highlight.text,highlight.note, [NSNumber numberWithInt:highlight.isNote ? 1:0] ,ns,[NSNumber numberWithInt:highlight.bookCode],[NSNumber numberWithInt:highlight.chapterIndex],[NSNumber numberWithInt:highlight.startIndex],[NSNumber numberWithInt:highlight.startOffset],[NSNumber numberWithInt:highlight.endIndex],[NSNumber numberWithInt:highlight.endOffset],nil];
    [database executeUpdate:sql withArgumentsInArray:arguments];
}

-(void)deleteHighlight:(Highlight*)highlight {
    [self checkDatabase];
    NSString* sql = [NSString stringWithFormat:@"DELETE FROM Highlight where BookCode=%d and ChapterIndex=%d and StartIndex=%d and StartOffset=%d and EndIndex=%d and EndOffset=%d",highlight.bookCode,highlight.chapterIndex,highlight.startIndex,highlight.startOffset,highlight.endIndex,highlight.endOffset];
    [database executeUpdate:sql];
}

-(NSMutableArray*)fetchHighlightsBySQL:(NSString*)sql {
    [self checkDatabase];
    NSMutableArray* rets = [[NSMutableArray alloc]init];
    FMResultSet* results;
    @try {
         results = [database executeQuery:sql];
        
    }@catch(NSException* ne) {}
    while ([results next]) {
        Highlight* highlight = [[Highlight alloc]init];
        
        highlight.bookCode          = [results intForColumn:@"BookCode"];
        highlight.code              = [results intForColumn:@"Code"];
        highlight.chapterIndex      = [results intForColumn:@"ChapterIndex"];
        highlight.startIndex        = [results intForColumn:@"StartIndex"];
        highlight.startOffset       = [results intForColumn:@"StartOffset"];
        highlight.endIndex          = [results intForColumn:@"EndIndex"];
        highlight.endOffset         = [results intForColumn:@"EndOffset"];
        highlight.highlightColor    = [results intForColumn:@"Color"];
        highlight.text              = [results stringForColumn:@"Text"];
        highlight.note              = [results stringForColumn:@"Note"];
        highlight.isNote            = [results intForColumn:@"IsNote"] != 0 ? true:false;
        highlight.datetime          = [results stringForColumn:@"CreatedDate"];

        [rets addObject:highlight];
    }
    return rets;
}

-(NSMutableArray*)fetchHighlights:(int)bookCode chapterIndex:(int)chapterIndex {
    [self checkDatabase];
    NSString* sql = [NSString stringWithFormat:@"SELECT * FROM Highlight where BookCode=%d and ChapterIndex=%d",bookCode,chapterIndex];
    return [self fetchHighlightsBySQL:sql];
}

-(NSMutableArray*)fetchHighlightsByBookCode:(int)bookCode {
    [self checkDatabase];
    NSString* sql = [NSString stringWithFormat:@"SELECT * FROM Highlight where BookCode=%d order by ChapterIndex",bookCode];
    return [self fetchHighlightsBySQL:sql];
}

-(BOOL)isSameHighlight:(Highlight*)first secondHighlight:(Highlight*)second {
    if (first.bookCode==second.bookCode && first.startIndex == second.startIndex && first.endIndex == second.endIndex && first.startOffset==second.startOffset && first.endOffset==second.endOffset && first.chapterIndex==second.chapterIndex) {
        return true;
    }else {
        return false;
    }
}

// Bookmark
-(BOOL)isBookmarked:(PageInformation*)pageInformation {
    int code = [self getBookmarkCode:pageInformation];
    if (code == -1) {
        return false;
    }else {
        return true;
    }
}

-(BOOL)isFixedLayout:(int)bookCode {
    BookInformation* bi = [self fetchBookInformation:bookCode];
    if (bi.isFixedLayout) {
        return true;
    }else {
        return false;
    }
}

-(int)getBookmarkCode:(PageInformation*)pageInformation {
    [self checkDatabase];
    BOOL isFixedLayout = [self isFixedLayout:(int)pageInformation.bookCode];
    if (isFixedLayout) {
        NSString* sql = [NSString stringWithFormat:@"SELECT Code from Bookmark where BookCode=%ld and ChapterIndex=%ld",pageInformation.bookCode,pageInformation.chapterIndex];
        @try {
            FMResultSet* results = [database executeQuery:sql];
            while ([results next]) {
                int code = [results intForColumn:@"Code"];
                return code;
            }
        }@catch(NSException* ne) {}
    }else {
        double pageDelta = 1.0f/ (double)(pageInformation.numberOfPagesInChapter);
        double target = pageInformation.pagePositionInChapter;

        NSString*sql = [NSString stringWithFormat:@"SELECT Code,PagePositionInChapter from Bookmark where BookCode=%ld and ChapterIndex=%ld",pageInformation.bookCode,pageInformation.chapterIndex];
        @try {
            FMResultSet* results = [database executeQuery:sql];
            while ([results next]) {
                int code = [results intForColumn:@"Code"];
                double ppc = [results doubleForColumn:@"PagePositionInChapter"];
                if (target>=(ppc-pageDelta/2) && target<=(ppc+pageDelta/2)) {
                    return code;
                }
            }
        }@catch(NSException* ne) {}
    }
    return -1;
}

-(void)insertBookmark:(PageInformation*)pageInformation {
    [self checkDatabase];
    double ppb = pageInformation.pagePositionInBook;
    double ppc = pageInformation.pagePositionInChapter;
    long ci = pageInformation.chapterIndex;
    long bc = pageInformation.bookCode;
    NSString* ns = [self getNowString];
    
    NSString* sql = [NSString stringWithFormat:@"INSERT INTO Bookmark (BookCode,ChapterIndex,PagePositionInChapter,PagePositionInBook,CreatedDate) VALUES(%ld,%ld,%f,%f,'%@')",bc,ci,ppc,ppb,ns];
    [database executeUpdate:sql];
}

-(void)deleteBookmarkByCode:(long)code {
    [self checkDatabase];
    NSString* sql = [NSString stringWithFormat:@"DELETE FROM Bookmark where Code = %ld",code];
    [database executeUpdate:sql];
}

-(void)deleteBookmark:(PageInformation*)pageInformation {
    [self checkDatabase];
    long code = pageInformation.code;
    [self deleteBookmarkByCode:code];
}

-(void)toggleBookmark:(PageInformation*)pageInformation {
    int code = [self getBookmarkCode:pageInformation];
    if (code == -1) {
        [self insertBookmark:pageInformation];
    }else {
        [self deleteBookmarkByCode:code];
    }
}

-(NSMutableArray*)fetchBookmarks:(int)bookCode {
    [self checkDatabase];
    NSMutableArray* rets = [[NSMutableArray alloc]init];
    FMResultSet* results;
    @try {
        NSString* sql = [NSString stringWithFormat:@"SELECT * FROM Bookmark where BookCode=%d ORDER BY ChapterIndex,PagePositionInBook",bookCode];
        results = [database executeQuery:sql];
    }@catch(NSException* ne) {}
    while ([results next]) {
        PageInformation* pg         = [[PageInformation alloc]init];
        pg.bookCode                 = bookCode;
        pg.code                     = [results intForColumn:@"Code"];
        pg.chapterIndex             = [results intForColumn:@"ChapterIndex"];
        pg.pagePositionInChapter    = [results doubleForColumn:@"PagePositionInBook"];
        pg.pagePositionInBook       = [results doubleForColumn:@"PagePositionInBook"];
        pg.pageDescription          = [results stringForColumn:@"Description"];
        pg.datetime                 = [results stringForColumn:@"CreatedDate"];
        [rets addObject:pg];
    }
    return rets;
}

// PagingInformation
-(void)deletePagingInformation:(PagingInformation*)pgi {
    [self checkDatabase];
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM Paging WHERE BookCode=%ld AND ChapterIndex=%ld AND FontName='%@' AND FontSize=%ld AND LineSpacing=%ld AND Width=%d AND Height=%d AND HorizontalGapRatio=%f AND VerticalGapRatio=%f AND IsPortrait=%d AND IsDoublePagedForLandscape=%d",(long)pgi.bookCode,    (long)pgi.chapterIndex,        pgi.fontName,        (long)pgi.fontSize,        (long)pgi.lineSpacing,    pgi.width,        pgi.height,        pgi.horizontalGapRatio,        pgi.verticalGapRatio,        pgi.isPortrait ? 1:0,    pgi.isDoublePagedForLandscape ? 1:0];
    [database executeUpdate:sql];
}


-(void)insertPagingInformation:(PagingInformation*)pgi {
    [self checkDatabase];
    PagingInformation* tgi = [self fetchPagingInformation:pgi];
    if (tgi!=nil) {
        [self deletePagingInformation:tgi];
    }
    if (pgi.fontName==nil || [pgi.fontName isEqualToString:@"Book Fonts"]) {
        pgi.fontName = @"";
    }
    NSArray * arguments = [NSArray arrayWithObjects:[NSNumber numberWithLong:pgi.bookCode],[NSNumber numberWithLong:pgi.chapterIndex],[NSNumber numberWithLong:pgi.numberOfPagesInChapter],pgi.fontName,[NSNumber numberWithLong:pgi.fontSize],[NSNumber numberWithLong:pgi.lineSpacing],[NSNumber numberWithInt:pgi.width],[NSNumber numberWithInt:pgi.height],[NSNumber numberWithDouble:pgi.verticalGapRatio],[NSNumber numberWithDouble:pgi.horizontalGapRatio], [NSNumber numberWithInt:pgi.isPortrait ? 1:0],[NSNumber numberWithInt:pgi.isDoublePagedForLandscape ? 1:0],nil];
    
    NSString *sql = @"INSERT INTO Paging (BookCode,ChapterIndex,NumberOfPagesInChapter,FontName,FontSize,LineSpacing,Width,height,VerticalGapRatio,HorizontalGapRatio,IsPortrait,IsDoublePagedForLandscape) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";
    @try {
        [database executeUpdate:sql withArgumentsInArray:arguments];
    }@catch(NSException *ne) {}
}


-(NSMutableArray*)fetchPagingInformationsBySQL:(NSString*)sql {
    [self checkDatabase];
    NSMutableArray* rets = [[NSMutableArray alloc]init];
    FMResultSet* results;
    @try {
         results = [database executeQuery:sql];
        
    }@catch(NSException* ne) {}
    while ([results next]) {
        PagingInformation* pg = [[PagingInformation alloc]init];
        pg.bookCode = [results intForColumn:@"BookCode"];
        pg.code = [results intForColumn:@"Code"];
        pg.chapterIndex = [results intForColumn:@"ChapterIndex"];
        pg.numberOfPagesInChapter = [results intForColumn:@"NumberOfPagesInChapter"];
        pg.fontName = [results stringForColumn:@"FontName"];
        pg.fontSize = [results intForColumn:@"FontSize"];
        pg.lineSpacing = [results intForColumn:@"LineSpacing"];
        pg.width = [results intForColumn:@"Width"];
        pg.height = [results intForColumn:@"Height"];
        pg.verticalGapRatio = [results doubleForColumn:@"VerticalGapRatio"];
        pg.horizontalGapRatio =[results doubleForColumn:@"HorizontalGapRatio"];
        pg.isPortrait = [results intForColumn:@"IsPortrait"] != 0 ? true:false;
        pg.isDoublePagedForLandscape =  [results intForColumn:@"IsDoublePagedForLandscape"] != 0 ? true:false;
        [rets addObject:pg];
    }
    return rets;
}


-(NSMutableArray*)fetchPagingInformationsByBookCode:(int)bookCode {
    [self checkDatabase];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM Paging WHERE BookCode=%d AND ChapterIndex=0",bookCode];
    return [self fetchPagingInformationsBySQL:sql];
}

-(NSMutableArray*)fetchPagingInformationsByPagingInformation:(PagingInformation*)pgi {
    [self checkDatabase];
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM Paging WHERE BookCode=%ld AND FontName='%@' AND FontSize=%ld AND LineSpacing=%ld AND Width=%d AND Height=%d AND HorizontalGapRatio=%f AND VerticalGapRatio=%f AND IsPortrait=%d AND IsDoublePagedForLandscape=%d Order By ChapterIndex",
                      (long)pgi.bookCode,         pgi.fontName,        (long)pgi.fontSize,        (long)pgi.lineSpacing,    pgi.width,        pgi.height,        pgi.horizontalGapRatio,        pgi.verticalGapRatio,        pgi.isPortrait ? 1:0,    pgi.isDoublePagedForLandscape ? 1:0 ];
    return [self fetchPagingInformationsBySQL:sql];
}

-(NSMutableArray*)fetchPagingInformationsForScan:(int)bookCode numberOfChapters:(int)numberOfChapters {
    [self checkDatabase];
    NSMutableArray* sps = [self fetchPagingInformationsByBookCode:bookCode];
    for (int i=0; i<[sps count]; i++) {
        PagingInformation* sp = [sps objectAtIndex:i];
        NSMutableArray* tps = [self fetchPagingInformationsByPagingInformation:sp];
        if (tps.count == numberOfChapters) {
            return tps;
        }
    }
    return nil;
}

-(PagingInformation*)fetchPagingInformation:(PagingInformation*)pgi {
    [self checkDatabase];
    if (pgi.fontName==nil || [pgi.fontName isEqualToString:@"Book Fonts"]) {
        pgi.fontName = @"";
    }
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM Paging WHERE BookCode=%ld AND ChapterIndex=%ld AND FontName='%@' AND FontSize=%ld AND LineSpacing=%ld AND Width=%d AND Height=%d AND HorizontalGapRatio=%f AND VerticalGapRatio=%f AND IsPortrait=%d AND IsDoublePagedForLandscape=%d",
                     (long)pgi.bookCode,    (long)pgi.chapterIndex,        pgi.fontName,        (long)pgi.fontSize,        (long)pgi.lineSpacing,    pgi.width,        pgi.height,        pgi.horizontalGapRatio,        pgi.verticalGapRatio,        pgi.isPortrait ? 1:0,    pgi.isDoublePagedForLandscape ? 1:0];
    
    NSMutableArray* results = [self fetchPagingInformationsBySQL:sql];
    if ([results count]==0) {
        return nil;
    }else {
        PagingInformation* pgi = [results objectAtIndex:0];
        return pgi;
    }
}

// ItemRef
-(void)insertItemRef:(ItemRef*)itemRef {
    [self checkDatabase];
    NSString* sql = @"INSERT INTO ItemRef (BookCode,ChapterIndex,Title,Text,HRef,IdRef) VALUES(?,?,?,?,?,?)";
    @try {
        NSArray* arguments = [NSArray arrayWithObjects:[NSNumber numberWithLong:itemRef.bookCode],[NSNumber numberWithInt:itemRef.chapterIndex],itemRef.title ,itemRef.text ,itemRef.href  ,itemRef.idref,nil];
        [database executeUpdate:sql withArgumentsInArray:arguments];
    }@catch(NSException *ne) {
        
    }
}

-(void)updateItemRef:(ItemRef*)itemRef {
    [self checkDatabase];
    NSString* sql = @"UPDATE ItemRef SET Title=?,Text=? where BookCode=? and ChapterIndex=?";
    NSArray * arguments = [NSArray arrayWithObjects:[NSNumber numberWithInt:itemRef.bookCode],[NSNumber numberWithInt:itemRef.chapterIndex],itemRef.title ,itemRef.text ,itemRef.href  ,itemRef.idref,nil];
    [database executeUpdate:sql withArgumentsInArray:arguments];
}


-(void)deleteItemRefs:(int)bookCode {
    [self checkDatabase];
    NSString* sql = [NSString stringWithFormat:@"DELETE FROM ItemRef where BookCode=%d",bookCode];
    [database executeUpdate:sql];
}

-(ItemRef*)fetchItemRef:(int)bookCode chapterIndex:(int)chapterIndex {
    [self checkDatabase];
    NSString* sql = [NSString stringWithFormat:@"SELECT * FROM ItemRef where BookCode=%d and ChapterIndex=%d",bookCode,chapterIndex];
    @try {
        FMResultSet* results  = [database executeQuery:sql];
        while ([results next]) {
            ItemRef* itemRef = [[ItemRef alloc]init];
            itemRef.bookCode        = [results intForColumn:@"BookCode"];
            itemRef.chapterIndex    = [results intForColumn:@"ChapterIndex"];
            itemRef.title           = [results stringForColumn:@"Title"];
            itemRef.text            = [results stringForColumn:@"Text"];
            itemRef.href            = [results stringForColumn:@"Href"];
            itemRef.fullPath        = [results stringForColumn:@"FullPath"];
            itemRef.idref           = [results stringForColumn:@"IdREF"];
            return itemRef;
        }
    }@catch(NSException* ne) {}
    return nil;
}

// Install Epub
-(void)installEpubByFileName:(NSString*)fileName {
    NSString* bookPath = [self getBookPath:fileName];
    NSFileManager *fm =[NSFileManager defaultManager];
    if ([fm fileExistsAtPath:bookPath]) {
        NSLog(@"Book already installed");
         return;
    }
    [self copyFileFromBundleToDownloads:fileName];
    [self copyFileFromDownloadsToBooks:fileName];
    
    NSString* baseDirectory = [self getBooksDirectory];
    BookInformation* bi= [[BookInformation alloc]initWithBookName:fileName baseDirectory:baseDirectory];
    bi.fileName = fileName;
    SkyProvider* skyProvider = [[SkyProvider alloc]init];
    skyProvider.dataSource = self;
    skyProvider.book = bi.book;
    [bi setContentProvider:skyProvider];
    [bi makeInformation];
    [self insertBookInformation:bi];
    return;
}

-(void)installEpubByURL:(NSURL*)url {
    NSString* fileName = [self getFileNameFromURL:url];
    NSString* bookPath = [self getBookPath:fileName];
    NSFileManager *fm =[NSFileManager defaultManager];
    if ([fm fileExistsAtPath:bookPath]) {
        NSLog(@"Book already installed");
        return;
    }
    [self copyFileFromURLToBooks:url];
    
    NSString* baseDirectory = [self getBooksDirectory];
    BookInformation* bi= [[BookInformation alloc]initWithBookName:fileName baseDirectory:baseDirectory];
    bi.fileName = fileName;
    SkyProvider* skyProvider = [[SkyProvider alloc]init];
    skyProvider.dataSource = self;
    skyProvider.book = bi.book;
    [bi setContentProvider:skyProvider];
    [bi makeInformation];
    [self insertBookInformation:bi];
    return;
}

-(NSString*)skyProvider:(SkyProvider*)sp keyForEncryptedData:(NSString*)uuidForContent contentName:(NSString*)contentName uuidForEpub:(NSString *)uuidForEpub{
    NSString* key = [self.keyManager getKey:uuidForEpub uuidForContent:uuidForContent];
    return key;
}

@end

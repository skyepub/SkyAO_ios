//
//  MagazineViewController.m
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/26.
//

#import "MagazineViewController.h"
#import "AppDelegate.h"
#import "ContentsTableViewCell.h"
#import "BookmarksTableViewCell.h"
#import "NotesTableViewCell.h"

#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define SEARCHRESULT    0
#define SEARCHMORE      1
#define SEARCHFINISHED  2
#define MAX_NUM_SEARCH = 100

@interface ThumbnailView : UIView {
    int pageIndex;
    UIButton *thumbButton;
    UIImageView* thumbImageView;
}

@property int pageIndex;
@property (nonatomic,retain) UIButton* thumbButton;
@property (nonatomic,retain) UIImageView* thumbImageView;

@end

@interface UIImage(Overlay)
@end
@implementation UIImage(Overlay)
- (UIImage *)imageWithColor:(UIColor *)color1
{
        UIGraphicsBeginImageContextWithOptions(self.size, NO, self.scale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextTranslateCTM(context, 0, self.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        CGRect rect = CGRectMake(0, 0, self.size.width, self.size.height);
        CGContextClipToMask(context, rect, self.CGImage);
        [color1 setFill];
        CGContextFillRect(context, rect);
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
}
@end

@implementation ThumbnailView
@synthesize thumbButton,thumbImageView,pageIndex;
- (id)init{
    self = [super init];
    if (self) {
        pageIndex = -1;
    }
    return self;
}
@end

@interface MagazineViewController () <UITableViewDelegate,UITableViewDataSource>{
    AppDelegate* ad;
    SkyData* sd;
    Setting* setting;
    int bookCode;

    UIScrollView* thumbnailBox;
    
    FixedViewController* fv;
    FixedPageInformation* currentPageInformation;
    BOOL initialized;
    BOOL isCaching;
    
    BOOL isUIShown;
    Theme* currentTheme;
    int currentThemeIndex;
    NSMutableArray* themes;
    
    UIColor* currentColor;
    Highlight* currentHighlight;
    CGRect currentMenuRect;
    
    BOOL isRotationLocked;

    NSMutableArray* highlights;
    NSMutableArray* bookmarks;
    
    CGFloat searchScrollHeight;
    NSMutableArray* searchResults;
    int lastNumberOfSearched;
    
    BOOL isAutoPlaying;
    BOOL isLoop;
    BOOL autoStartPlayingWhenNewPagesLoaded;
    BOOL autoMovePageWhenParallesFinished;
    Parallel* currentParallel;
    BOOL isChapterJustLoaded;
    
    CGFloat ThumbnailViewASPECT;
    CGFloat ThumbnailViewHEIGHT;
    CGFloat ThumbnailViewWIDTH;
    CGFloat ThumbnailViewMARGIN;

}
@property (weak, nonatomic) IBOutlet UIView *skyepubView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *homeButton;
@property (weak, nonatomic) IBOutlet UIButton *listButton;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;
@property (weak, nonatomic) IBOutlet UIButton *bookmarkButton;
@property (weak, nonatomic) IBOutlet UIButton *menuButton;

@property (strong, nonatomic) IBOutlet UIView *highlightBox;
@property (strong, nonatomic) IBOutlet UIView *colorBox;
@property (strong, nonatomic) IBOutlet UIView *noteBox;
@property (weak, nonatomic) IBOutlet UITextView *noteTextView;

@property (strong, nonatomic) IBOutlet UIView *listBox;
@property (weak, nonatomic) IBOutlet UILabel *listBoxTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *listBoxResumeButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *listBoxSegmentedControl;
@property (weak, nonatomic) IBOutlet UIView *listBoxContainer;
@property (weak, nonatomic) IBOutlet UITableView *contentsTableView;
@property (weak, nonatomic) IBOutlet UITableView *notesTableView;
@property (weak, nonatomic) IBOutlet UITableView *bookmarksTableView;

@property (strong, nonatomic) IBOutlet UIView *baseView;

@property (strong, nonatomic) IBOutlet UIView *searchBox;
@property (weak, nonatomic) IBOutlet UIButton *searchCancelButton;
@property (weak, nonatomic) IBOutlet UIScrollView *searchScrollView;
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;

@property (strong, nonatomic) IBOutlet UIView *mediaBox;
@property (weak, nonatomic) IBOutlet UIButton *prevButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@property (nonatomic) IBOutlet UIScrollView *thumbnailBox;
@end

@implementation MagazineViewController
@synthesize bookInformation,thumbnailBox;

-(void)setDefaultValues {
    bookCode = -1;
    initialized = false;
    isCaching = false;
    
    isUIShown = false;
    currentThemeIndex = 0;
    themes = [[NSMutableArray alloc]init];
    
    isRotationLocked = false;

    highlights = [[NSMutableArray alloc]init];
    bookmarks = [[NSMutableArray alloc]init];
    
    searchScrollHeight = 0;
    searchResults = [[NSMutableArray alloc]init];
    lastNumberOfSearched = 0;
    
    isAutoPlaying = false;
    isLoop = false;
    autoStartPlayingWhenNewPagesLoaded = false;
    autoMovePageWhenParallesFinished = false;
    isChapterJustLoaded = false;
    
    ThumbnailViewASPECT = 0;
    ThumbnailViewHEIGHT = 0;
    ThumbnailViewWIDTH = 0;
    ThumbnailViewMARGIN = 20;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setDefaultValues];
    // Do any additional setup after loading the view.
    ad =  (AppDelegate*)[[UIApplication sharedApplication] delegate];
    sd = ad.data;
    setting = [sd fetchSetting];
    [sd createCachesDirectory];
    
    [self addSkyErrorNotification];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];

    autoStartPlayingWhenNewPagesLoaded = setting.autoStartPlaying;
    autoMovePageWhenParallesFinished = setting.autoLoadNewChapter;
    if (autoStartPlayingWhenNewPagesLoaded) {
        isAutoPlaying = true;
    }
    [self makeBookViewer];
    [self makeUI];
    [self hideUI];
}

-(void)addSkyErrorNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processError:) name:@"SkyError" object:nil];
}

-(void)removeSkyErrorNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SkyError" object:nil];
}

-(void)processError:(NSNotification*)notification {
    if (!initialized) initialized = YES;
    NSNumber* code  = [[notification userInfo] objectForKey:@"code"];
    NSNumber* level  = [[notification userInfo] objectForKey:@"level"];
    NSString* message  = [[notification userInfo] objectForKey:@"message"];
    NSLog(@"SkyError code %d level %d Detected :%@",[code intValue],[level intValue],message);
}

-(void)didRotate:(NSNotification *)notification {
    NSLog(@"rotated");
    [self hideUI];
    [self recalcFrames];
}

-(void)recalcFrames {
    [self recalcThumbnailBox];
}

-(BOOL)prefersStatusBarHidden{
    if ([self isPad]) {
        return true;
    }
    return false;
}

// simple funtion to return bookPath just binding baseDirectory + / + fileName
-(NSString*)getBookPath {
    NSString* bookPath = [NSString stringWithFormat:@"%@/%@",fv.baseDirectory,fv.fileName];
    return bookPath;
}

-(void)makeBookViewer {
    __weak id weakSelf = self;
    fv = [[FixedViewController alloc]initWithStartPosition:self.bookInformation.position spread:self.bookInformation.spread];
    
    fv.bookCode = bookInformation.bookCode;
    fv.fileName = bookInformation.fileName;
    fv.isFixedLayout = YES;
    bookCode = bookInformation.bookCode;
    [fv setLicenseKey:@"0000-0000-0000-0000"];
    fv.dataSource = weakSelf;
    fv.delegate =weakSelf;
    fv.baseDirectory = [sd getBooksDirectory];
    
    [fv setBookPath:[self getBookPath]];
    
    // If YES, page will be fit to Height, if NO, it will be fit to Width
    [fv setFitToHeight:NO];
    
    [fv addMenuItemForSelection:self title:@"Highlight" selector:@selector(onHighlightItemPressed:)];
    [fv addMenuItemForSelection:self title:@"Note" selector:@selector(onNoteItemPressed:)];
    
    // set the color of window
    UIColor* windowColor = [UIColor darkGrayColor];
    self.view.backgroundColor = windowColor;
    [fv changeWindowColor:windowColor];
    // set the color of the background for each page.
    [fv changeBackgroundColor:[UIColor whiteColor]];
    
    currentColor = [self getMarkerColor:0];
    
    // set the page transition mode such as None, Slide and Curl
    fv.transitionType = setting.transitionType;
    
    // set max page scale to reduce memory - set low value for the device that has not enough memory or the epub which has large page size.
    [fv setPageScaleFactor:1.0];
    [fv setSwipeGestureEnabled:YES];

    //    FileProvider reads the content of epub (which is unzipped) from file system.
    //       [fv setContentProviderClass:[FileProvider self]];
    
    //    EpubProvider will read the content of epub without unzipping.
    //        [fv setContentProviderClass:[EPubProvider self]];
    SkyProvider* skyProvider = [[SkyProvider alloc]init];
    skyProvider.dataSource = weakSelf;
    skyProvider.book = fv.book;
    [fv setContentProvider:skyProvider];

    // set fixedViewController's size and coordinates.
    fv.view.frame = self.skyepubView.bounds;
    fv.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    // add fv as subview of self.view
    [self.skyepubView addSubview:fv.view];
    [self addChildViewController:fv];
    self.view.autoresizesSubviews = true;
}

// make all custom themes.
-(void)makeThemes {
    // Theme 0  -  White
    Theme* theme0 = [[Theme alloc]initWithName:@"White" textColor:[UIColor blackColor] backgroundColor:[UIColor colorWithRed:252.0f/255.0f green:252.0f/255.0f blue:252.0f/255.0f alpha:1.0f] boxColor:[UIColor whiteColor] borderColor:[UIColor colorWithRed:198.0f/255.0f green:198.0f/255.0f blue:200.0f/255.0f alpha:1.0f] iconColor:[UIColor colorWithRed:0.0f/255.0f green:2.0f/255.0f blue:0.0f/255.0f alpha:1.0f] labelColor:[UIColor blackColor] selectedColor:[UIColor blueColor] sliderThumbColor:[UIColor blackColor] sliderMinTrackColor:[UIColor darkGrayColor] sliderMaxTrackColor:[UIColor colorWithRed:220.0f/255.0f green:220.0f/255.0f blue:220.0f/255.0f alpha:1.0f]];
    [themes addObject:theme0];
    // Theme 1 -   Brown
    Theme* theme1 = [[Theme alloc]initWithName:@"Brown" textColor:[UIColor blackColor] backgroundColor:[UIColor colorWithRed:240.0f/255.0f green:232.0f/255.0f blue:206.0f/255.0f alpha:1.0f] boxColor:[UIColor colorWithRed:253.0f/255.0f green:249.0f/255.0f blue:237.0f/255.0f alpha:1.0f] borderColor:[UIColor colorWithRed:219.0f/255.0f green:212.0f/255.0f blue:199.0f/255.0f alpha:1.0f] iconColor:[UIColor brownColor] labelColor:[UIColor colorWithRed:70.0f/255.0f green:52.0f/255.0f blue:35.0f/255.0f alpha:1.0f] selectedColor:[UIColor blueColor] sliderThumbColor:[UIColor colorWithRed:191.0f/255.0f green:154.0f/255.0f blue:70.0f/255.0f alpha:1.0f] sliderMinTrackColor:[UIColor colorWithRed:191.0f/255.0f green:154.0f/255.0f blue:70.0f/255.0f alpha:1.0f] sliderMaxTrackColor:[UIColor colorWithRed:219.0f/255.0f green:212.0f/255.0f blue:199.0f/255.0f alpha:1.0f]];
    [themes addObject:theme1];

    // Theme 2 -  Dark
    Theme* theme2 = [[Theme alloc]initWithName:@"Dark" textColor:[UIColor colorWithRed:212.0f/255.0f green:212.0f/255.0f blue:213.0f/255.0f alpha:1.0f] backgroundColor:[UIColor colorWithRed:71.0f/255.0f green:71.0f/255.0f blue:73.0f/255.0f alpha:1.0f] boxColor:[UIColor colorWithRed:77.0f/255.0f green:77.0f/255.0f blue:79.0f/255.0f alpha:1.0f] borderColor:[UIColor colorWithRed:91.0f/255.0f green:91.0f/255.0f blue:95.0f/255.0f alpha:1.0f] iconColor:[UIColor colorWithRed:238.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0f] labelColor:[UIColor colorWithRed:212.0f/255.0f green:212.0f/255.0f blue:213.0f/255.0f alpha:1.0f] selectedColor:[UIColor yellowColor] sliderThumbColor:[UIColor colorWithRed:254.0f/255.0f green:254.0f/255.0f blue:254.0f/255.0f alpha:1.0f] sliderMinTrackColor:[UIColor colorWithRed:254.0f/255.0f green:254.0f/255.0f blue:254.0f/255.0f alpha:1.0f] sliderMaxTrackColor:[UIColor colorWithRed:103.0f/255.0f green:103.0f/255.0f blue:106.0f/255.0f alpha:1.0f]];
    [themes addObject:theme2];

    // Theme 3 - Black
    Theme* theme3 = [[Theme alloc]initWithName:@"Black" textColor:[UIColor colorWithRed:175.0f/255.0f green:175.0f/255.0f blue:175.0f/255.0f alpha:1.0f] backgroundColor:[UIColor blackColor] boxColor:[UIColor colorWithRed:44.0f/255.0f green:44.0f/255.0f blue:46.0f/255.0f alpha:1.0f] borderColor:[UIColor colorWithRed:90.0f/255.0f green:90.0f/255.0f blue:92.0f/255.0f alpha:1.0f] iconColor:[UIColor colorWithRed:241.0f/255.0f green:241.0f/255.0f blue:241.0f/255.0f alpha:1.0f] labelColor:[UIColor colorWithRed:169.0f/255.0f green:169.0f/255.0f blue:169.0f/255.0f alpha:1.0f] selectedColor:[UIColor whiteColor] sliderThumbColor:[UIColor colorWithRed:169.0f/255.0f green:169.0f/255.0f blue:169.0f/255.0f alpha:1.0f] sliderMinTrackColor:[UIColor colorWithRed:169.0f/255.0f green:169.0f/255.0f blue:169.0f/255.0f alpha:1.0f] sliderMaxTrackColor:[UIColor colorWithRed:42.0f/255.0f green:42.0f/255.0f blue:44.0f/255.0f alpha:1.0f]];
    [themes addObject:theme3];
    
    // Theme 4 -  FixedLayout
    Theme* theme4 = [[Theme alloc]initWithName:@"Fixed" textColor:[UIColor colorWithRed:238.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0f] backgroundColor:[UIColor colorWithRed:71.0f/255.0f green:71.0f/255.0f blue:73.0f/255.0f alpha:1.0f] boxColor:[UIColor colorWithRed:65.0f/255.0f green:65.0f/255.0f blue:65.0f/255.0f alpha:1.0f] borderColor:[UIColor colorWithRed:91.0f/255.0f green:91.0f/255.0f blue:95.0f/255.0f alpha:1.0f] iconColor:[UIColor colorWithRed:238.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0f] labelColor:[UIColor colorWithRed:238.0f/255.0f green:238.0f/255.0f blue:238.0f/255.0f alpha:1.0f] selectedColor:[UIColor yellowColor] sliderThumbColor:[UIColor colorWithRed:254.0f/255.0f green:254.0f/255.0f blue:254.0f/255.0f alpha:1.0f] sliderMinTrackColor:[UIColor colorWithRed:254.0f/255.0f green:254.0f/255.0f blue:254.0f/255.0f alpha:1.0f] sliderMaxTrackColor:[UIColor colorWithRed:103.0f/255.0f green:103.0f/255.0f blue:106.0f/255.0f alpha:1.0f]];
    [themes addObject:theme4];
}

-(void)applyTheme:(Theme*)theme  {
    [self applyThemeToBody:theme];
    [self applyThemeToListBox:theme];
    [self applyThemeToSearchBox:theme];
    [self applyThemeToMediaBox:theme];
}

-(void)applyThemeToBody:(Theme*)theme {
    self.homeButton.tintColor = currentTheme.iconColor;
    self.listButton.tintColor = currentTheme.iconColor;
    self.searchButton.tintColor = currentTheme.iconColor;
    self.bookmarkButton.tintColor = currentTheme.iconColor;
    self.menuButton.tintColor = currentTheme.iconColor;
    self.titleLabel.textColor = currentTheme.labelColor;
}

-(void)makeUI {
    [self makeThemes];
    currentThemeIndex = 4;
    currentTheme = [themes objectAtIndex:currentThemeIndex];
    [self applyTheme:currentTheme];
    self.contentsTableView.delegate = self;
    self.contentsTableView.dataSource = self;
    self.bookmarksTableView.delegate = self;
    self.bookmarksTableView.dataSource = self;
    self.notesTableView.delegate = self;
    self.notesTableView.dataSource = self;
    self.thumbnailBox = [[UIScrollView alloc]init];
    [self.view addSubview:thumbnailBox];
}

-(void)showUI {
    [self showControls];
    [self showThumbnailBox];
}

-(void)hideUI {
    [self hideControls];
    [self hideThumbnailBox];
}

-(void)showControls {
    self.homeButton.hidden = false;
    self.listButton.hidden = false;
    self.searchButton.hidden = false;
    self.bookmarkButton.hidden = false;
    if (self.mediaBox.hidden) {
        self.titleLabel.hidden = false;
    }else {
        self.titleLabel.hidden = true;
    }
    self.menuButton.hidden = true;
    isUIShown = true;
}

-(void)hideControls {
    self.homeButton.hidden = true;
    self.listButton.hidden = true;
    self.searchButton.hidden = true;
    self.bookmarkButton.hidden = true;
    self.titleLabel.hidden = true;
    self.menuButton.hidden = false;
    isUIShown = false;
}

// SKYEPUB SDK CALLBACK
// called when touch on book is detected.
// positionInView is iphone view coodinates.
// positionInPage is HTML coordinates of book .
-(void)fixedViewController:(FixedViewController*)fvc didDetectTapAtPositionInView:(CGPoint)positionInView positionInPage:(CGPoint)positionInPage {
    if (isUIShown) {
        [self hideUI];
    }
}

-(NSString*)imageFilePath:(int)pageIndex {
    NSString* documentPath = [sd getDocumentsPath];
    NSString *filepath = [NSString stringWithFormat:@"%@/caches/sb%d-cache%d.png",documentPath,bookCode,pageIndex] ;
    return filepath;
}

-(ThumbnailView*)makeThumbnailView:(int)pageIndex {
    ThumbnailView* tv = [[ThumbnailView alloc]init];
    tv.tag = pageIndex;
    
    tv.backgroundColor = [UIColor lightGrayColor];
    tv.pageIndex = pageIndex;
    
    tv.thumbImageView = [[UIImageView alloc]init];
    tv.thumbImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    NSString* imagePath = [self imageFilePath:pageIndex];
    UIImage* thumbImage = [UIImage imageWithContentsOfFile:imagePath];
    tv.thumbImageView.image = thumbImage;
    [tv addSubview:tv.thumbImageView];
    
    tv.thumbButton = [UIButton buttonWithType:UIButtonTypeCustom];
    tv.thumbButton.tag = pageIndex;
    tv.thumbButton.showsTouchWhenHighlighted = YES;
    [tv.thumbButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    
    int pi = pageIndex+1;
    if (fv.isRTL) pi = ([fv.spine count]-1-pageIndex);
    [tv.thumbButton  setTitle:[NSString stringWithFormat:@"%d",pi] forState:UIControlStateNormal];
    tv.thumbButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [tv.thumbButton  addTarget:self
                        action:@selector(thumbmailPressed:)
              forControlEvents:UIControlEventTouchUpInside];
    [tv addSubview:tv.thumbButton];
    return tv;
}

// SKYEPUB SDK CALLBACK
// called whenever page is moved.
// fixedPageInformation contains all information about current page.
-(void)fixedViewController:(FixedViewController*)fvc pageMoved:(FixedPageInformation*)fixedPageInformation {
//    NSLog(@"pageMoved %d/%d = %f %@ !!!!",fixedPageInformation.pageIndex,fixedPageInformation.numberOfPages,fixedPageInformation.pagePosition,fixedPageInformation.cachedImagePath);
    currentPageInformation = fixedPageInformation;
    self.bookInformation.position = fixedPageInformation.pagePosition; // 0~1
    [self performSelector:@selector(startMediaOverlay) withObject:nil afterDelay:1.0f];
    
    self.titleLabel.text = fvc.title;
    
    [self applyBookmark];
    if (!initialized) {
        [self makeThumbnailBox];
        [fv performSelector:@selector(startCaching) withObject:nil afterDelay:0.5f];
        initialized = YES;
    }
    [self markThumbnail:fixedPageInformation.pageIndex];
}

// SKYEPUB SDK CALLBACK
// called when sdk needs to ask key to decrypt the encrypted epub. (encrypted by skydrm or any other drm which conforms to epub3 encrypt specification)
// for more information about SkyDRM. please refer to the links below
// https://www.dropbox.com/s/ctbe4yvhs60lq4n/SkyDRM%20Diagram.pdf?dl=1
// https://www.dropbox.com/s/ch0kf0djrcxd241/SkyDRM%20Solution.pdf?dl=1
// https://www.dropbox.com/s/xkxw4utpqq9frjw/SCS%20API%20Reference.pdf?dl=1
-(NSString*)skyProvider:(SkyProvider*)sp keyForEncryptedData:(NSString*)uuidForContent contentName:(NSString*)contentName uuidForEpub:(NSString *)uuidForEpub{
    NSString* key = [sd.keyManager getKey:uuidForEpub uuidForContent:uuidForContent];
    return key;
}


// if the cache(thumnail) image for pageIndex exists, YES should be returned to skyepub sdk.
// SKYEPUB SDK CALLBACK
// need to return true to SDK if cachedImage for pageIndex exists.
-(BOOL)fixedViewController:(FixedViewController*)fvc cacheExists:(int)pageIndex {
    NSString* path = [self imageFilePath:pageIndex];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return YES;
    }
    return NO;
}

// when caching process is started, this function will be called with pageIndex;
// SKYEPUB SDK CALLBACK
// called when caching process starts.
-(void)fixedViewController:(FixedViewController*)fvc cachingStarted:(int)index {
    NSLog(@"caching started %d",index);
    isCaching = YES;
}


// when caching process is done, this function will be called with pageIndex;
// SKYEPUB SDK CALLBACK
// called when caching process ends.
-(void)fixedViewController:(FixedViewController*)fvc cachingFinished:(int)index {
    NSLog(@"caching stopped %d",index);
    isCaching = NO;
}

// whenever the cache image for pageIndex is created, this will be called with image and pageIndex;
// SKYEPUB SDK CALLBACK
// called whenever one page image is cached, the image is needed to be saved in device persistant memory for future use.
-(void)fixedViewController:(FixedViewController*)fvc cached:(int)index image:(UIImage *)image {
    [self writeImage:image pageIndex:index];
}

-(UIImage*)resizeImage: (UIImage*) sourceImage maxWidth:(float)i_width {
    float oldWidth = sourceImage.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

-(void)writeImage:(UIImage *)image pageIndex:(int)pageIndex; {
    @autoreleasepool {
        NSString* path = [self imageFilePath:pageIndex];
        UIImage* resized = [self resizeImage:image maxWidth:100];
        NSData *imageData = [NSData dataWithData:UIImagePNGRepresentation(resized)];
        [imageData writeToFile:path atomically:YES];
        NSLog(@"PageIndex %d is cached in %@",pageIndex,path);
        [self loadThumbnailImage:resized pageIndex:pageIndex];
    }
}

-(ThumbnailView*)getThumbView:(int)pageIndex {
    for (UIView* view in thumbnailBox.subviews) {
        if ([view isKindOfClass: [ThumbnailView class]]) {
            ThumbnailView* tv  = (ThumbnailView*)view;
            if (tv.pageIndex==pageIndex) return tv;
        }
    }
    return nil;
}

-(void)loadThumbnailImage:(UIImage*)image pageIndex:(int)pageIndex {
    ThumbnailView* tv = [self getThumbView:pageIndex];
    [tv.thumbImageView setImage:image];
}

// make thumbnail box to display all cacked images for each page.
-(void)makeThumbnailBox {
    for (UIView* view in [thumbnailBox subviews]) {
        if ([view isKindOfClass: [ThumbnailView class]]) {
            ThumbnailView* tv  = (ThumbnailView*)view;
            [tv removeFromSuperview];
        }
    }
    // in fixedc layout, chaper is page, so the number of chapters is equal to the number of pages.
    // fv.spine.count always returns the number of chapters.
    for (int i=0; i<[fv.spine count]; i++) {
        ThumbnailView* tv = [self makeThumbnailView:i];
        [thumbnailBox addSubview:tv];
    }
    [self recalcThumbnailBox];
}

-(void)recalcThumbnailBox {
    CGFloat vw = self.view.frame.size.width;
    CGFloat vh = self.view.frame.size.height;
    CGFloat bm = self.view.safeAreaInsets.bottom + 5;
    
    // in fixed layout, book has fixedWidth and fixedHeight of fixed layout book .
    // aspect is fixedWidth / fixedheight
    ThumbnailViewASPECT = (CGFloat)(fv.fixedWidth) / (CGFloat)(fv.fixedHeight);
    ThumbnailViewHEIGHT = (CGFloat)(self.view.bounds.size.height/7);
    ThumbnailViewWIDTH = (CGFloat)(ThumbnailViewHEIGHT * ThumbnailViewASPECT);

    for (int i=0; i<[fv.spine count]; i++) {
        ThumbnailView* tv = [self getThumbView:i];
        tv.frame    = CGRectMake(ThumbnailViewMARGIN + (ThumbnailViewWIDTH + ThumbnailViewMARGIN) * i,0,ThumbnailViewWIDTH,ThumbnailViewHEIGHT);
    }
    
    CGFloat totalWidth = (ThumbnailViewWIDTH + ThumbnailViewMARGIN)*[fv.spine count]+ThumbnailViewMARGIN;
    thumbnailBox.contentSize = CGSizeMake(totalWidth, ThumbnailViewHEIGHT);
    thumbnailBox.frame = CGRectMake(0,(vh-(bm+vh/7)),vw,vh/7);
}

-(void)markThumbnail:(int)pageIndex {
    for (UIView* view in thumbnailBox.subviews) {
        if ([view isKindOfClass: [ThumbnailView class]]) {
            ThumbnailView* nv  = (ThumbnailView*)view;
            nv.thumbButton.layer.borderColor = [UIColor grayColor].CGColor;
            nv.thumbButton.layer.borderWidth = 1.0f;
            if (nv.pageIndex==pageIndex) {
                nv.thumbButton.layer.borderWidth = 3.0f;
            }
        }
    }

    CGFloat offsetX = ThumbnailViewMARGIN+(ThumbnailViewWIDTH+ThumbnailViewMARGIN)*pageIndex-(self.view.bounds.size.width-ThumbnailViewWIDTH)/2;
    if (offsetX <= 0) {
        offsetX = 0;
    }
    [self.thumbnailBox setContentOffset:CGPointMake(offsetX,0) animated: true];
}

// if one of cached image in thumbnailBox is pressed, goth the page.
-(void)thumbmailPressed:(UIButton*)sender {
    UIButton* thumbnailButton = sender;
    int pageIndex = (int)thumbnailButton.tag;
    [fv gotoPage:pageIndex];
}

-(void)showThumbnailBox {
    [self recalcFrames];
    self.thumbnailBox.hidden = false;
}

-(void)hideThumbnailBox {
    self.thumbnailBox.hidden = true;
}


// Bookmark
-(PageInformation*)getPageInformation:(FixedPageInformation*)fi {
    PageInformation*pi = [[PageInformation alloc]init];
    pi.bookCode = fi.bookCode;
    pi.chapterIndex = fi.pageIndex;
    pi.pageIndex = fi.pageIndex;
    pi.pagePositionInBook = fi.pagePosition;
    return pi;
}

-(void)changeBookmarkButton:(BOOL)isBookmarked {
    if (isBookmarked) {
        [self.bookmarkButton setImage:[UIImage imageNamed:@"bookmarked"] forState:UIControlStateNormal];
    }else {
        [self.bookmarkButton setImage:[UIImage imageNamed:@"bookmark"] forState:UIControlStateNormal];
    }
}

-(void)toggleBookmark  {
    PageInformation* pi = [self getPageInformation:currentPageInformation];
    BOOL isMarked = [sd isBookmarked:pi];
    [self changeBookmarkButton:!isMarked];
    [sd toggleBookmark:pi];
}

-(void)applyBookmark {
    PageInformation* pi = [self getPageInformation:currentPageInformation];
    BOOL isMarked = [sd isBookmarked:pi];
    [self changeBookmarkButton:isMarked];
}


// Highlight & Note

// SKYEPUB SDK CALLBACK
// need to return all highlight objects to SDK.
-(NSMutableArray*)fixedViewController:(FixedViewController*)rvc highlightsForChapter:(NSInteger)index {
    NSMutableArray* highlights = [sd fetchHighlights:bookInformation.bookCode chapterIndex:(int)index];
    return highlights;
}

// SKYEPUB SDK CALLBACK
// called when user select text to highlight.
-(void)fixedViewController:(FixedViewController*)rvc didSelectRange:(Highlight*)highlight menuRect:(CGRect)menuRect {
    currentHighlight = highlight;
    currentMenuRect = menuRect;
}

// SKYEPUB SDK CALLBACK
// called when a highlight is about to be deleted.
-(void)fixedViewController:(FixedViewController*)rvc deleteHighlight:(Highlight*)highlight {
    [sd deleteHighlight:highlight];
}


// SKYEPUB SDK CALLBACK
// called when a highlight is about to be update.
-(void)fixedViewController:(FixedViewController*)rvc updateHighlight:(Highlight*)highlight {
    [sd updateHighlight:highlight];
}

// SKYEPUB SDK CALLBACK
// called when a highlight is about to be inserted
-(void)fixedViewController:(FixedViewController*)rvc
                insertHighlight:(Highlight*)highlight {
    [sd insertHighlight:highlight];
    currentHighlight = highlight;
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setString:highlight.text];
}

// SKYEPUB SDK CALLBACK
// called when user touches on a highlight.
-(void)fixedViewController:(FixedViewController*)fvc didHitHighlight:(Highlight*)highlight atPosition:(CGPoint)position {
    currentHighlight = highlight;
    currentMenuRect.origin.x = position.x-15;
    currentMenuRect.origin.y = position.y-40;
    currentMenuRect.size.width = 50;
    currentMenuRect.size.height = 50;
    
    currentColor = UIColorFromRGB(currentHighlight.highlightColor);
    [self showHighlightBox];
}

// SKYEPUB SDK CALLBACK
// called when user touches on a link.
-(void)fixedViewController:(FixedViewController*)fvc didHitLink:(NSString*)urlString {
    NSLog(@"didHitLink detected : %@",urlString);
}

// when highlight menu item (which is registered into standard menu system by fv.addMenuItem) is pressed.
-(void)onHighlightItemPressed:(UIMenuController*)sender {
    [self showHighlightBox];
    // make the selected text highlight.
    [fv makeSelectionHighlight:currentColor];
}

// when note menu item (which is registered into standard menu system by fv.addMenuItem) is pressed.
-(void)onNoteItemPressed:(UIMenuController*)sender {
    // make the selected text note (highlight with note text)
    [fv makeSelectionHighlight:currentColor];
    [self showNoteBox];
}

-(void)showBaseView {
    [self.view addSubview:self.baseView];
    self.baseView.frame = self.view.bounds;
    self.baseView.hidden = false;
    self.baseView.backgroundColor = [UIColor clearColor];
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(baseClick:)];
    [self.baseView addGestureRecognizer:gesture];
}

-(void)hideBaseView {
    if (!self.baseView.hidden) {
        [self.baseView removeFromSuperview];
        self.baseView.hidden = true;
    }
}

-(void)baseClick:(UITapGestureRecognizer *)tapGesture{
    [self hideBoxes];
}

-(void)hideBoxes {
    [self hideHighlightBox];
    [self hideColorBox];
    [self hideNoteBox];
}

-(unsigned int)intFromColor:(UIColor*)color {
    CGColorRef colorref = [color CGColor];
    const CGFloat *components = CGColorGetComponents(colorref);
    
    unsigned int hexValue = 0xFF0000*components[0] + 0xFF00*components[1] + 0xFF*components[2];
    return hexValue;
}

-(int)getMarkerIndexByColor:(unsigned int)highlightColor {
    for (int i=0; i<4; i++) {
        UIColor* mc = [self getMarkerColor:i];
        unsigned int uc = [self intFromColor:mc];
        if (highlightColor==uc) return i;
    }
    return 0;
}

-(UIColor*)getMarkerColor:(int)colorIndex {
    switch (colorIndex) {
        case 0:
            return [UIColor colorWithRed:238/255.0f green:230/255.0f blue:142/255.0f alpha:1.0f];
            break;
        case 1:
            return [UIColor colorWithRed:218/255.0f green:244/255.0f blue:160/255.0f alpha:1.0f];
            break;
        case 2:
            return [UIColor colorWithRed:172/255.0f green:201/255.0f blue:246/255.0f alpha:1.0f];
            break;
        case 3:
            return [UIColor colorWithRed:249/255.0f green:182/255.0f blue:214/255.0f alpha:1.0f];
            break;
        default:
            return [UIColor colorWithRed:249/255.0f green:182/255.0f blue:214/255.0f alpha:1.0f];
            break;
    }
}

-(void)showHighlightBox {
    [self showBaseView];
    [self.view addSubview:self.highlightBox];
    CGFloat hx = (currentMenuRect.size.width - self.highlightBox.frame.size.width)/2+currentMenuRect.origin.x;
    CGRect highlightFrame = CGRectMake(hx,currentMenuRect.origin.y,190,37);
    self.highlightBox.frame = highlightFrame;
    self.highlightBox.hidden = false;
}

-(void)hideHighlightBox {
    [self.highlightBox removeFromSuperview];
    self.highlightBox.hidden = true;
    [self hideBaseView];
}

-(void)showColorBox {
    [self showBaseView];
    [self.view addSubview:self.colorBox];
    self.colorBox.frame = CGRectMake(currentMenuRect.origin.x,currentMenuRect.origin.y,self.colorBox.frame.size.width,self.colorBox.frame.size.height);
    self.colorBox.backgroundColor = currentColor;
    self.colorBox.hidden = false;
}

-(void)hideColorBox {
    [self.colorBox removeFromSuperview];
    self.colorBox.hidden = true;
    [self hideBaseView];
}

-(void)changeHighlightColor:(UIColor*)newColor {
    currentColor = newColor;
    self.highlightBox.backgroundColor = currentColor;
    self.colorBox.backgroundColor = currentColor;
    [fv changeHighlight:currentHighlight color:currentColor];
    [self hideColorBox];
}

-(BOOL)isPad {
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }else {
        return NO;
    }
}

-(BOOL)isPortrait {
    return UIDeviceOrientationIsPortrait(self.interfaceOrientation);
}

-(BOOL)isCurrentHighlightInLeftPage {
    BOOL isLeftPage = YES;
    if ((currentHighlight.pageIndex % 2)==0) {
        isLeftPage = NO;
    }else {
        isLeftPage = YES;
    }
    return isLeftPage;
}

-(void)showNoteBox {
    [self showBaseView];
    CGFloat noteX,noteY,noteWidth,noteHeight;
    noteWidth  = 280;
    noteHeight = 230;
    
    if ([self isPad]) { // iPad
        noteY = currentMenuRect.origin.y+100;
        if ((noteY+noteHeight) > (self.view.bounds.size.height*0.7)) {
            noteY = (self.view.bounds.size.height - self.noteBox.frame.size.height)/2;
        }
        if ([self isPortrait]) {
            noteX = (self.view.bounds.size.width - noteWidth)/2;
        }else {
            // if fv is double paged (two pages displayed in landscape mode)
            if ([fv isDoublePaged]) {
                noteHeight = 150;
                noteWidth = 250;
                if ([self isCurrentHighlightInLeftPage]) {
                    noteX = (self.view.bounds.size.width / 2 - noteWidth) / 2;
                }else {
                    CGFloat halfViewWidth = self.view.bounds.size.width / 2;
                    noteX = (halfViewWidth + (halfViewWidth - noteWidth) / 2);
                }
            }else {
                noteX = (self.view.bounds.size.width - noteWidth)/2;
                noteHeight = 200;
                noteWidth = 300;
            }
        }
    }else { // in case of iPhone, coordinates are fixed.
        if ([self isPortrait]) {
            noteY = (self.view.bounds.size.height - self.noteBox.frame.size.height)/2;
        }else {
            noteY = (self.view.bounds.size.height - self.noteBox.frame.size.height)/2;
            noteHeight = 150;
            noteWidth = 500;
        }
        noteX = (self.view.bounds.size.width - noteWidth)/2;
    }
    self.noteBox.frame =  CGRectMake(noteX,noteY,noteWidth,noteHeight);
    self.noteBox.backgroundColor = currentColor;
    [self.view addSubview:self.noteBox];
    self.noteBox.hidden = false;
}

-(void)hideNoteBox  {
    if (self.noteBox.hidden) {
        return;
    }
    [self saveNote];
    [self.noteBox removeFromSuperview];
    self.noteBox.hidden = true;
    self.noteTextView.text = @"";
    [self.noteTextView resignFirstResponder];
    [self hideBaseView];
}

-(void)saveNote {
    if (self.noteBox.hidden)  {
        return;
    }
    if (currentHighlight == nil) {
        return;
    }
    NSString* text = self.noteTextView.text;
    if (text!=nil || text!=0) {
        int uc = currentHighlight.highlightColor;
        UIColor* hc;
        if (uc==0) {
            hc = [self getMarkerColor:0];
        }else {
            hc = UIColorFromRGB(currentHighlight.highlightColor);
        }
        text = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (text.length!=0) {
            currentHighlight.note = text;
            currentHighlight.isNote = YES;
        }else {
            currentHighlight.note = @"";
            currentHighlight.isNote = NO;
        }
        [fv changeHighlight:currentHighlight color:hc note:text];
    }
}

-(void)colorPressed:(id)sender {
    [self hideHighlightBox];
    [self showColorBox];
}


-(void)trashPressed:(id)sender {
    [fv deleteHighlight:currentHighlight];
    [self hideHighlightBox];
}

-(void)noteInHighlightBoxPressed:(id)sender {
    [self hideHighlightBox];
    self.noteTextView.text = currentHighlight.note;
    [self showNoteBox];
}

-(void)savePressed:(id)sender {
    [self hideHighlightBox];
}

-(void)yellowPressed:(id)sender {
    UIColor* color = [self getMarkerColor:0];
    [self changeHighlightColor: color];
}

-(void)greenPressed:(id)sender {
    UIColor* color = [self getMarkerColor:1];
    [self changeHighlightColor: color];
}

-(void)bluePressed:(id)sender {
    UIColor* color = [self getMarkerColor:2];
    [self changeHighlightColor: color];
}

-(void)redPressed:(id)sender {
    UIColor* color = [self getMarkerColor:3];
    [self changeHighlightColor: color];
}

// ListBox
-(void)applyThemeToListBox:(Theme*)theme  {
    self.listBox.backgroundColor = theme.backgroundColor;
    
    self.listBoxTitleLabel.textColor = theme.textColor;
    [self.listBoxResumeButton setTitleColor:theme.textColor forState:UIControlStateNormal];
    
    if (@available(iOS 13, *)) {
        NSDictionary *attributes0 = @{ NSForegroundColorAttributeName: [UIColor blackColor] };
        [self.listBoxSegmentedControl setTitleTextAttributes:attributes0 forState: UIControlStateSelected];
        NSDictionary *attributes1 = @{ NSForegroundColorAttributeName: theme.labelColor};
        [self.listBoxSegmentedControl setTitleTextAttributes:attributes1 forState: UIControlStateNormal];
    }else {
        self.listBoxSegmentedControl.tintColor = [UIColor darkGrayColor];
    }
}

-(void)listBoxSegmentedControlChanged:(UISegmentedControl*)sender {
    [self showTableView:(int)self.listBoxSegmentedControl.selectedSegmentIndex];
}

-(void)listBoxResumePressed:(id)sender {
    [self hideListBox];
}

-(void)showListBox {
    [self showBaseView];
    isRotationLocked = true;
    CGFloat sx,sy,sw,sh;
    self.listBox.layer.borderColor = [UIColor clearColor].CGColor;
    sx = self.view.safeAreaInsets.left * 0.4;
    sy = self.view.safeAreaInsets.top;
    sw = self.view.bounds.size.width-(self.view.safeAreaInsets.left+self.view.safeAreaInsets.right) * 0.4;
    sh = self.view.bounds.size.height-(self.view.safeAreaInsets.top+self.view.safeAreaInsets.bottom);
    
    self.listBox.frame = CGRectMake(sx,sy,sw,sh);
    
    self.listBoxTitleLabel.text = fv.title;
    
    [self reloadContents];
    [self reloadHighlights];
    [self reloadBookmarks];
    
    [self showTableView:(int)self.listBoxSegmentedControl.selectedSegmentIndex];
    
    [self.view addSubview:self.listBox];
    [self applyThemeToListBox:currentTheme];
    self.listBox.hidden = false;
}

-(void)hideListBox {
    if (self.listBox.hidden) {
        return;
    }
    self.listBox.hidden = true;
    [self.listBox removeFromSuperview];   // this line causes the constraint issues.
    isRotationLocked = setting.lockRotation;
    [self hideBaseView];
}


-(void)showTableView:(int)index {
    self.contentsTableView.hidden = true;
    self.notesTableView.hidden = true;
    self.bookmarksTableView.hidden = true;
    if (index==0) {
        self.contentsTableView.hidden = false;
    }else if (index==1) {
        self.notesTableView.hidden = false;
    }else if (index==2) {
        self.bookmarksTableView.hidden = false;
    }
}

-(void)reloadContents {
    [self.contentsTableView reloadData];
}

-(void)reloadHighlights {
    highlights = [sd fetchHighlightsByBookCode:bookCode];
    [self.notesTableView reloadData];
}

-(void)reloadBookmarks {
    bookmarks = [sd fetchBookmarks:bookCode];
    [self.bookmarksTableView reloadData];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int ret = 0;
    if (tableView.tag==200) {
        ret  = (int)[fv.navMap count];
    }else if (tableView.tag==201) {
        ret  = (int)[highlights count];
    }else if (tableView.tag==202) {
        ret  = (int)[bookmarks count];
    }
    return ret;
}

// for more information about navMap and navPoint in epub, please refer to https://www.dropbox.com/s/yko3mq35if9ix68/NavMap.pdf?dl=1
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int index = (int)[indexPath row];
    if (tableView.tag==200) {
        // constructs the table of contents.
        // navMap and navPoint contains the information of TOC (table of contents)
        ContentsTableViewCell* cell = [self.contentsTableView dequeueReusableCellWithIdentifier:@"contentsTableViewCell" forIndexPath:indexPath];
        if (cell!=nil) {
            NavPoint* np = [fv.navMap objectAtIndex:index];
            NSString* leadingSpaceForDepth = @"";
            for (int i=0; i<np.depth; i++) {
                leadingSpaceForDepth = [NSString stringWithFormat:@"   %@",leadingSpaceForDepth];
            }
            cell.chapterTitleLabel.text = [NSString stringWithFormat:@"%@%@",leadingSpaceForDepth,np.text];
            cell.positionLabel.text = @"";
            cell.chapterTitleLabel.textColor = currentTheme.textColor;
            cell.positionLabel.textColor = currentTheme.textColor;
            
            if (np.chapterIndex == currentPageInformation.pageIndex) {
                cell.chapterTitleLabel.textColor = [UIColor systemIndigoColor];
            }
            return cell;
        }
    }else if (tableView.tag==201) {
        // constructs the table of highlights
        NotesTableViewCell* cell = [self.notesTableView dequeueReusableCellWithIdentifier:@"notesTableViewCell" forIndexPath:indexPath];
        if (cell!=nil) {
            Highlight* highlight = [highlights objectAtIndex:index];
            int displayPageIndex = highlight.chapterIndex+1;
            if ([fv isDoublePaged]) {
                displayPageIndex = displayPageIndex*2;
            }
            cell.positionLabel.text = [NSString stringWithFormat:@"Page %d",displayPageIndex];
            cell.highlightTextLabel.text = highlight.text;
            cell.noteTextLabel.text = highlight.note;
            cell.datetimeLabel.text = highlight.datetime;
            
            cell.positionLabel.textColor = currentTheme.textColor;
            cell.highlightTextLabel.textColor = [UIColor blackColor];
            cell.noteTextLabel.textColor = currentTheme.textColor;
            cell.datetimeLabel.textColor = currentTheme.textColor;

            cell.highlightTextLabel.backgroundColor =  UIColorFromRGB(highlight.highlightColor);
            return cell;
        }
    }else if (tableView.tag==202) {
        // constructs the table of bookmarks
        BookmarksTableViewCell* cell = [self.bookmarksTableView dequeueReusableCellWithIdentifier:@"bookmarksTableViewCell" forIndexPath:indexPath];
        if (cell!=nil) {
            PageInformation *pg = [bookmarks objectAtIndex:index];
            int displayPageIndex = pg.chapterIndex+1;
            if ([fv isDoublePaged]) {
                displayPageIndex = displayPageIndex*2;
            }
            cell.positionLabel.text = [NSString stringWithFormat:@"Page %d",displayPageIndex];
            cell.datetimeLabel.text = pg.datetime;
            cell.datetimeLabel.textColor = currentTheme.textColor;
            cell.positionLabel.textColor = currentTheme.textColor;
            return cell;
        }
    }
    return [[UITableViewCell alloc]init];
}


// called when user presses one item of tables
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = [indexPath row];
    if (tableView.tag==200) {
        NavPoint* np = [fv.navMap objectAtIndex:index];
        [fv gotoPageByNavPoint:np];
        [self hideListBox];
    }else if (tableView.tag==201) {
        Highlight* highlight = [highlights objectAtIndex:index];
        [fv gotoPage:highlight.chapterIndex];
        [self hideListBox];
    }else if (tableView.tag==202) {
        PageInformation* pg = [bookmarks objectAtIndex:index];
        [fv gotoPage:pg.chapterIndex];
        [self hideListBox];
    }
}

// bookmarks and highlights list are editable to delete a item from the list.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag==201 || tableView.tag==202) {
        return YES;
    }
    return NO;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) return;
    int index = (int)[indexPath row];
    if (tableView.tag==202) {
        PageInformation* pi = [bookmarks objectAtIndex:index];
        [sd deleteBookmark:pi];
        [self reloadBookmarks];
    }else if (tableView.tag==201) {
        Highlight* ht = [highlights objectAtIndex:index];
        [sd deleteHighlight:ht];
        [self reloadHighlights];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    int index = (int)[indexPath row];
    CGFloat height = 70;
    if (tableView.tag==200) {
        height =  40;
    }else if (tableView.tag == 201) {
        Highlight* highlight = [highlights objectAtIndex:index];
        if (highlight.isNote) {
            height = 125;
        }else {
            height = 100;
        }
    }else if (tableView.tag == 202) {
        height = 67;
    }
    return height;
}


// Search Routines ==========================================================================================
-(void)searchCancelPressed:(id)sender {
    [self hideSearchBox];
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString* searchKey = textField.text;
    [self hideSearchBox];
    [self showSearchBox:false];
    [self startSearch:searchKey];
    [self.searchTextField resignFirstResponder];
    lastNumberOfSearched = 0;
    return true;
}

-(void)clearSearchResults {
    searchScrollHeight = 0;
    [searchResults removeAllObjects];
    for (UIView* sv in self.searchScrollView.subviews) {
        [sv removeFromSuperview];
    }
    self.searchScrollView.contentSize = CGSizeMake(self.searchScrollView.bounds.size.width,0);
}

-(void)startSearch:(NSString*)key {
    lastNumberOfSearched = 0;
    [self clearSearchResults];
    [fv searchKey:key];
}

-(void)searchMore {
    [fv searchMore];
}

-(void)stopSearch {
    [fv stopSearch];
}

BOOL didApplyClearBox = false;

-(void)showSearchBox:(BOOL)isCollapsed {
    [self showBaseView];
    NSString* searchText;
    
    self.searchTextField.delegate = self;
    searchText = self.searchTextField.text;

    [self.searchTextField setLeftViewMode:UITextFieldViewModeAlways];
    
    UIImageView* imageView = [[UIImageView alloc]init];
    UIImage* image = [UIImage imageNamed:@"magnifier"];
    imageView.image = image;
    self.searchTextField.leftView = imageView;

    self.searchBox.layer.borderWidth = 1;
    self.searchBox.layer.cornerRadius = 10;
    isRotationLocked = true;
    
    CGFloat sx,sy,sw,sh;
    CGFloat rightMargin = 50.0;
    CGFloat topMargin = 60.0 + self.view.safeAreaInsets.top;
    CGFloat bottomMargin = 50.0 + self.view.safeAreaInsets.bottom;
    
    if (isCollapsed) {
        if (searchText!=nil && searchText.length!=0) {
            [self clearSearchResults];
            [self.searchTextField becomeFirstResponder];
        }
    }
    
    if ([self isPad]) {
        self.searchBox.layer.borderColor = [UIColor lightGrayColor].CGColor;
        sx = self.view.bounds.size.width - self.searchBox.bounds.size.width - rightMargin;
        sw = 400;
        sy = topMargin;
        if (isCollapsed && (searchText!=nil && searchText.length!=0))  {
            self.searchScrollView.hidden = true;
            sh = 95;
        }else {
            sh = self.view.bounds.size.height - (topMargin+bottomMargin);
            self.searchScrollView.hidden = false;
        }
    }else {
        self.searchBox.layer.borderColor = [UIColor clearColor].CGColor;
        sx = 0;
        sy = self.view.safeAreaInsets.top;
        sw = self.view.bounds.size.width;
        sh = self.view.bounds.size.height-(self.view.safeAreaInsets.top+self.view.safeAreaInsets.bottom);
    }
    
    self.searchBox.frame = CGRectMake(sx,sy,sw,sh);
    self.searchScrollView.frame = CGRectMake(30,100,self.searchBox.frame.size.width-55,self.searchBox.frame.size.height-(35+95));
    
    [self.view addSubview:self.searchBox];
    
    [self applyThemeToSearchBox: currentTheme];
    self.searchBox.hidden = false;
}

-(void)hideSearchBox {
    if (self.searchBox.hidden) {
        return;
    }
    [self.searchTextField resignFirstResponder];
    self.searchBox.hidden = true;
    [self.searchBox removeFromSuperview];   // this line causes the constraint issues.
    isRotationLocked = setting.lockRotation;
    [self hideBaseView];
}

- (void)searchTextFieldDidChange:(UITextField *)searchTextField {
    if (searchTextField.text!=nil && searchTextField.text.length!=0) {
        [self applyThemeToSearchTextFieldClearButton:currentTheme];
    }
}

-(void)applyThemeToSearchTextFieldClearButton:(Theme*)theme {
    if (didApplyClearBox) {
        return;
    }
    for (UIView* view in self.searchTextField.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            UIButton* button = (UIButton*)view;
            UIImage *image = [button imageForState:UIControlStateHighlighted];
            if (image!=nil) {
                [button setImage:[image imageWithColor:[UIColor lightGrayColor]] forState:UIControlStateHighlighted];
                didApplyClearBox = true;
            }
            image = [button imageForState:UIControlStateNormal];
            if (image!=nil) {
                [button setImage:[image imageWithColor:[UIColor lightGrayColor]] forState:UIControlStateNormal];
                didApplyClearBox = true;
            }
        }
    }
}

-(void)applyThemeToSearchBox:(Theme*)theme {
    self.searchBox.backgroundColor = theme.boxColor;
    self.searchBox.layer.borderWidth = 1;
    self.searchBox.layer.borderColor = theme.borderColor.CGColor;
    
    self.searchTextField.backgroundColor = [UIColor clearColor];
    self.searchTextField.layer.masksToBounds = true;
    self.searchTextField.layer.borderWidth = 1;
    self.searchTextField.layer.cornerRadius = 5;
    self.searchTextField.layer.borderColor = theme.borderColor.CGColor;
    self.searchTextField.textColor = theme.textColor;
    
    [self.searchTextField addTarget:self action:@selector(searchTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    [self.searchCancelButton setTitleColor:theme.textColor forState:UIControlStateNormal];
    [self applyThemeToSearchTextFieldClearButton:theme];
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [SearchResultView class]];
    NSArray* resultViews= [self.searchScrollView.subviews filteredArrayUsingPredicate:predicate];
    
    for (int i=0; i< [resultViews count]; i++) {
        SearchResultView* resultView = [resultViews objectAtIndex:i];
        resultView.headerLabel.textColor = theme.textColor;
        resultView.contentLabel.textColor = theme.textColor;
        resultView.bottomLine.backgroundColor = theme.borderColor;
        resultView.bottomLine.alpha = 0.65f;
    }
}

-(void)addSearchResult:(SearchResult*)searchResult mode:(int)mode{
    NSString *headerText = @"";
    NSString *contentText = @"";
    
    SearchResultView* resultView = [[[NSBundle mainBundle] loadNibNamed:@"SearchResultView" owner:self options:nil] firstObject];
    UIButton* gotoButton = resultView.searchResultButton;
    
    if (mode==SEARCHRESULT) {
        int ci = searchResult.chapterIndex;
        NSString* chapterTitle = [fv getChapterTitle:ci];
        int displayPageIndex = (searchResult.pageIndex+1);
        int displayNumberOfPages = searchResult.numberOfPagesInChapter;
        if (fv.isDoublePaged) {
            displayPageIndex = displayPageIndex*2;
            displayNumberOfPages = displayNumberOfPages*2;
        }
        if (searchResult.chapterTitle.length != 0) {
            headerText = [NSString stringWithFormat:@"%@",searchResult.chapterTitle];
        }else {
            headerText = [NSString stringWithFormat:@"Page%d",displayPageIndex];
        }
        contentText = searchResult.text;
        [searchResults addObject:searchResult];
        gotoButton.tag = searchResults.count - 1;
    }else if (mode==SEARCHMORE){
        headerText =  NSLocalizedString(@"search_more",@"");
        contentText = [NSString stringWithFormat:@"%d %@",searchResult.numberOfSearched,NSLocalizedString(@"found",@"")];
        gotoButton.tag =  -2;
    }else if (mode==SEARCHFINISHED) {
        headerText =  NSLocalizedString(@"search_finished",@"");
        contentText = [NSString stringWithFormat:@"%d %@",searchResult.numberOfSearched,NSLocalizedString(@"found",@"")];
        gotoButton.tag =  -1;
    }
    
    resultView.headerLabel.text = headerText;
    resultView.contentLabel.text = contentText;
    
    resultView.headerLabel.textColor = currentTheme.textColor;
    resultView.contentLabel.textColor = currentTheme.textColor;
    resultView.bottomLine.backgroundColor = currentTheme.borderColor;
    resultView.bottomLine.alpha = 0.65;
    
    [gotoButton addTarget:self action:@selector(gotoSearchPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat rx,ry,rw,rh;
    rx = 0;
    ry = searchScrollHeight;
    rw = self.searchScrollView.bounds.size.width;
    rh = 90;
    
    resultView.frame = CGRectMake(rx,ry,rw,rh);
    
    [self.searchScrollView addSubview:resultView];
    searchScrollHeight+=rh;
    self.searchScrollView.contentSize = CGSizeMake(rw,searchScrollHeight);
    float co = searchScrollHeight-self.searchScrollView.bounds.size.height;
    if (co<=0) {
        co = 0;
    }
    self.searchScrollView.contentOffset  = CGPointMake(0,co);
}

-(void)gotoSearchPressed:(UIButton*)sender {
    UIButton* gotoSearchButton = sender;
    if (gotoSearchButton.tag == -1) {
        [self hideSearchBox];
    }else if (gotoSearchButton.tag == -2) {
        searchScrollHeight -= gotoSearchButton.bounds.size.height;
        self.searchScrollView.contentSize = CGSizeMake(gotoSearchButton.bounds.size.width,searchScrollHeight);
        [gotoSearchButton.superview  removeFromSuperview];
        [fv searchMore];
    }else {
        [self hideSearchBox];
        SearchResult* sr = [searchResults objectAtIndex:gotoSearchButton.tag];
        [fv performSelector:@selector(gotoPageBySearchResult:) withObject:sr afterDelay:0.5];
    }
}

// SKYEPUB SDK CALLBACK
// called when key is found while searching.
// SearchResult object contains all information of the text found.
-(void)reflowableViewController:(FixedViewController *)fvc didSearchKey:(SearchResult *)searchResult {
    [self addSearchResult:searchResult mode:SEARCHRESULT];
}

// SKYEPUB SDK CALLBACK
// called when all search process is over.
-(void)reflowableViewController:(FixedViewController *)fvc didFinishSearchAll:(SearchResult *)searchResult {
    [self addSearchResult:searchResult mode:SEARCHFINISHED];
}

// SKYEPUB SDK CALLBACK
// called when all search process for given chapter (in fixed layout chapter = page).
-(void)reflowableViewController:(FixedViewController *)fvc didFinishSearchForChapter:(SearchResult *)searchResult {
    [fvc pauseSearch];
    int cn = searchResult.numberOfSearched - lastNumberOfSearched;
    if (cn > 150) {
        [self addSearchResult:searchResult mode:SEARCHMORE];
        lastNumberOfSearched = searchResult.numberOfSearched;
    }else {
        [fv searchMore];
    }
}

// MediaOverlay Routines ==============================================================================================================
-(void)applyThemeToMediaBox:(Theme*)theme {
    self.prevButton.tintColor = theme.iconColor;
    self.playButton.tintColor = theme.iconColor;
    self.stopButton.tintColor = theme.iconColor;
    self.nextButton.tintColor = theme.iconColor;
}

-(void)startMediaOverlay {
    // if fv has mediaOverlay and setting is set for mediaOverlay.
    if ([fv isMediaOverlayAvailable] && setting.mediaOverlay) {
        [self showMediaBox];
        if (isAutoPlaying) {
            [self.playButton setImage:[UIImage imageNamed: @"pause"] forState:UIControlStateNormal];
            [fv playFirstParallel];  // play the first parallel of mediaOverlay in this page.
        }
    }else {
        [self hideMediaBox];
    }
}

-(void)showMediaBox {
    [self.view addSubview:self.mediaBox];
    [self applyThemeToMediaBox: currentTheme];
    self.mediaBox.frame = CGRectMake(self.titleLabel.frame.origin.x,self.listButton.frame.origin.y - 7,self.mediaBox.frame.size.width,self.mediaBox.frame.size.height);
    self.mediaBox.hidden = false;
    self.titleLabel.hidden = true;
}

-(void)hideMediaBox {
    [self.mediaBox removeFromSuperview];
    self.mediaBox.hidden = true;
    if (!self.homeButton.hidden) {
        self.titleLabel.hidden = false;
    }
}

-(void)changePlayAndPauseButton {
    if (![fv isPlayingStarted]) {
        [self.playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    }else if ([fv isPlayingPaused]) {
        [self.playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    }else {
        [self.playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    }
}

-(void)prevPressed:(id)sender {
    [self playPrev];
}

-(void)playPressed:(id)sender {
    [self playAndPause];
}

-(void)stopPressed:(id)sender {
    [self stopPlaying];
}

-(void)nextPressed:(id)sender {
    [self playNext];
}

-(void)playAndPause {
    if ([fv isPlayingPaused]) {
        if (![fv isPlayingStarted]) {
            if (autoStartPlayingWhenNewPagesLoaded) {
                isAutoPlaying = true;
            }
            [fv playFirstParallel];
        }else {
            if (autoStartPlayingWhenNewPagesLoaded) {
                isAutoPlaying = true;
            }
            [fv resumePlayingParallel];
        }
    }else {
        if (autoStartPlayingWhenNewPagesLoaded) {
            isAutoPlaying = true;
        }
        [fv pausePlayingParallel];
    }
    
    [self performSelector:@selector(changePlayAndPauseButton) withObject:nil afterDelay:0.2f];
}

-(void)stopPlaying {
    [self.playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    [fv stopPlayingParallel];
    if (autoStartPlayingWhenNewPagesLoaded) {
        isAutoPlaying = false;
    }
    [fv restoreElementColor];
}

-(void)playPrev {
    [fv restoreElementColor];
    if (currentParallel.parallelIndex == 0) {
        if (autoMovePageWhenParallesFinished) {
            [fv gotoPrevPage];
        }
    }else {
        [fv playPrevParallel];
    }
}

-(void)playNext {
    [fv restoreElementColor];
    [fv playNextParallel];
}

/* MediaOverlay callbacks */

// SKYEPUB SDK CALLBACK
// called when Playing a parallel starts in MediaOverlay.
// setting.highlightTextToVoice is set, make the text for parallel which is being played as highlight.
-(void)fixedViewController:(FixedViewController *)fvc parallelDidStart:(Parallel *)parallel {
    if (setting.highlightTextToVoice) {
        [fv changeElementColor:@"#F0F000"  hash: parallel.hash  pageIndex: parallel.pageIndex];
    }
    currentParallel = parallel;
}

// SKYEPUB SDK CALLBACK
// called when Playing a parallel ends in MediaOverlay.
-(void)fixedViewController:(FixedViewController *)fvc parallelDidEnd:(Parallel *)parallel {
    if (setting.highlightTextToVoice) {
        [fv restoreElementColor];
    }
    if (isLoop) {
        [fv playPrevParallel];
    }
}

// SKYEPUB SDK CALLBACK
// called when playing all parallels is finished.
-(void)parallesDidEnd:(FixedViewController *)fvc {
    if (autoStartPlayingWhenNewPagesLoaded) {
        isAutoPlaying = true;
    }
    if (autoMovePageWhenParallesFinished) {
        [fv gotoNextPage];
    }
}

// should call destory explicitly whenever this viewController is dismissed.
-(void)destroy {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeSkyErrorNotification];
    [sd updateBookPosition:self.bookInformation];
    [sd updateSetting:setting];
    bookInformation = nil;
    [fv removeFromParentViewController];
    [fv.view removeFromSuperview];
    fv.dataSource = nil;
    fv.delegate = nil;
    [fv destroy];
}

-(void)homePressed:(id)sender {
    [self destroy];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)menuPressed:(id)sender {
    [self showUI];
}

-(void)listPressed:(id)sender {
    [self showListBox];
}

-(void)searchPressed:(id)sender {
    [self showSearchBox:true];
}

-(void)bookmarkPressed:(id)sender {
    [self toggleBookmark];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
@end

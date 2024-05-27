//
//  BookViewController.m
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/15.
//

#import "BookViewController.h"
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


@interface ArrowView : UIView {
    UIColor *color;
    BOOL upSide;
}
@property BOOL upSide;
@end

@implementation ArrowView
@synthesize upSide;

-(void)setColor:(UIColor*)newColor {
    color = newColor;
    [self setNeedsDisplay];
}

-(void)drawRect:(CGRect)rect {
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (upSide) {
        CGContextBeginPath(ctx);
        CGContextMoveToPoint   (ctx, CGRectGetMaxX(rect)/2, CGRectGetMinY(rect));  // top left
        CGContextAddLineToPoint(ctx, CGRectGetMinX(rect), CGRectGetMaxY(rect));  // mid right
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMaxY(rect));  // bottom left
        CGContextClosePath(ctx);
    }else {
        CGContextBeginPath(ctx);
        CGContextMoveToPoint   (ctx, CGRectGetMinX(rect), CGRectGetMinY(rect));  // top left
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect), CGRectGetMinY(rect));  // mid right
        CGContextAddLineToPoint(ctx, CGRectGetMaxX(rect)/2, CGRectGetMaxY(rect));  // bottom left
        CGContextClosePath(ctx);
    }
    CGContextSetFillColorWithColor(ctx, [color CGColor]);
    CGContextFillPath(ctx);
}
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

typedef enum {
    SearchResultNormal,
    SearchResultMore,
    SearchResultFinished
} SearchResultType;

IB_DESIGNABLE
@interface SkySlider : UISlider
@property (nonatomic) IBInspectable UIImage *thumbImage;
@end


@interface BookViewController () {
    int bookCode;
    SkyData* sd;
    Setting* setting;
    PageInformation* info;
    ReflowableViewController* rv;
    
    UIColor* currentColor;
    Highlight* currentHighlight;
    CGRect currentStartRect;
    CGRect currentEndRect;
    CGRect currentMenuFrame;
    CGRect currentArrowFrame;
    CGRect currentArrowFrameForNote;
    CGRect currentNoteFrame;
    BOOL isUpArrow;
    PageInformation* currentPageInformation;
    
    BOOL isRotationLocked;
    BOOL isBookmarked;
    int lastNumberOfSearched;
    CGFloat searchScrollHeight;
    NSMutableArray* searchResults;
    
    NSMutableArray* fontNames;
    NSMutableArray* fontAliases;
    CGFloat selectedFontOffsetY;
    int currentSelectedFontIndex;
    UIButton* currentSelectedFontButton;
    
    NSMutableArray* themes;
    Theme* currentTheme;
    int currentThemeIndex;
    
    NSMutableArray* highlights;
    NSMutableArray* bookmarks;
    
    Parallel* currentParallel;
    ArrowView* arrow;
    UIView* snapView;
    UIActivityIndicatorView* activityIndicator;
    
    BOOL isAutoPlaying;
    BOOL isLoop;
    BOOL autoStartPlayingWhenNewChapterLoaded;
    BOOL autoMoveChapterWhenParallesFinished;
    
    BOOL isChapterJustLoaded;
    BOOL isControlsShown;
    BOOL isScrollMode;
    BOOL isFontBoxMade;
    
    BOOL isInitialized;
    BOOL didApplyClearBox;
}
@property (strong, nonatomic) IBOutlet UIView *listBox;
@property (weak, nonatomic) IBOutlet UILabel *listBoxTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *listBoxResumeButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *listBoxSegmentedControl;
@property (weak, nonatomic) IBOutlet UIView *listBoxContainer;
@property (weak, nonatomic) IBOutlet UITableView *contentsTableView;
@property (weak, nonatomic) IBOutlet UITableView *notesTableView;
@property (weak, nonatomic) IBOutlet UITableView *bookmarksTableView;

@property (weak, nonatomic) IBOutlet UIView *skyepubView;
@property (weak, nonatomic) IBOutlet UIButton *homeButton;
@property (weak, nonatomic) IBOutlet UIButton *listButton;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;
@property (weak, nonatomic) IBOutlet UIButton *fontButton;
@property (weak, nonatomic) IBOutlet UIButton *bookmarkButton;

@property (weak, nonatomic) IBOutlet UILabel *pageIndexLabel;
@property (weak, nonatomic) IBOutlet UILabel *leftIndexLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightIndexLabel;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet SkySlider *slider;

@property (strong, nonatomic) IBOutlet UIView *menuBox;
@property (strong, nonatomic) IBOutlet UIView *highlightBox;
@property (strong, nonatomic) IBOutlet UIView *colorBox;
@property (strong, nonatomic) IBOutlet UIView *noteBox;
@property (weak, nonatomic) IBOutlet UITextView *noteTextView;

@property (strong, nonatomic) IBOutlet UIView *searchBox;
@property (weak, nonatomic) IBOutlet UITextField *searchTextField;
@property (weak, nonatomic) IBOutlet UIButton *searchCancelButton;
@property (weak, nonatomic) IBOutlet UIScrollView *searchScrollView;
@property (strong, nonatomic) IBOutlet UIView *baseView;

@property (strong, nonatomic) IBOutlet UIView *fontBox;
@property (weak, nonatomic) IBOutlet UISlider *brightnessSlider;
@property (weak, nonatomic) IBOutlet UIImageView *decreaseBrightnessIcon;
@property (weak, nonatomic) IBOutlet UIImageView *increaseBrightnessIcon;
@property (weak, nonatomic) IBOutlet UIButton *decreaseFontSizeButton;
@property (weak, nonatomic) IBOutlet UIButton *increaseFontSizeButton;
@property (weak, nonatomic) IBOutlet UIButton *decreaseLineSpacingButton;
@property (weak, nonatomic) IBOutlet UIButton *increaseLineSpacingButton;
@property (weak, nonatomic) IBOutlet UIButton *theme0Button;
@property (weak, nonatomic) IBOutlet UIButton *theme1Button;
@property (weak, nonatomic) IBOutlet UIButton *theme2Button;
@property (weak, nonatomic) IBOutlet UIButton *theme3Button;
@property (weak, nonatomic) IBOutlet UIScrollView *fontScrollView;

@property (strong, nonatomic) IBOutlet UIView *siBox;
@property (weak, nonatomic) IBOutlet UILabel *siBoxChapterTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *siBoxPositionLabel;

@property (strong, nonatomic) IBOutlet UIView *mediaBox;
@property (weak, nonatomic) IBOutlet UIButton *prevButton;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *stopButton;
@property (weak, nonatomic) IBOutlet UIButton *nextButton;

@end

@implementation BookViewController
@synthesize bookInformation;

-(void)setDefaultValues {
    bookCode = -1;
    currentPageInformation = [[PageInformation alloc]init];
    
    lastNumberOfSearched = 0;
    searchScrollHeight = 0;
    
    searchResults = [[NSMutableArray alloc]init];
    fontNames = [[NSMutableArray alloc]init];
    fontAliases = [[NSMutableArray alloc]init];
    
    selectedFontOffsetY = 0;
    currentSelectedFontIndex = 0;
    
    themes = [[NSMutableArray alloc]init];
    currentTheme = [[Theme alloc]init];
    currentThemeIndex= 0;
    
    highlights = [[NSMutableArray alloc]init];
    bookmarks = [[NSMutableArray alloc]init];
    
    isAutoPlaying = true;
    isLoop = false;
    autoStartPlayingWhenNewChapterLoaded = false;
    autoMoveChapterWhenParallesFinished = false;
    
    isChapterJustLoaded = false;
    isControlsShown = true;
    isScrollMode = false;
    isFontBoxMade = false;
    
    isInitialized = false;
    didApplyClearBox = false;
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
}

-(void)addSkyErrorNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processError:) name:@"SkyError" object:nil];
}

-(void)removeSkyErrorNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SkyError" object:nil];
}

-(void)processError:(NSNotification*)notification {
    if (!isInitialized) isInitialized = YES;
    NSNumber* code  = [[notification userInfo] objectForKey:@"code"];
    NSNumber* level  = [[notification userInfo] objectForKey:@"level"];
    NSString* message  = [[notification userInfo] objectForKey:@"message"];
    NSLog(@"SkyError code %d level %d Detected :%@",[code intValue],[level intValue],message);
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

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setDefaultValues];
    // Do any additional setup after loading the view.
    
    AppDelegate* ad =  (AppDelegate*)[[UIApplication sharedApplication] delegate];
    sd = ad.data;
    
    setting = [sd fetchSetting];
    [self makeThemes];
    
    currentThemeIndex = setting.theme;
    currentTheme = [themes objectAtIndex:currentThemeIndex];
    
    [self addSkyErrorNotification];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    [self makeBookViewer];
    [self makeUI];
    
    [self recalcPageLabels];
    
    currentColor =  [self getMarkerColor:0];
    
    isAutoPlaying = true;
    autoStartPlayingWhenNewChapterLoaded = setting.autoStartPlaying;
    autoMoveChapterWhenParallesFinished  = setting.autoLoadNewChapter;
    isLoop = false;
}

// simple funtion to return bookPath just binding baseDirectory + / + fileName
-(NSString*)getBookPath {
    NSString* bookPath = [NSString stringWithFormat:@"%@/%@",rv.baseDirectory,rv.fileName];
    return bookPath;
}

-(void)makeBookViewer {
    //-----------------------------------------
    __weak id weakSelf = self;
    // make ReflowableViewController object for epub.
    rv = [[ReflowableViewController alloc]initWithStartPagePositionInBook:self.bookInformation.position];
    // set the color for blank screen.
    [rv setBlankColor:currentTheme.backgroundColor];
    // set the inital background color.
    [rv changeBackgroundColor:currentTheme.backgroundColor];
    // set global pagination mode
    [rv setPagingMode:PAGING_NORMAL];
//        [rv setPagingMode:PAGING_SCAN];
//        [rv setPagingMode:PAGING_ESTIMATION];
    // set rv's datasource to self.
    rv.dataSource = weakSelf;
    // set rv's delegate to self.
    rv.delegate =weakSelf;
    // set filename and bookCode to open.
    rv.fileName = self.bookInformation.fileName;
    rv.bookCode = self.bookInformation.bookCode;
    bookCode = rv.bookCode;
    // booksDirectory is the place where the epub files exist.
    // set baseDirector of rv to booksDirectory
    rv.baseDirectory = [sd getBooksDirectory];
    
    // since 8.5.0, setBookPath is used to set the path of epub
    // once setBookPath is used, skyepub sdk will extract baseDirectory and fileName from bookPath automatically. 
    [rv setBookPath:[self getBookPath]];
    
    // set the font size of rv
    rv.fontSize = [self getRealFontSize:setting.fontSize];
    // set lineSpacing of rv
    rv.lineSpacing = [self getRealLineSpacing:setting.lineSpacing];
    // set book flow as Reflowable Layout not Fixed Layout
    rv.isFixedLayout = NO;
    if (![setting.fontName isEqualToString:@"Book Fonts"]) {
        rv.fontName = setting.fontName;
    }
    // 0: none, 1:slide transition, 2: curling transition.
    rv.transitionType = setting.transitionType;
    // if true, sdk will show 2 pages when screen is landscape.
    [rv setDoublePagedForLandscape:setting.doublePaged];
    // if true, sdk will use gloabal pagination.
    [rv setGlobalPaging:setting.globalPagination];
    // 25% space (in both left most and right most margins)
    [rv setHorizontalGapRatio:0.25f];
    // 20% space (in both top and bottom margins)
    [rv setVerticalGapRatio:0.20];
    // enable tts feature
    [rv setTTSEnabled:setting.tts];
    // set the speed of tts.
    // AVSpeechUtteranceMinimumSpeechRate,AVSpeechUtteranceDefaultSpeechRate,AVSpeechUtteranceMaximumSpeechRate
    // 0~1.0f   1.0f is max and fastest.
    [rv setTTSRate:AVSpeechUtteranceDefaultSpeechRate];
    // set the tone of tts.
    [rv setTTSPitch:1.0];
    // set the language of tts
    // if "auto" is set, TTS follows the language of epub itself.
    [rv setTTSLanguage:@"auto"];
    // set the voice rate (voice speed) of mediaOverlay (1.0f is default, if 2.0 is set, twice times faster than normal speed.
    [rv setMediaOverlayRate:1.0f];
    
    [rv setLicenseKey:@"0000-0000-0000-0000"];
    // ignore page-break property in css file to avoid text line overlapping
    [rv setPageBreakIgnored:YES];        // ignore page-break property in css file to avoid text line overlapping
    // if No, tapping on both side to navigate page will be disabled.
    [rv setNavigationAreaEnabled:YES];
    
    // Normally Scan is activated when globalPagination or searching starts,
    // but autoStartScan is set to YES, Scan will starts when book opens at the first time.
    [rv setAutoStartScan:NO];
    [rv setAutoStartGlobalPaging:YES];
    [rv performSelector:@selector(showVersion) withObject:nil];
    
    // make SkyProvider object to read epub reader.
    SkyProvider* skyProvider = [[SkyProvider alloc]init];
    // set skyProvider datasource
    skyProvider.dataSource = weakSelf;
    // set skyProvider book to rv's book
    skyProvider.book = rv.book;
    // set the content provider of rv as skyProvider
    [rv setContentProvider:skyProvider];
    // if true, you are able to draw highlight in custom.
    [rv setCustomDrawHighlight:YES];
    // set the coordinates and size of rv
    rv.view.frame = self.skyepubView.bounds;
    rv.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    // add tv to skyepubView which is made in story board as a container of epub viewer.
    [self.skyepubView addSubview:rv.view];
    [self addChildViewController:rv];
    self.view.autoresizesSubviews = true;
}

-(void)makeUI {
    // if RTL (Right to Left writing like Arabic or Hebrew)
    if ([rv isRTL]) {
        // Inverse the direction of slider.
        self.slider.transform = CGAffineTransformRotate(self.slider.transform, 180.0/180*M_PI);
    }
    
    if ([rv isGlobalPagination]) {
        self.slider.maximumValue = [rv getNumberOfPagesInBook]-1;
        self.slider.minimumValue = 0;
        long globalPageIndex = [rv getPageIndexInBook];
        [self.slider setValue:globalPageIndex];
    }
    
    isRotationLocked = setting.lockRotation;
    [self makeFonts];
    
    arrow = [[ArrowView alloc]init];
    arrow.hidden = true;
    [self.view addSubview:arrow];
    
    // listBox
    self.contentsTableView.delegate = self;
    self.contentsTableView.dataSource = self;
    self.bookmarksTableView.delegate = self;
    self.bookmarksTableView.dataSource = self;
    self.notesTableView.delegate = self;
    self.notesTableView.dataSource = self;
    
    [self fillFontScrollView];
    [self applyCurrentTheme];
    
    self.menuBox.hidden = true;
    self.colorBox.hidden = true;
    self.highlightBox.hidden = true;
}

// SKYEPUB SDK CALLBACK
// called when page is moved.
// PageInformation object contains all information about current page position.
-(void)reflowableViewController:(ReflowableViewController*)rvc pageMoved:(PageInformation*)pageInformation{
    double ppb = pageInformation.pagePositionInBook;
    double pageDelta = ((1/pageInformation.numberOfChaptersInBook)/pageInformation.numberOfPagesInChapter);
    
    if ([rv isGlobalPagination]) {
        if (![rv isPaging]) {
            self.slider.minimumValue = 0;
            self.slider.maximumValue = (float)(pageInformation.numberOfPagesInBook-1);
            self.slider.value = (float)(pageInformation.pageIndexInBook);
            int cgpi = [rv getPageIndexInBookByPagePositionInBook:pageInformation.pagePositionInBook];
        }
    }else {
        self.slider.value = (float)ppb;
    }
        
    self.bookInformation.position = pageInformation.pagePositionInBook;
    
    self.titleLabel.text = rvc.title;
    [self changePageLabels:pageInformation];
    
    isBookmarked = [sd isBookmarked:pageInformation];
    currentPageInformation = pageInformation;
    
    if (autoStartPlayingWhenNewChapterLoaded && isChapterJustLoaded) {
        if ((([rv isMediaOverlayAvailable] && setting.mediaOverlay) || ([rv isTTSEnabled] && setting.tts))  && isAutoPlaying ) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [rv playFirstParallelInPage];
                [self changePlayAndPauseButton];
            });
        }
    }
    isChapterJustLoaded = false;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self processNoteIcons];
        [self processBookmark];
    });
}

// SKYEPUB SDK CALLBACK
// called when a new chapter has been just loaded.
-(void)reflowableViewController:(ReflowableViewController*)rvc didChapterLoad:(int)chapterIndex {
    if ([rvc isMediaOverlayAvailable] && setting.mediaOverlay) {
        [rv setTTSEnabled:NO];
        [self showMediaBox];
    }else if ([rv isTTSEnabled] ) {
        [self showMediaBox];
    }else {
        [self hideMediaBox];
    }
    isChapterJustLoaded = YES;
}


- (IBAction)sliderDragStarted:(id)sender {
    [self showSIBox];
}

// about pagePosition concepts of skyepub, please refer to the link https://www.dropbox.com/s/heu7v0mjtyayh0q/PagePositionInBoo k.pdf?dl=1
- (IBAction)sliderDragEnded:(id)sender {
    int position = self.slider.value;
    // if rv is global pagination mode,
    if ([rv isGlobalPagination]) {
        int pib = position;
        double ppb = [rv getPagePositionInBookByPageIndexInBook:pib];
        // goto the position in book by ppb which is calculated by pageIndex in boo k.
        [rv gotoPageByPagePositionInBook:ppb];
        NSLog(@"sliderDragEnded for Global");
    }else {
        [rv gotoPageByPagePositionInBook:self.slider.value animated:false];
    }
    [self hideSIBox];
}

- (IBAction)sliderValueChanged:(id)sender {
    [self updateSIBox];
}

-(void)showSIBox  {
    float sx,sy,sw,sh;
    sx = (self.view.frame.size.width-self.siBox.frame.size.width)/2;
    sy = self.view.frame.size.height-135;
    sw = self.siBox.frame.size.width;
    sh = self.siBox.frame.size.height;
    if (![rv isGlobalPagination]) {
        sh = 42;
        sy = sy + 10;
        self.siBoxPositionLabel.hidden = true;
    }else {
        sh = 52;
        self.siBoxPositionLabel.hidden = false;
    }
    self.siBox.frame = CGRectMake(sx,sy,sw,sh);
    [self.view addSubview:self.siBox];
    [self applyThemeToSIBox: currentTheme];
    self.siBox.hidden = false;
}

-(void)hideSIBox {
    if (self.siBox.hidden) {
        return;
    }
    self.siBox.hidden = true;
    [self.siBox removeFromSuperview];   // this line causes the constraint issues.
}


-(void)updateSIBox {
    double ppb = 0;
    PageInformation* pi;
    int pib = self.slider.value;
    
    if ([rv isGlobalPagination]) {
        ppb = [rv getPagePositionInBookByPageIndexInBook:pib];
    }else {
        ppb = (double)self.slider.value;
    }
    pi = [rv getPageInformationAtPagePositionInBook: ppb];
    
    long ci = pi.chapterIndex;
    NSString* caption;
        
    if (self.slider.value == self.slider.maximumValue) {
        caption = @"The End";
    }else if (pi.chapterTitle==nil || pi.chapterTitle.length==0) {
        caption = [NSString stringWithFormat:@"Chapter %ldth",ci];
    }else {
        caption = pi.chapterTitle;
    }
    
    self.siBoxChapterTitleLabel.text = caption;
    if ([rv isGlobalPagination]) {
        long gpi = self.slider.value;
        self.siBoxPositionLabel.text = [NSString stringWithFormat:@"%ld",gpi+1];
    }else {
        self.siBoxPositionLabel.text = @"";
    }
}

-(void)changePageLabels:(PageInformation*)pageInformation {
    int pi,pn;
    if ([rv isGlobalPagination]) {
        pi = pageInformation.pageIndexInBook;
        pn = pageInformation.numberOfPagesInBook;
    }else {
        pi = pageInformation.pageIndex;
        pn = pageInformation.numberOfPagesInChapter;
    }
    int dpi,dpn;
    if ([rv isDoublePaged] && ![self isPortrait]) {
        dpi = (pi*2)+1;
        dpn = pn*2;
        self.leftIndexLabel.text = [NSString stringWithFormat:@"%d/%d",dpi,dpn];
        dpi = (pi*2)+2;
        self.rightIndexLabel.text = [NSString stringWithFormat:@"%d/%d",dpi,dpn];
    }else {
        dpi = pi+1;
        dpn = pn;
        self.pageIndexLabel.text =[NSString stringWithFormat:@"%d/%d",dpi,dpn];
    }
}


-(void)destroy {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeSkyErrorNotification];
    [sd updateBookPosition:self.bookInformation];
    [sd updateSetting:setting];
    bookInformation = nil;
    rv.dataSource = nil;
    rv.delegate = nil;
    rv.customView = nil;
    [rv removeFromParentViewController];
    [rv.view removeFromSuperview];
    [rv destroy];
}

-(void)homePressed:(id)sender {
    [self destroy];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)listPressed:(id)sender {
    [self showListBox];
}

-(void)fontPressed:(id)sender {
    [self showFontBox];
}

-(void)searchPressed:(id)sender {
    [self showSearchBox:true];
}

-(void)bookmarkPressed:(id)sender {
    [self toggleBookmark];
}

-(void)processBookmark {
    if (isBookmarked) {
        [self.bookmarkButton setImage:[UIImage imageNamed:@"bookmarked"] forState:UIControlStateNormal];
    }else {
        [self.bookmarkButton setImage:[UIImage imageNamed:@"bookmark"] forState:UIControlStateNormal];
    }
}

-(void)toggleBookmark {
    [sd toggleBookmark: [rv getPageInformation]];
    isBookmarked = !isBookmarked;
    [self processBookmark];
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

-(void)applyCurrentTheme {
    [self focusSelectedThemeButton];
    [self applyTheme:currentTheme];
}

-(void)applyTheme:(Theme*)theme {
    [self applyThemeToBookViewer:theme];
    [self applyThemeToFontBox:theme];
    [self applyThemeToListBox:theme];
    [self applyThemeToSearchBox:theme];
    [self applyThemeToMediaBox:theme];
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
    
    // self.searchTextField.addTarget(self, action: #selector(self.searchTextFieldDidChange(_:)), for: .editingChanged)
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

-(void)applyThemeToMediaBox:(Theme*)theme {
    self.prevButton.tintColor = theme.iconColor;
    self.playButton.tintColor = theme.iconColor;
    self.stopButton.tintColor = theme.iconColor;
    self.nextButton.tintColor = theme.iconColor;
}

-(void)applyThemeToFontBox:(Theme*)theme {
    self.fontBox.backgroundColor = theme.boxColor;
    self.fontBox.layer.borderColor = theme.borderColor.CGColor;
    
    self.brightnessSlider.thumbTintColor = [UIColor colorWithRed:250/255 green:250/255 blue:250/255 alpha:1];
    self.brightnessSlider.minimumTrackTintColor = theme.sliderMinTrackColor;
    self.brightnessSlider.maximumTrackTintColor = theme.sliderMaxTrackColor;
        
    self.decreaseBrightnessIcon.tintColor = theme.iconColor;
    self.increaseBrightnessIcon.tintColor = theme.iconColor;
    
    self.increaseFontSizeButton.layer.borderColor = theme.borderColor.CGColor;
    self.decreaseFontSizeButton.layer.borderColor = theme.borderColor.CGColor;
    self.increaseFontSizeButton.tintColor = theme.iconColor;
    self.decreaseFontSizeButton.tintColor = theme.iconColor;
    
    self.increaseLineSpacingButton.layer.borderColor = theme.borderColor.CGColor;
    self.increaseLineSpacingButton.tintColor = theme.iconColor;
    self.decreaseLineSpacingButton.layer.borderColor = theme.borderColor.CGColor;
    self.decreaseLineSpacingButton.tintColor = theme.iconColor;
    
    self.fontScrollView.layer.borderColor = theme.borderColor.CGColor;
    
    [self focusSelectedFont];
}

-(void)applyThemeToSIBox:(Theme*)theme {
    self.siBox.layer.borderWidth = 1;
    self.siBox.layer.cornerRadius = 10;
    
    if (currentThemeIndex == 0 || currentThemeIndex == 1) {
        self.siBox.backgroundColor = theme.iconColor;
        self.siBox.layer.borderColor = theme.textColor.CGColor;
        self.siBoxChapterTitleLabel.textColor = theme.backgroundColor;
        self.siBoxPositionLabel.textColor = theme.backgroundColor;
    }else {
        self.siBox.backgroundColor = theme.boxColor;
        self.siBox.layer.borderColor = [UIColor darkGrayColor].CGColor;
        self.siBoxChapterTitleLabel.textColor = theme.textColor;
        self.siBoxPositionLabel.textColor = theme.textColor;
    }
}

-(void)applyThemeToBookViewer:(Theme*)theme {
    self.homeButton.tintColor = theme.iconColor;
    self.listButton.tintColor = theme.iconColor;
    self.searchButton.tintColor = theme.iconColor;
    self.fontButton.tintColor = theme.iconColor;
    self.bookmarkButton.tintColor = theme.iconColor;
    
    self.titleLabel.textColor = theme.labelColor;
    self.pageIndexLabel.textColor = theme.labelColor;
    self.leftIndexLabel.textColor = theme.labelColor;
    self.rightIndexLabel.textColor = theme.labelColor;
    
    [self.slider setThumbImage:[self thumbImage] forState:UIControlStateNormal];
    [self.slider setThumbImage:[self thumbImage] forState:UIControlStateHighlighted];
    
    self.slider.minimumTrackTintColor = theme.sliderMinTrackColor;
    self.slider.maximumTrackTintColor = theme.sliderMaxTrackColor;
    
    self.view.backgroundColor = theme.backgroundColor;
    [rv changeBackgroundColor:theme.backgroundColor];
    if ([theme.textColor isEqual:[UIColor blackColor]]) {
        [rv changeForegroundColor:nil];
        // to set foreground color to nil will restore original book style color.
    }else {
        [rv changeForegroundColor:theme.textColor];
    }
}

-(UIImage*)thumbImage {
    UIImage* thumbImage;
    thumbImage = [[UIImage imageNamed:@"skythumb"] imageWithColor:currentTheme.sliderThumbColor];
    return thumbImage;
}

-(void)addFont:(NSString*)name alias:(NSString*)alias {
    [fontNames addObject:name];
    [fontAliases addObject:alias];
}

// Make fontNames and fontAliases array once.
-(void)makeFonts {
    [self addFont:@"Book Fonts" alias:@"전자책 폰트"];
    [self addFont:@"Courier" alias:@"Courier"];
    [self addFont:@"Arial" alias:@"Arial"];
    [self addFont:@"Times New Roman" alias:@"Times New Roman"];
    [self addFont:@"American Typewriter" alias:@"American Typewriter"];
    [self addFont:@"Marker Felt" alias:@"Marker Felt"];
    [self addFont:@"Mayflower Antique" alias:@"Mayflower Antique"];
    [self addFont:@"Underwood Champion" alias:@"Underwood Champion"];
}

-(void)showFontBox {
    CGFloat fx = 0;
    CGFloat fy = 0;
    
    [self showBaseView];
    self.fontBox.exclusiveTouch = true;
    self.fontBox.hidden = false;
    [self.view addSubview:self.fontBox];
    
    CGFloat rightMargin = 50.0;
    CGFloat topMargin = 60.0 + self.view.safeAreaInsets.top;

    if ([self isPad]) {
        fx = self.view.bounds.size.width - self.fontBox.bounds.size.width - rightMargin;
        fy = topMargin;
    }else {
        fx = (self.view.frame.size.width-self.fontBox.frame.size.width)/2;
        fy = self.view.safeAreaInsets.top+50;
    }
    
    self.fontBox.frame = CGRectMake(fx,fy,self.fontBox.frame.size.width,self.fontBox.frame.size.height);
    
    if (!isFontBoxMade)  {
        [self fillFontScrollView];
    }
    [self focusSelectedFont];
    
    self.fontBox.layer.borderWidth = 1;
    self.fontBox.layer.cornerRadius = 10;
    self.fontScrollView.layer.borderWidth = 1;
    self.fontScrollView.layer.cornerRadius = 10;
    
    self.brightnessSlider.value = (float)setting.brightness;
}

-(void)hideFontBox  {
    self.fontBox.hidden = true;
    [self.fontBox removeFromSuperview];
    [self hideBaseView];
}

-(void)increaseFontSize {
    NSString* fontName = setting.fontName;
    if ([fontName isEqualToString:@"Book Fonts"]) {
        fontName = @"";
    }
    if (setting.fontSize != 4) {
        int fontSize = setting.fontSize;
        fontSize += 1;
        // changeFontName changes font, fontSize.
        BOOL ret = [rv changeFontName:fontName fontSize:[self getRealFontSize:fontSize]];
        if (ret) {
            setting.fontSize = fontSize;
        }
    }
}

-(void)decreaseFontSize {
    NSString* fontName = setting.fontName;
    if ([fontName isEqualToString:@"Book Fonts"]) fontName = @"";
    if (setting.fontSize!=0) {
        int fontSize = setting.fontSize;
        fontSize--;
        BOOL ret = [rv changeFontName:fontName fontSize:[self getRealFontSize:fontSize]];
        if (ret) {
            setting.fontSize = fontSize;
        }
    }
}

-(void)decreaseLineSpacing {
    if (setting.lineSpacing != 0) {
        int lineSpacingIndex = setting.lineSpacing;
        lineSpacingIndex -= 1;
        int realLineSpacing = [self getRealLineSpacing:lineSpacingIndex];
        BOOL ret = [rv changeLineSpacing:realLineSpacing];
        if (ret) {
            setting.lineSpacing = lineSpacingIndex;
        }
    }
}

-(void)increaseLineSpacing {
    if (setting.lineSpacing != 5) {
        int lineSpacingIndex = setting.lineSpacing;
        lineSpacingIndex += 1;
        int realLineSpacing = [self getRealLineSpacing:lineSpacingIndex];
        BOOL ret = [rv changeLineSpacing:realLineSpacing];
        if (ret) {
            setting.lineSpacing = lineSpacingIndex;
        }
    }
}

-(void)focusSelectedThemeButton {
    self.theme0Button.layer.borderWidth = 1;
    self.theme1Button.layer.borderWidth = 1;
    self.theme2Button.layer.borderWidth = 1;
    self.theme3Button.layer.borderWidth = 1;
    switch (currentThemeIndex) {
        case 0:
            self.theme0Button.layer.borderWidth = 3;
            break;
        case 1:
            self.theme1Button.layer.borderWidth = 3;
            break;
        case 2:
            self.theme2Button.layer.borderWidth = 3;
            break;
        case 3:
            self.theme3Button.layer.borderWidth = 3;
            break;
        default:
            self.theme0Button.layer.borderWidth = 3;
    }
    currentTheme = [themes objectAtIndex:currentThemeIndex];
}


-(void)focusSelectedFont {
    CGFloat itemHeight  = 40;
    CGFloat selectedFontOffsetY = 0;
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"self isKindOfClass: %@", [UIButton class]];
    NSArray* fontButtons= [self.fontScrollView.subviews filteredArrayUsingPredicate:predicate];
    
    for (int i=0; i<[fontButtons count]; i++) {
        UIButton* fontButton = [fontButtons objectAtIndex:i];
        if (fontButton.isSelected) {
            selectedFontOffsetY = fontButton.frame.origin.y - itemHeight;
        }
        [fontButton setTitleColor:currentTheme.selectedColor forState:UIControlStateSelected];
        [fontButton setTitleColor:currentTheme.labelColor forState:UIControlStateNormal];
    }
    [self.fontScrollView setContentOffset:CGPointMake(0,selectedFontOffsetY)];
}

-(void)fillFontScrollView {
    CGFloat itemHeight = 40;
    CGFloat itemOffsetY = 0;
    int fontIndex = 0;
    
    for (int i=0; i<[fontNames count]; i++) {
        NSString* fontName = [fontNames objectAtIndex:i];
        NSString* fontAlias = [fontAliases objectAtIndex:i];
        UIFont* font = [UIFont fontWithName:fontName size:18.0];
        if (font==nil) {
            font = [UIFont systemFontOfSize:18.0];
        }
        UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitle:fontAlias forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:20.0f/255.0f green:40.0f/255.0f blue:230.0f/255.0f alpha:1.0f] forState:UIControlStateSelected];
        button.frame = CGRectMake(0,itemOffsetY,280,itemHeight);
        
        if ([fontName isEqualToString:setting.fontName]) {
            [button setSelected:YES];
            selectedFontOffsetY = itemOffsetY;
            currentSelectedFontIndex = fontIndex;
            currentSelectedFontButton = button;
        }
        button.tag = fontIndex;
        button.titleLabel.font = font;
        button.showsTouchWhenHighlighted = YES;
        [button addTarget:self action:@selector(fontNameButtonClick:) forControlEvents:UIControlEventTouchUpInside];
        [self.fontScrollView addSubview:button];
        fontIndex++;
        itemOffsetY += itemHeight;
    }
    
    self.fontScrollView.contentSize = CGSizeMake(200, itemOffsetY);
    [self focusSelectedFont];
    isFontBoxMade = true;
}

-(void)fontNameButtonClick:(id)sender {
    [currentSelectedFontButton setSelected:NO];
    UIButton *button = (UIButton*)sender;
    [button setSelected:YES];
    
    currentSelectedFontButton = button;
    currentSelectedFontIndex = (int)button.tag;
    NSString* fontName = [fontNames objectAtIndex:currentSelectedFontIndex];
    
    if ([fontName isEqualToString:@"Book Fonts"]) fontName = @"";
    BOOL ret = [rv changeFontName:fontName fontSize:[self getRealFontSize:setting.fontSize]];
    if (ret) {
        setting.fontName = fontName;
    }
}

-(IBAction)brightnessSliderChanged:(id)sender {
    setting.brightness = _brightnessSlider.value;
    [[UIScreen mainScreen] setBrightness: setting.brightness];
}

- (IBAction)increaseFontSizeDown:(id)sender {
    self.increaseFontSizeButton.backgroundColor = [UIColor lightGrayColor];
}

- (IBAction)increaseFontSizePressed:(id)sender {
    self.increaseFontSizeButton.backgroundColor = [UIColor clearColor];
    [self increaseFontSize];
}

- (IBAction)decreaseFontSizeDown:(id)sender {
    self.decreaseFontSizeButton.backgroundColor = [UIColor lightGrayColor];
}

- (IBAction)decreaseFontSizePressed:(id)sender {
    self.decreaseFontSizeButton.backgroundColor = [UIColor clearColor];
    [self decreaseFontSize];
}

- (IBAction)increaseLineSpacingDown:(id)sender {
    self.increaseLineSpacingButton.backgroundColor = [UIColor lightGrayColor];
}

- (IBAction)increaseLineSpacingPressed:(id)sender {
    self.increaseLineSpacingButton.backgroundColor = [UIColor clearColor];
    [self increaseLineSpacing];
}

- (IBAction)decreaseLineSpacingDown:(id)sender {
    self.decreaseLineSpacingButton.backgroundColor = [UIColor lightGrayColor];
}

- (IBAction)decreaseLineSpacingPressed:(id)sender {
    self.decreaseLineSpacingButton.backgroundColor = [UIColor clearColor];
    [self decreaseLineSpacing];
}

- (IBAction)theme0Pressed:(id)sender {
    [self themePressed:0];
}

- (IBAction)theme1Pressed:(id)sender {
    [self themePressed:1];
}

- (IBAction)theme2Pressed:(id)sender {
    [self themePressed:2];
}

- (IBAction)theme3Pressed:(id)sender {
    [self themePressed:3];
}

-(void)showSnapView {
    snapView = [self.view snapshotViewAfterScreenUpdates:false];
    [self.view addSubview:snapView];
}

-(void)hideSnapView {
    [snapView removeFromSuperview];
}

-(void)showActivityIndicator {
    activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    if (currentThemeIndex == 0 || currentThemeIndex == 1) {
        activityIndicator.color = [UIColor darkGrayColor];
    }else {
        activityIndicator.color = [UIColor whiteColor];
    }
    [activityIndicator startAnimating];
    activityIndicator.center = self.view.center;
    [self.view addSubview:activityIndicator];
}

-(void)hideActivityIndicator {
    [activityIndicator stopAnimating];
    [activityIndicator removeFromSuperview];
}


-(void)themePressed:(int)themeIndex {
    if (themeIndex == currentThemeIndex) {
        return;
    }
    double delayTime = 0.1f;
    [self showSnapView];
    if (setting.transitionType==2) {
        delayTime = 2;
        [self showActivityIndicator];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self hideActivityIndicator];
        [self hideSnapView];
    });
    currentThemeIndex = themeIndex;
    setting.theme = currentThemeIndex;
    [self applyCurrentTheme];
}


-(int)getRealFontSize:(int)fontSizeIndex {
    int rs = 0;
    switch (fontSizeIndex) {
        case 0:
            rs = 15;
            break;
        case 1:
            rs = 17;
            break;
        case 2:
            rs = 20;
            break;
        case 3:
            rs = 24;
            break;
        case 4:
            rs = 27;
            break;
        default:
            rs = 20;
    }
    return rs;
}

-(int)getRealLineSpacing:(int)lineSpaceIndex {
    int rs = 0;
    switch (lineSpaceIndex) {
        case 0:
            rs = -1;
            break;
        case 1:
            rs = 125;
            break;
        case 2:
            rs = 150;
            break;
        case 3:
            rs = 165;
            break;
        case 4:
            rs = 180;
            break;
        case 5:
            rs = 200;
            break;

        default:
            rs = 150;
    }
    return rs;
}

-(void)didRotate:(NSNotification *)notification {
    // do stuff here
    NSLog(@"didRotate");
    [self recalcPageLabels];
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

-(BOOL)highlightDrawnOnFront {
    return NO;
}

-(void)recalcPageLabels {
    if ([self isPortrait]) {
        self.pageIndexLabel.hidden = false;
        self.leftIndexLabel.hidden = true;
        self.rightIndexLabel.hidden = true;
    }else {
        if (setting.doublePaged) {
            self.pageIndexLabel.hidden = true;
            self.leftIndexLabel.hidden = false;
            self.rightIndexLabel.hidden = false;
        }else {
            self.pageIndexLabel.hidden = false;
            self.leftIndexLabel.hidden = true;
            self.rightIndexLabel.hidden = true;
        }
    }
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

-(UIImage*)getMarkerImageFromColor:(UIColor*)color {
    if ([self color:color isEqual:[UIColor colorWithRed:238/255.0f green:230/255.0f blue:142/255.0f alpha:1.0f]]) {
        return [UIImage imageNamed:@"yellowmarker"];
    }else if ([self color:color isEqual:[UIColor colorWithRed:218/255.0f green:244/255.0f blue:160/255.0f alpha:1.0f]]) {
        return [UIImage imageNamed:@"greenmarker"];
    }else if ([self color:color isEqual:[UIColor colorWithRed:172/255.0f green:201/255.0f blue:246/255.0f alpha:1.0f]]) {
        return [UIImage imageNamed:@"bluemarker"];
    }else if ([self color:color isEqual:[UIColor colorWithRed:249/255.0f green:182/255.0f blue:214/255.0f alpha:1.0f]]) {
        return [UIImage imageNamed:@"redmarker"];
    }if ([self color:color isEqual:[UIColor yellowColor]]) {
        return [UIImage imageNamed:@"yellowmarker"];
    }else if ([self color:color isEqual:[UIColor greenColor]]) {
        return [UIImage imageNamed:@"greenmarker"];
    }else if ([self color:color isEqual:[UIColor blueColor]]) {
        return [UIImage imageNamed:@"bluemarker"];
    }else if ([self color:color isEqual:[UIColor redColor]]) {
        return [UIImage imageNamed:@"redmarker"];
    }else {
        return [UIImage imageNamed:@"yellowmarker"];
    }
    return nil;
}

-(BOOL)color:(UIColor*)color isEqual:(UIColor*)anotherColor {
    const CGFloat* components = CGColorGetComponents(color.CGColor);
    float red = components[0];
    float green = components[1];
    float blue = components[2];
    
    const CGFloat* anothers = CGColorGetComponents(anotherColor.CGColor);
    float ared = anothers[0];
    float agreen = anothers[1];
    float ablue = anothers[2];
    
    if (fabs(red-ared)<0.00001 && fabs(blue-ablue)<0.00001 && fabs(green-agreen)<0.00001) {
        return YES;
    }else {
        return NO;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


// Highlight
-(void)calcMenuFramesWithStartRect:(CGRect)startRect endRect:(CGRect)endRect {
    CGFloat offset = 50.0;
    CGFloat topHeight = 50.0;
    CGFloat bottomHeight = 50.0;
    CGFloat menuX = 0.0;
    CGFloat arrowX = 0.0;
    CGFloat arrowWidth = 20.0;
    CGFloat arrowHeight = 20.0;
    CGFloat topAdjust = 20;
    if ([self isPad]) {
        topAdjust = 35;
    }
    
    // check upper room for menubox
    if (startRect.origin.y-offset < topHeight) {
        if (endRect.origin.y+endRect.size.height + 50 > bottomHeight) { // there's no enough room.
            menuX = (endRect.size.width-self.menuBox.frame.size.width)/2+endRect.origin.x;
            arrowX = (endRect.size.width-arrowWidth)/2+endRect.origin.x;
            isUpArrow = true;
            currentMenuFrame = CGRectMake(menuX,endRect.origin.y+endRect.size.height+70,self.menuBox.bounds.size.width,self.menuBox.bounds.size.height);
        }
    }else {
        arrowX = (startRect.size.width-arrowWidth)/2+startRect.origin.x;
        menuX = (startRect.size.width-self.menuBox.frame.size.width)/2+startRect.origin.x;
        currentMenuFrame = CGRectMake(menuX,startRect.origin.y-topAdjust,self.menuBox.bounds.size.width,self.menuBox.bounds.size.height);
        isUpArrow = false;
    }
    
    if (currentMenuFrame.origin.x < self.view.bounds.size.width*0.1) {
        currentMenuFrame.origin.x = self.view.bounds.size.width*0.1;
    }else if ((currentMenuFrame.origin.x + currentMenuFrame.size.width) > self.view.bounds.size.width*0.9) {
        currentMenuFrame.origin.x = self.view.bounds.size.width*0.9-currentMenuFrame.size.width;
    }
    
    if (arrowX < currentMenuFrame.origin.x+20) {
        arrowX = currentMenuFrame.origin.x+20;
    }
    if (arrowX > currentMenuFrame.origin.x + self.menuBox.bounds.size.width-40) {
        arrowX = currentMenuFrame.origin.x+self.menuBox.bounds.size.width-40;
    }
    if (isUpArrow) {
        currentArrowFrame = CGRectMake(arrowX,currentMenuFrame.origin.y-arrowHeight+4,arrowWidth,arrowHeight);
    }else {
        currentArrowFrame = CGRectMake(arrowX,currentMenuFrame.origin.y+currentMenuFrame.size.height-4,arrowWidth,arrowHeight);
    }
}

-(void)showMenuBox:(CGRect)startRect endRect:(CGRect)endRect {
    [self calcMenuFramesWithStartRect:startRect endRect:endRect];
    [self.view addSubview:self.menuBox];
    self.menuBox.frame = currentMenuFrame;
    self.menuBox.hidden = false;
    [self showArrow:0];
}

-(void)showArrow:(int)targetType {
    arrow.backgroundColor = [UIColor clearColor];
    if (targetType==0) {
        arrow.color = [UIColor darkGrayColor];
    }else if (targetType==1) {
        arrow.color = currentColor;
    }
    arrow.upSide = isUpArrow;
    arrow.frame = currentArrowFrame;
    arrow.hidden = false;
}

-(void)showControls {
    self.homeButton.hidden = false;
    self.listButton.hidden = false;
    self.fontButton.hidden = false;
    self.searchButton.hidden = false;
    if (!isScrollMode) {
        self.slider.hidden = false;
    }
    isControlsShown = true;
}

-(void)hideControls {
    self.homeButton.hidden = true;
    self.listButton.hidden = true;
    self.fontButton.hidden = true;
    self.searchButton.hidden = true;
    self.slider.hidden = true;
    isControlsShown = false;
}


// MediaOverlay && TTS
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
    self.titleLabel.hidden = false;
}


-(void)hideBoxes {
    [self hideMenuBox];
    [self hideHighlightBox];
    [self hideColorBox];
    [self hideNoteBox];
    [self hideSearchBox];
    [self hideFontBox];
}

-(void)hideMenuBox {
    [self.menuBox removeFromSuperview];
    self.menuBox.hidden = true;
    arrow.hidden = true;
}

-(void)hideNoteBox {
    if (self.noteBox.hidden) {
        return;
    }
    [self saveNote];
    [self.noteBox removeFromSuperview];
    self.noteBox.hidden = true;
    arrow.hidden = true;
    self.noteTextView.text = @"";
    [self.noteTextView resignFirstResponder];
    [self hideBaseView];
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
        currentHighlight.note = text;
        currentHighlight.isNote = YES;
        [rv changeHighlight:currentHighlight color:hc note:text];
    }
}

-(void)highlightPressed:(id)sender {
    [self hideMenuBox];
    [self showHighlightBox];
    [rv makeSelectionHighlight:currentColor];
}

// called from the button in black menuBox
-(void)notePressed:(id)sender {
    [self hideMenuBox];
    [rv makeSelectionHighlight:currentColor];
    [self showNoteBox];
}

-(void)showHighlightBox  {
    [self showBaseView];
    [self.view addSubview:self.highlightBox];
    self.highlightBox.frame = CGRectMake(currentMenuFrame.origin.x,currentMenuFrame.origin.y,self.highlightBox.frame.size.width,self.highlightBox.frame.size.height);
    self.highlightBox.backgroundColor = currentColor;
    self.highlightBox.hidden = false;
    [self showArrow:1];
}

-(void)showNoteBox {
    [self showBaseView];
    CGRect startRect = [rv getStartRectFromHighlight:currentHighlight];
    CGRect endRect = [rv getEndRectFromHighlight:currentHighlight];

    CGFloat topHegith = 50;
    CGFloat noteX,noteY,noteWidth,noteHeight;
    noteWidth = 280;
    noteHeight = 230;
    CGFloat arrowWidth = 20;
    CGFloat arrowHeight = 20;
    CGFloat arrowX = 0;
    CGFloat arrowY = 0;

    arrow.color = currentColor;
    CGFloat delta = 60;
    
    if ([self isPad]) { // iPad
        BOOL toDownSide;
        CGRect targetRect;
        // detect there's room in top side
        if ((startRect.origin.y - noteHeight)<topHegith) {
            toDownSide = true;  // reverse case
            targetRect = endRect;
            isUpArrow = true;
        }else {
            toDownSide = false;   // normal case
            targetRect = startRect;
            isUpArrow = true;
        }
        
        if (![self isPortrait]) { // landscape mode
            if ([rv isDoublePaged]) { // double Paged mode
                // detect whether highlight is on left side or right side.
                if (targetRect.origin.x < self.view.bounds.size.width/2) {
                    noteX = (self.view.bounds.size.width/2-noteWidth)/2;
                }else {
                    noteX = (self.view.bounds.size.width/2-noteWidth)/2 + self.view.bounds.size.width/2  ;
                }
            }else {
                noteX = (targetRect.size.width-noteWidth)/2+targetRect.origin.x;
            }
        }else { // portrait mode
            noteX = (targetRect.size.width-noteWidth)/2+targetRect.origin.x;
        }
        
        if (noteX+noteWidth>self.view.bounds.size.width*0.9) {
            noteX = self.view.bounds.size.width*0.9 - noteWidth;
        }
        if (noteX<self.view.bounds.size.width * 0.1) {
            noteX = self.view.bounds.size.width * 0.1;
        }
        arrowX = (targetRect.size.width-arrowWidth)/2+targetRect.origin.x;
        if (arrowX<noteX+10) {
            arrowX = noteX+10;
        }
        if (arrowX>noteX+noteWidth-40) {
            arrowX = noteX+noteWidth-40;
        }
        // set noteY according to isDownSide flag.
        if (!toDownSide) { // normal case - test ok
            noteY = targetRect.origin.y - noteHeight-10;
            arrowY = noteY + noteHeight-5;
            currentArrowFrame = CGRectMake(arrowX,arrowY,arrowWidth,arrowHeight);
        }else { // normal case
            noteY = targetRect.origin.y + delta;
            arrowY = noteY-20;
            currentArrowFrame = CGRectMake(arrowX,arrowY,arrowWidth,arrowHeight);
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
    
    currentNoteFrame = CGRectMake(noteX,noteY,noteWidth,noteHeight);
    
    self.noteTextView.editable = YES;
    self.noteBox.frame = currentNoteFrame;
    self.noteBox.backgroundColor = currentColor;
    [self.view addSubview:self.noteBox];
    self.noteBox.hidden = false;
}

-(void)noteIconPressed:(id)sender {
    [self hideBoxes];
    UIButton* noteIcon = (UIButton*)sender;
    int index = (int)noteIcon.tag - 10000;
    NSLog(@"index %d",index);
    PageInformation* pi = [rv getPageInformation];
    NSMutableArray* highlightsInPage = pi.highlightsInPage;
    Highlight* highlight = [highlightsInPage objectAtIndex:index];
    currentHighlight = highlight;
    currentColor = UIColorFromRGB(currentHighlight.highlightColor);
    self.noteTextView.text = currentHighlight.note;
    currentStartRect = [rv getStartRectFromHighlight:currentHighlight];
    currentEndRect = [rv getEndRectFromHighlight:currentHighlight];
    [self showNoteBox];
}


-(void)removeNoteIcons {
    for (UIView* view in self.view.subviews) {
        if (view.tag >= 10000) {
            [view removeFromSuperview];
        }
    }
}

-(UIImage*)getNoteIconImageByIndex:(int)index {
    UIImage* image;
    if (index==0) {
        image = [UIImage imageNamed:@"yellowMemo.png"];
    }else if (index==1) {
        image = [UIImage imageNamed:@"greenMemo.png"];
    }else if (index==2) {
        image = [UIImage imageNamed:@"blueMemo.png"];
    }else if (index==3) {
        image = [UIImage imageNamed:@"redMemo.png"];
    }else {
        image = [UIImage imageNamed:@"yellowMemo.png"];
    }
    return image;
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

-(UIImage*)getNoteIconImageByHighlightColor:(unsigned int)highlightColor {
    int index = [self getMarkerIndexByColor:highlightColor];
    return [self getNoteIconImageByIndex:index];
}

-(UIButton*)getNoteIcon:(Highlight*)highlight index:(int)index{
    UIButton* noteIcon = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage* iconImage = [self getNoteIconImageByHighlightColor:highlight.highlightColor];
    [noteIcon setImage:iconImage forState:UIControlStateNormal];
    [noteIcon addTarget:self action:@selector(noteIconPressed:) forControlEvents:UIControlEventTouchUpInside];
    [noteIcon setContentMode:UIViewContentModeCenter];
    int mx,my;
    int mw = 32;
    int mh = 32;
    mx = self.view.bounds.size.width - 10 - mw;
    my = highlight.top+35;
    if ([self isPad]) {
        if (![self isPortrait]) { // doublePaged mode, landscape
            if ([rv isDoublePaged]) {
                if (highlight.left <self.view.bounds.size.width/2) {
                    mx = 50;
                    my = highlight.top+3;
                }else {
                    mx = self.view.bounds.size.width - 50 - mw;
                    my = highlight.top+3;
                }
            }
        }else { // portriat mode
            mx = self.view.bounds.size.width - 60 - mw;
            my = highlight.top + 5;
        }
    }
    CGRect mf = CGRectMake(mx,my,mw,mh);
    noteIcon.tag = 10000 + index;
    noteIcon.frame = mf;
    
    return noteIcon;
}

-(void)processNoteIcons {
    [self removeNoteIcons];
    PageInformation*pi = [rv getPageInformation];
    BOOL hasNoteIcon = NO;
    NSMutableArray* highlightsInPage = pi.highlightsInPage;
    for (int i=0; i<[highlightsInPage count]; i++) {
        Highlight* highlight = [highlightsInPage objectAtIndex:i];
        if (highlight.isNote && highlight.note.length!=0) {
            UIButton* noteIcon = [self getNoteIcon:highlight index:i];
            [self.view addSubview:noteIcon];
            [self.view bringSubviewToFront:noteIcon];
            hasNoteIcon = YES;
        }
    }
    if ([highlightsInPage count]!=0 && hasNoteIcon) {
        [rv refresh];
    }
}

-(void)showHighlightBox:(CGRect)startRect endRect:(CGRect)endRect {
    [self calcMenuFramesWithStartRect:startRect endRect:endRect];
    [self showHighlightBox];
}

-(void)hideHighlightBox {
    [self.highlightBox removeFromSuperview];
    self.highlightBox.hidden = true;
    arrow.hidden = true;
    [self hideBaseView];
}

-(void)showColorBox {
    [self showBaseView];
    [self.view addSubview:self.colorBox];
    self.colorBox.frame = CGRectMake(currentMenuFrame.origin.x,currentMenuFrame.origin.y,self.colorBox.frame.size.width,self.colorBox.frame.size.height);
    self.colorBox.backgroundColor = currentColor;
    self.colorBox.hidden = false;
    [self showArrow:1];
}

-(void)changeHighlightColor:(UIColor*)newColor {
    currentColor = newColor;
    self.highlightBox.backgroundColor = currentColor;
    self.colorBox.backgroundColor = currentColor;
    [rv changeHighlight:currentHighlight color:currentColor];
    [self hideColorBox];
}

-(void)hideColorBox {
    [self.colorBox removeFromSuperview];
    self.colorBox.hidden = true;
    arrow.hidden = true;
    [self hideBaseView];
}

// SKYEPUB SDK CALLBACK
// called when User selects text.
-(void)reflowableViewController:(ReflowableViewController*)rvc didSelectRange:(Highlight*)highlight startRect:(CGRect)startRect endRect:(CGRect)endRect{
    currentHighlight = highlight;
    currentStartRect = startRect;
    currentEndRect = endRect;
    [self showMenuBox:startRect endRect:endRect];
}

-(void)reflowableViewController:(ReflowableViewController*)rvc didSelectionCanceled:(NSString*)lastSelectedText {
    [self hideMenuBox];
}

-(void)reflowableViewController:(ReflowableViewController*)rvc didSelectionChanged:(NSString*)selectedText {
    [self hideMenuBox];
    [self hideHighlightBox];
}

-(void)colorPressed:(id)sender {
    [self hideHighlightBox];
    [self showColorBox];
}

-(void)trashPressed:(id)sender {
    [rv deleteHightlight:currentHighlight];
    [self hideHighlightBox];
}

-(void)yellowPressed:(id)sender {
    UIColor* color = [self getMarkerColor:0];
    [self changeHighlightColor:color];
}

-(void)greenPressed:(id)sender {
    UIColor* color = [self getMarkerColor:1];
    [self changeHighlightColor:color];
}

-(void)bluePressed:(id)sender {
    UIColor* color = [self getMarkerColor:2];
    [self changeHighlightColor:color];
}

-(void)redPressed:(id)sender {
    UIColor* color = [self getMarkerColor:3];
    [self changeHighlightColor:color];
}

// the note button inside highlightBox is pressed
-(void)noteInHighlightBoxPressed:(id)sender {
    [self hideHighlightBox];
    self.noteTextView.text = currentHighlight.note;
    [self showNoteBox];
}

-(void)savePressed:(id)sender {
    [self hideHighlightBox];
}

// SKYEPUB SDK CALLBACK - DataSource
// all highlights which belong to the chapter should be returned to SDK.
// for more information about SkyEpub highlight system, please refer to https://www.dropbox.com/s/knnbxqdn077aace/Highlight%20Offsets.pdf?dl=1
-(NSMutableArray*)reflowableViewController:(ReflowableViewController*)rvc highlightsForChapter:(NSInteger)chapterIndex {
    highlights = [sd fetchHighlights:self.bookInformation.bookCode chapterIndex:chapterIndex];
    return highlights;
}

-(NSString*)script {
    NSString *script;
    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"/script" ofType:@"js"];
    script = [NSString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:NULL];
    return script;
}

-(NSString*)style {
    NSString* style = @"";
    //    NSString *stylePath = [[NSBundle mainBundle] pathForResource:@"/custom" ofType:@"css"];
    //    style = [NSString stringWithContentsOfFile:stylePath encoding:NSUTF8StringEncoding error:NULL];
    return style;
}

-(NSString*)reflowableViewController:(ReflowableViewController*)rvc scriptForChapter:(NSInteger)chapterIndex {
    NSString* script;
    if (isScrollMode) {
        script = @"document.documentElement.style.webkitUserSelect='none';document.documentElement.style.webkitTouchCallout='none';";
    }else {
        script = [self script];
    }
    return script;
}


-(NSString*)reflowableViewController:(ReflowableViewController*)rvc styleForChapter:(NSInteger)chapterIndex {
    return [self style];
}

// SKYEPUB SDK CALLBACK
// called when user touches on a highlight.
-(void)reflowableViewController:(ReflowableViewController*)rvc didHitHighlight:(Highlight*)highlight atPosition:(CGPoint)position startRect:(CGRect)startRect endRect:(CGRect)endRect{
    currentHighlight = highlight;
    currentColor = UIColorFromRGB(highlight.highlightColor);
    [self showHighlightBox:startRect endRect:endRect];
}

-(void)reflowableViewController:(ReflowableViewController*)rvc didHitLink:(NSString*)urlString {
    NSLog(@"didHitLink detected : %@",urlString);
}


// SKYEPUB SDK CALLBACK
// called when user touches on any area of boo k.
-(void)reflowableViewController:(ReflowableViewController*)rvc didDetectTapAtPosition:(CGPoint)position{
    NSLog(@"tap detected");
    if (isControlsShown && (self.menuBox.hidden && self.colorBox.hidden && self.highlightBox.hidden)) {
        [self hideControls];
        [self hideMediaBox];
    } else {
        [self showControls];
        if (([rvc isMediaOverlayAvailable] && setting.mediaOverlay) || [rv isTTSEnabled]) {
            [self showMediaBox];
        }
    }
    [self hideHighlightBox];
    [self hideColorBox];
}


-(void)reflowableViewController:(ReflowableViewController*)rvc didDetectDoubleTapAtPosition:(CGPoint)position{
}

// SKYEPUB SDK CALLBACK
// called when a new highlight is about to be inserted.
-(void)reflowableViewController:(ReflowableViewController*)rvc
                insertHighlight:(Highlight*)highlight {
    [sd insertHighlight:highlight];
    currentHighlight = highlight;
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setString:highlight.text];
    [self processNoteIcons];
}

// SKYEPUB SDK CALLBACK
// called when a new highlight is about to be deleted.
-(void)reflowableViewController:(ReflowableViewController*)rvc deleteHighlight:(Highlight*)highlight {
    [sd deleteHighlight:highlight];
    [self processNoteIcons];
}

// SKYEPUB SDK CALLBACK
// called when a new highlight is about to be updated.
-(void)reflowableViewController:(ReflowableViewController*)rvc updateHighlight:(Highlight*)highlight {
    [sd updateHighlight:highlight];
    [self processNoteIcons];
}



// if [rv setCustomDrawHighlight:YES] then you can draw the highlight.
// since 4.0
// SKYEPUB SDK CALLBACK
// called whenever new custom drawing for highlight is required.
-(void)reflowableViewController:(ReflowableViewController*)rvc drawHighlightRect:(CGRect)highlightRect context:(CGContextRef)context highlightColor:(UIColor*)highlightColor highlight:(Highlight*)highlight {
    @autoreleasepool {
        // If you want to draw brush mark, use below.
        if (!highlight.isTemporary) {
            if ([self highlightDrawnOnFront]) {
                CGContextClearRect(context,highlightRect);
                CGContextSetBlendMode(context, kCGBlendModeOverlay);
                CGContextSetFillColorWithColor( context, [[UIColor blueColor] colorWithAlphaComponent:0.2].CGColor);
                CGContextFillRect( context, highlightRect );
            }else {
                UIImage* markerImage = [self getMarkerImageFromColor:highlightColor];
                CGContextDrawImage(context, highlightRect, markerImage.CGImage);
            }
        }else {
            if (!rv.isVerticalWriting) {
                UIImage* markerImage = [self getMarkerImageFromColor:[UIColor blueColor]];
                float thickness = 6.0f;
                CGRect bottomRect = CGRectMake(highlightRect.origin.x,highlightRect.origin.y+highlightRect.size.height-thickness+2, highlightRect.size.width, thickness);
                
                CGContextDrawImage(context, bottomRect, markerImage.CGImage);
            }else {
                UIImage* markerImage = [self getMarkerImageFromColor:highlightColor];
                float thickness = 6.0f;
                CGRect bottomRect = CGRectMake(highlightRect.origin.x,highlightRect.origin.y, thickness,highlightRect.size.height);
                CGContextDrawImage(context, bottomRect, markerImage.CGImage);
            }
        }
    }
}

// Global Pagination.
-(void)changeSliderUI:(int)mode {
    if (mode == 0) {
        [self.slider setThumbImage:[self thumbImage] forState:UIControlStateNormal];
        [self.slider setThumbImage:[self thumbImage] forState:UIControlStateHighlighted];
        self.slider.minimumTrackTintColor = [UIColor blackColor];
        self.slider.maximumTrackTintColor = [UIColor lightGrayColor];
    }

    if  (mode == 1) {
        [self.slider setThumbImage:[self thumbImage] forState:UIControlStateNormal];
        [self.slider setThumbImage:[self thumbImage] forState:UIControlStateHighlighted];
        self.slider.minimumTrackTintColor = [UIColor blackColor];
        self.slider.maximumTrackTintColor = [UIColor lightGrayColor];

        [self.slider setThumbImage:[UIImage imageNamed:@"clearthumb"] forState:UIControlStateNormal];
        [self.slider setThumbImage:[UIImage imageNamed:@"clearthumb"] forState:UIControlStateHighlighted];
        self.slider.minimumTrackTintColor = [UIColor lightGrayColor];
        self.slider.maximumTrackTintColor = [UIColor clearColor];
    }
}

-(void)disableControlBeforePagination {
    self.listButton.hidden = true;
    self.searchButton.hidden = true;
    self.fontButton.hidden = true;
    
    self.pageIndexLabel.hidden = true;
    self.leftIndexLabel.hidden = true;
    self.rightIndexLabel.hidden = true;
    
    [self changeSliderUI:1];
    
    self.slider.minimumValue = 0;
    self.slider.maximumValue = 1;
}

-(void)enableControlAfterPagination {
    self.listButton.hidden = true;
    self.searchButton.hidden = true;
    self.fontButton.hidden = true;
    
    [self changeSliderUI:0];
    
    if ([rv isGlobalPagination]) {
        self.slider.maximumValue = [rv getNumberOfPagesInBook]-1;
        self.slider.minimumValue = 0;
        
        int globalPageIndex = [rv getPageIndexInBook];
        self.slider.value = (float)globalPageIndex;
    }
    PageInformation* pg = [[PageInformation alloc]init];
    pg.pageIndexInBook = [rv getPageIndexInBook];
    pg.numberOfPagesInBook = [rv getNumberOfPagesInBook];
    [self changePageLabels:pg];
    [self recalcPageLabels];
}


// SKYEPUB SDK CALLBACK
// called when Global Pagination starts.
-(void)reflowableViewController:(ReflowableViewController*)rvc didStartPaging:(int)code {
    [self disableControlBeforePagination];
}

// SKYEPUB SDK CALLBACK
// called whenever each chapter is paginated.
// PagingInformation contains about all factors that can affect the numberOfPages of each chapter like numberOfPages, chapterIndex, the width or height of book, font and line spacing.
-(void)reflowableViewController:(ReflowableViewController*)rvc didPaging:(PagingInformation *)pagingInformation {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self processPaging:pagingInformation];
    });
}

// SKYEPUB SDK CALLBACK
// called when Global Pagination ends.
-(void)reflowableViewController:(ReflowableViewController*)rvc didFinishPaging:(int)code {
    [self enableControlAfterPagination];
}

-(void)processPaging:(PagingInformation*)pagingInformation {
    if ([rv isPaging]) {
        int ci = pagingInformation.chapterIndex;
        int cn = [rv getNumberOfChaptersInBook];
        double value = (double)(ci) / (double)(cn);
        [self.slider setValue:value animated:true];
    }
    [sd insertPagingInformation:pagingInformation];
}

// SKYEPUB SDK CALLBACK
-(NSInteger)reflowableViewController:(ReflowableViewController*)rvc numberOfPagesForPagingInformation:(PagingInformation *)pagingInformation{
    PagingInformation* pgi = [sd fetchPagingInformation:pagingInformation];
    int nc = 0;
    if (pgi==NULL) nc=0;
    else nc=pgi.numberOfPagesInChapter;
    return nc;
}

// 8.0 New
// SKYEPUB SDK CALLBACK
// if there's stored paging information which matches given paging information, return it to sdk to avoid repaging of the same chapter with the same conditions.
-(PagingInformation*)reflowableViewController:(ReflowableViewController*)rvc pagingInformationForPagingInformation:(PagingInformation*)pagingInformation {
    PagingInformation* pgi = [sd fetchPagingInformation:pagingInformation];
    return pgi;
}

// 8.0 New
// SKYEPUB SDK CALLBACK
// returns the text of chapter which is stored in permanant storage to SDK.
-(NSString*)reflowableViewController:(ReflowableViewController*)rvc textForBookCode:(int)bookCode chapterIndex:(int)chapterIndex {
    @autoreleasepool {
//        NSLog(@"textForBookCode");
        ItemRef *itemRef =  [sd fetchItemRef:bookCode chapterIndex:chapterIndex];
        if (itemRef==nil) {
            return nil;
        }
        NSString* ret = [[NSString alloc]initWithString:itemRef.text];
        itemRef = nil;
        return ret;
    }
}

// 8.0 New
// SKYEPUB SDK CALLBACK
// returns all paging information about one book to SDK
-(NSMutableArray*)reflowableViewController:(ReflowableViewController*)rvc anyPagingInformationsForBookCode:(int)bookCode numberOfChapters:(int)numberOfChapters {
    return [sd fetchPagingInformationsForScan:bookCode  numberOfChapters:numberOfChapters];
}

// 8.0 New
// SKYEPUB SDK CALLBACK
// called when text inforamtion is extracted from each chapter. text information of each chapter can be stored external storage with or without encrypting.
// and they will be used for searching, text speech, highlight or etc.
-(void)reflowableViewController:(ReflowableViewController*)rvc textExtracted:(int)bookCode chapterIndex:(int)chapterIndex text:(NSString*)text {
    ItemRef* itemRef = [sd fetchItemRef:bookCode chapterIndex:chapterIndex];
    if (itemRef!=nil) {
        if (text!=nil && text.length!=0) {
            itemRef.text = text;
            [sd updateItemRef:itemRef];
        }
        itemRef = nil;
    }else {
        ItemRef *newRef = [[ItemRef alloc]init];
        newRef.bookCode = bookCode;
        newRef.chapterIndex = chapterIndex;
        newRef.title = @"";
        newRef.idref = @"";
        newRef.href = @"";
        newRef.fullPath = @"";
        newRef.text = text;
        [sd insertItemRef:newRef];
        newRef = nil;
    }
}

/* MediaOverlay callbacks */
// SKYEPUB SDK CALLBACK
// called when playing a parallel starts in MediaOverlay or TTS
// make the text of speech highlight while playing.
-(void)reflowableViewController:(ReflowableViewController *)rvc parallelDidStart:(Parallel *)parallel {
    if ([rvc pageIndexInChapter]!=parallel.pageIndex) {
        [rvc gotoPageInChapter:parallel.pageIndex];
    }

    if (setting.highlightTextToVoice) {
        if (![rvc isTTSEnabled]) {
            [rvc changeElementColor:@"#F00000" hash:parallel.hash];
        }else {
            [rvc markParallelHighlight:parallel color:[self getMarkerColor:1]];
        }
    }
    currentParallel = parallel;
}

// SKYEPUB SDK CALLBACK
// called when playing a parallel ends in MediaOverlay or TTS
-(void)reflowableViewController:(ReflowableViewController *)rvc parallelDidEnd:(Parallel *)parallel {
    if (![rvc isTTSEnabled]) {
        if (setting.highlightTextToVoice) {
            [rvc restoreElementColor];
        }
        if (isLoop) {
            [rvc playPrevParallel];
        }
    }else {
        if (setting.highlightTextToVoice) {
            [rvc removeParallelHighlights];
        }
    }
}

// SKYEPUB SDK CALLBACK
// called after playing all parallels are finished in MediaOverlay or TTS.
-(void)parallesDidEnd:(ReflowableViewController *)rvc {
    [rvc restoreElementColor];
    [rvc stopPlayingParallel];
    [self changePlayAndPauseButton];
    isAutoPlaying = YES;
    if (autoMoveChapterWhenParallesFinished) {
        autoStartPlayingWhenNewChapterLoaded = YES;
        [rvc gotoNextChapter];
    }
}

// SKYEPUB SDK CALLBACK
// if you need to modify text to speech (like numbers, punctuation or etc), you can send over the modifed text of original rawString.
-(NSString*)reflowableViewController:(ReflowableViewController*)rvc postProcessText:(NSString*)rawString {
    return rawString;
}

/* MediaOverlay Utilities */
-(void)changePlayAndPauseButton {
    if (![rv isPlayingStarted]) {
        [self.playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    }else if ([rv isPlayingPaused]) {
        [self.playButton setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    }else {
        [self.playButton setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    }
}

-(void)playAndPause {
    if (![rv isPlayingStarted]) {
        [rv playFirstParallelInPage];
        isAutoPlaying = YES;
    }else if ([rv isPlayingPaused]) {
        [rv resumePlayingParallel];
        isAutoPlaying = YES;
    }else {
        [rv pausePlayingParallel];
        isAutoPlaying = NO;
    }
    [self performSelector:@selector(changePlayAndPauseButton) withObject:nil afterDelay:0.2f];
}

-(void)stopPlaying {
    [rv stopPlayingParallel];
    if (![rv isTTSEnabled]) {
        [rv restoreElementColor];
    }else {
        [rv removeParallelHighlights];
    }
    isAutoPlaying = NO;
    [self performSelector:@selector(changePlayAndPauseButton) withObject:nil afterDelay:1.0f];
}


-(void)playPrev {
    [rv playPrevParallel];
    [self performSelector:@selector(changePlayAndPauseButton) withObject:nil afterDelay:1.0f];
}

-(void)playNext {
    [rv playNextParallel];
    [self performSelector:@selector(changePlayAndPauseButton) withObject:nil afterDelay:1.0f];
}

// Text Processing for TTS
-(BOOL)isPeriod:(NSString*)text pos:(int)pos {
    @try {
        NSString * c = [text substringWithRange:NSMakeRange(pos, 1)];
        if ([c isEqualToString:@"."]) {
            if (pos>=3) {
                NSString* sub0 = [text substringWithRange:NSMakeRange(pos-2, 2)];
                NSString* sub1 = [text substringWithRange:NSMakeRange(pos-3, 3)];
                if (([sub0 caseInsensitiveCompare:@"mr"] == NSOrderedSame) ||
                    ([sub0 caseInsensitiveCompare:@"dr"] == NSOrderedSame) ||
                    ([sub0 caseInsensitiveCompare:@"st"] == NSOrderedSame) ||
                    ([sub1 caseInsensitiveCompare:@"mrs"] == NSOrderedSame)) {
                    return false;
                }else {
                    return true;
                }
            }else {
                return true;
            }
        }
        
        if ([c isEqualToString:@";"] || [c isEqualToString:@"!"] || [c isEqualToString:@"?"] /*|| [c isEqualToString:@","]*/ ) {
            return true;
        }
        if ([c isEqualToString:@"\r"] || [c isEqualToString:@"\n"] ) {
            return true;
        }
        if ([c isEqualToString:@"。"] ||[c isEqualToString:@"、"]) {
            return true;
        }
        if ([c isEqualToString:@"，"] || [c isEqualToString:@"。"] || [c isEqualToString:@"，"]) {
            return true;
        }
        
        return false;
    }@catch(NSException* e) {
        NSLog(@"Exception: %@", e);
        @throw e;
    }
}

// Text Processing for TTS
-(long)getRealStartOffset:(NSString*)text {
    @try {
        NSString* ch = nil;
        long tp = 0;
        for (long i=0; i<[text length]; i++) {
            ch = [text substringWithRange:NSMakeRange(i, 1)];
            unichar uc = [text characterAtIndex:i];
            //        NSLog(@"%c %d %@",uc,uc,ch);
            if ([ch isEqualToString:@"\n"] || [ch isEqualToString:@"\r"] || [ch isEqualToString:@"\t"] || [ch isEqualToString:@" "] || [ch isEqualToString:@""] || uc==160 ) continue;
            tp = i;
            break;
        }
        return tp;
    }@catch(NSException* e) {
        NSLog(@"Exception: %@", e);
        @throw e;
    }
}

// Text Processing for TTS
-(long)getRealEndOffset:(NSString*)text {
    @try {
        NSString* ch = nil;
        long tp = [text length]-1;
        for (long i=[text length]-1; i>=0; i--) {
            ch = [text substringWithRange:NSMakeRange(i, 1)];
            unichar uc = [text characterAtIndex:i];
            //        NSLog(@"%c %d %@",uc,uc,ch);
            if ([ch isEqualToString:@"\n"] || [ch isEqualToString:@"\r"] || [ch isEqualToString:@"\t"] || [ch isEqualToString:@" "]  || [ch isEqualToString:@""]  || uc==160) continue;
            tp = i;
            break;
        }
        return tp;
    }@catch(NSException* e) {
        NSLog(@"Exception: %@", e);
        @throw e;
    }
}

// Text Processing for TTS
-(NSMutableArray*)createParallelsForTTS:(int)chapterIndex text:(NSString*)text {
    @try{
        NSMutableArray* parallels = [[NSMutableArray alloc]init];
        if (text==nil || text.length==0) return nil;

        text = [text stringByReplacingOccurrencesOfString:@"\"" withString:@" "];
        text = [text stringByReplacingOccurrencesOfString:@"'"  withString:@" "];
        text = [text stringByReplacingOccurrencesOfString:@"’"  withString:@" "];
        text = [text stringByReplacingOccurrencesOfString:@"‘"  withString:@" "];
        text = [text stringByReplacingOccurrencesOfString:@"“"  withString:@" "];
        text = [text stringByReplacingOccurrencesOfString:@"”"  withString:@" "];
        text = [text stringByReplacingOccurrencesOfString:@"「"  withString:@" "];
        text = [text stringByReplacingOccurrencesOfString:@"」"  withString:@" "];
        
        int pp = 0;
        for (int i=0; i<text.length; i++) {
            if ([self isPeriod:text pos:i] || i==text.length-1) {
                NSRange range = NSMakeRange(pp,(i-pp+1));
                NSString *subText = [text substringWithRange:range];
                subText = [subText stringByReplacingOccurrencesOfString:@"\r" withString:@" "];
                subText = [subText stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
                
                if (subText==nil || subText.length==0) continue;
                NSString *trimmed = [subText stringByTrimmingCharactersInSet:
                                     [NSCharacterSet whitespaceCharacterSet]];
                if (trimmed==nil || [trimmed length]==0) continue;
                
                long rso = [self getRealStartOffset:subText];
                long reo = [self getRealEndOffset:subText];
                NSString* textContent = [subText substringWithRange:NSMakeRange(rso, reo-rso+1)];
                long startOffset = rso+pp;
                long endOffset = (int)(startOffset + textContent.length);

                Parallel* par = [[Parallel alloc]initWithTextContent:textContent bookCode:rv.bookCode chapterIndex:chapterIndex startOffset:startOffset endOffset:endOffset];
                [parallels addObject:par];
                
                pp = i+1;
            }
        }
        return parallels;
        //        NSLog(@"processText is finished");
    }@catch(NSException* e) {
        NSLog(@"Exception: %@", e);
        @throw e;
    }
    //    NSLog(@"processText Ends");
}


// dataSource call back
-(NSMutableArray*)reflowableViewController:(ReflowableViewController*)rvc parallelsForTTS:(int)chapterIndex text:(NSString*)text {
    return [self createParallelsForTTS:chapterIndex text:text];
}


// Search Text Routines
// SKYEPUB SDK CALLBACK
// called when key is found while searching.
-(void)reflowableViewController:(ReflowableViewController *)rvc didSearchKey:(SearchResult *)searchResult {
    [self addSearchResult:searchResult mode:SEARCHRESULT];
}

// SKYEPUB SDK CALLBACK
// called after searching process for one chapter is over.
-(void)reflowableViewController:(ReflowableViewController *)rvc didFinishSearchForChapter:(SearchResult *)searchResult {
    [rvc pauseSearch];
    rv.isSearching = NO;
    int cn = searchResult.numberOfSearched - lastNumberOfSearched;
    if (cn > 150) {
        [self addSearchResult:searchResult mode:SEARCHMORE];
        lastNumberOfSearched = searchResult.numberOfSearched;
    }else {
        [rv searchMore];
    }
}

// SKYEPUB SDK CALLBACK
// called after all searching process is over.
-(void)reflowableViewController:(ReflowableViewController *)rvc didFinishSearchAll:(SearchResult *)searchResult {
    [self addSearchResult:searchResult mode:SEARCHFINISHED];
}

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
    [rv searchKey:key];
}

-(void)searchMore {
    [rv searchMore];
    rv.isSearching = YES;
}

-(void)stopSearch {
    [rv stopSearch];
}

-(void)searchCancelPressed:(id)sender {
    [self hideSearchBox];
    [rv clearHighlightForSearch];
}

-(void)gotoSearchPressed:(UIButton*)sender {
    UIButton* gotoSearchButton = sender;
    if (gotoSearchButton.tag == -1) {
        [self hideSearchBox];
    }else if (gotoSearchButton.tag == -2) {
        searchScrollHeight -= gotoSearchButton.bounds.size.height;
        self.searchScrollView.contentSize = CGSizeMake(gotoSearchButton.bounds.size.width,searchScrollHeight);
        [gotoSearchButton.superview  removeFromSuperview];
        [rv searchMore];
    }else {
        [self hideSearchBox];
        SearchResult* sr = [searchResults objectAtIndex:gotoSearchButton.tag];
        [rv performSelector:@selector(gotoPageBySearchResult:) withObject:sr afterDelay:0.5];
    }
}

-(void)addSearchResult:(SearchResult*)searchResult mode:(int)mode{
    NSString *headerText = @"";
    NSString *contentText = @"";
    
    SearchResultView* resultView = [[[NSBundle mainBundle] loadNibNamed:@"SearchResultView" owner:self options:nil] firstObject];
    UIButton* gotoButton = resultView.searchResultButton;
    
    if (mode==SEARCHRESULT) {
        int ci = searchResult.chapterIndex;
        NSString* chapterTitle = [rv.book getChapterTitle:ci];
        int displayPageIndex = (searchResult.pageIndex+1);
        int displayNumberOfPages = searchResult.numberOfPagesInChapter;
        if (rv.isDoublePaged) {
            displayPageIndex = displayPageIndex*2;
            displayNumberOfPages = displayNumberOfPages*2;
        }
        if (chapterTitle==NULL || chapterTitle.length==0 ) {
            if (searchResult.numberOfPagesInChapter!=-1) {
                headerText = [NSString stringWithFormat:@"%@ %d %@ %d/%d",NSLocalizedString(@"chapter",@""),ci, NSLocalizedString(@"page",@""), displayPageIndex,displayNumberOfPages];
            }else {
                headerText = [NSString stringWithFormat:@"%@ %d ",NSLocalizedString(@"chapter",@""),ci];
            }
        }else {
            if (searchResult.numberOfPagesInChapter!=-1) {
                headerText = [NSString stringWithFormat:@"%@ %@ %d/%d",chapterTitle,NSLocalizedString(@"page",@""),displayPageIndex,displayNumberOfPages];
            }else {
                headerText = [NSString stringWithFormat:@"%@",chapterTitle];
            }
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

// listBox routines
-(void)listBoxSegmentedControlChanged:(UISegmentedControl*)sender {
    [self showTableView:(int)self.listBoxSegmentedControl.selectedSegmentIndex];
}

-(void)listBoxResumePressed:(id)sender {
    [self hideListBox];
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
    
    self.listBoxTitleLabel.text = rv.title;
    
    [self reloadContents];
    [self reloadHighlights];
    [self reloadBookmarks];
    
    [self showTableView:(int)self.listBoxSegmentedControl.selectedSegmentIndex];
    
    [self.view addSubview:self.listBox];
    [self applyThemeToListBox:currentTheme];
    self.listBox.hidden = false;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int ret = 0;
    if (tableView.tag==200) {
        ret  = (int)[rv.navMap count];
    }else if (tableView.tag==201) {
        ret  = (int)[highlights count];
    }else if (tableView.tag==202) {
        ret  = (int)[bookmarks count];
    }
    return ret;
}

// called when user presses one item of tables
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger index = [indexPath row];
    if (tableView.tag==200) {
        NavPoint* np = [rv.navMap objectAtIndex:index];
        [rv gotoPageByNavPoint:np];
        [self hideListBox];
    }else if (tableView.tag==201) {
        Highlight* highlight = [highlights objectAtIndex:index];
        [rv gotoPageByHighlight:highlight];
        [self hideListBox];
    }else if (tableView.tag==202) {
        PageInformation* pg = [bookmarks objectAtIndex:index];
        [rv gotoPageByPagePositionInBook:pg.pagePositionInBook animated:false];
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


// for more information about navMap and navPoint in epub, please refer to https://www.dropbox.com/s/yko3mq35if9ix68/NavMap.pdf?dl=1
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int index = (int)[indexPath row];
    if (tableView.tag==200) {
        // constructs the table of contents.
        // navMap and navPoint contains the information of TOC (table of contents)
        NavPoint* cnp = [rv getCurrentNavPoint];
        ContentsTableViewCell* cell = [self.contentsTableView dequeueReusableCellWithIdentifier:@"contentsTableViewCell" forIndexPath:indexPath];
        if (cell!=nil) {
            NavPoint* np = [rv.navMap objectAtIndex:index];
            NSString* leadingSpaceForDepth = @"";
            for (int i=0; i<np.depth; i++) {
                leadingSpaceForDepth = [NSString stringWithFormat:@"   %@",leadingSpaceForDepth];
            }
            cell.chapterTitleLabel.text = [NSString stringWithFormat:@"%@%@",leadingSpaceForDepth,np.text];
            cell.positionLabel.text = @"";
            cell.chapterTitleLabel.textColor = currentTheme.textColor;
            cell.positionLabel.textColor = currentTheme.textColor;
            
            if (np.chapterIndex == currentPageInformation.chapterIndex) {
                cell.chapterTitleLabel.textColor = [UIColor systemIndigoColor];
            }
            if (cnp != nil && np == cnp) {
                cell.chapterTitleLabel.textColor = [UIColor systemBlueColor];
            }
            return cell;
        }
    }else if (tableView.tag==201) {
        // constructs the table of highlights
        NotesTableViewCell* cell = [self.notesTableView dequeueReusableCellWithIdentifier:@"notesTableViewCell" forIndexPath:indexPath];
        if (cell!=nil) {
            Highlight* highlight = [highlights objectAtIndex:index];
            cell.positionLabel.text = [rv.book getChapterTitle:highlight.chapterIndex];
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
            cell.positionLabel.text = [rv.book getChapterTitle:(int)pg.chapterIndex];
            cell.datetimeLabel.text = pg.datetime;
            cell.datetimeLabel.textColor = currentTheme.textColor;
            cell.positionLabel.textColor = currentTheme.textColor;
            return cell;
        }
    }
    return [[UITableViewCell alloc]init];
}

@end

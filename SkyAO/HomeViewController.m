//
//  HomeViewController.m
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/14.
//

#import "HomeViewController.h"
#import "AppDelegate.h"
#import "SkyData.h"
#import "Setting.h"
#import "BookInformation.h"
#import "BookCollectionViewCell.h"
#import "SettingViewController.h"
#import "BookViewController.h"
#import "MagazineViewController.h"

@interface HomeViewController () <UICollectionViewDataSource,UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,UISearchBarDelegate>{
    AppDelegate* ad;
    SkyData* sd;
    Setting* setting;
    
    NSMutableArray* bis;
    int sortType;
    NSString* searchKey;
    BOOL isGridMode;
    
    BookInformation* currentBookInformation;

}
@property (nonatomic) AppDelegate *ad;
@property (nonatomic) SkyData* sd;
@property (nonatomic) Setting* setting;
@property (nonatomic) NSString* searchKey;
@property int sortType;
@property (nonatomic) NSMutableArray* bis;

@property (weak, nonatomic) IBOutlet UICollectionView *bookCollectionView;
@property (weak, nonatomic) IBOutlet UIView *topBar;
@property (weak, nonatomic) IBOutlet UIButton *importButton;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;
@property (weak, nonatomic) IBOutlet UIButton *sortButton;
@property (weak, nonatomic) IBOutlet UIButton *settingButton;
@property (weak, nonatomic) IBOutlet UIButton *gridButton;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@end

@implementation HomeViewController
@synthesize ad,sd,setting,bis,sortType,searchKey;

-(void)loadBis {
    self.bis = [sd fetchBookInformations:sortType key:searchKey];
}

-(void)reload {
    [self loadBis];
    [self.bookCollectionView reloadData];
}


-(UIColor *)UIColorFromRGB:(NSUInteger)RGBHex {
    CGFloat red = ((CGFloat)((RGBHex & 0xFF0000) >> 16)) / 255.0f;
    CGFloat green = ((CGFloat)((RGBHex & 0xFF00) >> 8)) / 255.0f;
    CGFloat blue = ((CGFloat)((RGBHex & 0xFF))) / 255.0f;
    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0f];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    sortType = 0;
    searchKey= @"";
    isGridMode = false;
    
    ad =  (AppDelegate*)[[UIApplication sharedApplication] delegate];
    sd = ad.data;
    
    self.searchBar.delegate = self;
    self.bookCollectionView.dataSource = self;
    self.bookCollectionView.delegate = self;
    
    [self addSkyErrorNotification];

    [self installSampleBooks]; // if books are already installed, it will do nothing.
    
    UILongPressGestureRecognizer * longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(longPressed:)];
    longPressGestureRecognizer.minimumPressDuration = .5; //seconds
    longPressGestureRecognizer.delegate = self;
    [self.bookCollectionView addGestureRecognizer:longPressGestureRecognizer];
    
    self.topBar.backgroundColor     = [self UIColorFromRGB: 0xff0000];
    self.view.backgroundColor       = [self UIColorFromRGB: 0xff0000];


    [self reload];
    
    // Do any additional setup after loading the view.
}

-(void)addSkyErrorNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processError:) name:@"SkyError" object:nil];
}

-(void)removeSkyErrorNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"SkyError" object:nil];
}

-(void)processError:(NSNotification*)notification {
    NSNumber* code  = [[notification userInfo] objectForKey:@"code"];
    NSNumber* level  = [[notification userInfo] objectForKey:@"level"];
    NSString* message  = [[notification userInfo] objectForKey:@"message"];
    NSLog(@"SkyError code %d level %d Detected :%@",[code intValue],[level intValue],message);
}

// install sample epubs from bundle.
-(void)installSampleBooks {
    [sd installEpubByFileName:@"Alice.epub"];
    [sd installEpubByFileName:@"Doctor.epub"];
}
- (IBAction)importPressed:(id)sender {
    UIDocumentPickerViewController* picker =
      [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"org.idpf.epub-container"]
                                                             inMode:UIDocumentPickerModeImport];
    picker.delegate = self;
    picker.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (controller.documentPickerMode == UIDocumentPickerModeImport) {
        [sd installEpubByURL:[urls objectAtIndex:0]];
        [self reload];
    }
}

- (IBAction)settingPressed:(id)sender {
    SettingViewController *settingViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SettingViewController"];
    [settingViewController setModalPresentationStyle: UIModalPresentationFullScreen];
    [self presentViewController:settingViewController animated:NO completion:nil];
}

-(void)showSortTypeActionSheet {
    UIAlertController* sortActionSheet = [UIAlertController
                                          alertControllerWithTitle:@""
                                          message:NSLocalizedString(@"sort_by",@"")
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* sortByTitleAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"title",@"")
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
        self.sortType = 0;
        [self reload];
        NSLog(@"Sort By Last Title");
    }];
    
    UIAlertAction* sortByAuthorAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"author",@"")
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
        self.sortType = 1;
        [self reload];
        NSLog(@"Sort By Author");
    }];
    
    UIAlertAction* sortByLastReadAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"last_read",@"")
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
        self.sortType = 2;
        [self reload];
        NSLog(@"Sort By Last Read");
    }];
    
    UIAlertActionStyle noSortActionStyle = UIAlertActionStyleCancel;
    
    if ([self isPad]) {
        noSortActionStyle = UIAlertActionStyleDefault;
    }
    
    UIAlertAction* noSortAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"no_sort",@"")
                                                   style:noSortActionStyle
                                                 handler:^(UIAlertAction *action) {
        self.sortType = 3;
        [self reload];
        NSLog(@"No Sort");
    }];
    
    [sortActionSheet addAction:sortByTitleAction];
    [sortActionSheet addAction:sortByAuthorAction];
    [sortActionSheet addAction:sortByLastReadAction];
    [sortActionSheet addAction:noSortAction];
    
    if ([self isPad]) {
        sortActionSheet.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
        CGRect rect = self.view.bounds;
        rect.origin.x = 0;
        rect.origin.y = 0;
        sortActionSheet.popoverPresentationController.sourceView = self.view;
        sortActionSheet.popoverPresentationController.sourceRect = rect;
        
    }
    
    [self presentViewController:sortActionSheet animated:YES completion:nil];
}


- (IBAction)sortPressed:(id)sender {
    [self showSortTypeActionSheet];
}

- (IBAction)searchPressed:(id)sender {
    self.searchBar.hidden = false;
    [self.searchBar becomeFirstResponder];
}

- (IBAction)gridPressed:(id)sender {
    isGridMode = !isGridMode;
    NSString* iconName = @"";
    if (isGridMode)   {
        iconName = @"grid-shelf";
    }else {
        iconName = @"list-shelf";
    }
    [self.gridButton setImage:[UIImage imageNamed:iconName] forState:UIControlStateNormal];
    [self reload];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    self.searchKey = searchBar.text;
    [self reload];
}

-(void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton:YES animated:YES];
}

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar setText:@""];
    [searchBar setShowsCancelButton:NO animated:YES];
    [searchBar resignFirstResponder];
    searchBar.hidden = YES;
    self.searchKey = @"";
    [self reload];
}

-(void)longPressed:(UILongPressGestureRecognizer *)gestureRecognizer {
    CGPoint p = [gestureRecognizer locationInView:self.bookCollectionView];
    NSIndexPath *indexPath = [self.bookCollectionView indexPathForItemAtPoint:p];
    BookCollectionViewCell *cell = (BookCollectionViewCell *)[self.bookCollectionView cellForItemAtIndexPath:indexPath];
    long index = cell.tag;
    BookInformation* bi = [self.bis objectAtIndex:index];
    currentBookInformation = bi;
    [self showLongPressedActionSheet:bi];
}

-(void)showLongPressedActionSheet:(BookInformation*)bi {
    UIAlertController* longPressedActionSheet = [UIAlertController
                                          alertControllerWithTitle:bi.title
                                          message:@""
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction* openAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"open",@"")
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
        [self openBook:bi];
    }];
    UIAlertAction* openFirstPageAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"open_the_first_page",@"")
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
        bi.position = -1.0;
        [self openBook:bi];
    }];
    UIAlertAction* deleteBookAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"delete_book",@"")
                                                   style:UIAlertActionStyleDefault
                                                 handler:^(UIAlertAction *action) {
        [self.sd deleteBookByBookCode:bi.bookCode];
        [self reload];
    }];
    UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"cancel",@"")
                                                   style:UIAlertActionStyleCancel
                                                 handler:^(UIAlertAction *action) {

    }];
    [longPressedActionSheet addAction:openAction];
    [longPressedActionSheet addAction:openFirstPageAction];
    [longPressedActionSheet addAction:deleteBookAction];
    
    if (![self isPad]) {
        [longPressedActionSheet addAction:cancelAction];
    }else {
        longPressedActionSheet.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
        CGRect rect = self.view.bounds;
        rect.origin.x = 0;
        rect.origin.y = 0;
        longPressedActionSheet.popoverPresentationController.sourceView = self.view;
        longPressedActionSheet.popoverPresentationController.sourceRect = rect;
    }
    [self presentViewController:longPressedActionSheet animated:YES completion:nil];
}

-(void)openBook:(BookInformation*)bi {
    if (!bi.isFixedLayout) {
        BookViewController* bvc = [self.storyboard instantiateViewControllerWithIdentifier:@"BookViewController"];
        bvc.bookInformation = bi;
        [bvc setModalPresentationStyle: UIModalPresentationFullScreen];
        [self presentViewController:bvc animated:NO completion:nil];
    }else {
        MagazineViewController* mvc = [self.storyboard instantiateViewControllerWithIdentifier:@"MagazineViewController"];
        mvc.bookInformation = bi;
        [mvc setModalPresentationStyle: UIModalPresentationFullScreen];
        [self presentViewController:mvc animated:NO completion:nil];
    }
}

-(BOOL)isPad  {
    if (UIDevice.currentDevice.userInterfaceIdiom==UIUserInterfaceIdiomPad)  {
        return true;
    }else {
        return false;
    }
}

-(BOOL)isPortrait {
    return UIDeviceOrientationIsPortrait(self.interfaceOrientation);
}


-(int)numberOfItemsInRow  {
    if ([self isPad]) {
        if ([self isPortrait]) {    // for Pad
            if (isGridMode) {
                return 3;
            }else {
                return 2;
            }
        }else {
            if (isGridMode) {
                return 5;
            }else {
                return 3;
            }
        }
    }else {
        if ([self isPortrait]) {    // for Phone
            if (isGridMode) {
                return 2;
            }else {
                return 1;
            }
        }else {
            if (isGridMode) {
                return 4;
            }else {
                return 2;
            }
        }
    }
}
    


-(CGFloat)cellWidth {
    int ni = [self numberOfItemsInRow];
    int vw = self.view.bounds.size.width;
    CGFloat iw = (CGFloat)(vw*0.96)/(CGFloat)(ni);
    return iw;
}

-(CGFloat)cellHeight {
    return 200;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGSize size = CGSizeMake([self cellWidth],[self cellHeight]);
    return size;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [bis count];
}


-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [collectionView cellForItemAtIndexPath:indexPath];
    int index = (int)cell.tag;
    BookInformation* bi = [self.bis objectAtIndex:index];
    [self openBook:bi];
}

-(void)addShadow:(UIView*)view rect:(CGRect)rect size:(CGSize)size {
    UIBezierPath* shadowPath =[UIBezierPath bezierPathWithRect:rect];
    view.layer.masksToBounds = false;
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOffset = size;
    view.layer.shadowOpacity = 0.1;
    view.layer.shadowPath = shadowPath.CGPath;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    BookCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"bookCollectionViewCell" forIndexPath:indexPath];
    long index = indexPath.row;
    BookInformation* bi = [self.bis objectAtIndex:index];
    if (cell.isInit && cell.bookCode == bi.bookCode) {
        return cell;
    }
    NSString* coverPath = [sd getCoverPath:bi.fileName];
    NSFileManager *fm =[NSFileManager defaultManager];
    if (![fm fileExistsAtPath:coverPath]) {
        cell.titleLabelOnCover.text = bi.title;
    }else {
        cell.titleLabelOnCover.text = @"";
        cell.bookCoverImageView.image = [UIImage imageWithContentsOfFile:coverPath];
    }
    
    [self addShadow:cell.bookCoverImageView rect:CGRectMake(0,0,125,175) size:CGSizeMake(5,20)];
    cell.titleLabel.text = bi.title;
    cell.authorLabel.text = bi.creator;
    cell.publisherLabel.text = bi.publisher;
    cell.bookCode = bi.bookCode;
    cell.tag = index;
    if (isGridMode) {
        cell.titleLabel.hidden = true;
        cell.authorLabel.hidden = true;
        cell.publisherLabel.hidden = true;
    }else {
        cell.titleLabel.hidden = false;
        cell.authorLabel.hidden = false;
        cell.publisherLabel.hidden = false;
    }
    return cell;
}


@end

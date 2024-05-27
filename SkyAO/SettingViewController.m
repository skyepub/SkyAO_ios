//
//  SettingViewController.m
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/11.
//

#import "SettingViewController.h"
#import "AppDelegate.h"
#import "Setting.h"

@interface SettingViewController () {
    AppDelegate* ad;
    SkyData* sd;
    Setting* setting;
}
@property (nonatomic) AppDelegate *ad;
@property (nonatomic) SkyData* sd;
@property (nonatomic) Setting* setting;

@property (weak, nonatomic) IBOutlet UIButton *homeButton;
@property (strong, nonatomic) IBOutlet UIView *coreView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UISwitch *doublePagedSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *lockRotationSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *globalPaginationSwitch;
@property (weak, nonatomic) IBOutlet UIButton *theme0Button;
@property (weak, nonatomic) IBOutlet UIButton *theme1Button;
@property (weak, nonatomic) IBOutlet UIButton *theme2Button;
@property (weak, nonatomic) IBOutlet UIButton *theme3Button;
@property (weak, nonatomic) IBOutlet UISwitch *mediaOverlaySwitch;
@property (weak, nonatomic) IBOutlet UISwitch *ttsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *autoPlaySwitch;
@property (weak, nonatomic) IBOutlet UISwitch *highlightTextSwitch;
@property (weak, nonatomic) IBOutlet UIImageView *noneEffectCheckmark;
@property (weak, nonatomic) IBOutlet UIImageView *slideEffectCheckmark;
@property (weak, nonatomic) IBOutlet UIImageView *curlEffectCheckmark;
@property (weak, nonatomic) IBOutlet UISwitch *autoLoadSwitch;

@end

@implementation SettingViewController
@synthesize ad,sd,setting;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    ad =  (AppDelegate*)[[UIApplication sharedApplication] delegate];
    sd = ad.data;
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    [self loadSetting];
    [self makeUI];
}

-(void)loadSetting {
    self.setting = [sd fetchSetting];
    self.doublePagedSwitch.on = setting.doublePaged;
    self.lockRotationSwitch.on = setting.lockRotation;
    self.globalPaginationSwitch.on = setting.globalPagination;
    
    [self focusSelectedTheme];
    [self focusSelectedEffect];

    self.mediaOverlaySwitch.on = setting.mediaOverlay;
    self.ttsSwitch.on = setting.tts;
    
    self.autoPlaySwitch.on = setting.autoStartPlaying;
    self.autoLoadSwitch.on = setting.autoLoadNewChapter;
    self.highlightTextSwitch.on = setting.highlightTextToVoice;
}

-(void)saveSetting {
    setting.doublePaged = self.doublePagedSwitch.on;
    setting.lockRotation = self.lockRotationSwitch.on;
    setting.globalPagination = self.globalPaginationSwitch.on;
    
    setting.mediaOverlay = self.mediaOverlaySwitch.on;
    setting.tts = self.ttsSwitch.on;
    
    setting.autoStartPlaying = self.autoPlaySwitch.on;
    setting.autoLoadNewChapter = self.autoLoadSwitch.on;
    setting.highlightTextToVoice = self.highlightTextSwitch.on;
    
    [sd updateSetting: setting];
}

-(void)makeUI {
    [self.scrollView addSubview:self.coreView];
    [self recalcFrames];
}

-(void)recalcFrames {
    CGFloat topOffset = 80;
    CGRect rect = self.coreView.bounds;
    rect.size.width = self.view.bounds.size.width;
    self.coreView.bounds = rect;
    self.scrollView.frame = CGRectMake(0,self.view.safeAreaInsets.top+topOffset,self.view.bounds.size.width,self.view.bounds.size.height);
    self.scrollView.contentSize = CGSizeMake(self.coreView.frame.size.width,  self.coreView.frame.size.height+topOffset);
    self.coreView.frame = CGRectMake(0, 0, self.coreView.frame.size.width, self.coreView.frame.size.height);
}

-(void)didRotate:(id)sender {
    [self recalcFrames];
}

- (IBAction)homePressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)dismissViewControllerAnimated:(BOOL)flag
                           completion:(void (^)(void))completion {
    [super dismissViewControllerAnimated:flag completion:completion];
    [self saveSetting];
}

-(void)focusSelectedTheme {
    self.theme0Button.layer.borderColor = [UIColor grayColor].CGColor;
    self.theme1Button.layer.borderColor = [UIColor grayColor].CGColor;
    self.theme2Button.layer.borderColor = [UIColor grayColor].CGColor;
    self.theme3Button.layer.borderColor = [UIColor grayColor].CGColor;
    
    self.theme0Button.layer.borderWidth = 1;
    self.theme1Button.layer.borderWidth = 1;
    self.theme2Button.layer.borderWidth = 1;
    self.theme3Button.layer.borderWidth = 1;
    
    switch (setting.theme) {
        case 0: self.theme0Button.layer.borderWidth = 3;
            break;
        case 1: self.theme1Button.layer.borderWidth = 3;
            break;
        case 2: self.theme2Button.layer.borderWidth = 3;
            break;
        case 3: self.theme3Button.layer.borderWidth = 3;
            break;
        default:
            self.theme0Button.layer.borderWidth = 3;
    }
}

- (IBAction)theme0Pressed:(id)sender {
    setting.theme = 0;
    [self focusSelectedTheme];
}

- (IBAction)theme1Pressed:(id)sender {
    setting.theme = 1;
    [self focusSelectedTheme];
}

- (IBAction)theme2Pressed:(id)sender {
    setting.theme = 2;
    [self focusSelectedTheme];
}
- (IBAction)theme3Pressed:(id)sender {
    setting.theme = 3;
    [self focusSelectedTheme];
}

-(void)focusSelectedEffect {
    self.noneEffectCheckmark.hidden = true;
    self.slideEffectCheckmark.hidden = true;
    self.curlEffectCheckmark.hidden = true;
    
    switch (setting.transitionType) {
    case 0:
            self.noneEffectCheckmark.hidden = false;
            break;
    case 1:
            self.slideEffectCheckmark.hidden = false;
            break;
    case 2:
            self.curlEffectCheckmark.hidden = false;
            break;
    default:
            self.noneEffectCheckmark.hidden = false;
            break;
    }
}

-(IBAction)noneEffectPressed:(id)sender {
    setting.transitionType = 0;
    [self focusSelectedEffect];
}

-(IBAction)slideEffectPressed:(id)sender {
    setting.transitionType = 1;
    [self focusSelectedEffect];
}

-(IBAction)curlEffectPressed:(id)sender {
    setting.transitionType = 2;
    [self focusSelectedEffect];
}

- (IBAction)companyPressed:(id)sender {
    UIApplication *application = [UIApplication sharedApplication];
    [application openURL:[NSURL URLWithString:@"http://www.skyepub.net"] options:@{} completionHandler:nil];
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

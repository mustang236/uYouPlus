#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import "Header.h"
#import "Tweaks/YouTubeHeader/YTVideoQualitySwitchOriginalController.h"
#import "Tweaks/YouTubeHeader/YTPlayerViewController.h"
#import "Tweaks/YouTubeHeader/YTWatchController.h"
#import "Tweaks/YouTubeHeader/YTIGuideResponse.h"
#import "Tweaks/YouTubeHeader/YTIGuideResponseSupportedRenderers.h"
#import "Tweaks/YouTubeHeader/YTIPivotBarSupportedRenderers.h"
#import "Tweaks/YouTubeHeader/YTIPivotBarRenderer.h"
#import "Tweaks/YouTubeHeader/YTIBrowseRequest.h"
#import "Tweaks/YouTubeHeader/YTCommonColorPalette.h"
#import "Tweaks/YouTubeHeader/ASCollectionView.h"

#define YT_BUNDLE_ID @"com.google.ios.youtube"
#define YT_NAME @"YouTube"

BOOL hideHUD() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"hideHUD_enabled"];
}
BOOL oled() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"oled_enabled"];
}
BOOL oledKB() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"oledKeyBoard_enabled"];
}
BOOL isDarkMode() {
    return ([[NSUserDefaults standardUserDefaults] integerForKey:@"page_style"] == 1);
}
BOOL autoFullScreen() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"autoFull_enabled"];
}
BOOL hideHoverCard() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"hideHoverCards_enabled"];
}
BOOL reExplore() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"reExplore_enabled"];
}
BOOL bigYTMiniPlayer() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"bigYTMiniPlayer_enabled"];
}
BOOL hideCC() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"hideCC_enabled"];
}
BOOL hideAutoplaySwitch() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"hideAutoplaySwitch_enabled"];
}
BOOL hidePreviousAndNextButton() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"hidePreviousAndNextButton_enabled"];
}
BOOL castConfirm() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"castConfirm_enabled"];
}
BOOL ytMiniPlayer() {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"ytMiniPlayer_enabled"];
}

// Tweaks
// YTMiniPlayerEnabler: https://github.com/level3tjg/YTMiniplayerEnabler/
%hook YTWatchMiniBarViewController
- (void)updateMiniBarPlayerStateFromRenderer {
    if (ytMiniPlayer()) {}
    else { return %orig; }
}
%end

// Hide CC / Autoplay switch
%hook YTMainAppControlsOverlayView
- (void)setClosedCaptionsOrSubtitlesButtonAvailable:(BOOL)arg1 { // hide CC?!
    if (hideCC()) { return %orig(NO); }   
    else { return %orig; }
}
- (void)setAutoplaySwitchButtonRenderer:(id)arg1 {
    if (hideAutoplaySwitch()) {}
    else { return %orig; }
}
- (void)layoutSubviews {
    if (hidePreviousAndNextButton()) {
	    MSHookIvar<YTMainAppControlsOverlayView *>(self, "_nextButton").hidden = YES;
    	MSHookIvar<YTMainAppControlsOverlayView *>(self, "_previousButton").hidden = YES;        
        %orig;
    }
        return %orig;
}
%end

// Hide HUD Messages
%hook YTHUDMessageView
- (id)initWithMessage:(id)arg1 dismissHandler:(id)arg2 {
    return hideHUD() ? nil : %orig;
}
%end

// YTAutoFullScreen: https://github.com/PoomSmart/YTAutoFullScreen/
%hook YTPlayerViewController
- (void)loadWithPlayerTransition:(id)arg1 playbackConfig:(id)arg2 {
    %orig;
    if (autoFullScreen())
        [NSTimer scheduledTimerWithTimeInterval:0.75 target:self selector:@selector(autoFullscreen) userInfo:nil repeats:NO];
}
%new
- (void)autoFullscreen {
    YTWatchController *watchController = [self valueForKey:@"_UIDelegate"];
    [watchController showFullScreen];
}
%end

// YTNoHoverCards: https://github.com/level3tjg/YTNoHoverCards
%hook YTCreatorEndscreenView
- (void)setHidden:(BOOL)hidden {
    if (hideHoverCard())
        hidden = YES;
    %orig;
}
%end
 
//YTCastConfirm: https://github.com/JamieBerghmans/YTCastConfirm
%hook MDXPlaybackRouteButtonController
- (void)didPressButton:(id)arg1 {
    if (castConfirm()) {
        UIAlertController* alertController = [%c(UIAlertController) alertControllerWithTitle:@"Casting"
                                message:@"Are you sure you want to start casting?"
                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [%c(UIAlertAction) actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            %orig;
        }];

        UIAlertAction* noButton = [%c(UIAlertAction)
                                actionWithTitle:@"Cancel"
                                style:UIAlertActionStyleDefault
                                handler: ^(UIAlertAction * action) {
            return;
        }];

        [alertController addAction:defaultAction];
        [alertController addAction:noButton];
        
        id rootViewController = [%c(UIApplication) sharedApplication].delegate.window.rootViewController;
        if ([rootViewController isKindOfClass:[%c(UINavigationController) class]]) {
            rootViewController = ((UINavigationController *)rootViewController).viewControllers.firstObject;
        }
        if ([rootViewController isKindOfClass:[%c(UITabBarController) class]]) {
            rootViewController = ((UITabBarController *)rootViewController).selectedViewController;
        }
        if ([rootViewController presentedViewController] != nil) {
            rootViewController = [rootViewController presentedViewController];
        }
        [rootViewController presentViewController:alertController animated:YES completion:nil];
	} else { return %orig; }
        
}
%end

// Workaround for https://github.com/MiRO92/uYou-for-YouTube/issues/12
%hook YTAdsInnerTubeContextDecorator
- (void)decorateContext:(id)arg1 { %orig(nil); }
%end

// YTClassicVideoQuality: https://github.com/PoomSmart/YTClassicVideoQuality
%hook YTVideoQualitySwitchControllerFactory
- (id)videoQualitySwitchControllerWithParentResponder:(id)responder {
    Class originalClass = %c(YTVideoQualitySwitchOriginalController);
    return originalClass ? [[originalClass alloc] initWithParentResponder:responder] : %orig;
}
%end

// YTNoCheckLocalNetwork: https://poomsmart.github.io/repo/depictions/ytnochecklocalnetwork.html
%hook YTHotConfig
- (BOOL)isPromptForLocalNetworkPermissionsEnabled { return NO; }
%end

// YTSystemAppearance: https://poomsmart.github.io/repo/depictions/ytsystemappearance.html
// YouRememberCaption: https://poomsmart.github.io/repo/depictions/youremembercaption.html
%hook YTColdConfig
- (BOOL)shouldUseAppThemeSetting { return YES; }
- (BOOL)respectDeviceCaptionSetting { return NO; }
- (BOOL)isEnhancedSearchBarEnabled { return YES; }
%end

// NOYTPremium - https://github.com/PoomSmart/NoYTPremium/
%hook YTCommerceEventGroupHandler
- (void)addEventHandlers {}
%end

%hook YTInterstitialPromoEventGroupHandler
- (void)addEventHandlers {}
%end

%hook YTPromosheetEventGroupHandler
- (void)addEventHandlers {}
%end

%hook YTPromoThrottleController
- (BOOL)canShowThrottledPromo { return NO; }
- (BOOL)canShowThrottledPromoWithFrequencyCap:(id)arg1 { return NO; }
- (BOOL)canShowThrottledPromoWithFrequencyCaps:(id)arg1 { return NO; }
%end

%hook YTIShowFullscreenInterstitialCommand
- (BOOL)shouldThrottleInterstitial { return YES; }
%end

%hook YTSurveyController
- (void)showSurveyWithRenderer:(id)arg1 surveyParentResponder:(id)arg2 {}
%end

// Enable Shorts scroll bar - level3tjg - https://reddit.com/r/jailbreak/comments/v29yvk/_/iasl1l0/
%hook YTReelPlayerViewControllerSub
- (BOOL)shouldEnablePlayerBar { return YES; }
%end

// Hide the download playlist button of uYou cuz it's broken ?!
// Why aren't you working?? :/
// %hook YTPlaylistHeaderViewController
// - (void)viewDidLoad {
//     %orig;
//     self.downloadsButton.hidden = YES;
// }
// %end

// IAmYouTube - https://github.com/PoomSmart/IAmYouTube/
%hook YTVersionUtils
+ (NSString *)appName { return YT_NAME; }
+ (NSString *)appID { return YT_BUNDLE_ID; }
%end

%hook GCKBUtils
+ (NSString *)appIdentifier { return YT_BUNDLE_ID; }
%end

%hook GPCDeviceInfo
+ (NSString *)bundleId { return YT_BUNDLE_ID; }
%end

%hook OGLBundle
+ (NSString *)shortAppName { return YT_NAME; }
%end

%hook GVROverlayView
+ (NSString *)appName { return YT_NAME; }
%end

%hook OGLPhenotypeFlagServiceImpl
- (NSString *)bundleId { return YT_BUNDLE_ID; }
%end

%hook SSOConfiguration
- (id)initWithClientID:(id)clientID supportedAccountServices:(id)supportedAccountServices {
    self = %orig;
    [self setValue:YT_NAME forKey:@"_shortAppName"];
    [self setValue:YT_BUNDLE_ID forKey:@"_applicationIdentifier"];
    return self;
}
%end

%hook NSBundle
- (NSString *)bundleIdentifier {
    NSArray *address = [NSThread callStackReturnAddresses];
    Dl_info info = {0};
    if (dladdr((void *)[address[2] longLongValue], &info) == 0)
        return %orig;
    NSString *path = [NSString stringWithUTF8String:info.dli_fname];
    if ([path hasPrefix:NSBundle.mainBundle.bundlePath])
        return YT_BUNDLE_ID;
    return %orig;
}
- (id)objectForInfoDictionaryKey:(NSString *)key {
    if ([key isEqualToString:@"CFBundleIdentifier"])
        return YT_BUNDLE_ID;
    if ([key isEqualToString:@"CFBundleDisplayName"] || [key isEqualToString:@"CFBundleName"])
        return YT_NAME;
    return %orig;
}
%end

// Workaround for issue #54
// %hook YTMainAppVideoPlayerOverlayViewController
// - (void)updateRelatedVideos {
//     if ([[NSUserDefaults standardUserDefaults] boolForKey:@"relatedVideosAtTheEndOfYTVideos"] == NO) {}
//     else { return %orig; }
// }
// %end

// OLED dark mode by BandarHL
UIColor* oledColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];

%group gOLED
%hook YTCommonColorPalette
- (UIColor *)brandBackgroundSolid {
    if (self.pageStyle == 1) {
        return oledColor;
    }
        return %orig;
}
- (UIColor *)brandBackgroundPrimary {
    if (self.pageStyle == 1) {
        return oledColor;
    }
        return %orig;
}
- (UIColor *)brandBackgroundSecondary {
    if (self.pageStyle == 1) {
        return oledColor;
    }
        return %orig;
}
- (UIColor *)staticBrandBlack {
    if (self.pageStyle == 1) {
        return oledColor;
    }
        return %orig;
}
- (UIColor *)generalBackgroundA {
    if (self.pageStyle == 1) {
        return oledColor;
    }
        return %orig;
}
%end

// Account view controller
%hook YTAccountPanelBodyViewController
- (UIColor *)backgroundColor:(NSInteger)pageStyle {
    if (pageStyle == 1) { 
        return oledColor; 
    }
        return %orig;
}
%end

%hook YTInnerTubeCollectionViewController
- (UIColor *)backgroundColor:(NSInteger)pageStyle {
    if (pageStyle == 1) { 
        return oledColor; 
    }
        return %orig;
}
%end

// Explore
%hook ASScrollView 
- (void)didMoveToWindow {
    if (isDarkMode()) {
        %orig;
        self.backgroundColor = oledColor;
    }
}
%end

%hook ASCollectionView
- (void)didMoveToWindow {
    if (isDarkMode()) { 
        %orig;
        self.superview.backgroundColor = [UIColor clearColor];
    }
}
%end

// uYou's page
%hook DownloadedVC
- (UIColor *)ytBackgroundColor {
    if (isDarkMode()) {
        return oledColor;
    }
        return %orig;
}
%end

%hook DownloadsPagerVC
- (UIColor *)ytBackgroundColor {
    if (isDarkMode()) {
        return oledColor;
    }
        return %orig;
}
%end

%hook DownloadingVC
- (UIColor *)ytBackgroundColor {
    if (isDarkMode()) {
        return oledColor;
    }
        return %orig;
}
%end

%hook PlayerVC
- (UIColor *)ytBackgroundColor {
    if (isDarkMode()) {
        return oledColor;
    }
        return %orig;
}
%end

// SponsorBlock settings
%hook SponsorBlockSettingsController
- (void)viewDidLoad {
    if (self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        %orig;
        self.tableView.backgroundColor = oledColor;
    } else { return %orig; }
}
%end

// YT player
%hook YTWatchMiniBarView 
- (void)setBackgroundColor:(UIColor *)color { 
    if (isDarkMode()) {
        return %orig([UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.9]);
    }
        return %orig;
}
%end

// Search View
%hook YTSearchBarView 
- (void)setBackgroundColor:(UIColor *)color { 
    if (isDarkMode()) {
        return %orig (oledColor);
    }
        return %orig;
}
%end

%hook YTSearchBoxView 
- (void)setBackgroundColor:(UIColor *)color { 
    if (isDarkMode()) {
        return %orig (oledColor);
    }
        return %orig;
}
%end

// Comment view
%hook YTCreateCommentAccessoryView // community reply comment
- (void)setBackgroundColor:(UIColor *)color { 
    if (isDarkMode()) {
        return %orig (oledColor);
    }
        return %orig;
}
%end

%hook YTCreateCommentTextView
- (void)setBackgroundColor:(UIColor *)color { 
    if (isDarkMode()) {
        return %orig (oledColor);
    }
        return %orig;
}
- (void)setTextColor:(UIColor *)color { // fix black text in #Shorts video's comment
    if (isDarkMode()) { 
        return %orig ([UIColor whiteColor]); 
    }
        return %orig;
}
%end

%hook _ASDisplayView
- (void)didMoveToWindow {
    %orig;
    if (isDarkMode()) {
        if ([self.accessibilityIdentifier isEqualToString:@"id.elements.components.comment_composer"] || [self.accessibilityIdentifier isEqualToString:@"id.elements.components.video_list_entry"] || [self.accessibilityIdentifier isEqualToString:@"id.elements.components.filter_chip_bar"]) {
            self.backgroundColor = oledColor;
        }
        if ([self.accessibilityIdentifier isEqualToString:@"id.comment.guidelines_text"]) {
            self.superview.backgroundColor = oledColor;
        }
    }
}
%end

%hook YTFormattedStringLabel  // YT is werid...
- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkMode()) {
        return %orig ([UIColor clearColor]);
    }
        return %orig;
}
%end

%hook YCHLiveChatActionPanelView  // live chat comment
- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkMode()) {
        return %orig (oledColor);
    }
        return %orig;
}
%end

%hook YTEmojiTextView // live chat comment
- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkMode()) {
        return %orig (oledColor);
    }
        return %orig;
}
%end

// Separation lines
%hook YTCollectionSeparatorView
- (void)didMoveToWindow {
    if (isDarkMode()) {}
    else { return %orig; }
}
%end

// Open link with...
%hook ASWAppSwitchingSheetHeaderView
- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkMode()) {
        return %orig (oledColor);
    }
}
%end

%hook ASWAppSwitchingSheetFooterView
- (void)setBackgroundColor:(UIColor *)color {
    if (isDarkMode()) {
        return %orig (oledColor);
    }
}
%end

%hook ASWAppSwitcherCollectionViewCell
- (void)didMoveToWindow {
    if (isDarkMode()) { 
        %orig;        
        self.subviews[1].backgroundColor = oledColor;
    }
}
%end
%end

%group gOLEDKB // OLED keyboard by @ichitaso <3 - http://gist.github.com/ichitaso/935100fd53a26f18a9060f7195a1be0e
%hook UIPredictionViewController
- (void)loadView {
    %orig;
    [self.view setBackgroundColor:oledColor];
}
%end

%hook UICandidateViewController
- (void)loadView {
    %orig;
    [self.view setBackgroundColor:oledColor];
}
%end

%hook UIKeyboardDockView
- (void)didMoveToWindow {
    %orig;
    self.backgroundColor = oledColor;
}
%end

%hook UIKeyboardLayoutStar 
- (void)didMoveToWindow {
    %orig;
    self.backgroundColor = oledColor;
}
%end

%hook UIKBRenderConfig // Prediction text color
- (void)setLightKeyboard:(BOOL)arg1 { %orig(NO); }
%end
%end

// YTReExplore: https://github.com/PoomSmart/YTReExplore/
%group gReExplore
static void replaceTab(YTIGuideResponse *response) {
    NSMutableArray <YTIGuideResponseSupportedRenderers *> *renderers = [response itemsArray];
    for (YTIGuideResponseSupportedRenderers *guideRenderers in renderers) {
        YTIPivotBarRenderer *pivotBarRenderer = [guideRenderers pivotBarRenderer];
        NSMutableArray <YTIPivotBarSupportedRenderers *> *items = [pivotBarRenderer itemsArray];
        NSUInteger shortIndex = [items indexOfObjectPassingTest:^BOOL(YTIPivotBarSupportedRenderers *renderers, NSUInteger idx, BOOL *stop) {
            return [[[renderers pivotBarItemRenderer] pivotIdentifier] isEqualToString:@"FEshorts"];
        }];
        if (shortIndex != NSNotFound) {
            [items removeObjectAtIndex:shortIndex];
            NSUInteger exploreIndex = [items indexOfObjectPassingTest:^BOOL(YTIPivotBarSupportedRenderers *renderers, NSUInteger idx, BOOL *stop) {
                return [[[renderers pivotBarItemRenderer] pivotIdentifier] isEqualToString:[%c(YTIBrowseRequest) browseIDForExploreTab]];
            }];
            if (exploreIndex == NSNotFound) {
                YTIPivotBarSupportedRenderers *exploreTab = [%c(YTIPivotBarRenderer) pivotSupportedRenderersWithBrowseId:[%c(YTIBrowseRequest) browseIDForExploreTab] title:@"Explore" iconType:292];
                [items insertObject:exploreTab atIndex:1];
            }
        }
    }
}
%hook YTGuideServiceCoordinator
- (void)handleResponse:(YTIGuideResponse *)response withCompletion:(id)completion {
    replaceTab(response);
    %orig(response, completion);
}
- (void)handleResponse:(YTIGuideResponse *)response error:(id)error completion:(id)completion {
    replaceTab(response);
    %orig(response, error, completion);
}
%end
%end

// BigYTMiniPlayer: https://github.com/Galactic-Dev/BigYTMiniPlayer
%group Main
%hook YTWatchMiniBarView
- (void)setWatchMiniPlayerLayout:(int)arg1 {
    %orig(1);
}
- (int)watchMiniPlayerLayout {
    return 1;
}
- (void)layoutSubviews {
    %orig;
    self.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width - self.frame.size.width), self.frame.origin.y, self.frame.size.width, self.frame.size.height);
}
%end

%hook YTMainAppVideoPlayerOverlayView
- (BOOL)isUserInteractionEnabled {
    if([[self _viewControllerForAncestor].parentViewController.parentViewController isKindOfClass:%c(YTWatchMiniBarViewController)]) {
        return NO;
    }
        return %orig;
}
%end
%end

NSBundle *uYouPlusBundle() {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
 	dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:@"uYouPlus" ofType:@"bundle"];
        bundle = [NSBundle bundleWithPath:tweakBundlePath];
    });
    return bundle;
}

%ctor {
    %init;
    if (oled()) {
       %init(gOLED);
    }
    if (oledKB()) {
       %init(gOLEDKB);
    }
    if (reExplore()) {
       %init(gReExplore);
    }
    if (bigYTMiniPlayer() && (UIDevice.currentDevice.userInterfaceIdiom != UIUserInterfaceIdiomPad)) {
       %init(Main);
    }
}

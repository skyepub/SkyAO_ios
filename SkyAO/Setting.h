//
//  Setting.h
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/07.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PageInformation;
@interface Setting : NSObject {
    int bookCode;
    NSString *fontName;
    int fontSize;
    int lineSpacing;
    int foreground;
    int background;
    int theme;
    double brightness;
    int transitionType;
    BOOL lockRotation;
    BOOL doublePaged;
    BOOL allow3G;
    BOOL globalPagination;
    
    BOOL mediaOverlay;
    BOOL tts;
    BOOL autoStartPlaying;
    BOOL autoLoadNewChapter;
    BOOL highlightTextToVoice;
}
@property (nonatomic,retain) NSString* fontName;
@property int foreground;
@property int background;
@property int transitionType;
@property int bookCode,fontSize,lineSpacing,theme;
@property BOOL lockRotation,doublePaged,allow3G,globalPagination;
@property BOOL mediaOverlay,tts,autoStartPlaying,autoLoadNewChapter,highlightTextToVoice;
@property double brightness;

@end

NS_ASSUME_NONNULL_END

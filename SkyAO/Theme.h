//
//  Theme.h
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/26.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Theme: NSObject  {
    UIColor* textColor;
    UIColor* labelColor;
    UIColor* backgroundColor;
    UIColor* boxColor;
    UIColor* borderColor;
    UIColor* iconColor;
    UIColor* selectedColor;
    NSString* themeName;
    UIColor* sliderMinTrackColor;
    UIColor* sliderMaxTrackColor;
    UIColor* sliderThumbColor;
}
@property (nonatomic) UIColor* textColor;
@property (nonatomic) UIColor* labelColor;
@property (nonatomic) UIColor* backgroundColor;
@property (nonatomic) UIColor* boxColor;
@property (nonatomic) UIColor* borderColor;
@property (nonatomic) UIColor* iconColor;
@property (nonatomic) UIColor* selectedColor;
@property (nonatomic) NSString* themeName;
@property (nonatomic) UIColor* sliderMinTrackColor;
@property (nonatomic) UIColor* sliderMaxTrackColor;
@property (nonatomic) UIColor* sliderThumbColor;
-(void)setDefaultValues;
-(id)initWithName:(NSString*)themeName textColor:(UIColor*)textColor backgroundColor:(UIColor*)backgroundColor boxColor:(UIColor*)boxColor  borderColor:(UIColor*)borderColor iconColor:(UIColor*)iconColor labelColor:(UIColor*)labelColor selectedColor:(UIColor*)selectedColor  sliderThumbColor:(UIColor*)sliderThumbColor sliderMinTrackColor:(UIColor*)sliderMinTrackColor  sliderMaxTrackColor:(UIColor*)sliderMaxTrackColor;
@end


NS_ASSUME_NONNULL_END

//
//  Theme.m
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/26.
//

#import "Theme.h"

@implementation Theme
@synthesize themeName,textColor,labelColor,backgroundColor,boxColor,borderColor,iconColor,selectedColor,sliderMinTrackColor,sliderMaxTrackColor,sliderThumbColor;

-(id)init {
    self = [super init];
    if (self != nil) {
        [self setDefaultValues];
    }
    return self;
}

-(id)initWithName:(NSString*)themeName textColor:(UIColor*)textColor backgroundColor:(UIColor*)backgroundColor boxColor:(UIColor*)boxColor  borderColor:(UIColor*)borderColor iconColor:(UIColor*)iconColor labelColor:(UIColor*)labelColor selectedColor:(UIColor*)selectedColor  sliderThumbColor:(UIColor*)sliderThumbColor sliderMinTrackColor:(UIColor*)sliderMinTrackColor  sliderMaxTrackColor:(UIColor*)sliderMaxTrackColor {
    self = [super init];
    if(self != nil){
        self.textColor = textColor;
        self.backgroundColor = backgroundColor;
        self.boxColor = boxColor;
        self.borderColor = borderColor;
        self.iconColor = iconColor;
        self.labelColor = labelColor;
        self.sliderThumbColor = sliderThumbColor;
        self.sliderMinTrackColor = sliderMinTrackColor;
        self.sliderMaxTrackColor = sliderMaxTrackColor;
        self.selectedColor = selectedColor;
    }
    return self;
}

-(void)setDefaultValues {
    textColor =  [UIColor blackColor];
    labelColor = [UIColor darkGrayColor];
    backgroundColor= [UIColor whiteColor];
    boxColor = [UIColor whiteColor];
    borderColor = [UIColor lightGrayColor];
    iconColor = [UIColor lightGrayColor];
    selectedColor = [UIColor blueColor];
    themeName = @"";
    sliderMinTrackColor = [UIColor lightGrayColor];
    sliderMaxTrackColor = [UIColor lightGrayColor];
    sliderThumbColor = [UIColor lightGrayColor];
}
@end


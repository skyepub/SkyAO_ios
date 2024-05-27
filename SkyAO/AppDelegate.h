//
//  AppDelegate.h
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/07.
//

#import <UIKit/UIKit.h>
#import "SkyData.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    SkyData *data;
}
@property (nonatomic) SkyData* data;
@end


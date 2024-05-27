//
//  MagazineViewController.h
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/26.
//

#import <UIKit/UIKit.h>
#import "SkyData.h"
#import "BookInformation.h"
#import "Book.h"
#import "SearchResultView.h"
#import "Theme.h"
#import "AppDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MagazineViewController : UIViewController <FixedViewControllerDelegate,FixedViewControllerDataSource,SkyProviderDataSource> {
    BookInformation* bookInformation;
}
@property (nonatomic) BookInformation* bookInformation;
@end

NS_ASSUME_NONNULL_END

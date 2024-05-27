//
//  BookViewController.h
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/15.
//

#import <UIKit/UIKit.h>
#import "SkyData.h"
#import "BookInformation.h"
#import "Book.h"
#import "SearchResultView.h"
#import "Theme.h"

NS_ASSUME_NONNULL_BEGIN

@interface BookViewController : UIViewController <ReflowableViewControllerDataSource,ReflowableViewControllerDelegate,UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,UITextViewDelegate,SkyProviderDataSource> {
    BookInformation* bookInformation;
}
@property (nonatomic) BookInformation* bookInformation;
@end

NS_ASSUME_NONNULL_END

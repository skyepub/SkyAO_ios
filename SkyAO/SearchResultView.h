//
//  SearchResultView.h
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/24.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SearchResultView : UIView {
}
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@property (weak, nonatomic) IBOutlet UIView *bottomLine;
@property (weak, nonatomic) IBOutlet UIButton *searchResultButton;
@end

NS_ASSUME_NONNULL_END

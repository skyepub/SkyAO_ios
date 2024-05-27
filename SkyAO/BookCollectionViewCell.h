//
//  BookCollectionViewCell.h
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/15.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BookCollectionViewCell : UICollectionViewCell {
    int bookCode;
    BOOL isInit;
}
@property BOOL isInit;
@property int bookCode;
@property (weak, nonatomic) IBOutlet UIView *masterView;
@property (weak, nonatomic) IBOutlet UIImageView *bookCoverImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UILabel *publisherLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabelOnCover;

@end

NS_ASSUME_NONNULL_END

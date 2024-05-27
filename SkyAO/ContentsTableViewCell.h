//
//  ContentsTableViewCell.h
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ContentsTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *chapterTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *positionLabel;

@end

NS_ASSUME_NONNULL_END

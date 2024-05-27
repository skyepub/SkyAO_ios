//
//  NotesTableViewCell.h
//  SkyAO
//
//  Created by 하늘나무 on 2020/12/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NotesTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *highlightTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *noteTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *positionLabel;
@property (weak, nonatomic) IBOutlet UILabel *datetimeLabel;

@end

NS_ASSUME_NONNULL_END

//
//  SectionHeaderViewCell.h
//  RuiSi
//
//  Created by 汪泽伟 on 2016/11/19.
//  Copyright © 2016年 aloes. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SectionHeaderViewCell : UICollectionViewCell
@property (nonatomic,weak) IBOutlet UILabel *headerTitleLabel;

- (void) setUpFontAndBackground;
@end

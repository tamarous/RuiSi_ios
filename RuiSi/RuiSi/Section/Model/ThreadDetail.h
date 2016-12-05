//
//  ThreadDetail.h
//  RuiSi
//
//  Created by 汪泽伟 on 2016/12/1.
//  Copyright © 2016年 aloes. All rights reserved.
//

#import "BaseModel.h"
#import "Member.h"
@interface ThreadDetail : BaseModel
@property (nonatomic,strong) NSString *threadID;
@property (nonatomic,strong) NSString *creatorName;
@property (nonatomic,copy) NSString *createTime;
@property (nonatomic,copy) NSString *homepage;
@property (nonatomic,strong) NSArray *quotoArray;
@property (nonatomic,copy) NSAttributedString *attributeString;
@property (nonatomic,strong) NSArray* contentsArray;
@property (nonatomic,strong) NSArray *imageURLs;
@property (nonatomic,strong) Member *threadCreator;
@end


@interface ThreadDetailList : BaseModel
@property (nonatomic,strong) NSArray *list;
- (instancetype) initWithArray:(NSArray *)array;
- (NSInteger) countOfList;
+ (ThreadDetailList *)getThreadDetailListFromResponseObject:(id) responseObject;
@end
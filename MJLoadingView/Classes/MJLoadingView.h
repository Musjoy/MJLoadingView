//
//  MJLoadingView.h
//  Common
//
//  Created by 黄磊 on 16/4/6.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifndef ALLOW_MAX_LOADING_TYPE
#define ALLOW_MAX_LOADING_TYPE 2                    // 最大loading类型
#endif

#ifndef LOADING_IMAGE_NAME_PREFIX
#define LOADING_IMAGE_NAME_PREFIX @"img_loading_type"
#endif

typedef void (^LoadingCompletionBlock)();


@interface MJLoadingView : UIView


// 以下是公用部分
@property (weak, nonatomic) IBOutlet UIView *viewContent;                           /**< loading内容界面，除两个按钮外的所有内容都包含在这里 */
@property (nonatomic, strong, readonly) UIImageView *viewActivity;                  /**< 当前动画view(公用)，将在初始化时被设置，不可修改 */
@property (weak, nonatomic) IBOutlet UILabel *lblLoadingText;                       /**< loading文案label */
@property (weak, nonatomic) IBOutlet UIButton *btnBack;
@property (weak, nonatomic) IBOutlet UIButton *btnCancle;                           /**< 取消按钮 */
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *lytActivityLeft;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *lytActivityBottom;

// 以下是不同loadingType对应有区别的部分
// loadingType = 0
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
// loadingType != 0
@property (weak, nonatomic) IBOutlet UIImageView *imgviewLoading;                   /**< loanding动画界面，与activityView只能用其一 */

@property (nonatomic, assign, readonly) int loadingType;                            /**< loading类型<0-默认loading 1-动画loading> */

@property (nonatomic, strong) LoadingCompletionBlock completionBlock;       /**< loading隐藏时候的回调 */

@property (nonatomic, strong) NSString *loadingText;                        /**< 当前loading文案 */

@property (nonatomic, assign) BOOL isInShow;                                /**< loading是否正在展示 */


/** 左上角返回按钮点击 */
- (IBAction)backButtonClick:(id)sender;
/** 取消按钮点击 */
- (IBAction)cancelButtonClick:(id)sender;

- (id)initWithFrame:(CGRect)frame andType:(int)loadingType;


- (NSInteger)startLoading:(NSString *)loadingText;

//- (NSInteger)startLoading:(NSString *)loadingText withRequestId:(NSString *)requestId needCancel:(BOOL)needCancel;

- (void)setLoadingRequestId:(NSString *)requestId needCancel:(BOOL)needCancel atIndex:(NSInteger)aIndex;


- (void)stopLoading;
- (void)stopAllLoading;
- (void)stopLoadingAtIndex:(NSInteger)aIndex;

@end

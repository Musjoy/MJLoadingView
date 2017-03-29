//
//  MJLoadingView.m
//  Common
//
//  Created by 黄磊 on 16/4/6.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import "MJLoadingView.h"
#ifdef MODULE_WEB_INTERFACE
#import "WebInterface.h"
#endif
#ifdef MODULE_CONTROLLER_MANAGER
#import "MJControllerManager.h"
#import "MJNavigationController.h"
#endif


#ifndef DEFALUT_ANIMATE_DURATION
#define DEFALUT_ANIMATE_DURATION 0.3
#endif

@interface MJLoadingView ()

@property (nonatomic, strong) NSMutableArray *arrLoadings;          /**< 当前loading列表 */

@property (nonatomic, assign) NSInteger curShowIndex;               /**< 当前展示的loading对应的index */

@property (nonatomic, assign) BOOL isLoadingLabelHide;              /**< loading中的label是否隐藏 */

@property (nonatomic, assign) BOOL isShowing;                       /**< 正在进行显示动画，从无到有，对显示动画进行判断 */

@end

@implementation MJLoadingView

- (id)initWithFrame:(CGRect)frame
{
    self = [self initWithFrame:frame andType:0];
    if (self) {

    }
    return self;
}

- (id)initWithFrame:(CGRect)frame andType:(int)loadingType
{
    self = [super initWithFrame:frame];
    if (self) {
        _loadingType = loadingType;
        [self settingView];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    if (self.tag < 0 || self.tag >= ALLOW_MAX_LOADING_TYPE) {
        _loadingType = 0;
    } else {
        _loadingType = (int)self.tag;
    }
    [self settingView];
}


- (void)settingView
{
    self.backgroundColor = [UIColor clearColor];
    NSString *nibName = [NSString stringWithFormat:@"%@%d", NSStringFromClass(self.class), _loadingType];
    UIView *contentView = [[[NSBundle mainBundle] loadNibNamed:nibName
                                                         owner:self
                                                       options:nil] objectAtIndex:0];
    if (_loadingType == 0) {
        _viewActivity = (UIImageView *)_activityView;
    } else {
        _viewActivity = _imgviewLoading;
        // 处理loading图片
        NSString *imgNamePrefix = [LOADING_IMAGE_NAME_PREFIX stringByAppendingFormat:@"%d_", _loadingType];
        _imgviewLoading.image = [UIImage animatedImageNamed:imgNamePrefix duration:2];
    }
    [contentView setFrame:self.bounds];
    [contentView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
    [self addSubview:contentView];
    self.arrLoadings = [[NSMutableArray alloc] init];
    self.curShowIndex = -1;
    self.alpha = 0;
    self.btnCancle.transform = CGAffineTransformMakeRotation(M_PI / 4);
    self.viewContent.layer.cornerRadius = 5;
    self.viewContent.layer.masksToBounds = YES;
}


#pragma mark - Set & Get

- (void)setLoadingText:(NSString *)loadingText
{
    if (_lblLoadingText == nil) {
        return;
    }
    if (_loadingText && [_loadingText isEqualToString:loadingText]) {
        return;
    }
    _loadingText = loadingText;
    if (_loadingText.length > 0) {
        _lblLoadingText.text = _loadingText;
        [self showLoadingLabel];
    } else {
        _lblLoadingText.text = @"";
        [self hideLoadingLabel];
    }
}

#pragma mark - Public

- (NSInteger)startLoading:(NSString *)loadingText
{
    return [self startLoading:loadingText withRequestId:nil needCancel:NO];
}

- (NSInteger)startLoading:(NSString *)loadingText withRequestId:(NSString *)requestId needCancel:(BOOL)needCancel
{
    NSMutableDictionary *aDic = [[NSMutableDictionary alloc] init];
    if (loadingText == nil) {
        loadingText = @"";
    }
    [aDic setObject:loadingText forKey:@"loadingText"];
    [aDic setObject:[NSNumber numberWithBool:needCancel] forKey:@"needCancel"];
    if (requestId) {
        [aDic setObject:requestId forKey:@"requestId"];
    }
    [_arrLoadings addObject:aDic];
    [self refreshWithLoadingAtIndex:_arrLoadings.count-1];
    return _arrLoadings.count-1;
}

- (void)setLoadingRequestId:(NSString *)requestId needCancel:(BOOL)needCancel atIndex:(NSInteger)aIndex
{
    if (aIndex < 0 || aIndex >= _arrLoadings.count) {
        return;
    }
    
    NSMutableDictionary *aDic = [[NSMutableDictionary alloc] init];
    if (requestId.length > 0) {
        [aDic setObject:requestId forKey:@"requestId"];
    }
    [aDic setObject:[NSNumber numberWithBool:needCancel] forKey:@"needCancel"];
    
    if (_curShowIndex == aIndex) {
        [self refreshWithCancel:needCancel];
    }
}

- (void)stopLoading
{
    LogTrace(@"Stop Loading at index : %d", (int)_curShowIndex);
    [self stopLoadingAtIndex:_curShowIndex];
}

- (void)stopAllLoading
{
    [_arrLoadings removeAllObjects];
    _curShowIndex = -1;
    [self checkLoading];
}

- (void)stopLoadingAtIndex:(NSInteger)aIndex
{
    if (aIndex < 0 || aIndex >= _arrLoadings.count) {
        LogError(@"Hide Loading Error At Index : {%d}", (int)aIndex);
        return;
    }
    
    [_arrLoadings replaceObjectAtIndex:aIndex withObject:[NSNull null]];
    [self checkLoading];
}


#pragma mark - Action

- (IBAction)backButtonClick:(id)sender
{
#ifdef MODULE_CONTROLLER_MANAGER
    UIViewController *topVC = [MJControllerManager topViewController];
    if (!topVC.navigationController.isNavigationBarHidden) {
        if (![topVC.navigationController isKindOfClass:[MJNavigationController class]]) {
            return;
        }
        MJNavigationController *navVC = (MJNavigationController *)topVC.navigationController;
        if ([navVC respondsToSelector:@selector(clickLeftItem)]) {
            if ([navVC clickLeftItem]) {
                [self stopAllLoading];
            }
        }
    }
#endif
}

- (IBAction)cancelButtonClick:(id)sender
{
    NSDictionary *aDic = _arrLoadings.lastObject;
    NSString *requestId = aDic[@"requestId"];
    if (requestId.length > 0) {
#ifdef MODULE_WEB_INTERFACE
        [WebInterface cancelRequestWith:requestId];
#endif
    }
    [self stopLoadingAtIndex:_curShowIndex];
}

/** 检查loading状态 */
- (void)checkLoading
{
    NSObject *lastLoading = _arrLoadings.lastObject;
    while (lastLoading && [lastLoading isKindOfClass:[NSNull class]]) {
        // 最后一个为空，则移除掉
        [_arrLoadings removeLastObject];
        lastLoading = _arrLoadings.lastObject;
    }
    
    if (lastLoading == nil) {
        _curShowIndex = -1;
        [self hideLoading];
    } else {
        NSInteger theLastIndex = [_arrLoadings indexOfObject:lastLoading];
        [self refreshWithLoadingAtIndex:theLastIndex];
    }
}




#pragma mark - View Update

/** 用_arrLoadings中aIndex位置的数据刷新loadding界面 */
- (void)refreshWithLoadingAtIndex:(NSInteger)aIndex
{
    if (_curShowIndex == aIndex) {
        return;
    }
    _curShowIndex = aIndex;
    if (_curShowIndex < 0 || _curShowIndex >= _arrLoadings.count) {
        return;
    }
    NSDictionary *aDic = _arrLoadings[_curShowIndex];
    NSString *loadingText = aDic[@"loadingText"];
//    NSString *requestId = aDic[@"requestId"];
    NSNumber *needCancel = aDic[@"needCancel"];
    [self setLoadingText:loadingText];
    
    [self refreshWithCancel:[needCancel boolValue]];
    
    [self showLoading];
}

- (void)refreshWithCancel:(BOOL)needCancle
{
    if (needCancle) {
        _btnCancle.hidden = NO;
        _btnBack.hidden = YES;
    } else {
        _btnCancle.hidden = YES;
        _btnBack.hidden = NO;
    }
}

#pragma mark - View Animate

/** 显示loading */
- (void)showLoading
{
    if (_isInShow) {
        return;
    }
    _isInShow = YES;

    [_viewActivity startAnimating];
    self.hidden = NO;
    _isShowing = YES;
    [UIView animateWithDuration:DEFALUT_ANIMATE_DURATION animations:^{
        self.alpha = 1.0f;
    } completion:^(BOOL finished) {
        _isShowing = NO;
    }];
    
}

/** 隐藏loading */
- (void)hideLoading
{
    if (!_isInShow) {
        return;
    }
    _isInShow = NO;
    [_viewActivity stopAnimating];
    if (!_isShowing) {
        // 没有在显示动画中
        [UIView animateWithDuration:DEFALUT_ANIMATE_DURATION animations:^{
            self.alpha = 0.02f;
        } completion:^(BOOL finished) {
            /* 此处isInShow作用: 如果在hide动画进行过程中，
            又执行了show动画，这是isInshow=YES，不能隐藏自己，显示loading。*/
            if (!_isInShow) {
                self.hidden = YES;
                if (_completionBlock) {
                    _completionBlock();
                }
            }
        }];
    } else {
        // 正在进行loading显示动画，需要直接隐藏
        [self.layer removeAllAnimations];
        self.alpha = 0;
        self.hidden = YES;
        if (_completionBlock) {
            _completionBlock();
        }
    }
}

- (void)showLoadingLabel
{
//    if (!_isLoadingLabelHide) {
//        return;
//    }
//    _isLoadingLabelHide = NO;
    if (_lblLoadingText == nil) {
        return;
    }
    if (!_isInShow) {
        [_viewContent removeConstraints:@[_lytActivityLeft, _lytActivityBottom]];
        _lytActivityLeft.priority = UILayoutPriorityDefaultHigh;
        _lytActivityBottom.priority = UILayoutPriorityDefaultHigh;
        [_viewContent addConstraints:@[_lytActivityLeft, _lytActivityBottom]];
        _lblLoadingText.alpha = 1;
        [self layoutIfNeeded];
        return;
    }
    
    [UIView animateWithDuration:DEFALUT_ANIMATE_DURATION animations:^{
        [_viewContent removeConstraints:@[_lytActivityLeft, _lytActivityBottom]];
        _lytActivityLeft.priority = UILayoutPriorityDefaultHigh;
        _lytActivityBottom.priority = UILayoutPriorityDefaultHigh;
        [_viewContent addConstraints:@[_lytActivityLeft, _lytActivityBottom]];
        _lblLoadingText.alpha = 1;
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
    
}

- (void)hideLoadingLabel
{
//    if (_isLoadingLabelHide) {
//        return;
//    }
//    _isLoadingLabelHide = YES;
    if (_lblLoadingText == nil) {
        return;
    }
    [UIView animateWithDuration:DEFALUT_ANIMATE_DURATION animations:^{
        [_viewContent removeConstraints:@[_lytActivityLeft, _lytActivityBottom]];
        _lytActivityLeft.priority = UILayoutPriorityRequired;
        _lytActivityBottom.priority = UILayoutPriorityRequired;
        [_viewContent addConstraints:@[_lytActivityLeft, _lytActivityBottom]];
        _lblLoadingText.alpha = 0;
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
    
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end

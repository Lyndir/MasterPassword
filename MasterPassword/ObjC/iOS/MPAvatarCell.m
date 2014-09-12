/**
* Copyright Maarten Billemont (http://www.lhunath.com, lhunath@lyndir.com)
*
* See the enclosed file LICENSE for license information (LGPLv3). If you did
* not receive this file, see http://www.gnu.org/licenses/lgpl-3.0.txt
*
* @author   Maarten Billemont <lhunath@lyndir.com>
* @license  http://www.gnu.org/licenses/lgpl-3.0.txt
*/

//
//  MPAvatarCell.h
//  MPAvatarCell
//
//  Created by lhunath on 2014-03-11.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPAvatarCell.h"

const long MPAvatarAdd = 10000;

@interface MPAvatarCell()

@property(strong, nonatomic) IBOutlet UIImageView *avatarImageView;
@property(strong, nonatomic) IBOutlet UILabel *nameLabel;
@property(strong, nonatomic) IBOutlet UIView *nameContainer;
@property(strong, nonatomic) IBOutlet UIImageView *spinner;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *nameToCenterConstraint;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *avatarSizeConstraint;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *avatarToTopConstraint;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *avatarRaisedConstraint;

@end

@implementation MPAvatarCell {
    CAAnimationGroup *_targetedShadowAnimation;
}

+ (NSString *)reuseIdentifier {

    return NSStringFromClass( self );
}

#pragma mark - Life cycle

- (void)awakeFromNib {

    [super awakeFromNib];

    self.alpha = 0;

    self.nameContainer.layer.cornerRadius = 5;

    self.avatarImageView.hidden = NO;
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.bounds.size.height / 2;
    self.avatarImageView.layer.masksToBounds = NO;
    self.avatarImageView.backgroundColor = [UIColor clearColor];

    [self observeKeyPath:@"selected" withBlock:^(id from, id to, NSKeyValueChange cause, id _self) {
        [_self updateAnimated:self.superview != nil];
    }];
    [self observeKeyPath:@"highlighted" withBlock:^(id from, id to, NSKeyValueChange cause, id _self) {
        [_self updateAnimated:self.superview != nil];
    }];

    CABasicAnimation *toShadowOpacityAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    toShadowOpacityAnimation.toValue = @0.2f;
    toShadowOpacityAnimation.duration = 0.5f;

    CABasicAnimation *pulseShadowOpacityAnimation = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    pulseShadowOpacityAnimation.fromValue = @0.2f;
    pulseShadowOpacityAnimation.toValue = @0.6f;
    pulseShadowOpacityAnimation.beginTime = 0.5f;
    pulseShadowOpacityAnimation.duration = 2.0f;
    pulseShadowOpacityAnimation.autoreverses = YES;
    pulseShadowOpacityAnimation.repeatCount = MAXFLOAT;

    _targetedShadowAnimation = [CAAnimationGroup new];
    _targetedShadowAnimation.animations = @[ toShadowOpacityAnimation, pulseShadowOpacityAnimation ];
    _targetedShadowAnimation.duration = MAXFLOAT;
    self.avatarImageView.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.avatarImageView.layer.shadowOffset = CGSizeZero;
}

- (void)prepareForReuse {

    [super prepareForReuse];

    _newUser = NO;
    _visibility = 0;
    _mode = MPAvatarModeLowered;
    _spinnerActive = NO;
}

- (void)dealloc {

    [self removeKeyPathObservers];
}

#pragma mark - Properties

- (void)setAvatar:(long)avatar {

    _avatar = avatar == MPAvatarAdd? MPAvatarAdd: (avatar + MPAvatarCount) % MPAvatarCount;

    if (_avatar == MPAvatarAdd) {
        self.avatarImageView.image = [UIImage imageNamed:@"avatar-add"];
        self.name = strl( @"New User" );
        _newUser = YES;
    }
    else
        self.avatarImageView.image = [UIImage imageNamed:strf( @"avatar-%ld", _avatar )];
}

- (NSString *)name {

    return self.nameLabel.text;
}

- (void)setName:(NSString *)name {

    self.nameLabel.text = name;
}

- (void)setVisibility:(CGFloat)visibility {

    [self setVisibility:visibility animated:YES];
}

- (void)setVisibility:(CGFloat)visibility animated:(BOOL)animated {

    if (visibility == _visibility)
        return;
    _visibility = visibility;

    [self updateAnimated:animated];
}

- (void)setHighlighted:(BOOL)highlighted {

    super.highlighted = highlighted;

    self.avatarImageView.transform = highlighted? CGAffineTransformMakeScale( 1.1f, 1.1f ): CGAffineTransformIdentity;
}

- (void)setMode:(MPAvatarMode)mode {

    [self setMode:mode animated:YES];
}

- (void)setMode:(MPAvatarMode)mode animated:(BOOL)animated {

    if (mode == _mode)
        return;
    _mode = mode;

    [self updateAnimated:animated];
}

- (void)setSpinnerActive:(BOOL)spinnerActive {

    [self setSpinnerActive:spinnerActive animated:YES];
}

- (void)setSpinnerActive:(BOOL)spinnerActive animated:(BOOL)animated {

    if (_spinnerActive == spinnerActive)
        return;
    _spinnerActive = spinnerActive;

    CABasicAnimation *rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotate.toValue = @(2 * M_PI);
    rotate.duration = 5.0;

    if (spinnerActive) {
        rotate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        rotate.fromValue = @0.0;
        rotate.repeatCount = MAXFLOAT;
    }
    else {
        rotate.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        rotate.repeatCount = 1;
    }

    [self.spinner.layer removeAnimationForKey:@"rotation"];
    [self.spinner.layer addAnimation:rotate forKey:@"rotation"];

    [self updateAnimated:animated];
}

#pragma mark - Private

- (void)updateAnimated:(BOOL)animated {

    [self.contentView layoutIfNeeded];
    [UIView animateWithDuration:animated? 0.2f: 0 animations:^{
        self.avatarImageView.transform = CGAffineTransformIdentity;
    }];
    [UIView animateWithDuration:animated? 0.5f: 0 delay:0
                        options:UIViewAnimationOptionOverrideInheritedDuration | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.alpha = 1;

                         if (self.newUser) {
                             if (self.mode == MPAvatarModeLowered)
                                 self.avatar = MPAvatarAdd;
                             else if (self.avatar == MPAvatarAdd)
                                 self.avatar = arc4random() % MPAvatarCount;
                         }

                         switch (self.mode) {
                             case MPAvatarModeLowered: {
                                 [self.avatarSizeConstraint updateConstant:self.avatarImageView.image.size.height];
                                 [self.avatarRaisedConstraint updatePriority:UILayoutPriorityDefaultLow];
                                 [self.avatarToTopConstraint updatePriority:UILayoutPriorityDefaultLow];
                                 [self.nameToCenterConstraint updatePriority:UILayoutPriorityDefaultLow];
                                 self.nameContainer.alpha = self.visibility;
                                 self.nameContainer.backgroundColor = [UIColor clearColor];
                                 self.avatarImageView.alpha = self.visibility / 0.7f + 0.3f;
                                 self.avatarImageView.layer.shadowRadius = 15 * self.visibility * self.visibility;
                                 break;
                             }
                             case MPAvatarModeRaisedButInactive: {
                                 [self.avatarSizeConstraint updateConstant:self.avatarImageView.image.size.height];
                                 [self.avatarRaisedConstraint updatePriority:UILayoutPriorityDefaultHigh];
                                 [self.avatarToTopConstraint updatePriority:UILayoutPriorityDefaultLow];
                                 [self.nameToCenterConstraint updatePriority:UILayoutPriorityDefaultLow];
                                 self.nameContainer.alpha = self.visibility;
                                 self.nameContainer.backgroundColor = [UIColor clearColor];
                                 self.avatarImageView.alpha = 0;
                                 self.avatarImageView.layer.shadowRadius = 15 * self.visibility * self.visibility;
                                 break;
                             }
                             case MPAvatarModeRaisedAndActive: {
                                 [self.avatarSizeConstraint updateConstant:self.avatarImageView.image.size.height];
                                 [self.avatarRaisedConstraint updatePriority:UILayoutPriorityDefaultHigh];
                                 [self.avatarToTopConstraint updatePriority:UILayoutPriorityDefaultLow];
                                 [self.nameToCenterConstraint updatePriority:UILayoutPriorityDefaultHigh];
                                 self.nameContainer.alpha = self.visibility;
                                 self.nameContainer.backgroundColor = [UIColor blackColor];
                                 self.avatarImageView.alpha = 1;
                                 self.avatarImageView.layer.shadowRadius = 15 * self.visibility * self.visibility;
                                 break;
                             }
                             case MPAvatarModeRaisedAndHidden: {
                                 [self.avatarSizeConstraint updateConstant:self.avatarImageView.image.size.height];
                                 [self.avatarRaisedConstraint updatePriority:UILayoutPriorityDefaultHigh];
                                 [self.avatarToTopConstraint updatePriority:UILayoutPriorityDefaultLow];
                                 [self.nameToCenterConstraint updatePriority:UILayoutPriorityDefaultHigh];
                                 self.nameContainer.alpha = 0;
                                 self.nameContainer.backgroundColor = [UIColor blackColor];
                                 self.avatarImageView.alpha = 0;
                                 self.avatarImageView.layer.shadowRadius = 15 * self.visibility * self.visibility;
                                 break;
                             }
                             case MPAvatarModeRaisedAndMinimized: {
                                 [self.avatarSizeConstraint updateConstant:36];
                                 [self.avatarRaisedConstraint updatePriority:UILayoutPriorityDefaultLow];
                                 [self.avatarToTopConstraint updatePriority:UILayoutPriorityDefaultHigh];
                                 [self.nameToCenterConstraint updatePriority:UILayoutPriorityDefaultHigh];
                                 self.nameContainer.alpha = 0;
                                 self.nameContainer.backgroundColor = [UIColor blackColor];
                                 self.avatarImageView.alpha = 1;
                                 break;
                             }
                         }

                         // Avatar minimized.
                         if (self.mode == MPAvatarModeRaisedAndMinimized)
                             [self.avatarImageView.layer removeAnimationForKey:@"targetedShadow"];
                         else if (![self.avatarImageView.layer animationForKey:@"targetedShadow"])
                             [self.avatarImageView.layer addAnimation:_targetedShadowAnimation forKey:@"targetedShadow"];

                         // Avatar selection and spinner.
                         if (self.mode != MPAvatarModeRaisedAndMinimized && (self.selected || self.highlighted) && !self.spinnerActive)
                             self.avatarImageView.backgroundColor = self.avatarImageView.tintColor;
                         else
                             self.avatarImageView.backgroundColor = [UIColor clearColor];
                         self.avatarImageView.layer.cornerRadius = self.avatarImageView.bounds.size.height / 2;
                         self.spinner.alpha = self.spinnerActive? 1: 0;

                         [self.contentView layoutIfNeeded];
                     } completion:nil];
}

@end

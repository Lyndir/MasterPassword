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
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *nameCenterConstraint;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *avatarSizeConstraint;
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *avatarTopConstraint;

@end

@implementation MPAvatarCell {
}

+ (NSString *)reuseIdentifier {

    return @"MPAvatarCell";
}

#pragma mark - Life cycle

- (void)awakeFromNib {

    [super awakeFromNib];

    self.nameContainer.layer.cornerRadius = 5;

    self.avatarImageView.hidden = NO;
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.bounds.size.height / 2;
    self.avatarImageView.layer.masksToBounds = NO;
    self.avatarImageView.backgroundColor = [UIColor clearColor];

    [self observeKeyPath:@"selected" withBlock:^(id from, id to, NSKeyValueChange cause, id _self) {
        [_self updateAnimated:YES];
    }];
    [self observeKeyPath:@"highlighted" withBlock:^(id from, id to, NSKeyValueChange cause, id _self) {
        [_self updateAnimated:YES];
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

    CAAnimationGroup *group = [CAAnimationGroup new];
    group.animations = @[ toShadowOpacityAnimation, pulseShadowOpacityAnimation ];
    group.duration = MAXFLOAT;
    [self.avatarImageView.layer addAnimation:group forKey:@"targetedShadow"];
    self.avatarImageView.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.avatarImageView.layer.shadowOffset = CGSizeZero;

    [self setVisibility:0 animated:NO];
    [self setMode:MPAvatarModeLowered animated:NO];
}

- (void)dealloc {

    [self removeKeyPathObservers];
}

#pragma mark - Properties

- (void)setAvatar:(long)avatar {

    _avatar = avatar;

    if (avatar == MPAvatarAdd)
        self.avatarImageView.image = [UIImage imageNamed:@"avatar-add"];
    else
        self.avatarImageView.image = [UIImage imageNamed:strf( @"avatar-%ld", avatar )];
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

    _visibility = visibility;

    [self updateAnimated:animated];
}

- (void)setHighlighted:(BOOL)highlighted {

    super.highlighted = highlighted;

    [UIView animateWithDuration:0.1f animations:^{
        self.avatarImageView.transform = highlighted? CGAffineTransformMakeScale( 1.1f, 1.1f ): CGAffineTransformIdentity;
    }];
}

- (void)setMode:(MPAvatarMode)mode {

    [self setMode:mode animated:YES];
}

- (void)setMode:(MPAvatarMode)mode animated:(BOOL)animated {

    _mode = mode;

    [self updateAnimated:animated];
}

- (void)setSpinnerActive:(BOOL)spinnerActive {

    [self setSpinnerActive:spinnerActive animated:YES];
}

- (void)setSpinnerActive:(BOOL)spinnerActive animated:(BOOL)animated {

    _spinnerActive = spinnerActive;

    CABasicAnimation *rotate = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotate.toValue = [NSNumber numberWithDouble:2 * M_PI];
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

    [UIView animateWithDuration:animated? 0.2f: 0 animations:^{
        self.avatarImageView.transform = CGAffineTransformIdentity;
    }];
    [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
        switch (self.mode) {

            case MPAvatarModeLowered: {
                self.avatarSizeConstraint.constant = self.avatarImageView.image.size.height;
                self.avatarTopConstraint.priority = UILayoutPriorityDefaultLow;
                self.nameCenterConstraint.priority = UILayoutPriorityDefaultLow;
                self.nameContainer.alpha = self.visibility;
                self.nameContainer.backgroundColor = [UIColor clearColor];
                self.avatarImageView.alpha = self.visibility / 0.7f + 0.3f;
                self.avatarImageView.layer.shadowRadius = 15 * self.visibility * self.visibility;
                break;
            }
            case MPAvatarModeRaisedButInactive: {
                self.avatarSizeConstraint.constant = self.avatarImageView.image.size.height;
                self.avatarTopConstraint.priority = UILayoutPriorityDefaultLow;
                self.nameCenterConstraint.priority = UILayoutPriorityDefaultLow;
                self.nameContainer.alpha = self.visibility;
                self.nameContainer.backgroundColor = [UIColor clearColor];
                self.avatarImageView.alpha = 0;
                self.avatarImageView.layer.shadowRadius = 15 * self.visibility * self.visibility;
                break;
            }
            case MPAvatarModeRaisedAndActive: {
                self.avatarSizeConstraint.constant = self.avatarImageView.image.size.height;
                self.avatarTopConstraint.priority = UILayoutPriorityDefaultLow;
                self.nameCenterConstraint.priority = UILayoutPriorityDefaultHigh;
                self.nameContainer.alpha = self.visibility;
                self.nameContainer.backgroundColor = [UIColor blackColor];
                self.avatarImageView.alpha = 1;
                self.avatarImageView.layer.shadowRadius = 15 * self.visibility * self.visibility;
                break;
            }
            case MPAvatarModeRaisedAndHidden: {
                self.avatarSizeConstraint.constant = self.avatarImageView.image.size.height;
                self.avatarTopConstraint.priority = UILayoutPriorityDefaultLow;
                self.nameCenterConstraint.priority = UILayoutPriorityDefaultHigh;
                self.nameContainer.alpha = 0;
                self.nameContainer.backgroundColor = [UIColor blackColor];
                self.avatarImageView.alpha = 0;
                self.avatarImageView.layer.shadowRadius = 15 * self.visibility * self.visibility;
                break;
            }
            case MPAvatarModeRaisedAndMinimized: {
                self.avatarSizeConstraint.constant = 36;
                self.avatarTopConstraint.priority = UILayoutPriorityDefaultHigh;
                self.nameCenterConstraint.priority = UILayoutPriorityDefaultHigh;
                self.nameContainer.alpha = 0;
                self.nameContainer.backgroundColor = [UIColor blackColor];
                self.avatarImageView.alpha = 1;
                self.avatarImageView.layer.shadowOpacity = 0;
                break;
            }
        }
        [self.avatarSizeConstraint apply];
        [self.avatarTopConstraint apply];
        [self.nameCenterConstraint apply];

        // Avatar selection and spinner.
        if (self.mode != MPAvatarModeRaisedAndMinimized && (self.selected || self.highlighted) && !self.spinnerActive)
            self.avatarImageView.backgroundColor = self.avatarImageView.tintColor;
        else
            self.avatarImageView.backgroundColor = [UIColor clearColor];
        self.avatarImageView.layer.cornerRadius = self.avatarImageView.bounds.size.height / 2;
        self.spinner.alpha = self.spinnerActive? 1: 0;
    }];
}

@end

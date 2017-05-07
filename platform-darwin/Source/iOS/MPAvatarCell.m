//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

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
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *keyboardHeightConstraint;

@property(nonatomic, strong) CAAnimationGroup *targetedShadowAnimation;

@property(assign, nonatomic, readwrite) BOOL newUser;
@end

@implementation MPAvatarCell

+ (NSString *)reuseIdentifier {

    return NSStringFromClass( self );
}

#pragma mark - Life cycle

- (void)awakeFromNib {

    [super awakeFromNib];

    self.visible = NO;

    self.nameContainer.layer.cornerRadius = 5;

    self.avatarImageView.layer.cornerRadius = self.avatarImageView.bounds.size.height / 2;
    self.avatarImageView.layer.masksToBounds = NO;
    self.avatarImageView.backgroundColor = [UIColor clearColor];

    [self observeKeyPath:@"bounds" withBlock:^(id from, id to, NSKeyValueChange cause, MPAvatarCell *self) {
        self.contentView.frame = self.bounds;
    }];
    [self observeKeyPath:@"selected" withBlock:^(id from, id to, NSKeyValueChange cause, MPAvatarCell *self) {
        [self updateAnimated:self.superview != nil];
    }];
    [self observeKeyPath:@"highlighted" withBlock:^(id from, id to, NSKeyValueChange cause, MPAvatarCell *self) {
        [self updateAnimated:self.superview != nil];
    }];
    PearlAddNotificationObserver( UIKeyboardWillShowNotification, nil, [NSOperationQueue mainQueue],
            ^(MPAvatarCell *self, NSNotification *note) {
                CGRect keyboardRect = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
                CGFloat keyboardHeight = CGRectGetHeight( self.window.screen.bounds ) - CGRectGetMinY( keyboardRect );
                [self.keyboardHeightConstraint updateConstant:keyboardHeight];
            } );

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

    self.targetedShadowAnimation = [CAAnimationGroup new];
    self.targetedShadowAnimation.animations = @[ toShadowOpacityAnimation, pulseShadowOpacityAnimation ];
    self.targetedShadowAnimation.duration = MAXFLOAT;
    self.avatarImageView.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.avatarImageView.layer.shadowOffset = CGSizeZero;
}

- (void)prepareForReuse {

    [super prepareForReuse];

    self.newUser = NO;
    self.visibility = 0;
    self.mode = MPAvatarModeLowered;
    self.spinnerActive = NO;
}

- (void)dealloc {

    [self removeKeyPathObservers];
    PearlRemoveNotificationObservers();
}

#pragma mark - Properties

- (void)setAvatar:(NSUInteger)avatar {

    _avatar = avatar == MPAvatarAdd? MPAvatarAdd: (avatar + MPAvatarCount) % MPAvatarCount;

    if (self.avatar == MPAvatarAdd) {
        self.avatarImageView.image = [UIImage imageNamed:@"avatar-add"];
        self.name = strl( @"New User" );
        self.newUser = YES;
    }
    else
        self.avatarImageView.image = [UIImage imageNamed:strf( @"avatar-%lu", (unsigned long)self.avatar )];
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

    if (self.visibility == visibility)
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

    if (self.mode == mode)
        return;
    _mode = mode;

    [self updateAnimated:animated];
}

- (void)setSpinnerActive:(BOOL)spinnerActive {

    [self setSpinnerActive:spinnerActive animated:YES];
}

- (void)setSpinnerActive:(BOOL)spinnerActive animated:(BOOL)animated {

    if (self.spinnerActive == spinnerActive)
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
                         self.visible = YES;

                         if (self.newUser) {
                             if (self.mode == MPAvatarModeLowered)
                                 self.avatar = MPAvatarAdd;
                             else if (self.avatar == MPAvatarAdd)
                                 self.avatar = arc4random() % MPAvatarCount;
                         }

                         self.nameContainer.alpha = self.visibility;
                         self.avatarImageView.alpha = self.visibility * 0.7f + 0.3f;
                         self.avatarImageView.layer.shadowRadius = 15 * self.visibility * self.visibility;

                         switch (self.mode) {
                             case MPAvatarModeLowered: {
                                 [self.avatarSizeConstraint updateConstant:
                                         self.avatarImageView.image.size.height * (self.visibility * 0.3f + 0.7f)];
                                 [self.avatarRaisedConstraint updatePriority:UILayoutPriorityDefaultLow];
                                 [self.avatarToTopConstraint updatePriority:UILayoutPriorityDefaultLow];
                                 [self.nameToCenterConstraint updatePriority:UILayoutPriorityDefaultLow];
                                 self.nameContainer.visible = YES;
                                 self.nameContainer.backgroundColor = [UIColor clearColor];
                                 self.avatarImageView.visible = YES;
                                 break;
                             }
                             case MPAvatarModeRaisedButInactive: {
                                 [self.avatarSizeConstraint updateConstant:
                                         self.avatarImageView.image.size.height * (self.visibility * 0.7f + 0.3f)];
                                 [self.avatarRaisedConstraint updatePriority:UILayoutPriorityDefaultHigh];
                                 [self.avatarToTopConstraint updatePriority:UILayoutPriorityDefaultLow];
                                 [self.nameToCenterConstraint updatePriority:UILayoutPriorityDefaultLow];
                                 self.nameContainer.visible = YES;
                                 self.nameContainer.backgroundColor = [UIColor clearColor];
                                 self.avatarImageView.visible = NO;
                                 break;
                             }
                             case MPAvatarModeRaisedAndActive: {
                                 [self.avatarSizeConstraint updateConstant:
                                         self.avatarImageView.image.size.height * (self.visibility * 0.7f + 0.3f)];
                                 [self.avatarRaisedConstraint updatePriority:UILayoutPriorityDefaultHigh];
                                 [self.avatarToTopConstraint updatePriority:UILayoutPriorityDefaultLow];
                                 [self.nameToCenterConstraint updatePriority:UILayoutPriorityDefaultHigh];
                                 self.nameContainer.visible = YES;
                                 self.nameContainer.backgroundColor = [UIColor blackColor];
                                 self.avatarImageView.visible = YES;
                                 break;
                             }
                             case MPAvatarModeRaisedAndHidden: {
                                 [self.avatarSizeConstraint updateConstant:
                                         self.avatarImageView.image.size.height * (self.visibility * 0.7f + 0.3f)];
                                 [self.avatarRaisedConstraint updatePriority:UILayoutPriorityDefaultHigh];
                                 [self.avatarToTopConstraint updatePriority:UILayoutPriorityDefaultLow];
                                 [self.nameToCenterConstraint updatePriority:UILayoutPriorityDefaultHigh];
                                 self.nameContainer.visible = NO;
                                 self.nameContainer.backgroundColor = [UIColor blackColor];
                                 self.avatarImageView.visible = NO;
                                 break;
                             }
                             case MPAvatarModeRaisedAndMinimized: {
                                 [self.avatarSizeConstraint updateConstant:36];
                                 [self.avatarRaisedConstraint updatePriority:UILayoutPriorityDefaultLow];
                                 [self.avatarToTopConstraint updatePriority:UILayoutPriorityDefaultHigh + 2];
                                 [self.nameToCenterConstraint updatePriority:UILayoutPriorityDefaultHigh];
                                 self.nameContainer.visible = NO;
                                 self.nameContainer.backgroundColor = [UIColor blackColor];
                                 self.avatarImageView.visible = YES;
                                 break;
                             }
                         }

                         // Avatar minimized.
                         if (self.mode == MPAvatarModeRaisedAndMinimized)
                             [self.avatarImageView.layer removeAnimationForKey:@"targetedShadow"];
                         else if (![self.avatarImageView.layer animationForKey:@"targetedShadow"])
                             [self.avatarImageView.layer addAnimation:self.targetedShadowAnimation forKey:@"targetedShadow"];

                         // Avatar selection and spinner.
                         if (self.mode != MPAvatarModeRaisedAndMinimized && (self.selected || self.highlighted) && !self.spinnerActive)
                             self.avatarImageView.backgroundColor = self.avatarImageView.tintColor;
                         else
                             self.avatarImageView.backgroundColor = [UIColor clearColor];
                         self.avatarImageView.layer.cornerRadius = self.avatarImageView.bounds.size.height / 2;
                         self.spinner.visible = self.spinnerActive;

                         [self.contentView layoutIfNeeded];
                     } completion:nil];
}

@end

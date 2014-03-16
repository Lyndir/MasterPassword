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
@property(strong, nonatomic) IBOutlet NSLayoutConstraint *nameCenterConstraint;

@end

@implementation MPAvatarCell {
}

+ (NSString *)reuseIdentifier {

    return @"MPAvatarCell";
}

- (void)awakeFromNib {

    [super awakeFromNib];

    self.nameContainer.layer.cornerRadius = 5;

    self.avatarImageView.hidden = NO;
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.bounds.size.height / 2;
    self.avatarImageView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.avatarImageView.layer.shadowOpacity = 1;
    self.avatarImageView.layer.shadowRadius = 15;
    self.avatarImageView.layer.masksToBounds = NO;
    self.avatarImageView.backgroundColor = [UIColor clearColor];

    [self observeKeyPath:@"selected" withBlock:^(id from, id to, NSKeyValueChange cause, id _self) {
        [_self onSelectedOrHighlighted];
    }];
    [self observeKeyPath:@"highlighted" withBlock:^(id from, id to, NSKeyValueChange cause, id _self) {
        [_self onSelectedOrHighlighted];
    }];

    self.visibility = 0;
    self.mode = MPAvatarModeLowered;
}

- (void)onSelectedOrHighlighted {

    self.avatarImageView.backgroundColor = self.selected || self.highlighted? self.avatarImageView.tintColor: [UIColor clearColor];
}

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

- (void)setVisibility:(float)visibility {

    _visibility = visibility;

    self.nameContainer.alpha = visibility;
}

- (void)setHighlighted:(BOOL)highlighted {

    super.highlighted = highlighted;

    [UIView animateWithDuration:0.1f animations:^{
        self.avatarImageView.transform = highlighted? CGAffineTransformMakeScale( 1.1f, 1.1f ): CGAffineTransformIdentity;
    }];
}

- (void)setMode:(MPAvatarMode)mode {

    _mode = mode;

    [UIView animateWithDuration:0.2f animations:^{
        self.avatarImageView.transform = CGAffineTransformIdentity;
    }];
    [UIView animateWithDuration:0.3f animations:^{
        switch (mode) {

            case MPAvatarModeLowered: {
                self.nameCenterConstraint.priority = UILayoutPriorityDefaultLow;
                self.nameContainer.backgroundColor = [UIColor clearColor];
                self.avatarImageView.alpha = 1;
                break;
            }
            case MPAvatarModeRaisedButInactive: {
                self.nameCenterConstraint.priority = UILayoutPriorityDefaultLow;
                self.nameContainer.backgroundColor = [UIColor clearColor];
                self.avatarImageView.alpha = 0.3f;
                break;
            }
            case MPAvatarModeRaisedAndActive: {
                self.nameCenterConstraint.priority = UILayoutPriorityDefaultHigh;
                self.nameContainer.backgroundColor = [UIColor blackColor];
                self.avatarImageView.alpha = 1;
                break;
            }
        }

        [self.nameCenterConstraint apply];
    }];
}

@end

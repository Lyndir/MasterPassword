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

#import "MPGuideViewController.h"
#import "markdown_lib.h"
#import "NSString+MPMarkDown.h"

@interface MPGuideStep : NSObject

@property(nonatomic) UIImage *image;
@property(nonatomic) NSString *caption;

+ (instancetype)stepWithImage:(UIImage *)image caption:(NSString *)caption;

@end

@interface MPGuideStepCell : UICollectionViewCell

@property(nonatomic) IBOutlet UIImageView *imageView;

@end

@interface MPGuideViewController()

@property(nonatomic, strong) NSArray *steps;
@end

@implementation MPGuideViewController

#pragma mark - Life

- (void)viewDidLoad {

    [super viewDidLoad];

    self.steps = @[
            [MPGuideStep stepWithImage:[UIImage imageNamed:@"initial"] caption:
                    @"To begin, tap the *New User* icon and add yourself as a user to the application."],

            [MPGuideStep stepWithImage:[UIImage imageNamed:@"name_new"] caption:
                    @"Enter your full name.  \n"
                            @"**Double-check** that you have spelled your name correctly and capitalized it appropriately.  \n"
                            @"Your passwords will depend on it."],

            [MPGuideStep stepWithImage:[UIImage imageNamed:@"mpw_new"] caption:
                    @"Choose a master password: Make it *new* and *long*.  \n"
                            @"A short phrase makes a great password.  \n"
                            @"**DO NOT FORGET THIS ONE PASSWORD**."],

            [MPGuideStep stepWithImage:[UIImage imageNamed:@"login_new"] caption:
                    @"After logging in, you'll see an empty screen with a search box.  \n"
                            @"Tap the search box to begin adding sites."],

            [MPGuideStep stepWithImage:[UIImage imageNamed:@"site_new"] caption:
                    @"To add a site, just enter its name and tap the result.  \n"
                            @"*We recommend* always using a site's **bare** domain name: eg. *apple.com*.  \n"
                            @"(NOT *www.*apple.com or *store.*apple.com)"],

            [MPGuideStep stepWithImage:[UIImage imageNamed:@"copy_pw"] caption:
                    @"Tap any site to copy its password.  \n"
                            @"The first time, change your site's old password into this new one."],

            [MPGuideStep stepWithImage:[UIImage imageNamed:@"settings"] caption:
                    @"To make changes to the site password, tap the settings icon or swipe left to reveal extra buttons."],

            [MPGuideStep stepWithImage:[UIImage imageNamed:@"login_name"] caption:
                    @"You can save the login name for the site.  \n"
                            @"This is useful if you find it hard to remember your user name for this site."],

            [MPGuideStep stepWithImage:[UIImage imageNamed:@"counter"] caption:
                    @"If you ever need a new password for the site, just tap the plus icon to increment its counter.  \n"
                            @"You can hold down to reset it back to 1."],

            [MPGuideStep stepWithImage:[UIImage imageNamed:@"choose_type"] caption:
                    @"Use the list icon to upgrade or downgrade your password's complexity.  \n"
                            @"Some sites won't let you use complex passwords."],

            [MPGuideStep stepWithImage:[UIImage imageNamed:@"personal_pw"] caption:
                    @"If you have a password that you cannot change, you can save it as a *personal* password.  "
                            @"*Device private* means the site will not be backed up."],
    ];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    [self.pageControl observeKeyPath:@"currentPage"
                           withBlock:^(id from, id to, NSKeyValueChange cause, UIPageControl *pageControl) {
                               MPGuideStep *activeStep = self.steps[pageControl.currentPage];
                               self.captionLabel.attributedText =
                                       [activeStep.caption attributedMarkdownStringWithFontSize:self.captionLabel.font.pointSize];
                           }];

    [self.collectionView setContentOffset:CGPointZero];
    self.pageControl.currentPage = 0;

    if (self.navigationController)
        [self.navigationBar removeFromSuperview];
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    [self.pageControl removeKeyPathObservers];
}

- (BOOL)shouldAutorotate {

    return NO;
}

- (BOOL)prefersStatusBarHidden {

    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {

    return UIStatusBarStyleLightContent;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {

    return UIInterfaceOrientationPortrait;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    return self.pageControl.numberOfPages = [self.steps count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    MPGuideStepCell *cell = [MPGuideStepCell dequeueCellFromCollectionView:collectionView indexPath:indexPath];
    cell.imageView.image = ((MPGuideStep *)self.steps[indexPath.item]).image;
    cell.contentView.frame = cell.bounds;

    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

    return collectionView.bounds.size;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

    if (scrollView == self.collectionView)
        self.pageControl.currentPage = [self.collectionView indexPathForItemAtPoint:CGRectGetCenter( self.collectionView.bounds )].item;
}

#pragma mark - Actions

- (IBAction)close:(id)sender {

    [MPiOSConfig get].showSetup = @NO;
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

@end

@implementation MPGuideStep

+ (instancetype)stepWithImage:(UIImage *)image caption:(NSString *)caption {

    MPGuideStep *step = [self new];
    step.image = image;
    step.caption = caption;

    return step;
}

@end

@implementation MPGuideStepCell

- (void)awakeFromNib {

    [super awakeFromNib];

    self.imageView.layer.shadowColor = [UIColor grayColor].CGColor;
    self.imageView.layer.shadowOffset = CGSizeZero;
    self.imageView.layer.shadowOpacity = 0.5f;
}

@end

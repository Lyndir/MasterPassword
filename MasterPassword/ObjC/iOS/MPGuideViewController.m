//
//  MPGuideViewController.m
//  MasterPassword
//
//  Created by Maarten Billemont on 30/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPGuideViewController.h"

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
            [MPGuideStep stepWithImage:[UIImage imageNamed:@"image-0"] caption:
                    @"To begin, tap the \"New User\" icon and add yourself as a user to the application."],
            [MPGuideStep stepWithImage:[UIImage imageNamed:@"image-1"] caption:
                    @"Enter your full name.  Double-check that you have spelled your name correctly and capitalized it appropriately.  Your passwords will depend on it."],
            [MPGuideStep stepWithImage:[UIImage imageNamed:@"image-2"] caption:
                    @"Choose a master password: Use something new and long.  A short sentence is ideal.\nDO NOT FORGET THIS ONE PASSWORD."],
            [MPGuideStep stepWithImage:[UIImage imageNamed:@"image-3"] caption:
                    @"After logging in, you'll see an empty screen with a search box.\nTap the search box to begin adding sites."],
            [MPGuideStep stepWithImage:[UIImage imageNamed:@"image-4"] caption:
                    @"To add a site, just enter its name fully and tap the result.  Names can be anything, but we recommend using a site's bare domain name."],
            [MPGuideStep stepWithImage:[UIImage imageNamed:@"image-5"] caption:
                    @"Your sites are easy to find and sorted by recency.\nTap any site to copy its password.\nYou can now switch and paste it in another app."],
            [MPGuideStep stepWithImage:[UIImage imageNamed:@"image-6"] caption:
                    @"The user icon lets you save your site's login.\nThis is useful if you find it hard to remember the user name for this site."],
            [MPGuideStep stepWithImage:[UIImage imageNamed:@"image-7"] caption:
                    @"To make changes to the site password, tap the settings icon or swipe left to reveal extra buttons."],
            [MPGuideStep stepWithImage:[UIImage imageNamed:@"image-8"] caption:
                    @"If you ever need a new password for the site, just tap the plus icon to increment its counter.\nYou can hold down to reset it back to 1."],
            [MPGuideStep stepWithImage:[UIImage imageNamed:@"image-9"] caption:
                    @"Use the list icon to upgrade or downgrade your password's complexity.\nSome sites won't let you use complex passwords."],
            [MPGuideStep stepWithImage:[UIImage imageNamed:@"image-10"] caption:
                    @"If you have a password that you cannot change, you can save it as a Personal password.  Device Private means the site will not be backed up."],
    ];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    [self.pageControl observeKeyPath:@"currentPage"
                           withBlock:^(id from, id to, NSKeyValueChange cause, UIPageControl *pageControl) {
        MPGuideStep *activeStep = self.steps[pageControl.currentPage];
        self.captionLabel.text = activeStep.caption;
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

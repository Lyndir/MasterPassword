//
//  MPGuideViewController.h
//  MasterPassword
//
//  Created by Maarten Billemont on 30/01/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MPGuideViewController : UIViewController<UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property(nonatomic) IBOutlet UICollectionView *collectionView;
@property(nonatomic) IBOutlet UILabel *captionLabel;
@property(nonatomic) IBOutlet UIPageControl *pageControl;
@property(nonatomic) IBOutlet UINavigationBar *navigationBar;

- (IBAction)close:(id)sender;

@end

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
//  MPPasswordTypesCell.h
//  MPPasswordTypesCell
//
//  Created by lhunath on 2014-03-27.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPPasswordTypesCell.h"
#import "MPPasswordLargeCell.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"

@implementation MPPasswordTypesCell

#pragma mark - Lifecycle

+ (instancetype)dequeueCellForTransientSite:(NSString *)siteName fromCollectionView:(UICollectionView *)collectionView
                                atIndexPath:(NSIndexPath *)indexPath {

    MPPasswordTypesCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass( [MPPasswordTypesCell class] )
                                                                          forIndexPath:indexPath];
    [cell setTransientSite:siteName];

    return cell;
}

+ (instancetype)dequeueCellForElement:(MPElementEntity *)element fromCollectionView:(UICollectionView *)collectionView
                          atIndexPath:(NSIndexPath *)indexPath {

    MPPasswordTypesCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass( [MPPasswordTypesCell class] )
                                                                          forIndexPath:indexPath];
    [cell setElement:element];

    return cell;
}

- (void)awakeFromNib {

    [super awakeFromNib];

    self.backgroundColor = [UIColor clearColor];
    self.layer.shadowColor = [UIColor clearColor].CGColor;

    [self prepareForReuse];
}

- (void)prepareForReuse {

    _algorithm = MPAlgorithmDefault;

    [super prepareForReuse];
}

- (void)reloadWithTransientSite:(NSString *)siteName {

    [super reloadWithTransientSite:siteName];

    [self.contentCollectionView reloadData];
    NSIndexPath *visibleIndexPath = [self contentIndexPathForType:
                IfElse([[MPiOSAppDelegate get] activeUserForMainThread].defaultType, MPElementTypeGeneratedLong)];
    [self.contentCollectionView scrollToItemAtIndexPath:visibleIndexPath
                                       atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

- (void)reloadWithElement:(MPElementEntity *)mainElement {

    [super reloadWithElement:mainElement];

    self.algorithm = IfNotNilElse([self mainElement].algorithm, MPAlgorithmDefault);

    [self.contentCollectionView reloadData];
    NSIndexPath *visibleIndexPath = [self contentIndexPathForType:mainElement.type];
    [self.contentCollectionView scrollToItemAtIndexPath:visibleIndexPath
                                       atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    if (!self.algorithm)
        dbg_return_tr(0, @, @(section));

    NSInteger types = 1;

    MPElementType type = [self typeForContentIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    for (MPElementType nextType = type; type != (nextType = [self.algorithm nextType:nextType]);)
        ++types;

    dbg_return_tr(types, @, @(section));
}

- (MPPasswordLargeCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    MPPasswordLargeCell *cell = [MPPasswordLargeCell dequeueCellWithType:[self typeForContentIndexPath:indexPath]
                                                      fromCollectionView:collectionView atIndexPath:indexPath];
    if (self.transientSite)
        [cell reloadWithTransientSite:self.transientSite];
    else
        [cell reloadWithElement:self.mainElement];

    dbg_return(cell, indexPath);
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    UICollectionView *passwordCollectionView = [UICollectionView findAsSuperviewOf:self];
    [passwordCollectionView.delegate collectionView:passwordCollectionView didSelectItemAtIndexPath:[passwordCollectionView indexPathForCell:self]];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {

    if (scrollView == self.contentCollectionView) {
        NSIndexPath *targetIndexPath = [self.contentCollectionView indexPathForItemAtPoint:
                CGPointPlusCGPoint( *targetContentOffset, self.contentCollectionView.center )];
        *targetContentOffset = CGPointFromCGRectTopLeft(
                [self.contentCollectionView layoutAttributesForItemAtIndexPath:targetIndexPath].frame );
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {

    if (scrollView == self.contentCollectionView && !decelerate)
        [self saveContentType];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

    if (scrollView == self.contentCollectionView)
        [self saveContentType];
}

#pragma mark - Private

- (MPElementType)typeForContentIndexPath:(NSIndexPath *)indexPath {

    MPElementType type = MPElementTypeGeneratedPIN;

    for (NSUInteger i = 0; i < indexPath.item; ++i)
        type = [self.algorithm nextType:type];

    return type;
}

- (NSIndexPath *)contentIndexPathForType:(MPElementType)type {

    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
    while ([self typeForContentIndexPath:indexPath] != type) {
        indexPath = [NSIndexPath indexPathForItem:indexPath.item + 1 inSection:indexPath.section];
        NSAssert1(indexPath.item < [self.contentCollectionView numberOfItemsInSection:0],
        @"No item found for type: %@", [self.algorithm nameOfType:type]);
    }

    return indexPath;
}

- (void)saveContentType {

    if (self.transientSite)
        return;

    CGPoint centerPoint = CGPointFromCGRectCenter( self.contentCollectionView.bounds );
    NSIndexPath *centerIndexPath = [self.contentCollectionView indexPathForItemAtPoint:centerPoint];

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPPasswordLargeCell *cell = (MPPasswordLargeCell *)[self.contentCollectionView cellForItemAtIndexPath:centerIndexPath];
        if (!cell) {
            err(@"Couldn't find cell to change type: centerIndexPath=%@", centerIndexPath);
            return;
        }

        MPElementEntity *element = [self elementInContext:context];
        if (element.type == cell.type)
                // Nothing changed.
            return;

        self.element = [cell saveContentTypeWithElement:element saveInContext:context];
    }];
}

#pragma mark - Properties

- (void)setSelected:(BOOL)selected {

    [super setSelected:selected];

    if (!selected)
        for (NSIndexPath *indexPath in [self.contentCollectionView indexPathsForSelectedItems])
            [self.contentCollectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (void)setAlgorithm:(id<MPAlgorithm>)algorithm {

    if ([_algorithm isEqual:algorithm])
        return;

    _algorithm = algorithm;

    [self.contentCollectionView reloadData];
}

@end

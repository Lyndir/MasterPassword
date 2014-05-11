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

    _activeType = 0;
    _algorithm = MPAlgorithmDefault;

    [super prepareForReuse];
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes {

    [super applyLayoutAttributes:layoutAttributes];

    [self.contentCollectionView.collectionViewLayout invalidateLayout];
    if (self.activeType)
        [self.contentCollectionView scrollToItemAtIndexPath:[self contentIndexPathForType:self.activeType]
                                           atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

- (void)reloadWithTransientSite:(NSString *)siteName {

    [super reloadWithTransientSite:siteName];

    [self.contentCollectionView reloadData];
    self.activeType = IfElse( [[MPiOSAppDelegate get] activeUserForMainThread].defaultType, MPElementTypeGeneratedLong );
}

- (void)reloadWithElement:(MPElementEntity *)mainElement {

    [super reloadWithElement:mainElement];

    self.algorithm = IfNotNilElse( [self mainElement].algorithm, MPAlgorithmDefault );

    [self.contentCollectionView reloadData];
    self.activeType = mainElement.type;
}

#pragma mark - UICollectionViewDataSource

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {

    return collectionView.bounds.size;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {

    if (!self.algorithm)
        dbg_return_tr( 0, @, @(section) );

    dbg_return_tr( [[self.algorithm allTypes] count] + 1, @, @(section) );
}

- (MPPasswordLargeCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    MPPasswordLargeCell *cell = [MPPasswordLargeCell dequeueCellWithType:[self typeForContentIndexPath:indexPath]
                                                      fromCollectionView:collectionView atIndexPath:indexPath];
    if (self.transientSite)
        [cell reloadWithTransientSite:self.transientSite];
    else
        [cell reloadWithElement:self.mainElement];

    dbg_return( cell, indexPath );
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

    NSString *newSiteName = self.transientSite;
    if (newSiteName) {
        [PearlAlert showAlertWithTitle:@"Create Site"
                               message:strf( @"Do you want to create a new site named:\n%@", newSiteName )
                             viewStyle:UIAlertViewStyleDefault
                             initAlert:nil tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
            if (buttonIndex == [alert cancelButtonIndex]) {
                // Cancel
//                NSIndexPath *indexPath_ = [collectionView indexPathForCell:cell];
//                [collectionView selectItemAtIndexPath:indexPath animated:NO
//                                       scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
//                [collectionView deselectItemAtIndexPath:indexPath animated:YES];
                for (NSIndexPath *selectedIndexPath in [collectionView indexPathsForSelectedItems])
                    [collectionView deselectItemAtIndexPath:selectedIndexPath animated:YES];
                return;
            }

            // Create
            [[MPiOSAppDelegate get] addElementNamed:newSiteName completion:^(MPElementEntity *element) {
                PearlMainQueue( ^{
                    [PearlOverlay showTemporaryOverlayWithTitle:strf( @"Added %@", newSiteName ) dismissAfter:2];
                    PearlMainQueueAfter( 0.2f, ^{
//                        NSIndexPath *indexPath_ = [collectionView indexPathForCell:cell];
//                        [collectionView selectItemAtIndexPath:indexPath animated:NO
//                                               scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
//                        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
                        for (NSIndexPath *selectedIndexPath in [collectionView indexPathsForSelectedItems])
                            [collectionView deselectItemAtIndexPath:selectedIndexPath animated:YES];
                    } );
                } );
            }];
        }                  cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonYes, nil];
        return;
    }

    MPElementEntity *element = [self mainElement];
    if (!element) {
//        [collectionView selectItemAtIndexPath:indexPath animated:NO
//                               scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
//        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
        for (NSIndexPath *selectedIndexPath in [collectionView indexPathsForSelectedItems])
            [collectionView deselectItemAtIndexPath:selectedIndexPath animated:YES];
        return;
    }

    inf( @"Copying password for: %@", element.name );
    MPCheckpoint( MPCheckpointCopyToPasteboard, @{
            @"type"      : NilToNSNull( element.typeName ),
            @"version"   : @(element.version),
            @"emergency" : @NO
    } );

    [element resolveContentUsingKey:[MPAppDelegate_Shared get].key result:^(NSString *result) {
        if (![result length]) {
            PearlMainQueue( ^{
//                NSIndexPath *indexPath_ = [collectionView indexPathForCell:cell];
//                [collectionView selectItemAtIndexPath:indexPath animated:NO
//                                       scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
//                [collectionView deselectItemAtIndexPath:indexPath animated:YES];
                for (NSIndexPath *selectedIndexPath in [collectionView indexPathsForSelectedItems])
                    [collectionView deselectItemAtIndexPath:selectedIndexPath animated:YES];
            } );
            return;
        }

        [UIPasteboard generalPasteboard].string = result;
        PearlMainQueue( ^{
            [PearlOverlay showTemporaryOverlayWithTitle:@"Password Copied" dismissAfter:2];
            PearlMainQueueAfter( 0.2f, ^{
//                NSIndexPath *indexPath_ = [collectionView indexPathForCell:cell];
//                [collectionView selectItemAtIndexPath:indexPath animated:NO
//                                       scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
//                [collectionView deselectItemAtIndexPath:indexPath animated:YES];
                for (NSIndexPath *selectedIndexPath in [collectionView indexPathsForSelectedItems])
                    [collectionView deselectItemAtIndexPath:selectedIndexPath animated:YES];

                [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    [[self elementInContext:context] use];
                    [context saveToStore];
                }];
            } );
        } );
    }];
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

    if (indexPath.item == 0)
        return (MPElementType)NSNotFound;

    return [[self.algorithm allTypesStartingWith:MPElementTypeGeneratedPIN][indexPath.item - 1] unsignedIntegerValue];
}

- (NSIndexPath *)contentIndexPathForType:(MPElementType)type {

    NSArray *types = [self.algorithm allTypesStartingWith:MPElementTypeGeneratedPIN];
    for (NSInteger t = 0; t < [types count]; ++t)
        if ([types[t] unsignedIntegerValue] == type)
            return [NSIndexPath indexPathForItem:t + 1 inSection:0];

    Throw(@"Unsupported type: %d", type);
}

- (void)saveContentType {

    if (self.transientSite)
        return;

    CGPoint centerPoint = CGPointFromCGRectCenter( self.contentCollectionView.bounds );
    NSIndexPath *centerIndexPath = [self.contentCollectionView indexPathForItemAtPoint:centerPoint];
    self.activeType = [self typeForContentIndexPath:centerIndexPath];

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPPasswordLargeCell *cell = (MPPasswordLargeCell *)[self.contentCollectionView cellForItemAtIndexPath:centerIndexPath];
        if (!cell) {
            err( @"Couldn't find cell to change type: centerIndexPath=%@", centerIndexPath );
            return;
        }

        MPElementEntity *element = [self elementInContext:context];
        if (element.type == cell.type)
            // Nothing changed.
            return;

        self.element = [cell saveContentTypeWithElement:element saveInContext:context];
    }];
}

#pragma mark - State

- (void)setActiveType:(MPElementType)activeType {

    _activeType = activeType;

    [self.contentCollectionView scrollToItemAtIndexPath:[self contentIndexPathForType:activeType]
                                       atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
}

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

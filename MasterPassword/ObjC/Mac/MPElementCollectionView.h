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
//  MPElementCollectionView.h
//  MPElementCollectionView
//
//  Created by lhunath on 2/11/2014.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MPElementModel;

@interface MPElementCollectionView : NSCollectionViewItem

@property (nonatomic) MPElementModel *representedObject;
@property (nonatomic) BOOL counterHidden;
@property (nonatomic) BOOL updateContentHidden;

- (IBAction)toggleType:(id)sender;
- (IBAction)updateLoginName:(id)sender;
- (IBAction)updateContent:(id)sender;
- (IBAction)delete:(id)sender;

@end

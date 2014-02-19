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
@property (nonatomic) NSString *typeTitle;
@property (nonatomic) NSString *loginNameTitle;
@property (nonatomic) NSString *counterTitle;

- (IBAction)toggleType:(id)sender;
- (IBAction)setLoginName:(id)sender;
- (IBAction)incrementCounter:(id)sender;

@end

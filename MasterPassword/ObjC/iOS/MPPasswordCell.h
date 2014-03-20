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

#import <Foundation/Foundation.h>
#import "MPEntities.h"

@interface MPPasswordCell : UICollectionViewCell <UITextFieldDelegate>

@property(nonatomic, copy) NSString *transientSite;
@property(strong, nonatomic) IBOutlet UITextField *contentField;

+ (NSString *)reuseIdentifier;

- (MPElementEntity *)elementInContext:(NSManagedObjectContext *)context;
+ (NSString *)reuseIdentifierForElement:(MPElementEntity *)entity;
- (void)setElement:(MPElementEntity *)element;

- (void)updateAnimated:(BOOL)animated;
- (void)populateWithElement:(MPElementEntity *)element;

@end

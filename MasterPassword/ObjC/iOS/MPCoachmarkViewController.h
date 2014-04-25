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
//  MPCoachmarkViewController.h
//  MPCoachmarkViewController
//
//  Created by lhunath on 2014-04-22.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MPCoachmark : NSObject

@property(nonatomic, strong) Class coachedClass;
@property(nonatomic) int coachedVersion;
@property(nonatomic) BOOL coached;

+ (instancetype)coachmarkForClass:(Class)class version:(NSInteger)version;

@end

@interface MPCoachmarkViewController : UIViewController

@property(nonatomic, strong) MPCoachmark *coachmark;

- (IBAction)close:(id)sender;

@end

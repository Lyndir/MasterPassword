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
//  MPSitesTableView.h
//  MPSitesTableView
//
//  Created by lhunath on 2014-06-30.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import <AppKit/AppKit.h>

@class MPPasswordWindowController;

@interface MPSitesTableView : NSTableView

@property(nonatomic, weak) MPPasswordWindowController *controller;

@end

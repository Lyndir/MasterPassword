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
//  MPElementsTableView.h
//  MPElementsTableView
//
//  Created by lhunath on 2014-06-30.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "MPElementsTableView.h"
#import "MPPasswordWindowController.h"

@implementation MPElementsTableView

- (void)doCommandBySelector:(SEL)aSelector {

    [self.controller handleCommand:aSelector];
}

- (void)keyDown:(NSEvent *)theEvent {

    [self interpretKeyEvents:@[ theEvent ]];
}

@end

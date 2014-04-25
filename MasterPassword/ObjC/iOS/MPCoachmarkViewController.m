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

#import "MPCoachmarkViewController.h"

@implementation MPCoachmarkViewController {
}

- (IBAction)close:(id)sender {

    [self dismissViewControllerAnimated:YES completion:^{
        self.coachmark.coached = YES;
    }];
}

@end

@implementation MPCoachmark

+ (instancetype)coachmarkForClass:(Class)coachedClass version:(NSInteger)coachedVersion {
    MPCoachmark *coachmark = [self new];
    coachmark.coachedClass = coachedClass;
    coachmark.coachedVersion = coachedVersion;

    return coachmark;
}

- (BOOL)coached {

    return [[NSUserDefaults standardUserDefaults] boolForKey:strf( @"%@.%d.coached", self.coachedClass, self.coachedVersion )];
}

- (void)setCoached:(BOOL)coached {

    [[NSUserDefaults standardUserDefaults] setBool:coached forKey:strf( @"%@.%d.coached", self.coachedClass, self.coachedVersion )];
}

@end

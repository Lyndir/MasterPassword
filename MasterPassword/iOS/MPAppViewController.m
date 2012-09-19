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
//  MPAppViewController
//
//  Created by Maarten Billemont on 2012-08-31.
//  Copyright 2012 lhunath (Maarten Billemont). All rights reserved.
//

#import "MPAppViewController.h"
#import "LocalyticsSession.h"


@implementation MPAppViewController {

}


- (IBAction)gorillas:(UIButton *)sender {

#ifdef TESTFLIGHT_SDK_VERSION
    [TestFlight passCheckpoint:MPCheckpointAppGorillas];
#endif
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointAppGorillas attributes:nil];

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/app/lyndir/gorillas/id302275459?mt=8"]];
}

- (IBAction)deblock:(UIButton *)sender {

#ifdef TESTFLIGHT_SDK_VERSION
    [TestFlight passCheckpoint:MPCheckpointAppDeBlock];
#endif
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:MPCheckpointAppDeBlock attributes:nil];

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/app/lyndir/deblock/id325058485?mt=8"]];
}

@end

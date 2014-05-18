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
    NSArray *_views;
    NSUInteger _nextView;
    __weak NSTimer *_viewTimer;
}

- (void)viewDidLoad {

    [super viewDidLoad];

    _views = [NSArray arrayWithObjects:
            self.view0, self.view1, self.view2, self.view3, self.view4, self.view5, self.view6, self.view7, self.view8, self.view9, nil];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    self.viewProgress.hidden = NO;
    self.viewProgress.progress = 0;
    [_views makeObjectsPerformSelector:@selector( setAlpha: ) withObject:@0];
    _nextView = 0;
}

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];

    [UIView animateWithDuration:0.3f animations:^{
        [_views[_nextView++] setAlpha:1];
    }];

    _viewTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 block:^(NSTimer *timer) {
        self.viewProgress.progress += 1.0f / 50;

        if (self.viewProgress.progress == 1)
            [UIView animateWithDuration:0.3f animations:^{
                self.viewProgress.progress = 0;
                [_views[_nextView++] setAlpha:1];

                if (_nextView >= [_views count]) {
                    [_viewTimer invalidate];
                    self.viewProgress.hidden = YES;
                }
            }];
    }                                            repeats:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle {

    return UIStatusBarStyleLightContent;
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

    return [[NSUserDefaults standardUserDefaults] boolForKey:strf( @"%@.%ld.coached", self.coachedClass, (long)self.coachedVersion )];
}

- (void)setCoached:(BOOL)coached {

    [[NSUserDefaults standardUserDefaults] setBool:coached forKey:strf( @"%@.%ld.coached", self.coachedClass, (long)self.coachedVersion )];
}

@end

//==============================================================================
// This file is part of Master Password.
// Copyright (c) 2011-2017, Maarten Billemont.
//
// Master Password is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Master Password is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You can find a copy of the GNU General Public License in the
// LICENSE file.  Alternatively, see <http://www.gnu.org/licenses/>.
//==============================================================================

#import "MPCoachmarkViewController.h"

@interface MPCoachmarkViewController()

@property(nonatomic, strong) NSArray *views;
@property(nonatomic) NSUInteger nextView;
@property(nonatomic, weak) NSTimer *viewTimer;

@end

@implementation MPCoachmarkViewController

- (void)viewDidLoad {

    [super viewDidLoad];

    self.views = @[
            self.view0, self.view1, self.view2, self.view3, self.view4, self.view5, self.view6, self.view7, self.view8, self.view9
    ];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    self.viewProgress.visible = YES;
    self.viewProgress.progress = 0;
    [self.views makeObjectsPerformSelector:@selector( setVisible: ) withObject:@NO];
    self.nextView = 0;
}

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];

    [UIView animateWithDuration:0.3f animations:^{
        [self.views[self.nextView++] setVisible:YES];
    }];

    if (@available(iOS 10.0, *))
        self.viewTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer *timer) {
            self.viewProgress.progress += 1.0f / 50;
            
            if (self.viewProgress.progress == 1)
                [UIView animateWithDuration:0.3f animations:^{
                    self.viewProgress.progress = 0;
                    [self.views[self.nextView++] setVisible:YES];
                    
                    if (self.nextView >= [self.views count]) {
                        [self.viewTimer invalidate];
                        self.viewProgress.visible = NO;
                    }
                }];
        }];
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
    if (![[NSUserDefaults standardUserDefaults] synchronize])
        wrn( @"Couldn't synchronize after coachmark updates." );
}

@end

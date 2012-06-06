//
//  MPPreferencesViewController.m
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 04/06/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "MPPreferencesViewController.h"
#import "MPAppDelegate.h"

@interface MPPreferencesViewController ()

@end

@implementation MPPreferencesViewController
@synthesize avatarsView;
@synthesize avatarTemplate;
@synthesize savePasswordSwitch;
@synthesize exportCell;
@synthesize changeMPCell;


- (void)viewDidLoad {
    
    self.avatarTemplate.hidden = YES;

    for (int a = 0; a < MPAvatarCount; ++a) {
        UIButton *avatar = [self.avatarTemplate clone];
        avatar.togglesSelectionInSuperview = YES;
        avatar.tag = a;
        avatar.hidden = NO;
        avatar.center = CGPointMake(
                self.avatarTemplate.center.x * (a + 1) + self.avatarTemplate.bounds.size.width / 2 * a,
                self.avatarTemplate.center.y);
        [avatar setBackgroundImage:[UIImage imageNamed:PearlString(@"avatar-%d", a)]
                forState:UIControlStateNormal];

        avatar.layer.cornerRadius = avatar.bounds.size.height / 2;
        avatar.layer.shadowColor = [UIColor blackColor].CGColor;
        avatar.layer.shadowOpacity = 1;
        avatar.layer.shadowRadius = 5;
        avatar.backgroundColor = [UIColor clearColor];

        [avatar onHighlightOrSelect:^(BOOL highlighted, BOOL selected) {
            if (highlighted || selected)
                avatar.backgroundColor = self.avatarTemplate.backgroundColor;
            else
                avatar.backgroundColor = [UIColor clearColor];
        } options:0];
        [avatar onSelect:^(BOOL selected) {
            if (selected)
                [MPAppDelegate get].activeUser.avatar = (unsigned)avatar.tag;
        } options:0];
        avatar.selected = (a == [MPAppDelegate get].activeUser.avatar);
    }

    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [self.avatarsView autoSizeContent];
    [self.avatarsView enumerateSubviews:^(UIView *subview, BOOL *stop, BOOL *recurse) {
        if (subview.tag && ((UIControl *) subview).selected) {
            [self.avatarsView setContentOffset:CGPointMake(subview.center.x - self.avatarsView.bounds.size.width / 2, 0) animated:animated];
        }
    } recurse:NO];

    self.savePasswordSwitch.on = [MPAppDelegate get].activeUser.saveKey;
    
    [super viewWillAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidUnload {
    [self setAvatarsView:nil];
    [self setAvatarTemplate:nil];
    [self setAvatarsView:nil];
    [self setSavePasswordSwitch:nil];
    [self setExportCell:nil];
    [self setChangeMPCell:nil];
    [super viewDidUnload];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    if (cell == self.exportCell)
        [[MPAppDelegate get] export];

    else if (cell == self.changeMPCell)
        [[MPAppDelegate get] changeMP];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - IASKSettingsDelegate

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender {
    
    while ([self.navigationController.viewControllers containsObject:sender])
        [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - IBActions

- (IBAction)didToggleSwitch:(UISwitch *)sender {
    
    [MPAppDelegate get].activeUser.saveKey = sender.on;
}

@end

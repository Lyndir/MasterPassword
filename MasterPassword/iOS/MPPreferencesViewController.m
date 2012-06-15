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
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"

@interface MPPreferencesViewController ()

@end

@implementation MPPreferencesViewController
@synthesize avatarsView;
@synthesize avatarTemplate;
@synthesize savePasswordSwitch;
@synthesize exportCell;
@synthesize changeMPCell;
@synthesize defaultTypeLabel;


- (void)viewDidLoad {

    self.avatarTemplate.hidden = YES;

    for (int a = 0; a < MPAvatarCount; ++a) {
        UIButton *avatar = [self.avatarTemplate clone];
        avatar.tag                         = a;
        avatar.hidden                      = NO;
        avatar.center                      = CGPointMake(
         self.avatarTemplate.center.x * (a + 1) + self.avatarTemplate.bounds.size.width / 2 * a,
         self.avatarTemplate.center.y);
        [avatar setBackgroundImage:[UIImage imageNamed:PearlString(@"avatar-%d", a)]
                forState:UIControlStateNormal];
        [avatar setSelectionInSuperviewCandidate:YES isClearable:NO];

        avatar.layer.cornerRadius  = avatar.bounds.size.height / 2;
        avatar.layer.shadowColor   = [UIColor blackColor].CGColor;
        avatar.layer.shadowOpacity = 1;
        avatar.layer.shadowRadius  = 5;
        avatar.backgroundColor     = [UIColor clearColor];

        [avatar onHighlightOrSelect:^(BOOL highlighted, BOOL selected) {
            if (highlighted || selected)
                avatar.backgroundColor = self.avatarTemplate.backgroundColor;
            else
                avatar.backgroundColor = [UIColor clearColor];
        } options:0];
        [avatar onSelect:^(BOOL selected) {
            if (selected) {
                [MPAppDelegate get].activeUser.avatar = (unsigned)avatar.tag;
                [[MPAppDelegate get] saveContext];
            }
        } options:0];
        avatar.selected            = (a == [MPAppDelegate get].activeUser.avatar);
    }

    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {

    inf(@"Preferences will appear");
    [self.avatarsView autoSizeContent];
    [self.avatarsView enumerateSubviews:^(UIView *subview, BOOL *stop, BOOL *recurse) {
        if (subview.tag && ((UIControl *)subview).selected) {
            [self.avatarsView setContentOffset:CGPointMake(subview.center.x - self.avatarsView.bounds.size.width / 2, 0) animated:animated];
        }
    } recurse:NO];

    self.savePasswordSwitch.on = [MPAppDelegate get].activeUser.saveKey;
    self.defaultTypeLabel.text = NSStringShortFromMPElementType([MPAppDelegate get].activeUser.defaultType);

    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {

    inf(@"Preferences will disappear");
    [super viewWillDisappear:animated];
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
    [self setDefaultTypeLabel:nil];
    [super viewDidUnload];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {

    if ([[segue identifier] isEqualToString:@"MP_ChooseType"])
        ((MPTypeViewController *)[segue destinationViewController]).delegate = self;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    if (cell == self.exportCell)
        [[MPAppDelegate get] export];

    else
        if (cell == self.changeMPCell)
            [[MPAppDelegate get] changeMasterPasswordFor:[MPAppDelegate get].activeUser];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - IASKSettingsDelegate

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender {

    while ([self.navigationController.viewControllers containsObject:sender])
        [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - MPTypeDelegate

- (void)didSelectType:(MPElementType)type {

    [MPAppDelegate get].activeUser.defaultType = type;
    [[MPAppDelegate get] saveContext];

    self.defaultTypeLabel.text = NSStringShortFromMPElementType([MPAppDelegate get].activeUser.defaultType);
}

- (MPElementType)selectedType {

    return [MPAppDelegate get].activeUser.defaultType;
}

#pragma mark - IBActions

- (IBAction)didToggleSwitch:(UISwitch *)sender {

    if (([MPAppDelegate get].activeUser.saveKey = sender.on))
        [[MPAppDelegate get] storeSavedKeyFor:[MPAppDelegate get].activeUser];
    else
        [[MPAppDelegate get] forgetSavedKeyFor:[MPAppDelegate get].activeUser];
    [[MPAppDelegate get] saveContext];
}

- (IBAction)settings:(UIBarButtonItem *)sender {
    
    IASKAppSettingsViewController *vc = [IASKAppSettingsViewController new];
    vc.showDoneButton = NO;
    
    [self.navigationController pushViewController:vc animated:YES];
}

@end

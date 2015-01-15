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

#import "MPPasswordCell.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "UIColor+Expanded.h"
#import "MPAppDelegate_InApp.h"

@interface MPPasswordCell()

@property(nonatomic, strong) IBOutlet UILabel *siteNameLabel;
@property(nonatomic, strong) IBOutlet UITextField *passwordField;
@property(nonatomic, strong) IBOutlet UIView *loginNameContainer;
@property(nonatomic, strong) IBOutlet UITextField *loginNameField;
@property(nonatomic, strong) IBOutlet UILabel *strengthLabel;
@property(nonatomic, strong) IBOutlet UILabel *counterLabel;
@property(nonatomic, strong) IBOutlet UIButton *counterButton;
@property(nonatomic, strong) IBOutlet UIButton *upgradeButton;
@property(nonatomic, strong) IBOutlet UIButton *answersButton;
@property(nonatomic, strong) IBOutlet UIButton *modeButton;
@property(nonatomic, strong) IBOutlet UIButton *editButton;
@property(nonatomic, strong) IBOutlet UIScrollView *modeScrollView;
@property(nonatomic, strong) IBOutlet UIButton *contentButton;
@property(nonatomic, strong) IBOutlet UIButton *loginNameButton;
@property(nonatomic, strong) IBOutlet UIView *indicatorView;

@property(nonatomic) MPPasswordCellMode mode;
@property(nonatomic, copy) NSString *transientSite;

@end

@implementation MPPasswordCell {
    NSManagedObjectID *_siteOID;
}

#pragma mark - Life cycle

- (void)awakeFromNib {

    [super awakeFromNib];

    [self addGestureRecognizer:
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector( doRevealPassword: )]];
    [self.counterButton addGestureRecognizer:
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector( doResetCounter: )]];

    [self setupLayer];

    [self observeKeyPath:@"bounds" withBlock:^(id from, id to, NSKeyValueChange cause, MPPasswordCell *_self) {
        if (from && !CGSizeEqualToSize( [from CGRectValue].size, [to CGRectValue].size ))
            [_self setupLayer];
    }];
    [self.contentButton observeKeyPath:@"highlighted"
                             withBlock:^(id from, id to, NSKeyValueChange cause, UIButton *button) {
                                 [UIView animateWithDuration:.2f delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                                     button.layer.shadowOpacity = button.selected? 0.7f: button.highlighted? 0.3f: 0;
                                 }                completion:nil];
                             }];
    [self.contentButton observeKeyPath:@"selected"
                             withBlock:^(id from, id to, NSKeyValueChange cause, UIButton *button) {
                                 [UIView animateWithDuration:.2f delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                                     button.layer.shadowOpacity = button.selected? 0.7f: button.highlighted? 0.3f: 0;
                                 }                completion:nil];
                             }];
    [self.loginNameButton observeKeyPath:@"highlighted"
                               withBlock:^(id from, id to, NSKeyValueChange cause, UIButton *button) {
                                   [UIView animateWithDuration:.2f delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                                       button.backgroundColor = [button.backgroundColor colorWithAlphaComponent:
                                               button.selected || button.highlighted? 0.1f: 0];
                                       button.layer.shadowOpacity = button.selected? 0.7f: button.highlighted? 0.3f: 0;
                                   }                completion:nil];
                               }];
    [self.loginNameButton observeKeyPath:@"selected"
                               withBlock:^(id from, id to, NSKeyValueChange cause, UIButton *button) {
                                   [UIView animateWithDuration:.2f delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                                       button.backgroundColor = [button.backgroundColor colorWithAlphaComponent:
                                               button.selected || button.highlighted? 0.1f: 0];
                                       button.layer.shadowOpacity = button.selected? 0.7f: button.highlighted? 0.3f: 0;
                                   }                completion:nil];
                               }];

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.y"];
    animation.byValue = @(10);
    animation.repeatCount = HUGE_VALF;
    animation.autoreverses = YES;
    animation.duration = 0.3f;
    [self.indicatorView.layer addAnimation:animation forKey:@"bounce"];
}

- (void)setupLayer {

    self.contentView.frame = self.bounds;
    self.contentButton.layer.cornerRadius = 4;
    self.contentButton.layer.shadowOffset = CGSizeZero;
    self.contentButton.layer.shadowRadius = 5;
    self.contentButton.layer.shadowOpacity = 0;
    self.contentButton.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.contentButton.layer.borderWidth = 1;
    self.contentButton.layer.borderColor = [UIColor colorWithWhite:0.15f alpha:0.6f].CGColor;
    self.loginNameButton.layer.cornerRadius = 4;
    self.loginNameButton.layer.shadowOffset = CGSizeZero;
    self.loginNameButton.layer.shadowRadius = 5;
    self.loginNameButton.layer.shadowOpacity = 0;
    self.loginNameButton.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.contentView.layer.shadowRadius = 5;
    self.contentView.layer.shadowOpacity = 1;
    self.contentView.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.6f].CGColor;
    self.contentView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.contentView.bounds cornerRadius:4].CGPath;
    self.contentView.layer.masksToBounds = NO;
    self.contentView.clipsToBounds = NO;
    self.layer.masksToBounds = NO;
    self.clipsToBounds = NO;
}

- (void)prepareForReuse {

    [super prepareForReuse];

    _siteOID = nil;
    _fuzzyGroups = nil;
    self.transientSite = nil;
    self.mode = MPPasswordCellModePassword;
    [self updateAnimated:NO];
}

- (void)dealloc {

    [self removeKeyPathObservers];
    [self.contentButton removeKeyPathObservers];
    [self.loginNameButton removeKeyPathObservers];
}

#pragma mark - State

- (void)setFuzzyGroups:(NSArray *)fuzzyGroups {

    if (_fuzzyGroups == fuzzyGroups)
        return;
    _fuzzyGroups = fuzzyGroups;

    [self updateSiteName:[self siteInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]]];
}

- (void)setMode:(MPPasswordCellMode)mode animated:(BOOL)animated {

    if (mode == _mode)
        return;

    _mode = mode;
    [self updateAnimated:animated];
}

- (void)setSite:(MPSiteEntity *)site animated:(BOOL)animated {

    _siteOID = [site objectID];
    [self updateAnimated:animated];
}

- (void)setTransientSite:(NSString *)siteName animated:(BOOL)animated {

    self.transientSite = siteName;
    [self updateAnimated:animated];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    if (textField == self.passwordField)
        [self.loginNameField becomeFirstResponder];
    else
        [textField resignFirstResponder];

    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {

    UICollectionView *collectionView = [UICollectionView findAsSuperviewOf:self];
    [collectionView scrollToItemAtIndexPath:[collectionView indexPathForCell:self]
                           atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];

    if (textField == self.loginNameField)
        self.loginNameButton.titleLabel.alpha = [self.loginNameField.text length] || self.loginNameField.enabled? 0: 1;
}

- (IBAction)textFieldDidChange:(UITextField *)textField {

    if (textField == self.passwordField) {
        NSString *password = self.passwordField.text;
        [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            TimeToCrack timeToCrack;
            MPSiteEntity *site = [self siteInContext:context];
            id<MPAlgorithm> algorithm = site.algorithm?: MPAlgorithmDefault;
            MPAttacker attackHardware = [[MPConfig get].siteAttacker unsignedIntegerValue];
            if ([algorithm timeToCrack:&timeToCrack passwordOfType:[self siteInContext:context].type byAttacker:attackHardware] ||
                [algorithm timeToCrack:&timeToCrack passwordString:password byAttacker:attackHardware])
                PearlMainQueue( ^{
                    self.strengthLabel.text = NSStringFromTimeToCrack( timeToCrack );
                } );
        }];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {

    if (textField == self.passwordField || textField == self.loginNameField) {
        textField.enabled = NO;
        NSString *text = textField.text;

        [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            MPSiteEntity *site = [self siteInContext:context];
            if (!site)
                return;

            if (textField == self.passwordField) {
                if ([site.algorithm savePassword:text toSite:site usingKey:[MPiOSAppDelegate get].key])
                    [PearlOverlay showTemporaryOverlayWithTitle:@"Password Updated" dismissAfter:2];
            }
            else if (textField == self.loginNameField &&
                     ((site.loginGenerated && ![text length]) ||
                      (!site.loginGenerated && ![text isEqualToString:site.loginName]))) {
                if (site.loginGenerated || !([site.loginName isEqualToString:text] || (!text && !site.loginName))) {
                    site.loginGenerated = NO;
                    site.loginName = text;

                    if ([text length])
                        [PearlOverlay showTemporaryOverlayWithTitle:@"Login Name Saved" dismissAfter:2];
                    else
                        [PearlOverlay showTemporaryOverlayWithTitle:@"Login Name Cleared" dismissAfter:2];
                }
            }

            [context saveToStore];
            [self updateAnimated:YES];
        }];
    }
}

#pragma mark - Actions

- (IBAction)doDelete:(UIButton *)sender {

    MPSiteEntity *site = [self siteInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]];
    if (!site)
        return;

    [PearlSheet showSheetWithTitle:strf( @"Delete %@?", site.name ) viewStyle:UIActionSheetStyleAutomatic
                         initSheet:nil tappedButtonBlock:^(UIActionSheet *sheet, NSInteger buttonIndex) {
                if (buttonIndex == [sheet cancelButtonIndex])
                    return;

                [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPSiteEntity *site_ = [self siteInContext:context];
                    if (site_) {
                        [context deleteObject:site_];
                        [context saveToStore];
                    }
                }];
            }          cancelTitle:@"Cancel" destructiveTitle:@"Delete Site" otherTitles:nil];
}

- (IBAction)doChangeType:(UIButton *)sender {

    [self setMode:MPPasswordCellModePassword animated:YES];

    [PearlSheet showSheetWithTitle:@"Change Password Type" viewStyle:UIActionSheetStyleAutomatic
                         initSheet:^(UIActionSheet *sheet) {
                             MPSiteEntity *mainSite = [self siteInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]];
                             for (NSNumber *typeNumber in [MPAlgorithmDefault allTypes]) {
                                 MPSiteType type = (MPSiteType)[typeNumber unsignedIntegerValue];
                                 NSString *typeName = [MPAlgorithmDefault nameOfType:type];
                                 if (type == mainSite.type)
                                     [sheet addButtonWithTitle:strf( @"● %@", typeName )];
                                 else
                                     [sheet addButtonWithTitle:typeName];
                             }
                         } tappedButtonBlock:^(UIActionSheet *sheet, NSInteger buttonIndex) {
                if (buttonIndex == [sheet cancelButtonIndex])
                    return;

                MPSiteType type = (MPSiteType)[[MPAlgorithmDefault allTypes][buttonIndex] unsignedIntegerValue]?: MPSiteTypeGeneratedLong;

                [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPSiteEntity *site = [self siteInContext:context];
                    site = [[MPiOSAppDelegate get] changeSite:site saveInContext:context toType:type];
                    [self setSite:site animated:YES];
                }];
            }          cancelTitle:@"Cancel" destructiveTitle:nil otherTitles:nil];
}

- (IBAction)doEdit:(UIButton *)sender {

    self.loginNameField.enabled = YES;
    self.passwordField.enabled = YES;

    if ([self siteInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]].type & MPSiteTypeClassStored)
        [self.passwordField becomeFirstResponder];
    else
        [self.loginNameField becomeFirstResponder];
}

- (IBAction)doMode:(UIButton *)sender {

    switch (self.mode) {
        case MPPasswordCellModePassword:
            [self setMode:MPPasswordCellModeSettings animated:YES];
            break;
        case MPPasswordCellModeSettings:
            [self setMode:MPPasswordCellModePassword animated:YES];
            break;
    }
}

- (IBAction)doUpgrade:(UIButton *)sender {

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        if (![[self siteInContext:context] tryMigrateExplicitly:YES]) {
            [PearlOverlay showTemporaryOverlayWithTitle:@"Couldn't Upgrade Site" dismissAfter:2];
            return;
        }

        [context saveToStore];
        [PearlOverlay showTemporaryOverlayWithTitle:@"Site Upgraded" dismissAfter:2];
        [self updateAnimated:YES];
    }];
}

- (IBAction)doIncrementCounter:(UIButton *)sender {

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPSiteEntity *site = [self siteInContext:context];
        if (!site || ![site isKindOfClass:[MPGeneratedSiteEntity class]])
            return;

        ++((MPGeneratedSiteEntity *)site).counter;
        [context saveToStore];

        [PearlOverlay showTemporaryOverlayWithTitle:@"Generating New Password" dismissAfter:2];
        [self updateAnimated:YES];
    }];
}

- (IBAction)doRevealPassword:(UILongPressGestureRecognizer *)recognizer {

    if (recognizer.state != UIGestureRecognizerStateBegan)
        return;

    if (self.passwordField.secureTextEntry) {
        self.passwordField.secureTextEntry = NO;

        PearlMainQueueAfter( 3, ^{
            self.passwordField.secureTextEntry = [[MPiOSConfig get].hidePasswords boolValue];
        } );
    }
}

- (IBAction)doResetCounter:(UILongPressGestureRecognizer *)recognizer {

    if (recognizer.state != UIGestureRecognizerStateBegan)
        return;

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPSiteEntity *site = [self siteInContext:context];
        if (!site || ![site isKindOfClass:[MPGeneratedSiteEntity class]])
            return;

        ((MPGeneratedSiteEntity *)site).counter = 1;
        [context saveToStore];

        [PearlOverlay showTemporaryOverlayWithTitle:@"Counter Reset" dismissAfter:2];
        [self updateAnimated:YES];
    }];
}

- (IBAction)doContent:(id)sender {

    [UIView animateWithDuration:.2f animations:^{
        self.contentButton.selected = YES;
    }];

    if (self.transientSite) {
        [[UIResponder findFirstResponder] resignFirstResponder];
        [PearlAlert showAlertWithTitle:@"Create Site"
                               message:strf( @"Remember site named:\n%@", self.transientSite )
                             viewStyle:UIAlertViewStyleDefault
                             initAlert:nil tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                    if (buttonIndex == [alert cancelButtonIndex]) {
                        self.contentButton.selected = NO;
                        return;
                    }

                    [[MPiOSAppDelegate get]
                            addSiteNamed:self.transientSite completion:^(MPSiteEntity *site, NSManagedObjectContext *context) {
                        [self copyContentOfSite:site saveInContext:context];

                        PearlMainQueueAfter( .3f, ^{
                            [UIView animateWithDuration:.2f animations:^{
                                self.contentButton.selected = NO;
                            }];
                        } );
                    }];
                }          cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonYes, nil];
        return;
    }

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        [self copyContentOfSite:[self siteInContext:context] saveInContext:context];

        PearlMainQueueAfter( .3f, ^{
            [UIView animateWithDuration:.2f animations:^{
                self.contentButton.selected = NO;
            }];
        } );
    }];
}

- (IBAction)doLoginName:(id)sender {

    [UIView animateWithDuration:.2f animations:^{
        self.loginNameButton.selected = YES;
    }];

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPSiteEntity *site = [self siteInContext:context];
        if (![self copyLoginOfSite:site saveInContext:context]) {
            site.loginGenerated = YES;
            [context saveToStore];
            [PearlOverlay showTemporaryOverlayWithTitle:@"Login Name Generated" dismissAfter:2];
            [self updateAnimated:YES];
        }

        PearlMainQueueAfter( .3f, ^{
            [UIView animateWithDuration:.2f animations:^{
                self.loginNameButton.selected = NO;
            }];
        } );
    }];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

    if (roundf( (float)(scrollView.contentOffset.x / self.bounds.size.width) ) == 0.0f)
        [self setMode:MPPasswordCellModePassword animated:YES];
    else
        [self setMode:MPPasswordCellModeSettings animated:YES];
}

#pragma mark - Private

- (void)updateAnimated:(BOOL)animated {

    if (![NSThread isMainThread]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self updateAnimated:animated];
        }];
        return;
    }

    [UIView animateWithDuration:animated? .3f: 0 animations:^{
        MPSiteEntity *mainSite = [self siteInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]];

        // UI
        self.upgradeButton.gone = !mainSite.requiresExplicitMigration;
        self.answersButton.gone = ![[MPiOSAppDelegate get] isFeatureUnlocked:MPProductGenerateAnswers];
        BOOL settingsMode = self.mode == MPPasswordCellModeSettings;
        self.loginNameContainer.alpha = settingsMode || mainSite.loginGenerated || [mainSite.loginName length]? 0.7f: 0;
        self.loginNameField.textColor = [UIColor colorWithHexString:mainSite.loginGenerated? @"5E636D": @"6D5E63"];
        self.modeButton.alpha = self.transientSite? 0: settingsMode? 0.5f: 0.1f;
        self.counterLabel.alpha = self.counterButton.alpha = mainSite.type & MPSiteTypeClassGenerated? 0.5f: 0;
        self.modeButton.selected = settingsMode;
        self.strengthLabel.gone = !settingsMode;
        self.modeScrollView.scrollEnabled = !self.transientSite;
        [self.modeScrollView setContentOffset:CGPointMake( self.mode * self.modeScrollView.frame.size.width, 0 ) animated:animated];
        if (!settingsMode) {
            [self.loginNameField resignFirstResponder];
            [self.passwordField resignFirstResponder];
        }
        if ([[MPiOSAppDelegate get] isFeatureUnlocked:MPProductGenerateLogins])
            [self.loginNameButton setTitle:@"Tap to generate username or use pencil to save one" forState:UIControlStateNormal];
        else
            [self.loginNameButton setTitle:@"Tap the pencil to save a username" forState:UIControlStateNormal];

        // Site Name
        [self updateSiteName:mainSite];

        // Site Password
        self.passwordField.secureTextEntry = [[MPiOSConfig get].hidePasswords boolValue];
        self.passwordField.attributedPlaceholder = stra(
                mainSite.type & MPSiteTypeClassStored? strl( @"No password" ):
                mainSite.type & MPSiteTypeClassGenerated? strl( @"..." ): @"", @{
                NSForegroundColorAttributeName : [UIColor whiteColor]
        } );
        [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            MPSiteEntity *site = [self siteInContext:context];
            MPKey *key = [MPiOSAppDelegate get].key;
            if (!key)
                return;

            NSString *password, *loginName = [site resolveLoginUsingKey:key];
            if (self.transientSite)
                password = [MPAlgorithmDefault generatePasswordForSiteNamed:self.transientSite ofType:
                                [[MPiOSAppDelegate get] activeUserInContext:context].defaultType?: MPSiteTypeGeneratedLong
                                                                withCounter:1 usingKey:key];
            else if (site)
                password = [site resolvePasswordUsingKey:key];
            else
                return;

            TimeToCrack timeToCrack;
            NSString *timeToCrackString = nil;
            id<MPAlgorithm> algorithm = site.algorithm?: MPAlgorithmDefault;
            MPAttacker attackHardware = [[MPConfig get].siteAttacker integerValue];
            if ([algorithm timeToCrack:&timeToCrack passwordOfType:site.type byAttacker:attackHardware] ||
                [algorithm timeToCrack:&timeToCrack passwordString:password byAttacker:attackHardware])
                timeToCrackString = NSStringFromTimeToCrack( timeToCrack );

            PearlMainQueue( ^{
                self.loginNameField.text = loginName;
                self.passwordField.text = password;
                self.strengthLabel.text = timeToCrackString;
                self.loginNameButton.titleLabel.alpha = [loginName length] || self.loginNameField.enabled? 0: 1;

                if ([password length])
                    self.indicatorView.alpha = 0;
                else {
                    self.indicatorView.alpha = 1;
                    [self.indicatorView removeFromSuperview];
                    [self.modeScrollView addSubview:self.indicatorView];
                    [self.contentView addConstraintsWithVisualFormat:@"V:[indicator][target]" options:NSLayoutFormatAlignAllCenterX
                                                             metrics:nil views:@{
                                    @"indicator" : self.indicatorView,
                                    @"target"    : settingsMode? self.editButton: self.modeButton
                            }];
                }
            } );
        }];

        // Site Counter
        if ([mainSite isKindOfClass:[MPGeneratedSiteEntity class]])
            self.counterLabel.text = strf( @"%lu", (unsigned long)((MPGeneratedSiteEntity *)mainSite).counter );

        // Site Login Name
        self.loginNameField.enabled = self.passwordField.enabled = //
                [self.loginNameField isFirstResponder] || [self.passwordField isFirstResponder];

        [self.contentView layoutIfNeeded];
    }];
}

- (void)updateSiteName:(MPSiteEntity *)site {

    NSString *siteName = self.transientSite?: site.name;
    NSMutableAttributedString *attributedSiteName = [[NSMutableAttributedString alloc] initWithString:siteName?: @""];
    if ([attributedSiteName length])
        for (NSUInteger f = 0, s = (NSUInteger)-1; f < [self.fuzzyGroups count]; ++f) {
            s = [siteName rangeOfString:self.fuzzyGroups[f] options:NSDiacriticInsensitiveSearch | NSCaseInsensitiveSearch
                                  range:NSMakeRange( s + 1, [siteName length] - (s + 1) )].location;
            if (s == NSNotFound)
                break;

            [attributedSiteName addAttribute:NSBackgroundColorAttributeName value:[UIColor redColor]
                                       range:NSMakeRange( s, [self.fuzzyGroups[f] length] )];
        }

    [attributedSiteName appendAttributedString:stra(
            strf( @" - %@", self.transientSite? @"Tap to create": [site.algorithm shortNameOfType:site.type] ), @{ } )];
    self.siteNameLabel.attributedText = attributedSiteName;
}

- (BOOL)copyContentOfSite:(MPSiteEntity *)site saveInContext:(NSManagedObjectContext *)context {

    inf( @"Copying password for: %@", site.name );
    NSString *password = [site resolvePasswordUsingKey:[MPAppDelegate_Shared get].key];
    if (![password length])
        return NO;

    PearlMainQueue( ^{
        [PearlOverlay showTemporaryOverlayWithTitle:strl( @"Password Copied" ) dismissAfter:2];
        [UIPasteboard generalPasteboard].string = password;
    } );

    [site use];
    [context saveToStore];
    return YES;
}

- (BOOL)copyLoginOfSite:(MPSiteEntity *)site saveInContext:(NSManagedObjectContext *)context {

    inf( @"Copying login for: %@", site.name );
    NSString *loginName = [site.algorithm resolveLoginForSite:site usingKey:[MPiOSAppDelegate get].key];
    if (![loginName length])
        return NO;

    PearlMainQueue( ^{
        [PearlOverlay showTemporaryOverlayWithTitle:strl( @"Login Name Copied" ) dismissAfter:2];
        [UIPasteboard generalPasteboard].string = loginName;
    } );

    [site use];
    [context saveToStore];
    return YES;
}

- (MPSiteEntity *)siteInContext:(NSManagedObjectContext *)context {

    return [MPSiteEntity existingObjectWithID:_siteOID inContext:context];
}

@end

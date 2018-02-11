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

#import "MPSiteCell.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "MPAppDelegate_InApp.h"

@interface MPSiteCell()

@property(nonatomic, strong) IBOutlet UILabel *siteNameLabel;
@property(nonatomic, strong) IBOutlet UITextField *passwordField;
@property(nonatomic, strong) IBOutlet UIView *loginNameContainer;
@property(nonatomic, strong) IBOutlet UITextField *loginNameField;
@property(nonatomic, strong) IBOutlet UILabel *loginNameGenerated;
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
@property(nonatomic, strong) IBOutlet UILabel *loginNameHint;
@property(nonatomic, strong) IBOutlet UIView *indicatorView;

@property(nonatomic) MPSiteCellMode mode;
@property(nonatomic, copy) NSString *transientSite;
@property(nonatomic, strong) NSManagedObjectID *siteOID;

@end

@implementation MPSiteCell

#pragma mark - Life cycle

- (void)awakeFromNib {

    [super awakeFromNib];

    [self addGestureRecognizer:
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector( doRevealPassword: )]];
    [self.counterButton addGestureRecognizer:
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector( doResetCounter: )]];
    [self.upgradeButton addGestureRecognizer:
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector( doDowngrade: )]];

    [self setupLayer];

    [self observeKeyPath:@"bounds" withBlock:^(id from, id to, NSKeyValueChange cause, MPSiteCell *self) {
        if (from && !CGSizeEqualToSize( [from CGRectValue].size, [to CGRectValue].size ))
            [self setupLayer];
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

    self.siteOID = nil;
    self.fuzzyGroups = nil;
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

    if (self.fuzzyGroups == fuzzyGroups)
        return;
    _fuzzyGroups = fuzzyGroups;

    [self updateSiteName:[self siteInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]]];
}

- (void)setMode:(MPSiteCellMode)mode animated:(BOOL)animated {

    if (self.mode == mode)
        return;
    _mode = mode;

    [self updateAnimated:animated];
}

- (void)setSite:(MPSiteEntity *)site animated:(BOOL)animated {

    self.siteOID = site.permanentObjectID;
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
        self.loginNameHint.hidden = [self.loginNameField.attributedText length] || self.loginNameField.enabled;
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
        NSString *text = [textField.attributedText string]?: textField.text;

        [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            MPSiteEntity *site = [self siteInContext:context];
            if (!site)
                return;

            if (textField == self.passwordField) {
                if ([site.algorithm savePassword:text toSite:site usingKey:[MPiOSAppDelegate get].key])
                    [PearlOverlay showTemporaryOverlayWithTitle:@"Password Updated" dismissAfter:2];
            }
            else if (textField == self.loginNameField) {
                if (![text isEqualToString:[site.algorithm resolveLoginForSite:site usingKey:[MPiOSAppDelegate get].key]]) {
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

    MPSiteEntity *mainSite = [self siteInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]];
    [PearlSheet showSheetWithTitle:@"Change Password Type" viewStyle:UIActionSheetStyleAutomatic
                         initSheet:^(UIActionSheet *sheet) {
                             for (NSNumber *typeNumber in [mainSite.algorithm allTypes]) {
                                 MPResultType type = (MPResultType)[typeNumber unsignedIntegerValue];
                                 NSString *typeName = [mainSite.algorithm nameOfType:type];
                                 if (type == mainSite.type)
                                     [sheet addButtonWithTitle:strf( @"● %@", typeName )];
                                 else
                                     [sheet addButtonWithTitle:typeName];
                             }
                         } tappedButtonBlock:^(UIActionSheet *sheet, NSInteger buttonIndex) {
                if (buttonIndex == [sheet cancelButtonIndex])
                    return;

                MPResultType type = (MPResultType)[[mainSite.algorithm allTypes][buttonIndex] unsignedIntegerValue]?:
                                  mainSite.user.defaultType?: mainSite.algorithm.defaultType;

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

    if ([self siteInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]].type & MPResultTypeClassStateful)
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
        MPSiteEntity *siteEntity = [self siteInContext:context];
        if (![siteEntity tryMigrateExplicitly:YES]) {
            [PearlOverlay showTemporaryOverlayWithTitle:@"Couldn't Upgrade Site" dismissAfter:2];
            return;
        }

        [context saveToStore];
        [PearlOverlay showTemporaryOverlayWithTitle:strf( @"Site Upgraded to V%d", siteEntity.algorithm.version )
                                       dismissAfter:2];
        [self updateAnimated:YES];
    }];
}

- (IBAction)doDowngrade:(UILongPressGestureRecognizer *)recognizer {

    if (recognizer.state != UIGestureRecognizerStateBegan)
        return;

    if (![[MPiOSConfig get].allowDowngrade boolValue])
        return;

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        MPSiteEntity *siteEntity = [self siteInContext:context];
        if (siteEntity.algorithm.version <= 0)
            return;

        siteEntity.algorithm = MPAlgorithmForVersion( siteEntity.algorithm.version - 1 );
        [context saveToStore];
        [PearlOverlay showTemporaryOverlayWithTitle:strf( @"Site Downgraded to V%d", siteEntity.algorithm.version )
                                       dismissAfter:2];
        [self updateAnimated:YES];
    }];
}

- (IBAction)doAction:(UIButton *)sender {

    [MPiOSAppDelegate managedObjectContextForMainThreadPerformBlock:^(NSManagedObjectContext *mainContext) {
        MPSiteEntity *mainSite = [self siteInContext:mainContext];
        [PearlAlert showAlertWithTitle:@"Login Page" message:nil
                             viewStyle:UIAlertViewStylePlainTextInput
                             initAlert:^(UIAlertView *alert, UITextField *firstField) {
                                 firstField.placeholder = strf( @"Login URL for %@", mainSite.name );
                                 firstField.text = mainSite.url;
                             }
                     tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                         if (buttonIndex == alert.cancelButtonIndex)
                             return;

                         [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                             MPSiteEntity *site = [self siteInContext:context];
                             NSURL *url = [NSURL URLWithString:[alert textFieldAtIndex:0].text];
                             site.url = [url.host? url: nil absoluteString];
                             [context saveToStore];
                         }];
                     }
                           cancelTitle:@"Cancel" otherTitles:@"Save", nil];
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

    Weakify( self );
    if (![NSThread isMainThread]) {
        PearlMainQueueOperation( ^{
            Strongify( self );
            [self updateAnimated:animated];
        } );
        return;
    }

    [UIView animateWithDuration:animated? .3f: 0 animations:^{
        MPSiteEntity *mainSite = [self siteInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]];

        // UI
        //self.backgroundColor = mainSite.url? [UIColor greenColor]: [UIColor redColor];
        self.upgradeButton.gone = !mainSite.requiresExplicitMigration && ![[MPiOSConfig get].allowDowngrade boolValue];
        self.answersButton.gone = ![[MPiOSAppDelegate get] isFeatureUnlocked:MPProductGenerateAnswers];
        BOOL settingsMode = self.mode == MPPasswordCellModeSettings;
        self.loginNameContainer.visible = settingsMode || mainSite.loginGenerated || [mainSite.loginName length];
        self.modeButton.visible = !self.transientSite;
        self.modeButton.alpha = settingsMode? 0.5f: 0.1f;
        self.counterLabel.visible = self.counterButton.visible = mainSite.type & MPResultTypeClassTemplate;
        self.modeButton.selected = settingsMode;
        self.strengthLabel.gone = !settingsMode;
        self.modeScrollView.scrollEnabled = !self.transientSite;
        [self.modeScrollView setContentOffset:CGPointMake( self.mode * self.modeScrollView.frame.size.width, 0 ) animated:animated];
        if (!settingsMode) {
            [self.loginNameField resignFirstResponder];
            [self.passwordField resignFirstResponder];
        }
        if ([[MPiOSAppDelegate get] isFeatureUnlocked:MPProductGenerateLogins])
            self.loginNameHint.text = @"Tap here to ⚙ generate username or the pencil to type one";
        else
            self.loginNameHint.text = @"Tap the pencil to type a username";

        // Site Name
        [self updateSiteName:mainSite];

        // Site Counter
        if ([mainSite isKindOfClass:[MPGeneratedSiteEntity class]])
            self.counterLabel.text = strf( @"%lu", (unsigned long)((MPGeneratedSiteEntity *)mainSite).counter );

        // Site Login Name
        self.loginNameField.enabled = self.passwordField.enabled = //
                [self.loginNameField isFirstResponder] || [self.passwordField isFirstResponder];

        // Site Password
        self.passwordField.secureTextEntry = [[MPiOSConfig get].hidePasswords boolValue];
        self.passwordField.attributedPlaceholder = stra(
                mainSite.type & MPResultTypeClassStateful? strl( @"No password" ):
                mainSite.type & MPResultTypeClassTemplate? strl( @"..." ): @"", @{
                        NSForegroundColorAttributeName: [UIColor whiteColor]
                } );

        // Calculate Fields
        if (![MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            MPKey *key = [MPiOSAppDelegate get].key;
            if (!key) {
                wrn( @"Could not load cell content: key unavailable." );
                PearlMainQueueOperation( ^{
                    Strongify( self );
                    [self updateAnimated:YES];
                } );
                return;
            }

            MPSiteEntity *site = [self siteInContext:context];
            BOOL loginGenerated = site.loginGenerated;
            NSString *password = nil, *loginName = [site resolveLoginUsingKey:key];
            MPResultType transientType = [[MPiOSAppDelegate get] activeUserInContext:context].defaultType?: MPAlgorithmDefault.defaultType;
            if (self.transientSite && transientType & MPResultTypeClassTemplate)
                password = [MPAlgorithmDefault mpwTemplateForSiteNamed:self.transientSite ofType:transientType
                                                           withCounter:1 usingKey:key];
            else if (site)
                password = [site resolvePasswordUsingKey:key];

            TimeToCrack timeToCrack;
            NSString *timeToCrackString = nil;
            id<MPAlgorithm> algorithm = site.algorithm?: MPAlgorithmDefault;
            MPAttacker attackHardware = [[MPConfig get].siteAttacker integerValue];
            if ([algorithm timeToCrack:&timeToCrack passwordOfType:site.type byAttacker:attackHardware] ||
                [algorithm timeToCrack:&timeToCrack passwordString:password byAttacker:attackHardware])
                timeToCrackString = NSStringFromTimeToCrack( timeToCrack );

            BOOL requiresExplicitMigration = site.requiresExplicitMigration;

            PearlMainQueue( ^{
                self.passwordField.text = password;
                self.strengthLabel.text = timeToCrackString;
                self.loginNameGenerated.hidden = !loginGenerated;
                self.loginNameField.attributedText =
                        strarm( stra( loginName?: @"", self.siteNameLabel.textAttributes ), NSParagraphStyleAttributeName, nil );
                self.loginNameHint.hidden = [loginName length] || self.loginNameField.enabled;

                if (![password length]) {
                    self.indicatorView.hidden = NO;
                    [self.indicatorView removeFromSuperview];
                    [self.modeScrollView addSubview:self.indicatorView];
                    [self.contentView addConstraintsWithVisualFormat:@"V:[indicator][target]" options:NSLayoutFormatAlignAllCenterX
                                                             metrics:nil views:@{
                                    @"indicator": self.indicatorView,
                                    @"target"   : settingsMode? self.editButton: self.modeButton
                            }];
                }
                else if (requiresExplicitMigration) {
                    self.indicatorView.hidden = NO;
                    [self.indicatorView removeFromSuperview];
                    [self.modeScrollView addSubview:self.indicatorView];
                    [self.contentView addConstraintsWithVisualFormat:@"V:[indicator][target]" options:NSLayoutFormatAlignAllCenterX
                                                             metrics:nil views:@{
                                    @"indicator": self.indicatorView,
                                    @"target"   : settingsMode? self.upgradeButton: self.modeButton
                            }];
                }
                else
                    self.indicatorView.hidden = YES;
            } );
        }]) {
            wrn( @"Could not load cell content: store unavailable." );
            PearlMainQueueOperation( ^{
                Strongify( self );
                [self updateAnimated:YES];
            } );
        }

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

    if (self.transientSite)
        [attributedSiteName appendAttributedString:stra( @" – Tap to create", @{} )];

    self.siteNameLabel.attributedText = attributedSiteName;
}

- (BOOL)copyContentOfSite:(MPSiteEntity *)site saveInContext:(NSManagedObjectContext *)context {

    inf( @"Copying password for: %@", site.name );
    NSString *password = [site resolvePasswordUsingKey:[MPAppDelegate_Shared get].key];
    if (![password length])
        return NO;

    PearlMainQueue( ^{
        [self.window endEditing:YES];

        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        if (@available(iOS 10.0, *)) {
            [pasteboard setItems:@[ @{ UIPasteboardTypeAutomatic: password } ]
                         options:@{
                                 UIPasteboardOptionLocalOnly     : @NO,
                                 UIPasteboardOptionExpirationDate: [NSDate dateWithTimeIntervalSinceNow:3 * 60]
                         }];
            [PearlOverlay showTemporaryOverlayWithTitle:strl( @"Password Copied (3 min)" ) dismissAfter:2];
        }
        else {
            pasteboard.string = password;
            [PearlOverlay showTemporaryOverlayWithTitle:strl( @"Password Copied" ) dismissAfter:2];
        }
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
        [self.window endEditing:YES];

        [UIPasteboard generalPasteboard].string = loginName;
        [PearlOverlay showTemporaryOverlayWithTitle:strl( @"Login Name Copied" ) dismissAfter:2];
    } );

    [site use];
    [context saveToStore];
    return YES;
}

- (MPSiteEntity *)siteInContext:(NSManagedObjectContext *)context {

    return [MPSiteEntity existingObjectWithID:self.siteOID inContext:context];
}

@end

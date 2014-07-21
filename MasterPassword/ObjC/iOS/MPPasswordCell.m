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


//    return [[MPiOSAppDelegate get] changeElement:element saveInContext:context toType:self.type];


@interface MPPasswordCell()

@property(nonatomic, strong) IBOutlet UILabel *siteNameLabel;
@property(nonatomic, strong) IBOutlet UITextField *passwordField;
@property(nonatomic, strong) IBOutlet UITextField *loginNameField;
@property(nonatomic, strong) IBOutlet UIPageControl *pageControl;
@property(nonatomic, strong) IBOutlet UILabel *strengthLabel;
@property(nonatomic, strong) IBOutlet UILabel *counterLabel;
@property(nonatomic, strong) IBOutlet UIButton *counterButton;
@property(nonatomic, strong) IBOutlet UIButton *upgradeButton;
@property(nonatomic, strong) IBOutlet UIButton *modeButton;
@property(nonatomic, strong) IBOutlet UIButton *passwordEditButton;
@property(nonatomic, strong) IBOutlet UIButton *usernameEditButton;
@property(nonatomic, strong) IBOutlet UIScrollView *modeScrollView;
@property(nonatomic, strong) IBOutlet UIButton *selectionButton;

@property(nonatomic) MPPasswordCellMode mode;
@property(nonatomic, copy) NSString *transientSite;

@end

@implementation MPPasswordCell {
    NSManagedObjectID *_elementOID;
}

#pragma mark - Life cycle

- (void)awakeFromNib {

    [super awakeFromNib];

    [self addGestureRecognizer:
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector( doRevealPassword: )]];
    [self.counterButton addGestureRecognizer:
            [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector( doResetCounter: )]];

    self.selectionButton.layer.cornerRadius = 5;
    self.selectionButton.layer.shadowOffset = CGSizeZero;
    self.selectionButton.layer.shadowRadius = 5;
    self.selectionButton.layer.shadowOpacity = 0;
    self.selectionButton.layer.shadowColor = [UIColor whiteColor].CGColor;

    self.pageControl.transform = CGAffineTransformMakeScale( 0.4f, 0.4f );

    [self.selectionButton observeKeyPath:@"highlighted"
               withBlock:^(id from, id to, NSKeyValueChange cause, UIButton *button) {
        button.layer.shadowOpacity = button.selected? 1: button.highlighted? 0.3f: 0;
    }];
    [self.selectionButton observeKeyPath:@"selected"
               withBlock:^(id from, id to, NSKeyValueChange cause, UIButton *button) {
        button.layer.shadowOpacity = button.selected? 1: button.highlighted? 0.3f: 0;
    }];
}

// Unblocks animations for all CALayer properties (eg. shadowOpacity)
- (id<CAAction>)actionForLayer:(CALayer *)layer forKey:(NSString *)event {

    id<CAAction> defaultAction = [super actionForLayer:layer forKey:event];
    if (defaultAction == (id)[NSNull null] && [event isEqualToString:@"position"])
        return defaultAction;

    return NSNullToNil( defaultAction );
}

#pragma mark - State

- (void)setMode:(MPPasswordCellMode)mode animated:(BOOL)animated {

    if (mode == _mode)
        return;

    _mode = mode;
    [self updateAnimated:animated];
}

- (void)setElement:(MPElementEntity *)element animated:(BOOL)animated {

    _elementOID = [element objectID];
    [self updateAnimated:animated];
}

- (void)setTransientSite:(NSString *)siteName animated:(BOOL)animated {

    self.transientSite = siteName;
    [self updateAnimated:animated];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {

    UICollectionView *collectionView = [UICollectionView findAsSuperviewOf:self];
    [collectionView scrollToItemAtIndexPath:[collectionView indexPathForCell:self]
                           atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {

    if (textField == self.passwordField) {
        NSString *text = textField.text;
        textField.enabled = NO;

        [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            MPElementEntity *element = [self elementInContext:context];
            if (!element)
                return;

            if (textField == self.passwordField) {
                [element.algorithm saveContent:text toElement:element usingKey:[MPiOSAppDelegate get].key];
                [PearlOverlay showTemporaryOverlayWithTitle:@"Password Updated" dismissAfter:2];
            }
            else if (textField == self.loginNameField) {
                element.loginName = text;
                [PearlOverlay showTemporaryOverlayWithTitle:@"Login Updated" dismissAfter:2];
            }

            [context saveToStore];
            [self updateAnimated:YES];
        }];
    }
}

#pragma mark - Actions

- (IBAction)doEditPassword:(UIButton *)sender {

    self.passwordField.enabled = YES;
    [self.passwordField becomeFirstResponder];
}

- (IBAction)doEditLoginName:(UIButton *)sender {

    self.loginNameField.enabled = YES;
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

    [self updateAnimated:YES];
}

- (IBAction)doUpgrade:(UIButton *)sender {

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        if (![[self elementInContext:context] migrateExplicitly:YES]) {
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
        MPElementEntity *element = [self elementInContext:context];
        if (!element || ![element isKindOfClass:[MPElementGeneratedEntity class]])
            return;

        ++((MPElementGeneratedEntity *)element).counter;
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
        MPElementEntity *element = [self elementInContext:context];
        if (!element || ![element isKindOfClass:[MPElementGeneratedEntity class]])
            return;

        ((MPElementGeneratedEntity *)element).counter = 1;
        [context saveToStore];

        [PearlOverlay showTemporaryOverlayWithTitle:@"Counter Reset" dismissAfter:2];
        [self updateAnimated:YES];
    }];
}

- (IBAction)doUse:(id)sender {

    self.selectionButton.selected = YES;

    if (self.transientSite) {
        [[UIResponder findFirstResponder] resignFirstResponder];
        [PearlAlert showAlertWithTitle:@"Create Site"
                               message:strf( @"Remember site named:\n%@", self.transientSite )
                             viewStyle:UIAlertViewStyleDefault
                             initAlert:nil tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
            if (buttonIndex == [alert cancelButtonIndex]) {
                self.selectionButton.selected = NO;
                return;
            }

            [[MPiOSAppDelegate get]
                    addElementNamed:self.transientSite completion:^(MPElementEntity *element, NSManagedObjectContext *context) {
                [self copyContentOfElement:element saveInContext:context];
                PearlMainQueue( ^{
                    self.selectionButton.selected = NO;
                } );
            }];
        }                  cancelTitle:[PearlStrings get].commonButtonCancel otherTitles:[PearlStrings get].commonButtonYes, nil];
        return;
    }

    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        [self copyContentOfElement:[self elementInContext:context] saveInContext:context];
        PearlMainQueue( ^{
            self.selectionButton.selected = NO;
        } );
    }];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

    if (roundf( scrollView.contentOffset.x / self.bounds.size.width ) == 0.0f)
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

    [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
        MPElementEntity *mainElement = [self elementInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]];

        // UI
        self.selectionButton.layer.shadowOpacity = self.selectionButton.selected? 1: self.selectionButton.highlighted? 0.3f: 0;
        self.upgradeButton.alpha = mainElement.requiresExplicitMigration? 1: 0;
        self.passwordEditButton.alpha = self.transientSite || mainElement.type & MPElementTypeClassGenerated? 0: 1;
        self.modeButton.alpha = self.transientSite? 0: 1;
        self.counterLabel.alpha = self.counterButton.alpha = mainElement.type & MPElementTypeClassGenerated? 1: 0;
        self.modeButton.selected = self.mode == MPPasswordCellModeSettings;
        self.pageControl.currentPage = self.mode == MPPasswordCellModePassword? 0: 1;
        [self.modeScrollView setContentOffset:CGPointMake( self.mode * self.modeScrollView.frame.size.width, 0 ) animated:YES];

        // Site Name
        self.siteNameLabel.text = strl( @"%@ - %@", self.transientSite?: mainElement.name,
                self.transientSite? @"Tap to create": [mainElement.algorithm shortNameOfType:mainElement.type] );

        // Site Password
        self.passwordField.enabled = NO;
        self.passwordField.secureTextEntry = [[MPiOSConfig get].hidePasswords boolValue];
        self.passwordField.attributedPlaceholder = stra(
                mainElement.type & MPElementTypeClassStored? strl( @"Set custom password" ):
                mainElement.type & MPElementTypeClassGenerated? strl( @"Generating..." ): @"", @{
                        NSForegroundColorAttributeName : [UIColor whiteColor]
                } );
        [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            NSString *password;
            if (self.transientSite)
                password = [MPAlgorithmDefault generateContentNamed:self.transientSite ofType:
                        [[MPiOSAppDelegate get] activeUserInContext:context].defaultType?: MPElementTypeGeneratedLong
                                                        withCounter:1 usingKey:[MPiOSAppDelegate get].key];
            else
                password = [[self elementInContext:context] resolveContentUsingKey:[MPiOSAppDelegate get].key];

            PearlMainQueue( ^{
                self.passwordField.text = password;
            } );
        }];

        // Site Counter
        if ([mainElement isKindOfClass:[MPElementGeneratedEntity class]])
            self.counterLabel.text = strf( @"%lu", (unsigned long)((MPElementGeneratedEntity *)mainElement).counter );

        // Site Login Name
        self.loginNameField.enabled = NO;
        self.loginNameField.text = mainElement.loginName;
        self.loginNameField.attributedPlaceholder = stra( strl( @"Set login name" ), @{
                NSForegroundColorAttributeName : [UIColor whiteColor]
        } );

        // Strength Label
//#warning TODO
    }];
}

- (void)copyContentOfElement:(MPElementEntity *)element saveInContext:(NSManagedObjectContext *)context {

    // Copy content.
    switch (self.mode) {
        case MPPasswordCellModePassword: {
            inf( @"Copying password for: %@", element.name );
            NSString *password = [element resolveContentUsingKey:[MPAppDelegate_Shared get].key];
            if (![password length])
                return;

            PearlMainQueue( ^{
                [PearlOverlay showTemporaryOverlayWithTitle:strl( @"Password Copied" ) dismissAfter:2];
                [UIPasteboard generalPasteboard].string = password;
            } );

            [element use];
            [context saveToStore];
            break;
        }
        case MPPasswordCellModeSettings: {
            inf( @"Copying login for: %@", element.name );
            NSString *loginName = element.loginName;
            if (![loginName length])
                return;

            PearlMainQueue( ^{
                [PearlOverlay showTemporaryOverlayWithTitle:strl( @"Login Name Copied" ) dismissAfter:2];
                [UIPasteboard generalPasteboard].string = loginName;
            } );

            [element use];
            [context saveToStore];
            break;
        }
    }
}

- (MPElementEntity *)elementInContext:(NSManagedObjectContext *)context {

    return [MPElementEntity existingObjectWithID:_elementOID inContext:context];
}

@end

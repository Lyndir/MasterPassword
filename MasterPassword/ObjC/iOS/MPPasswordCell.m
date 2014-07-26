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
@property(nonatomic, strong) IBOutlet UIButton *loginModeButton;
@property(nonatomic, strong) IBOutlet UIButton *editButton;
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

- (void)prepareForReuse {

    [super prepareForReuse];

    _elementOID = nil;
    self.loginModeButton.selected = NO;
    self.mode = MPPasswordCellModePassword;
    [self updateAnimated:NO];
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

- (IBAction)textFieldDidChange:(UITextField *)textField {

    if (textField == self.passwordField) {
        NSString *password = self.passwordField.text;
        [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            TimeToCrack timeToCrack;
            MPElementEntity *element = [self elementInContext:context];
            id<MPAlgorithm> algorithm = element.algorithm?: MPAlgorithmDefault;
            MPAttacker attackHardware = [[MPConfig get].attackHardware unsignedIntegerValue];
            if ([algorithm timeToCrack:&timeToCrack passwordOfType:[self elementInContext:context].type byAttacker:attackHardware] ||
                [algorithm timeToCrack:&timeToCrack passwordString:password byAttacker:attackHardware])
                PearlMainQueue( ^{
                    self.strengthLabel.text = NSStringFromTimeToCrack( timeToCrack );
                } );
        }];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {

    if (textField == self.passwordField || textField == self.loginNameField) {
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

- (IBAction)doLoginMode:(UIButton *)sender {

    self.loginModeButton.selected = !self.loginModeButton.selected;
    [self updateAnimated:YES];
}

- (IBAction)doDelete:(UIButton *)sender {

    MPElementEntity *element = [self elementInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]];
    if (!element)
        return;

    [PearlSheet showSheetWithTitle:strf( @"Delete %@?", element.name ) viewStyle:UIActionSheetStyleAutomatic
                         initSheet:nil tappedButtonBlock:^(UIActionSheet *sheet, NSInteger buttonIndex) {
        if (buttonIndex == [sheet cancelButtonIndex])
            return;

        [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            [context deleteObject:[self elementInContext:context]];
            [context saveToStore];
        }];
    }                  cancelTitle:@"Cancel" destructiveTitle:@"Delete Site" otherTitles:nil];
}

- (IBAction)doChangeType:(UIButton *)sender {

    [self setMode:MPPasswordCellModePassword animated:YES];

    [PearlSheet showSheetWithTitle:@"Change Password Type" viewStyle:UIActionSheetStyleAutomatic
                         initSheet:^(UIActionSheet *sheet) {
        MPElementEntity *mainElement = [self elementInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]];
        for (NSNumber *typeNumber in [MPAlgorithmDefault allTypes]) {
            MPElementType type = [typeNumber unsignedIntegerValue];
            NSString *typeName = [MPAlgorithmDefault nameOfType:type];
            if (type == mainElement.type)
                [sheet addButtonWithTitle:strf( @"● %@", typeName )];
            else
                [sheet addButtonWithTitle:typeName];
        }
    } tappedButtonBlock:^(UIActionSheet *sheet, NSInteger buttonIndex) {
        if (buttonIndex == [sheet cancelButtonIndex])
            return;

        MPElementType type = [[MPAlgorithmDefault allTypes][buttonIndex] unsignedIntegerValue]?: MPElementTypeGeneratedLong;

        [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
            MPElementEntity *element = [self elementInContext:context];
            element = [[MPiOSAppDelegate get] changeElement:element saveInContext:context toType:type];
            [self setElement:element animated:YES];
        }];
    }                  cancelTitle:@"Cancel" destructiveTitle:nil otherTitles:nil];
}

- (IBAction)doEdit:(UIButton *)sender {

    if (self.loginModeButton.selected) {
        self.loginNameField.enabled = YES;
        [self.loginNameField becomeFirstResponder];
    }
    else if ([self elementInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]].type & MPElementTypeClassStored) {
        self.passwordField.enabled = YES;
        [self.passwordField becomeFirstResponder];
    }
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

    [UIView animateWithDuration:animated? 0.3f: 0 animations:^{
        MPElementEntity *mainElement = [self elementInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]];

        // UI
        self.selectionButton.layer.shadowOpacity = self.selectionButton.selected? 1: self.selectionButton.highlighted? 0.3f: 0;
        self.upgradeButton.alpha = mainElement.requiresExplicitMigration? 1: 0;
        self.passwordField.alpha = self.loginModeButton.selected? 0: 1;
        self.loginNameField.alpha = self.loginModeButton.selected? 1: 0;
        self.modeButton.alpha = self.transientSite? 0: 1;
        self.counterLabel.alpha = self.counterButton.alpha = mainElement.type & MPElementTypeClassGenerated? 1: 0;
        self.modeButton.selected = self.mode == MPPasswordCellModeSettings;
        self.pageControl.currentPage = self.mode == MPPasswordCellModePassword? 0: 1;
        self.strengthLabel.alpha = self.mode == MPPasswordCellModePassword? 0: 1;
        self.editButton.enabled = self.loginModeButton.selected || mainElement.type & MPElementTypeClassStored;
        [self.modeScrollView setContentOffset:CGPointMake( self.mode * self.modeScrollView.frame.size.width, 0 ) animated:animated];

        // Site Name
        self.siteNameLabel.text = strl( @"%@ - %@", self.transientSite?: mainElement.name,
                self.transientSite? @"Tap to create": [mainElement.algorithm shortNameOfType:mainElement.type] );

        // Site Password
        self.passwordField.enabled = NO;
        self.passwordField.secureTextEntry = [[MPiOSConfig get].hidePasswords boolValue];
        self.passwordField.attributedPlaceholder = stra(
                mainElement.type & MPElementTypeClassStored? strl( @"No password" ):
                mainElement.type & MPElementTypeClassGenerated? strl( @"..." ): @"", @{
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

            MPAttacker attackHardware = [[MPConfig get].attackHardware unsignedIntegerValue];
            TimeToCrack timeToCrack;
            NSString *timeToCrackString = nil;
            id<MPAlgorithm> algorithm = mainElement.algorithm?: MPAlgorithmDefault;
            if ([algorithm timeToCrack:&timeToCrack passwordOfType:[self elementInContext:context].type byAttacker:attackHardware] ||
                [algorithm timeToCrack:&timeToCrack passwordString:password byAttacker:attackHardware])
                timeToCrackString = NSStringFromTimeToCrack( timeToCrack );

            PearlMainQueue( ^{
                self.passwordField.text = password;
                self.strengthLabel.text = timeToCrackString;
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
    }];
}

- (void)copyContentOfElement:(MPElementEntity *)element saveInContext:(NSManagedObjectContext *)context {

    // Copy content.
    if (self.loginModeButton.selected) {
        // Login Mode
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
    }
    else {
        // Password Mode
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
    }
}

- (MPElementEntity *)elementInContext:(NSManagedObjectContext *)context {

    return [MPElementEntity existingObjectWithID:_elementOID inContext:context];
}

@end

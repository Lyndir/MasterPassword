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

#import "MPAnswersViewController.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Store.h"
#import "MPOverlayViewController.h"

@interface MPAnswersViewController()

@property(nonatomic, strong) NSManagedObjectID *siteOID;
@property(nonatomic) BOOL multiple;

@end

@implementation MPAnswersViewController

#pragma mark - Life

- (void)viewDidLoad {

    [super viewDidLoad];

    self.tableView.tableHeaderView = [UIView new];
    self.tableView.tableFooterView = [UIView new];
    self.view.backgroundColor = [UIColor clearColor];

    [self.tableView automaticallyAdjustInsetsForKeyboard];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    PearlAddNotificationObserver( MPSignedOutNotification, nil, [NSOperationQueue mainQueue],
            ^(MPAnswersViewController *self, NSNotification *note) {
                if (![note.userInfo[@"animated"] boolValue])
                    [UIView setAnimationsEnabled:NO];
                [[MPOverlaySegue dismissViewController:self] perform];
                [UIView setAnimationsEnabled:YES];
            } );
}

- (void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];

    [self.view.window endEditing:YES];
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    PearlRemoveNotificationObserversFrom( self.tableView );
    PearlRemoveNotificationObservers();
}

- (UIStatusBarStyle)preferredStatusBarStyle {

    return UIStatusBarStyleLightContent;
}

#pragma mark - State

- (void)setSite:(MPSiteEntity *)site {

    self.siteOID = site.permanentObjectID;
    self.multiple = [site.questions count] > 0;
    [self.tableView reloadData];
    [self updateAnimated:NO];
}

- (void)setMultiple:(BOOL)multiple animated:(BOOL)animated {

    self.multiple = multiple;
    [self updateAnimated:animated];
}

- (MPSiteEntity *)siteInContext:(NSManagedObjectContext *)context {

    return [MPSiteEntity existingObjectWithID:self.siteOID inContext:context];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (section == 0)
        return 3;

    if (!self.multiple)
        return 0;

    return [[self siteInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]].questions count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    MPSiteEntity *site = [self siteInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]];
    if (indexPath.section == 0) {
        if (indexPath.item == 0) {
            MPGlobalAnswersCell *cell = [MPGlobalAnswersCell dequeueCellFromTableView:tableView indexPath:indexPath];
            [cell setSite:site];
            return cell;
        }
        if (indexPath.item == 1)
            return [MPSendAnswersCell dequeueCellFromTableView:tableView indexPath:indexPath];
        if (indexPath.item == 2) {
            MPMultipleAnswersCell *cell = [MPMultipleAnswersCell dequeueCellFromTableView:tableView indexPath:indexPath];
            cell.accessoryType = self.multiple? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
            return cell;
        }
        Throw( @"Unsupported row index: %@", indexPath );
    }

    MPAnswersQuestionCell *cell = [MPAnswersQuestionCell dequeueCellFromTableView:tableView indexPath:indexPath];
    MPSiteQuestionEntity *question = nil;
    if ([site.questions count] > indexPath.item)
        question = site.questions[indexPath.item];
    [cell setQuestion:question forSite:site inVC:self];

    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section == 0) {
        if (indexPath.item == 0)
            return 133;
        return 44;
    }

    return 130;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    MPSiteEntity *site = [self siteInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    if ([cell isKindOfClass:[MPGlobalAnswersCell class]])
        [self copyAnswer:((MPGlobalAnswersCell *)cell).answerField.text];

    else if ([cell isKindOfClass:[MPMultipleAnswersCell class]]) {
        if (!self.multiple)
            [self setMultiple:YES animated:YES];

        else if (self.multiple) {
            if (![site.questions count])
                [self setMultiple:NO animated:YES];

            else
                [PearlAlert showAlertWithTitle:@"Remove Site Questions?" message:
                                @"Do you want to remove the questions you have configured for this site?"
                                     viewStyle:UIAlertViewStyleDefault initAlert:nil
                             tappedButtonBlock:^(UIAlertView *alert, NSInteger buttonIndex) {
                                 if (buttonIndex == [alert cancelButtonIndex])
                                     return;

                                 [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                                     MPSiteEntity *site_ = [self siteInContext:context];
                                     NSOrderedSet *questions = [site_.questions copy];
                                     for (MPSiteQuestionEntity *question in questions)
                                         [context deleteObject:question];
                                     [context saveToStore];
                                     [self setMultiple:NO animated:YES];
                                 }];
                             } cancelTitle:@"Cancel" otherTitles:@"Remove Questions", nil];
        }
    }

    else if ([cell isKindOfClass:[MPSendAnswersCell class]]) {
        NSString *body;
        if (!self.multiple) {
            NSObject *answer = [site resolveSiteAnswerUsingKey:[MPiOSAppDelegate get].key];
            body = strf( @"Master Password generated the following security answer for your site: %@\n\n"
                    @"%@\n"
                    @"\n\nYou should use this as the answer to each security question the site asks you.\n"
                    @"Do not share this answer with others!", site.name, answer );
        }
        else {
            NSMutableString *bodyBuilder = [NSMutableString string];
            [bodyBuilder appendFormat:@"Master Password generated the following security answers for your site: %@\n\n", site.name];
            for (MPSiteQuestionEntity *question in site.questions) {
                NSObject *answer = [question resolveQuestionAnswerUsingKey:[MPiOSAppDelegate get].key];
                [bodyBuilder appendFormat:@"For question: '%@', use answer: %@\n", question.keyword, answer];
            }
            [bodyBuilder appendFormat:@"\n\nUse the answer for the matching security question.\n"
                    @"Do not share this answer with others!"];
            body = bodyBuilder;
        }

        [PearlEMail sendEMailTo:nil fromVC:self subject:strf( @"Master Password security answers for %@", site.name ) body:body];
    }

    else if ([cell isKindOfClass:[MPAnswersQuestionCell class]])
        [self copyAnswer:((MPAnswersQuestionCell *)cell).answerField.text];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)copyAnswer:(NSString *)answer {

    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    if (@available(iOS 10.0, *)) {
        [pasteboard setItems:@[ @{ UIPasteboardTypeAutomatic: answer } ]
                     options:@{
                             UIPasteboardOptionLocalOnly     : @NO,
                             UIPasteboardOptionExpirationDate: [NSDate dateWithTimeIntervalSinceNow:3 * 60]
                     }];
        [PearlOverlay showTemporaryOverlayWithTitle:strl( @"Answer Copied (3 min)" ) dismissAfter:2];
    }
    else {
        pasteboard.string = answer;
        [PearlOverlay showTemporaryOverlayWithTitle:strl( @"Answer Copied" ) dismissAfter:2];
    }
}

#pragma mark - Private

- (void)updateAnimated:(BOOL)animated {

    PearlMainQueue( ^{
        UITableViewCell *multipleAnswersCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]];
        multipleAnswersCell.accessoryType = self.multiple? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    } );
}

- (void)didAddQuestion:(MPSiteQuestionEntity *)question toSite:(MPSiteEntity *)site {

    NSUInteger newQuestionRow = [site.questions count];
    PearlMainQueue( ^{
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:newQuestionRow inSection:1] ]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    } );
}

@end

@implementation MPGlobalAnswersCell

#pragma mark - State

- (void)setSite:(MPSiteEntity *)site {

    self.titleLabel.text = strl( @"Answer for %@:", site.name );
    self.answerField.text = @"...";
    [site resolveSiteAnswerUsingKey:[MPiOSAppDelegate get].key result:^(NSString *result) {
        PearlMainQueue( ^{
            self.answerField.text = result;
        } );
    }];
}

@end

@implementation MPSendAnswersCell

@end

@implementation MPMultipleAnswersCell

@end

@interface MPAnswersQuestionCell()

@property(nonatomic, strong) NSManagedObjectID *siteOID;
@property(nonatomic, strong) NSManagedObjectID *questionOID;
@property(nonatomic, weak) MPAnswersViewController *answersVC;

@end

@implementation MPAnswersQuestionCell

#pragma mark - State

- (void)setQuestion:(MPSiteQuestionEntity *)question forSite:(MPSiteEntity *)site inVC:(MPAnswersViewController *)answersVC {

    self.siteOID = site.permanentObjectID;
    self.questionOID = question.permanentObjectID;
    self.answersVC = answersVC;

    [self updateAnswerForQuestion:question ofSite:site];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    [textField resignFirstResponder];

    return NO;
}

- (IBAction)textFieldDidChange:(UITextField *)textField {

    NSString *keyword = textField.text;
    [MPiOSAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
        BOOL didAddQuestionObject = NO;
        MPSiteEntity *site = [MPSiteEntity existingObjectWithID:self.siteOID inContext:context];
        MPSiteQuestionEntity *question = [MPSiteQuestionEntity existingObjectWithID:self.questionOID inContext:context];
        if (!question) {
            didAddQuestionObject = YES;
            [site addQuestionsObject:question = [MPSiteQuestionEntity insertNewObjectInContext:context]];
            question.site = site;
        }

        question.keyword = keyword;

        if ([context saveToStore]) {
            self.questionOID = question.permanentObjectID;
            [self updateAnswerForQuestion:question ofSite:site];

            if (didAddQuestionObject)
                [self.answersVC didAddQuestion:question toSite:site];
        }
    }];
}

#pragma mark - Private

- (void)updateAnswerForQuestion:(MPSiteQuestionEntity *)question ofSite:(MPSiteEntity *)site {

    if (!question)
        PearlMainQueue( ^{
            self.questionField.text = self.answerField.text = nil;
        } );

    else {
        NSString *keyword = question.keyword;
        PearlMainQueue( ^{
            self.answerField.text = @"...";
        } );
        [question resolveQuestionAnswerUsingKey:[MPiOSAppDelegate get].key result:^(NSString *result) {
            PearlMainQueue( ^{
                self.questionField.text = keyword;
                self.answerField.text = result;
            } );
        }];
    }
}

@end

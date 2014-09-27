//
//  MPPreferencesViewController.m
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 04/06/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPAnswersViewController.h"
#import "MPiOSAppDelegate.h"
#import "MPAppDelegate_Key.h"
#import "MPAppDelegate_Store.h"
#import "UIColor+Expanded.h"
#import "MPPasswordsViewController.h"
#import "MPCoachmarkViewController.h"
#import "MPSiteQuestionEntity.h"
#import "MPOverlayViewController.h"

@interface MPAnswersViewController()

@end

@implementation MPAnswersViewController {
    NSManagedObjectID *_siteOID;
    BOOL _multiple;
}

#pragma mark - Life

- (void)viewDidLoad {

    [super viewDidLoad];

    self.tableView.tableHeaderView = [UIView new];
    self.tableView.tableFooterView = [UIView new];
    self.view.backgroundColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated {

    [super viewWillAppear:animated];

    PearlAddNotificationObserver( MPSignedOutNotification, nil, [NSOperationQueue mainQueue], ^(NSNotification *note) {
        if (![note.userInfo[@"animated"] boolValue])
            [UIView setAnimationsEnabled:NO];
        [[MPOverlaySegue dismissViewController:self] perform];
        [UIView setAnimationsEnabled:YES];
    } );
}

- (void)viewWillDisappear:(BOOL)animated {

    [super viewWillDisappear:animated];

    PearlRemoveNotificationObservers();
}

- (UIStatusBarStyle)preferredStatusBarStyle {

    return UIStatusBarStyleLightContent;
}

#pragma mark - State

- (void)setSite:(MPSiteEntity *)site {

    _siteOID = [site objectID];
    _multiple = [site.questions count] > 0;
    [self.tableView reloadData];
    [self updateAnimated:NO];
}

- (void)setMultiple:(BOOL)multiple animated:(BOOL)animated {

    _multiple = multiple;
    [self updateAnimated:animated];
}

- (MPSiteEntity *)siteInContext:(NSManagedObjectContext *)context {

    return [MPSiteEntity existingObjectWithID:_siteOID inContext:context];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (section == 0)
        return 3;

    if (!_multiple)
        return 0;

    return MAX( 2, [[self siteInContext:[MPiOSAppDelegate managedObjectContextForMainThreadIfReady]].questions count] );
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
            cell.accessoryType = _multiple? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
            return cell;
        }
        Throw( @"Unsupported row index: %@", indexPath );
    }

    MPAnswersQuestionCell *cell = [MPAnswersQuestionCell dequeueCellFromTableView:tableView indexPath:indexPath];
    MPSiteQuestionEntity *question = nil;
    if ([site.questions count] > indexPath.item)
        question = site.questions[indexPath.item];
    [cell setQuestion:question forSite:site];

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

    if ([cell isKindOfClass:[MPGlobalAnswersCell class]]) {
        [PearlOverlay showTemporaryOverlayWithTitle:strl( @"Answer Copied" ) dismissAfter:2];
        [UIPasteboard generalPasteboard].string = ((MPGlobalAnswersCell *)cell).answerField.text;
    }
    else if ([cell isKindOfClass:[MPMultipleAnswersCell class]]) {
        if (!_multiple)
            [self setMultiple:YES animated:YES];

        else if (_multiple) {
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
                                     [site_ removeQuestions:questions];
                                     [context saveToStore];
                                     [self setMultiple:NO animated:YES];
                                 }];
                             } cancelTitle:@"Cancel" otherTitles:@"Remove Questions", nil];
        }
    }
    else if ([cell isKindOfClass:[MPSendAnswersCell class]]) {
        NSString *body;
        if (!_multiple) {
            NSObject *answer = [site.algorithm resolveAnswerForSite:site usingKey:[MPiOSAppDelegate get].key];
            body = strf( @"Master Password generated the following security answer for your site: %@\n\n"
                    @"%@\n"
                    @"\n\nYou should use this as the answer to each security question the site asks you.\n"
                    @"Do not share this answer with others!", site.name, answer );
        }
        else {
            NSMutableString *bodyBuilder = [NSMutableString string];
            [bodyBuilder appendFormat:@"Master Password generated the following security answers for your site: %@\n\n", site.name];
            for (MPSiteQuestionEntity *question in site.questions) {
                NSObject *answer = [site.algorithm resolveAnswerForQuestion:question ofSite:site usingKey:[MPiOSAppDelegate get].key];
                [bodyBuilder appendFormat:@"For question: '%@', use answer: %@\n", question.keyword, answer];
            }
            [bodyBuilder appendFormat:@"\n\nUse the answer for the matching security question.\n"
                    @"Do not share this answer with others!"];
            body = bodyBuilder;
        }

        [PearlEMail sendEMailTo:nil fromVC:self subject:strf( @"Master Password security answers for %@", site.name ) body:body];
    }
    else if ([cell isKindOfClass:[MPAnswersQuestionCell class]]) {
        [PearlOverlay showTemporaryOverlayWithTitle:strl( @"Answer Copied" ) dismissAfter:2];
        [UIPasteboard generalPasteboard].string = ((MPAnswersQuestionCell *)cell).answerField.text;
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Private

- (void)updateAnimated:(BOOL)animated {

    PearlMainQueue( ^{
        UITableViewCell *multipleAnswersCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]];
        multipleAnswersCell.accessoryType = _multiple? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
        }];
    } );
}

@end

@implementation MPGlobalAnswersCell

#pragma mark - State

- (void)setSite:(MPSiteEntity *)site {

    self.titleLabel.text = strl( @"Answer for %@:", site.name );
    self.answerField.text = @"...";
    [site.algorithm resolveAnswerForSite:site usingKey:[MPiOSAppDelegate get].key result:^(NSString *result) {
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

@implementation MPAnswersQuestionCell {
    NSManagedObjectID *_siteOID;
    NSManagedObjectID *_questionOID;
}

#pragma mark - State

- (void)setQuestion:(MPSiteQuestionEntity *)question forSite:(MPSiteEntity *)site {

    _siteOID = site.objectID;
    _questionOID = question.objectID;

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
        MPSiteEntity *site = [MPSiteEntity existingObjectWithID:_siteOID inContext:context];
        MPSiteQuestionEntity *question = [MPSiteQuestionEntity existingObjectWithID:_questionOID inContext:context];
        if (!question)
            [site addQuestionsObject:question = [MPSiteQuestionEntity insertNewObjectInContext:context]];

        question.keyword = keyword;

        if ([context saveToStore]) {
            if ([question.objectID isTemporaryID]) {
                NSError *error = nil;
                [context obtainPermanentIDsForObjects:@[ question ] error:&error];
                if (error)
                    err( @"Failed to obtain permanent object ID: %@", [error fullDescription] );
            }

            _questionOID = question.objectID;
            [self updateAnswerForQuestion:question ofSite:site];
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
        [site.algorithm resolveAnswerForQuestion:question ofSite:site usingKey:[MPiOSAppDelegate get].key result:^(NSString *result) {
            PearlMainQueue( ^{
                self.questionField.text = keyword;
                self.answerField.text = result;
            } );
        }];
    }
}

@end

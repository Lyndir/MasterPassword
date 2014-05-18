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
//  MPElementCollectionView.h
//  MPElementCollectionView
//
//  Created by lhunath on 2/11/2014.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MPElementCollectionView.h"
#import "MPElementModel.h"
#import "MPMacAppDelegate.h"
#import "MPAppDelegate_Store.h"

#define MPAlertChangeType @"MPAlertChangeType"
#define MPAlertChangeLogin @"MPAlertChangeLogin"
#define MPAlertChangeContent @"MPAlertChangeContent"
#define MPAlertDeleteSite @"MPAlertDeleteSite"

@implementation MPElementCollectionView {
}

@dynamic representedObject;

- (id)initWithCoder:(NSCoder *)coder {

    if (!(self = [super initWithCoder:coder]))
        return nil;

    [self addObserver:self forKeyPath:@"representedObject" options:0 context:nil];

    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.counterHidden = !(MPElementTypeClassGenerated & self.representedObject.type);
        self.updateContentHidden = !(MPElementTypeClassStored & self.representedObject.type);
    }];
}

- (void)dealloc {

    [self removeObserver:self forKeyPath:@"representedObject"];
}

- (IBAction)toggleType:(id)sender {

    id<MPAlgorithm> algorithm = self.representedObject.algorithm;
    NSString *previousType = [algorithm nameOfType:[algorithm previousType:self.representedObject.type]];
    NSString *nextType = [algorithm nameOfType:[algorithm nextType:self.representedObject.type]];

    [[NSAlert alertWithMessageText:@"Change Password Type"
                     defaultButton:nextType alternateButton:@"Cancel" otherButton:previousType
         informativeTextWithFormat:@"Changing the password type for this site will cause the password to change.\n"
                 @"You will need to update your account with the new password.\n\n"
                 @"Changing back to the old type will restore your current password."]
            beginSheetModalForWindow:self.view.window modalDelegate:self
                      didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:MPAlertChangeType];
}

- (IBAction)updateLoginName:(id)sender {

    NSAlert *alert = [NSAlert alertWithMessageText:@"Update Login Name"
                                     defaultButton:@"Update" alternateButton:@"Cancel" otherButton:nil
                         informativeTextWithFormat:@"Enter the login name for %@:", self.representedObject.site];
    NSTextField *passwordField = [[NSTextField alloc] initWithFrame:NSMakeRect( 0, 0, 200, 22 )];
    [alert setAccessoryView:passwordField];
    [alert layout];
    [passwordField becomeFirstResponder];
    [alert beginSheetModalForWindow:self.view.window modalDelegate:self
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:MPAlertChangeLogin];
}

- (IBAction)updateContent:(id)sender {

    NSAlert *alert = [NSAlert alertWithMessageText:@"Update Password"
                                     defaultButton:@"Update" alternateButton:@"Cancel" otherButton:nil
                         informativeTextWithFormat:@"Enter the new password for %@:", self.representedObject.site];
    NSSecureTextField *passwordField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect( 0, 0, 200, 22 )];
    [alert setAccessoryView:passwordField];
    [alert layout];
    [passwordField becomeFirstResponder];
    [alert beginSheetModalForWindow:self.view.window modalDelegate:self
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:MPAlertChangeContent];
}

- (IBAction)delete:(id)sender {

    NSAlert *alert = [NSAlert alertWithMessageText:@"Delete Site"
                                     defaultButton:@"Delete" alternateButton:@"Cancel" otherButton:nil
                         informativeTextWithFormat:@"Are you sure you want to delete the site: %@?", self.representedObject.site];
    [alert beginSheetModalForWindow:self.view.window modalDelegate:self
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:MPAlertDeleteSite];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {

    if (contextInfo == MPAlertChangeType) {
        switch (returnCode) {
            case NSAlertDefaultReturn: {
                // "Next type" button.
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPElementEntity *element = [self.representedObject entityInContext:context];
                    element = [[MPMacAppDelegate get] changeElement:element saveInContext:context
                                                             toType:[element.algorithm nextType:element.type]];

                    self.representedObject = [[MPElementModel alloc] initWithEntity:element];
                }];
                break;
            }

            case NSAlertAlternateReturn: {
                // "Cancel" button.
                break;
            }

            case NSAlertOtherReturn: {
                // "Previous type" button.
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPElementEntity *element = [self.representedObject entityInContext:context];
                    element = [[MPMacAppDelegate get] changeElement:element saveInContext:context
                                                             toType:[element.algorithm previousType:element.type]];

                    self.representedObject = [[MPElementModel alloc] initWithEntity:element];
                }];
                break;
            }

            default:
                break;
        }

        return;
    }
    if (contextInfo == MPAlertChangeLogin) {
        switch (returnCode) {
            case NSAlertDefaultReturn: {
                // "Update" button.
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPElementEntity *element = [self.representedObject entityInContext:context];
                    element.loginName = [(NSTextField *)alert.accessoryView stringValue];
                    [context saveToStore];

                    self.representedObject = [[MPElementModel alloc] initWithEntity:element];
                }];
                break;
            }

            case NSAlertAlternateReturn: {
                // "Cancel" button.
                break;
            }

            default:
                break;
        }

        return;
    }
    if (contextInfo == MPAlertChangeContent) {
        switch (returnCode) {
            case NSAlertDefaultReturn: {
                // "Update" button.
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPElementEntity *element = [self.representedObject entityInContext:context];
                    [element.algorithm saveContent:[(NSSecureTextField *)alert.accessoryView stringValue]
                                         toElement:element usingKey:[MPMacAppDelegate get].key];
                    [context saveToStore];

                    self.representedObject = [[MPElementModel alloc] initWithEntity:element];
                }];
                break;
            }

            case NSAlertAlternateReturn: {
                // "Cancel" button.
                break;
            }

            default:
                break;
        }

        return;
    }
    if (contextInfo == MPAlertDeleteSite) {
        switch (returnCode) {
            case NSAlertDefaultReturn: {
                // "Delete" button.
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPElementEntity *element = [self.representedObject entityInContext:context];
                    [context deleteObject:element];
                    [context saveToStore];

                    [((MPPasswordWindowController *)self.collectionView.window.windowController) updateElements];
                }];
                break;
            }

            case NSAlertAlternateReturn: {
                // "Cancel" button.
                break;
            }

            default:
                break;
        }

        return;
    }
}

@end

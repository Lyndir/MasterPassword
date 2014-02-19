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

#import "MPElementCollectionView.h"
#import "MPElementModel.h"
#import "MPMacAppDelegate.h"
#import "MPAppDelegate_Store.h"

#define MPAlertChangeType @"MPAlertChangeType"
#define MPAlertChangeLogin @"MPAlertChangeLogin"
#define MPAlertChangeCounter @"MPAlertChangeCounter"
#define MPAlertChangeContent @"MPAlertChangeContent"

@implementation MPElementCollectionView {
    id _representedObjectObserver;
}

@dynamic representedObject;

- (id)initWithCoder:(NSCoder *)coder {

    if (!(self = [super initWithCoder:coder]))
        return nil;

    __weak MPElementCollectionView *wSelf = self;
    _representedObjectObserver = [self addObserverBlock:^(NSString *keyPath, id object, NSDictionary *change, void *context) {
        dispatch_async( dispatch_get_main_queue(), ^{
            dbg(@"updating login name of %@ to: %@", wSelf.representedObject.site, wSelf.representedObject.loginName);
            wSelf.typeTitle = PearlString( @"Type:\n%@", wSelf.representedObject.typeName );
            wSelf.loginNameTitle = PearlString( @"Login Name:\n%@", wSelf.representedObject.loginName );

            if (wSelf.representedObject.type & MPElementTypeClassGenerated)
                wSelf.counterTitle = PearlString( @"Number:\n%@", wSelf.representedObject.counter );
            else if (wSelf.representedObject.type & MPElementTypeClassStored)
                wSelf.counterTitle = PearlString( @"Update Password" );
        } );
    }                                        forKeyPath:@"representedObject" options:0 context:nil];

    return self;
}

- (void)dealloc {

    if (_representedObjectObserver)
        [self removeObserver:_representedObjectObserver forKeyPath:@"representedObject"];
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

- (IBAction)setLoginName:(id)sender {

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

- (IBAction)incrementCounter:(id)sender {

    if (self.representedObject.type & MPElementTypeClassGenerated) {
        [[NSAlert alertWithMessageText:@"Change Password Number"
                         defaultButton:@"New Password" alternateButton:@"Cancel" otherButton:@"Initial Password"
             informativeTextWithFormat:@"Increasing the password number gives you a new password for the site.\n"
                     @"You will need to update your account with the new password.\n\n"
                     @"Changing back to the initial password will reset the password number to 1."]
                beginSheetModalForWindow:self.view.window modalDelegate:self
                          didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:MPAlertChangeCounter];
    }

    else if (self.representedObject.type & MPElementTypeClassStored) {
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
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {

    if (contextInfo == MPAlertChangeType) {
        switch (returnCode) {
            case NSAlertDefaultReturn: {
                // "Next type" button.
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPElementEntity *element = [self.representedObject entityInContext:context];
                    element = [[MPMacAppDelegate get] changeElement:element inContext:context
                                                             toType:[element.algorithm nextType:element.type]];
                    [context saveToStore];

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
                    element = [[MPMacAppDelegate get] changeElement:element inContext:context
                                                             toType:[element.algorithm previousType:element.type]];
                    [context saveToStore];

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
    if (contextInfo == MPAlertChangeCounter) {
        switch (returnCode) {
            case NSAlertDefaultReturn: {
                // "New Password" button.
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPElementEntity *element = [self.representedObject entityInContext:context];
                    if ([element isKindOfClass:[MPElementGeneratedEntity class]]) {
                        MPElementGeneratedEntity *generatedElement = (MPElementGeneratedEntity *)element;
                        ++generatedElement.counter;
                        [context saveToStore];

                        self.representedObject = [[MPElementModel alloc] initWithEntity:element];
                    }
                }];
                break;
            }

            case NSAlertAlternateReturn: {
                // "Cancel" button.
                break;
            }

            case NSAlertOtherReturn: {
                // "Initial Password" button.
                [MPMacAppDelegate managedObjectContextPerformBlock:^(NSManagedObjectContext *context) {
                    MPElementEntity *element = [self.representedObject entityInContext:context];
                    if ([element isKindOfClass:[MPElementGeneratedEntity class]]) {
                        MPElementGeneratedEntity *generatedElement = (MPElementGeneratedEntity *)element;
                        generatedElement.counter = 1;
                        [context saveToStore];

                        self.representedObject = [[MPElementModel alloc] initWithEntity:element];
                    }
                }];
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
}

@end

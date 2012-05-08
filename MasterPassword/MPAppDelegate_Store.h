//
//  MPAppDelegate_Key.h
//  MasterPassword
//
//  Created by Maarten Billemont on 24/11/11.
//  Copyright (c) 2011 Lyndir. All rights reserved.
//

#import "MPAppDelegate_Shared.h"

#import "UbiquityStoreManager.h"

@interface MPAppDelegate (Store) <UbiquityStoreManagerDelegate>

+ (NSManagedObjectContext *)managedObjectContext;
+ (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;
- (NSManagedObjectModel *)managedObjectModel;

- (UbiquityStoreManager *)storeManager;
- (void)saveContext;
- (void)printStore;

- (NSString *)exportSitesShowingPasswords:(BOOL)showPasswords;

@end

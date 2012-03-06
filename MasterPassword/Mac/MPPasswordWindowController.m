//
//  MPPasswordWindowController.m
//  MasterPassword-Mac
//
//  Created by Maarten Billemont on 04/03/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import "MPPasswordWindowController.h"
#import "MPAppDelegate_Key.h"
#import "MPElementEntity.h"
#import "MPElementGeneratedEntity.h"

@interface MPPasswordWindowController ()

@property (nonatomic, strong) NSString                      *oldSiteName;
@property (nonatomic, strong) NSArray /* MPElementEntity */ *siteResults;

@end

@implementation MPPasswordWindowController
@synthesize oldSiteName, siteResults;
@synthesize siteField;
@synthesize contentField;

- (void)windowDidLoad {
    
    [self.contentField setStringValue:@""];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:self.window queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [[NSApplication sharedApplication] hide:self];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSControlTextDidChangeNotification object:self.siteField queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      NSString *newSiteName = [self.siteField stringValue];
                                                      BOOL shouldComplete = [self.oldSiteName length] < [newSiteName length];
                                                      self.oldSiteName = newSiteName;
                                                      if (shouldComplete)
                                                          [[[note userInfo] objectForKey:@"NSFieldEditor"] complete:nil];
                                                  }];
    
    [super windowDidLoad];
}

- (NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
    
    NSString *query = [[control stringValue] substringWithRange:charRange];
    
    assert(query);
    assert([MPAppDelegate get].keyHashHex);
    NSFetchRequest *fetchRequest = [MPAppDelegate.managedObjectModel
                                    fetchRequestFromTemplateWithName:@"MPElements"
                                    substitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
                                                           query,                                   @"query",
                                                           [MPAppDelegate get].keyHashHex,          @"mpHashHex",
                                                           nil]];
    [fetchRequest setSortDescriptors:
     [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"uses" ascending:NO]]];
    
    NSError *error = nil;
    self.siteResults = [[MPAppDelegate managedObjectContext] executeFetchRequest:fetchRequest error:&error];
    if (error)
        err(@"Couldn't fetch elements: %@", error);
    
    NSMutableArray *mutableResults = [NSMutableArray arrayWithCapacity:[self.siteResults count] + 1];
    if (self.siteResults)
        for (MPElementEntity *element in self.siteResults)
            [mutableResults addObject:element.name];
    [mutableResults addObject:query];
    return mutableResults;
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    
    if (obj.object == self.siteField) {
        NSString *siteName = [self.siteField stringValue];
        
        MPElementEntity *result = nil;
        for (MPElementEntity *element in self.siteResults)
            if ([element.name isEqualToString:siteName]) {
                result = element;
                break;
            }
        
        if (result)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                NSString *description = [result description];
                [result use];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.contentField setStringValue:description];
                });
            });
        
        else
            [[MPAppDelegate get].managedObjectContext performBlock:^{
                MPElementEntity *element = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([MPElementGeneratedEntity class])
                                                                         inManagedObjectContext:[MPAppDelegate get].managedObjectContext];
                assert([element isKindOfClass:ClassFromMPElementType(element.type)]);
                assert([MPAppDelegate get].keyHashHex);
                
                element.name = siteName;
                element.mpHashHex = [MPAppDelegate get].keyHashHex;
                
                NSString *description = [element description];
                [element use];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.contentField setStringValue:description? description: @""];
                });
            }];
    }
}

@end

//
//  MPPreferencesViewController.h
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 04/06/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MPMessage : NSObject

@property(nonatomic) NSString *title;
@property(nonatomic) NSString *text;
@property(nonatomic) BOOL info;

+ (instancetype)messageWithTitle:(NSString *)title text:(NSString *)text info:(BOOL)info;

@end

@interface MPMessageViewController : UIViewController

@property(nonatomic) MPMessage *message;

@end

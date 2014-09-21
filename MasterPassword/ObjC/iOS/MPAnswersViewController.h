//
//  MPPreferencesViewController.h
//  MasterPassword-iOS
//
//  Created by Maarten Billemont on 04/06/12.
//  Copyright (c) 2012 Lyndir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MPTypeViewController.h"

@interface MPAnswersViewController : UITableViewController

@end

@interface MPGlobalAnswersCell : UITableViewCell

@property (nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic) IBOutlet UITextField *answerField;

@end

@interface MPSendAnswersCell : UITableViewCell

@end

@interface MPMultipleAnswersCell : UITableViewCell

@end

@interface MPAnswersQuestionCell : UITableViewCell

@property(nonatomic) IBOutlet UITextField *questionField;
@property(nonatomic) IBOutlet UITextField *answerField;

@end

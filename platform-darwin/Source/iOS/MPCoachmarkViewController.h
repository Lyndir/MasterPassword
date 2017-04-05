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

#import <Foundation/Foundation.h>

@interface MPCoachmark : NSObject

@property(nonatomic, strong) Class coachedClass;
@property(nonatomic) NSInteger coachedVersion;
@property(nonatomic) BOOL coached;

+ (instancetype)coachmarkForClass:(Class)class version:(NSInteger)version;

@end

@interface MPCoachmarkViewController : UIViewController

@property(nonatomic, strong) MPCoachmark *coachmark;
@property(nonatomic, strong) IBOutlet UIView *view0;
@property(nonatomic, strong) IBOutlet UIView *view1;
@property(nonatomic, strong) IBOutlet UIView *view2;
@property(nonatomic, strong) IBOutlet UIView *view3;
@property(nonatomic, strong) IBOutlet UIView *view4;
@property(nonatomic, strong) IBOutlet UIView *view5;
@property(nonatomic, strong) IBOutlet UIView *view6;
@property(nonatomic, strong) IBOutlet UIView *view7;
@property(nonatomic, strong) IBOutlet UIView *view8;
@property(nonatomic, strong) IBOutlet UIView *view9;
@property(nonatomic, strong) IBOutlet UIProgressView *viewProgress;

- (IBAction)close:(id)sender;

@end

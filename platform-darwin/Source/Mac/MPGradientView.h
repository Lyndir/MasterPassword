//
// Created by Maarten Billemont on 2016-05-15.
// Copyright (c) 2016 Lyndir. All rights reserved.
//

#import <Foundation/Foundation.h>

IB_DESIGNABLE
@interface MPGradientView : NSView

@property(nonatomic, retain) IBInspectable NSColor *startingColor;
@property(nonatomic, retain) IBInspectable NSColor *endingColor;
@property(nonatomic, assign) IBInspectable NSInteger angle;
@property(nonatomic, assign) IBInspectable CGFloat ratio;

@end

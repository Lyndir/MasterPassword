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

#import "MPGradientView.h"

@interface MPGradientView()

@property(nonatomic, strong) NSGradient *gradient;

@end

@implementation MPGradientView

- (id)initWithFrame:(NSRect)frame {

    if (!(self = [super initWithFrame:frame]))
        return nil;

    [self defaults];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {

    if (!(self = [super initWithCoder:coder]))
        return nil;

    [self defaults];
    return self;
}

- (void)defaults {

    self.startingColor = [NSColor colorWithCalibratedWhite:0.0 alpha:0.0];
    self.endingColor = [NSColor colorWithCalibratedWhite:0.0 alpha:1.0];
    self.angle = 270;
    self.ratio = 0.5f;
}

- (void)setStartingColor:(NSColor *)startingColor {

    _startingColor = startingColor;
    self.gradient = nil;
    [self setNeedsDisplay:YES];
}

- (void)setEndingColor:(NSColor *)endingColor {

    _endingColor = endingColor;
    self.gradient = nil;
    [self setNeedsDisplay:YES];
}

- (void)setAngle:(NSInteger)angle {

    _angle = angle;
    self.gradient = nil;
    [self setNeedsDisplay:YES];
}

- (void)setRatio:(CGFloat)ratio {

    _ratio = ratio;
    self.gradient = nil;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {

    if (!self.startingColor || !self.endingColor || [self.startingColor isEqual:self.endingColor]) {
        [(self.startingColor?: self.endingColor) set];
        NSRectFill( dirtyRect );
        return;
    }

    [(self.gradient?: (self.gradient = [[NSGradient alloc] initWithColorsAndLocations:
            self.startingColor, (CGFloat)0.f,
            [self.startingColor blendedColorWithFraction:0.5f ofColor:self.endingColor], self.ratio,
            self.endingColor, (CGFloat)1.f, nil]))
            drawInRect:self.bounds angle:self.angle];
}

@end

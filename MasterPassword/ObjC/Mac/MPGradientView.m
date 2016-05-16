//
// Created by Maarten Billemont on 2016-05-15.
// Copyright (c) 2016 Lyndir. All rights reserved.
//

#import "MPGradientView.h"

@implementation MPGradientView {
    NSGradient *gradient;
}

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
    gradient = nil;
    [self setNeedsDisplay:YES];
}

- (void)setEndingColor:(NSColor *)endingColor {

    _endingColor = endingColor;
    gradient = nil;
    [self setNeedsDisplay:YES];
}

- (void)setAngle:(NSInteger)angle {

    _angle = angle;
    gradient = nil;
    [self setNeedsDisplay:YES];
}

- (void)setRatio:(CGFloat)ratio {

    _ratio = ratio;
    gradient = nil;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {

    if (!self.startingColor || !self.endingColor || [self.startingColor isEqual:self.endingColor]) {
        [(self.startingColor?: self.endingColor) set];
        NSRectFill( dirtyRect );
        return;
    }

    [(gradient?: (gradient = [[NSGradient alloc] initWithColorsAndLocations:
            self.startingColor, (CGFloat)0.f,
            [self.startingColor blendedColorWithFraction:0.5f ofColor:self.endingColor], self.ratio,
            self.endingColor, (CGFloat)1.f, nil]))
            drawInRect:self.bounds angle:self.angle];
}

@end

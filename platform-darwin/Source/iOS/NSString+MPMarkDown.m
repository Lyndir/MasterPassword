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

#import "NSString+MPMarkDown.h"
#import "markdown_lib.h"
#import "markdown_peg.h"

@implementation NSString(MPMarkDown)

- (NSAttributedString *)attributedMarkdownStringWithFontSize:(CGFloat)fontSize {

    NSMutableAttributedString *attributedString = markdown_to_attr_string( self, 0, @{
            @(EMPH)         : @{ NSFontAttributeName: [UIFont fontWithName:@"Exo2.0-Bold" size:fontSize] },
            @(STRONG)       : @{ NSFontAttributeName: [UIFont fontWithName:@"Exo2.0-ExtraBold" size:fontSize] },
            @(EMPH | STRONG): @{ NSFontAttributeName: [UIFont fontWithName:@"Exo2.0-ExtraBold" size:fontSize] },
            @(PLAIN)        : @{ NSFontAttributeName: [UIFont fontWithName:@"Exo2.0-Regular" size:fontSize] },
            @(H1)           : @{ NSFontAttributeName: [UIFont fontWithName:@"Exo2.0-Thin" size:fontSize * 2.f] },
            @(H2)           : @{ NSFontAttributeName: [UIFont fontWithName:@"Exo2.0-Thin" size:fontSize * 1.5f] },
            @(H3)           : @{ NSFontAttributeName: [UIFont fontWithName:@"Exo2.0-Thin" size:fontSize * 1.17f] },
            @(H4)           : @{ NSFontAttributeName: [UIFont fontWithName:@"Exo2.0-Thin" size:fontSize * 1.f] },
            @(H5)           : @{ NSFontAttributeName: [UIFont fontWithName:@"Exo2.0-Thin" size:fontSize * .83f] },
            @(H6)           : @{ NSFontAttributeName: [UIFont fontWithName:@"Exo2.0-Thin" size:fontSize * .75f] },
            @(BLOCKQUOTE)   : @{ NSFontAttributeName: [UIFont fontWithName:@"Exo2.0-Thin" size:fontSize * 1.17f] },
            @(CODE)         : @{ NSFontAttributeName: [UIFont fontWithName:@"SourceCodePro-Regular" size:fontSize] },
            @(VERBATIM)     : @{ NSFontAttributeName: [UIFont fontWithName:@"SourceCodePro-Regular" size:fontSize] },
            @(NOTE)         : @{ NSFontAttributeName: [UIFont fontWithName:@"Exo2.0-Thin" size:fontSize * 1.17f] },
    } );

    // Trim trailing newlines.
    NSCharacterSet *trimSet = [NSCharacterSet newlineCharacterSet];
    while (YES) {
        NSRange range = [attributedString.string rangeOfCharacterFromSet:trimSet options:NSBackwardsSearch];
        if (!range.length || NSMaxRange( range ) != attributedString.length)
            break;

        [attributedString replaceCharactersInRange:range withString:@""];
    }

    return attributedString;
}
@end

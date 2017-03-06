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
//  NSString(MPMarkDown).h
//  NSString(MPMarkDown)
//
//  Created by lhunath on 2014-09-28.
//  Copyright, lhunath (Maarten Billemont) 2014. All rights reserved.
//

#import "NSString+MPMarkDown.h"
#import "markdown_lib.h"
#import "markdown_peg.h"

@implementation NSString(MPMarkDown)

- (NSAttributedString *)attributedMarkdownStringWithFontSize:(CGFloat)fontSize {

    NSMutableAttributedString *attributedString = markdown_to_attr_string( self, 0, @{
            @(EMPH)          : @{ NSFontAttributeName : [UIFont fontWithName:@"Exo2.0-Bold" size:fontSize] },
            @(STRONG)        : @{ NSFontAttributeName : [UIFont fontWithName:@"Exo2.0-ExtraBold" size:fontSize] },
            @(EMPH | STRONG) : @{ NSFontAttributeName : [UIFont fontWithName:@"Exo2.0-ExtraBold" size:fontSize] },
            @(PLAIN)         : @{ NSFontAttributeName : [UIFont fontWithName:@"Exo2.0-Regular" size:fontSize] },
            @(H1)            : @{ NSFontAttributeName : [UIFont fontWithName:@"Exo2.0-Thin" size:fontSize * 2.f] },
            @(H2)            : @{ NSFontAttributeName : [UIFont fontWithName:@"Exo2.0-Thin" size:fontSize * 1.5f] },
            @(H3)            : @{ NSFontAttributeName : [UIFont fontWithName:@"Exo2.0-Thin" size:fontSize * 1.17f] },
            @(H4)            : @{ NSFontAttributeName : [UIFont fontWithName:@"Exo2.0-Thin" size:fontSize * 1.f] },
            @(H5)            : @{ NSFontAttributeName : [UIFont fontWithName:@"Exo2.0-Thin" size:fontSize * .83f] },
            @(H6)            : @{ NSFontAttributeName : [UIFont fontWithName:@"Exo2.0-Thin" size:fontSize * .75f] },
            @(BLOCKQUOTE)    : @{ NSFontAttributeName : [UIFont fontWithName:@"Exo2.0-Thin" size:fontSize * 1.17f] },
            @(CODE)          : @{ NSFontAttributeName : [UIFont fontWithName:@"SourceCodePro-Regular" size:fontSize] },
            @(VERBATIM)      : @{ NSFontAttributeName : [UIFont fontWithName:@"SourceCodePro-Regular" size:fontSize] },
            @(NOTE)          : @{ NSFontAttributeName : [UIFont fontWithName:@"Exo2.0-Thin" size:fontSize * 1.17f] },
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

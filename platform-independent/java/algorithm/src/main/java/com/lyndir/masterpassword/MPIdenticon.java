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

package com.lyndir.masterpassword;

import static com.lyndir.lhunath.opal.system.util.StringUtils.*;

import com.lyndir.lhunath.opal.system.logging.Logger;
import edu.umd.cs.findbugs.annotations.SuppressFBWarnings;
import java.util.Locale;


/**
 * @author lhunath, 15-03-29
 */
public class MPIdenticon {

    @SuppressWarnings("UnusedDeclaration")
    private static final Logger logger = Logger.get( MPIdenticon.class );

    private final String fullName;
    private final String leftArm;
    private final String body;
    private final String rightArm;
    private final String accessory;
    private final Color  color;

    @SuppressFBWarnings("CLI_CONSTANT_LIST_INDEX")
    @SuppressWarnings("MethodCanBeVariableArityMethod")
    public MPIdenticon(final String fullName, final String leftArm, final String body, final String rightArm, final String accessory,
                       final Color color) {
        this.fullName = fullName;
        this.leftArm = leftArm;
        this.body = body;
        this.rightArm = rightArm;
        this.accessory = accessory;
        this.color = color;
    }

    public String getFullName() {
        return fullName;
    }

    public String getText() {
        return strf( "%s%s%s%s", this.leftArm, this.body, this.rightArm, this.accessory );
    }

    public String getHTML() {
        return strf( "<span style='color: %s'>%s</span>", color.getCSS(), getText() );
    }

    public Color getColor() {
        return color;
    }

    public enum Color {
        UNSET {
            @Override
            public String getCSS() {
                return "inherit";
            }
        },
        RED,
        GREEN,
        YELLOW,
        BLUE,
        MAGENTA,
        CYAN,
        MONO {
            @Override
            public String getCSS() {
                return "inherit";
            }
        };

        public String getCSS() {
            return name().toLowerCase( Locale.ROOT );
        }
    }
}

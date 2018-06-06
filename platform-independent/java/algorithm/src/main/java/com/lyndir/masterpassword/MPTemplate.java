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

import com.google.common.collect.ImmutableList;
import com.lyndir.lhunath.opal.system.util.MetaObject;
import java.io.Serializable;
import java.util.List;
import org.jetbrains.annotations.NonNls;


/**
 * <i>07 04, 2012</i>
 *
 * @author lhunath
 */
public class MPTemplate extends MetaObject implements Serializable {

    private static final long serialVersionUID = 1L;

    private final String                         templateString;
    private final List<MPTemplateCharacterClass> template;

    MPTemplate(@NonNls final String templateString) {

        ImmutableList.Builder<MPTemplateCharacterClass> builder = ImmutableList.builder();
        for (int i = 0; i < templateString.length(); ++i)
            builder.add( MPTemplateCharacterClass.forIdentifier( templateString.charAt( i ) ) );

        this.templateString = templateString;
        template = builder.build();
    }

    public String getTemplateString() {
        return templateString;
    }

    public MPTemplateCharacterClass getCharacterClassAtIndex(final int index) {

        return template.get( index );
    }

    public int length() {

        return template.size();
    }

    @Override
    public String toString() {
        return strf( "{MPTemplate: %s}", templateString );
    }
}
